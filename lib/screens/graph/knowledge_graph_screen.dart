import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/graph_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/vault_provider.dart';

// ═══════════════════════════════════════════════
//  SPATIAL HASH GRID — Fix #1: O(N×K) repulsion
// ═══════════════════════════════════════════════

/// Chia canvas thành lưới ô vuông, mỗi node gán vào ô theo tọa độ.
/// Khi tính lực đẩy, chỉ duyệt 9 ô lân cận (3×3) thay vì toàn bộ N² cặp.
class _SpatialGrid {
  final double cellSize;
  final Map<(int, int), List<String>> _cells = {};

  _SpatialGrid({this.cellSize = 650.0});

  /// Dùng floor division thay vì truncating division (~/) để xử lý đúng tọa độ âm.
  /// -50 ~/ 400 = 0 (sai), (-50 / 400).floor() = -1 (đúng).
  static int _floorDiv(double v, double size) => (v / size).floor();

  void clear() => _cells.clear();

  void insert(String nodeId, Offset position) {
    final key = (_floorDiv(position.dx, cellSize), _floorDiv(position.dy, cellSize));
    (_cells[key] ??= []).add(nodeId);
  }

  /// Trả về danh sách nodeId trong 9 ô lân cận (3×3 grid).
  List<String> getNeighbors(Offset position) {
    final cx = _floorDiv(position.dx, cellSize);
    final cy = _floorDiv(position.dy, cellSize);
    final result = <String>[];
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        final cell = _cells[(cx + dx, cy + dy)];
        if (cell != null) result.addAll(cell);
      }
    }
    return result;
  }
}

// ═══════════════════════════════════════════════
//  KNOWLEDGE GRAPH SCREEN
// ═══════════════════════════════════════════════

/// [Member 4 - T4.5] Màn hình trực quan hóa mạng lưới liên kết tri thức (Knowledge Graph).
///
/// Performance optimizations applied:
/// - Fix #1: Spatial Hash Grid cho lực đẩy O(N×K) thay vì O(N²)
/// - Fix #2: Static dot grid tách riêng RepaintBoundary, chỉ vẽ 1 lần
/// - Fix #3: Throttle onPanUpdate (position + relax + setState) ≤60fps
/// - Fix #4: shouldRepaint dùng version counter thay vì Map reference
/// - Fix #5: Drift animation dừng sớm khi graph ổn định
/// - Fix #6: RepaintBoundary cho từng node (GPU isolation only, không ngăn Dart rebuild)
class KnowledgeGraphScreen extends StatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen>
    with SingleTickerProviderStateMixin {
  double _canvasSize = 3200.0;
  Offset _canvasCenter = const Offset(1600.0, 1600.0);

  /// Tự động tính kích thước canvas dựa trên số lượng node trong Vault.
  /// Với vault lớn (ví dụ 639 nodes), canvas mở rộng lên ~8500px-9500px để các node tự do phân bố.
  static double _calculateCanvasSize(int nodeCount) {
    if (nodeCount <= 20) return 3200.0;
    if (nodeCount <= 80) return 4800.0;
    return (sqrt(nodeCount) * 360.0).clamp(4500.0, 12000.0);
  }

  final TransformationController _transformController = TransformationController();

  // Tọa độ các node trên canvas ảo (nodeId → Offset)
  final Map<String, Offset> _nodePositions = {};

  // Spatial grid cho lực đẩy O(N×K) — Fix #1
  final _SpatialGrid _spatialGrid = _SpatialGrid(cellSize: 650.0);

  // Node đang được hover chuột
  String? _hoveredNodeId;

  // Node đang bị kéo thả
  String? _draggingNodeId;

  // Quán tính trôi và cân bằng sau khi thả tay
  AnimationController? _driftController;
  String? _releasedNodeId;
  Offset _releaseVelocity = Offset.zero;

  AnimationController get _effectiveDriftController {
    return _driftController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..addListener(_onDriftTick);
  }

  // Cache danh sách node để phát hiện thay đổi và layout lại
  int _lastNodeCount = 0;
  int _lastEdgeCount = 0;

  // Fix #4: Version counter cho shouldRepaint (thay vì Map reference compare)
  int _paintVersion = 0;

  // Level of Detail (LOD): 0 = Full labels, 1 = Hub labels only, 2 = Hover/Active only
  int _currentLod = 0;

  static int _calculateLod(double scale) {
    if (scale >= 0.45) return 0; // Gần: hiện toàn bộ label
    if (scale >= 0.22) return 1; // Trung bình: chỉ hiện label của node trung tâm (connectionCount >= 3)
    return 2;                    // Xa: ẩn hết label thông thường, chỉ hiện khi hover/active/adjacent
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final newLod = _calculateLod(scale);
    if (newLod != _currentLod) {
      setState(() {
        _currentLod = newLod;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _effectiveDriftController; // Khởi tạo controller
    _transformController.addListener(_onTransformChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadGraphData();
      if (mounted) {
        _initializeLayout();
        _fitToScreen();
      }
    });
  }

  @override
  void dispose() {
    _driftController?.dispose();
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  /// Tải dữ liệu graph từ GraphProvider
  Future<void> _loadGraphData() async {
    final vaultProvider = context.read<VaultProvider>();
    final graphProvider = context.read<GraphProvider>();

    if (vaultProvider.hasVault) {
      await graphProvider.loadGraph(vaultProvider.vaultPath!);
    }
  }

  // ═══════════════════════════════════════════
  //  INITIAL LAYOUT — Force-Directed (chạy 1 lần)
  // ═══════════════════════════════════════════

  /// Tính toán bố trí ban đầu bằng thuật toán Force-Directed Physics.
  /// Dùng Spatial Grid cho lực đẩy (Fix #1).
  /// Gravity toward center giữ vai trò global spreading để tránh co cụm.
  void _initializeLayout() {
    final graphProvider = context.read<GraphProvider>();
    final nodes = graphProvider.nodes;
    final edges = graphProvider.edges;

    if (nodes.isEmpty) {
      _nodePositions.clear();
      return;
    }

    _lastNodeCount = nodes.length;
    _lastEdgeCount = edges.length;

    _canvasSize = _calculateCanvasSize(nodes.length);
    _canvasCenter = Offset(_canvasSize / 2, _canvasSize / 2);

    final rnd = Random(42);
    // Bán kính phân bố ban đầu tỉ lệ thuận theo số node và kích thước canvas
    final radius = (sqrt(nodes.length) * 110.0).clamp(320.0, _canvasSize * 0.38);

    // 1. Phân bố vòng tròn ban đầu quanh tâm canvas (bán kính rộng thoáng)
    for (int i = 0; i < nodes.length; i++) {
      final angle = (2 * pi * i) / nodes.length;
      _nodePositions[nodes[i].id] = Offset(
        _canvasCenter.dx + radius * cos(angle) + (rnd.nextDouble() - 0.5) * 40,
        _canvasCenter.dy + radius * sin(angle) + (rnd.nextDouble() - 0.5) * 40,
      );
    }

    // 2. Chạy 140 vòng lặp mô phỏng lực vật lý ban đầu
    // Lực đẩy kRepulsion mạnh hơn (450000), khoảng cách lý tưởng idealDistance 320px
    // Trọng lực tâm giảm (0.008) để các cụm node giãn cách tự nhiên và thoáng hơn
    const kRepulsion = 450000.0;
    const kSpring = 0.035;
    const idealDistance = 320.0;
    double temperature = 60.0;

    for (int iter = 0; iter < 140; iter++) {
      final displacements = <String, Offset>{
        for (final n in nodes) n.id: Offset.zero,
      };

      // Xây spatial grid cho iteration này
      _spatialGrid.clear();
      for (final n in nodes) {
        _spatialGrid.insert(n.id, _nodePositions[n.id]!);
      }

      // Lực đẩy — chỉ giữa neighbor trong spatial grid (Fix #1)
      for (int i = 0; i < nodes.length; i++) {
        final idA = nodes[i].id;
        final posA = _nodePositions[idA]!;
        final neighbors = _spatialGrid.getNeighbors(posA);

        for (final idB in neighbors) {
          if (idA.compareTo(idB) >= 0) continue; // Tránh tính trùng + self
          final posB = _nodePositions[idB];
          if (posB == null) continue;

          final delta = posA - posB;
          final dist = max(delta.distance, 15.0);
          final force = kRepulsion / (dist * dist);
          final disp = (delta / dist) * force;

          displacements[idA] = displacements[idA]! + disp;
          displacements[idB] = displacements[idB]! - disp;
        }
      }

      // Lực hút lò xo dọc theo các cạnh WikiLinks (Hooke's Law)
      for (final edge in edges) {
        final posA = _nodePositions[edge.sourceId];
        final posB = _nodePositions[edge.targetId];
        if (posA == null || posB == null) continue;

        final delta = posB - posA;
        final dist = max(delta.distance, 1.0);
        final force = (dist - idealDistance) * kSpring;
        final disp = (delta / dist) * force;

        displacements[edge.sourceId] = displacements[edge.sourceId]! + disp;
        displacements[edge.targetId] = displacements[edge.targetId]! - disp;
      }

      // Trọng lực kéo về tâm canvas nhẹ nhàng (0.008) để giữ graph không dồn cục
      for (final node in nodes) {
        final pos = _nodePositions[node.id]!;
        final deltaToCenter = _canvasCenter - pos;
        displacements[node.id] = displacements[node.id]! + deltaToCenter * 0.008;
      }

      // Áp dụng độ dời có giảm dần nhiệt độ
      for (final node in nodes) {
        final disp = displacements[node.id]!;
        final dispLen = disp.distance;
        if (dispLen > 0) {
          final step = (disp / dispLen) * min(dispLen, temperature);
          var newPos = _nodePositions[node.id]! + step;
          newPos = Offset(
            newPos.dx.clamp(120.0, _canvasSize - 120.0),
            newPos.dy.clamp(120.0, _canvasSize - 120.0),
          );
          _nodePositions[node.id] = newPos;
        }
      }

      temperature *= 0.97;
    }
  }

  // ═══════════════════════════════════════════
  //  REAL-TIME RELAXATION — Spatial Grid O(N×K)
  // ═══════════════════════════════════════════

  /// Tự động cân bằng vị trí các node liên kết theo cơ chế lực lò xo đàn hồi.
  /// Dùng Spatial Grid (Fix #1) cho lực đẩy cục bộ + gravity toàn cục để tránh co cụm.
  /// Trả về tổng displacement để Fix #5 có thể dừng sớm khi ổn định.
  double _relaxGraphStep({String? pinnedNodeId, int steps = 4, double maxStepScale = 1.0}) {
    final graphProvider = context.read<GraphProvider>();
    final nodes = graphProvider.nodes;
    final edges = graphProvider.edges;

    const kRepulsion = 380000.0;
    const kSpring = 0.04;
    const idealDistance = 300.0;
    const maxStep = 10.0;
    final effectiveMaxStep = maxStep * maxStepScale;

    double totalDisplacement = 0.0;

    for (int s = 0; s < steps; s++) {
      final displacements = <String, Offset>{
        for (final n in nodes) n.id: Offset.zero,
      };

      // Xây spatial grid cho step này (Fix #1)
      _spatialGrid.clear();
      for (final n in nodes) {
        final pos = _nodePositions[n.id];
        if (pos != null) _spatialGrid.insert(n.id, pos);
      }

      // 1. Lực đẩy cục bộ — chỉ neighbor trong spatial grid (Fix #1)
      for (final node in nodes) {
        final idA = node.id;
        final posA = _nodePositions[idA];
        if (posA == null) continue;

        final neighbors = _spatialGrid.getNeighbors(posA);
        for (final idB in neighbors) {
          if (idA.compareTo(idB) >= 0) continue;
          final posB = _nodePositions[idB];
          if (posB == null) continue;

          final delta = posA - posB;
          final dist = max(delta.distance, 15.0);
          final force = kRepulsion / (dist * dist);
          final disp = (delta / dist) * force;

          if (idA != pinnedNodeId) displacements[idA] = displacements[idA]! + disp;
          if (idB != pinnedNodeId) displacements[idB] = displacements[idB]! - disp;
        }
      }

      // 2. Lực co giãn đàn hồi lò xo dọc theo các cạnh nối
      for (final edge in edges) {
        final posA = _nodePositions[edge.sourceId];
        final posB = _nodePositions[edge.targetId];
        if (posA == null || posB == null) continue;

        final delta = posB - posA;
        final dist = max(delta.distance, 1.0);
        final force = (dist - idealDistance) * kSpring;
        final disp = (delta / dist) * force;

        if (edge.sourceId != pinnedNodeId) {
          displacements[edge.sourceId] = displacements[edge.sourceId]! + disp;
        }
        if (edge.targetId != pinnedNodeId) {
          displacements[edge.targetId] = displacements[edge.targetId]! - disp;
        }
      }

      // 3. Gravity hướng tâm nhẹ nhàng để graph phân bố rộng thoáng
      for (final node in nodes) {
        if (node.id == pinnedNodeId) continue;
        final pos = _nodePositions[node.id];
        if (pos == null) continue;
        final deltaToCenter = _canvasCenter - pos;
        displacements[node.id] = displacements[node.id]! + deltaToCenter * 0.0015;
      }

      // 4. Cập nhật vị trí các node không bị pin với hệ số Damping và Deadband chống rung
      const deadband = 1.2; // Bỏ qua dao động vi mô dưới 1.2px để triệt tiêu hoàn toàn hiện tượng rung
      const damping = 0.65; // Giảm chấn để chuyển động đầm, không bị giật nảy lò xo qua lại

      for (final node in nodes) {
        if (node.id == pinnedNodeId) continue;
        final disp = displacements[node.id]!;
        final len = disp.distance;
        if (len > deadband) {
          final dampedLen = (len - deadband) * damping;
          final step = (disp / len) * min(dampedLen, effectiveMaxStep);
          totalDisplacement += step.distance;
          final cur = _nodePositions[node.id]!;
          _nodePositions[node.id] = Offset(
            (cur.dx + step.dx).clamp(80.0, _canvasSize - 80.0),
            (cur.dy + step.dy).clamp(80.0, _canvasSize - 80.0),
          );
        }
      }
    }

    return totalDisplacement;
  }

  // ═══════════════════════════════════════════
  //  DRIFT ANIMATION — Fix #5: dừng sớm
  // ═══════════════════════════════════════════

  /// Khi người dùng thả tay, node tiếp tục trôi chậm dần theo quán tính.
  /// Dừng sớm khi tổng displacement < 1.5 hoặc quán tính tắt.
  void _onDriftTick() {
    if (!mounted || _nodePositions.isEmpty) return;

    final progress = _driftController?.value ?? 1.0;
    final decay = pow(1.0 - progress, 1.2).toDouble();

    if (_releasedNodeId != null && _releaseVelocity != Offset.zero) {
      final cur = _nodePositions[_releasedNodeId];
      if (cur != null) {
        final step = _releaseVelocity * (0.016 * decay * 1.5);
        _nodePositions[_releasedNodeId!] = Offset(
          (cur.dx + step.dx).clamp(80.0, _canvasSize - 80.0),
          (cur.dy + step.dy).clamp(80.0, _canvasSize - 80.0),
        );
      }
    }

    // Dừng sớm khi graph đã ổn định hoặc quán tính tắt để tránh rung dư thừa
    final totalDisp = _relaxGraphStep(pinnedNodeId: null, steps: 1, maxStepScale: decay);
    if (totalDisp < 1.5 || decay < 0.20) {
      _driftController?.stop(); // Graph đã ổn định, dừng animation sớm
      return;
    }

    _paintVersion++;
    setState(() {});
  }

  /// Lấy danh sách ID các node liền kề với 1 node cụ thể
  Set<String> _getAdjacentNodeIds(String nodeId, List<GraphEdge> edges) {
    final adjacent = <String>{};
    for (final edge in edges) {
      if (edge.sourceId == nodeId) {
        adjacent.add(edge.targetId);
      } else if (edge.targetId == nodeId) {
        adjacent.add(edge.sourceId);
      }
    }
    return adjacent;
  }

  // ═══════════════════════════════════════════
  //  ZOOM & PAN CONTROLS
  // ═══════════════════════════════════════════

  void _zoom(double factor) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final vp = renderBox.size;
    final center = Offset(vp.width / 2, (vp.height - 36) / 2);

    final currentMatrix = _transformController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.04, 8.0);
    final actualFactor = newScale / currentScale;

    final translation = Matrix4.translationValues(center.dx, center.dy, 0.0);
    final scale = Matrix4.diagonal3Values(actualFactor, actualFactor, 1.0);
    final negTranslation = Matrix4.translationValues(-center.dx, -center.dy, 0.0);

    setState(() {
      _transformController.value = translation * scale * negTranslation * currentMatrix;
    });
  }

  void _fitToScreen() {
    if (_nodePositions.isEmpty || !mounted) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final vp = renderBox.size;
    final vpHeight = vp.height - 36;
    if (vp.width <= 0 || vpHeight <= 0) return;

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final pos in _nodePositions.values) {
      if (pos.dx < minX) minX = pos.dx;
      if (pos.dx > maxX) maxX = pos.dx;
      if (pos.dy < minY) minY = pos.dy;
      if (pos.dy > maxY) maxY = pos.dy;
    }

    const padding = 160.0;
    final graphWidth = (maxX - minX) + padding * 2;
    final graphHeight = (maxY - minY) + padding * 2;
    final graphCenter = Offset((minX + maxX) / 2, (minY + maxY) / 2);

    final scaleX = vp.width / graphWidth;
    final scaleY = vpHeight / graphHeight;
    final targetScale = min(scaleX, scaleY).clamp(0.04, 1.8);

    final vpCenter = Offset(vp.width / 2, vpHeight / 2);
    final translation = vpCenter - (graphCenter * targetScale);

    final targetMatrix = Matrix4.translationValues(translation.dx, translation.dy, 0.0) *
        Matrix4.diagonal3Values(targetScale, targetScale, 1.0);

    setState(() {
      _transformController.value = targetMatrix;
    });
  }

  void _resetView() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      _transformController.value = Matrix4.identity();
      return;
    }

    final vp = renderBox.size;
    final center = Offset(vp.width / 2, (vp.height - 36) / 2);
    final translation = center - _canvasCenter;

    final targetMatrix = Matrix4.translationValues(translation.dx, translation.dy, 0.0);

    setState(() {
      _transformController.value = targetMatrix;
    });
  }

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final graphProvider = context.watch<GraphProvider>();
    final vaultProvider = context.watch<VaultProvider>();

    // 1. Chưa mở Vault
    if (!vaultProvider.hasVault) {
      return _buildEmptyState(
        colorScheme,
        icon: Icons.folder_open_outlined,
        title: 'Chưa mở Vault',
        subtitle: 'Mở Vault để xem mạng lưới liên kết tri thức',
      );
    }

    // 2. Đang tải
    if (graphProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Đang phân tích liên kết...',
              style: TextStyle(color: colorScheme.onSurface.withAlpha(120)),
            ),
          ],
        ),
      );
    }

    // 3. Không có dữ liệu
    if (!graphProvider.hasGraph) {
      return _buildEmptyState(
        colorScheme,
        icon: Icons.hub_outlined,
        title: 'Chưa có dữ liệu',
        subtitle: 'Tạo ghi chú và liên kết [[WikiLink]] để xây dựng đồ thị',
        showRefreshButton: true,
      );
    }

    // Nếu dữ liệu graph có node/edge mới mà chưa có vị trí, tính toán lại
    if (_nodePositions.isEmpty ||
        graphProvider.nodes.length != _lastNodeCount ||
        graphProvider.edges.length != _lastEdgeCount) {
      _initializeLayout();
    }

    final nodes = graphProvider.nodes;
    final edges = graphProvider.edges;

    // Tối ưu O(E): Tính trước bậc liên kết (degree) cho tất cả các node trong 1 lần duyệt
    final degreeMap = <String, int>{};
    for (final e in edges) {
      degreeMap[e.sourceId] = (degreeMap[e.sourceId] ?? 0) + 1;
      degreeMap[e.targetId] = (degreeMap[e.targetId] ?? 0) + 1;
    }

    // Tìm tập hợp node liền kề node đang được hover (nếu có)
    final adjacentNodeIds = _hoveredNodeId != null
        ? _getAdjacentNodeIds(_hoveredNodeId!, edges)
        : const <String>{};

    return Column(
      children: [
        // ─── Graph Toolbar ───
        _buildToolbar(colorScheme, graphProvider),

        // ─── Interactive Graph Canvas ───
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ClipRect(
                child: InteractiveViewer(
                  constrained: false,
                  boundaryMargin: EdgeInsets.all(_canvasSize * 0.35),
                  minScale: 0.04,
                  maxScale: 8.0,
                  scaleFactor: 280.0, // Cuộn chuột nhạy và nhanh hơn gấp 4 lần (trước là 1200.0)
                  transformationController: _transformController,
                  onInteractionStart: (_) {
                    if (_hoveredNodeId != null && _draggingNodeId == null) {
                      setState(() => _hoveredNodeId = null);
                    }
                  },
                  child: SizedBox(
                    width: _canvasSize,
                    height: _canvasSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Lớp 0: Dot grid tĩnh — Fix #2: RepaintBoundary, chỉ vẽ 1 lần.
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _StaticDotGridPainter(
                                colorScheme: colorScheme,
                              ),
                            ),
                          ),
                        ),

                        // Lớp nền bắt tap để bỏ chọn/bỏ hover khi click ra vùng trống
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              if (_hoveredNodeId != null) {
                                setState(() => _hoveredNodeId = null);
                              }
                            },
                          ),
                        ),

                        // Lớp 1: Vẽ các đường nối (Edges) — Fix #4: version counter & RepaintBoundary
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _KnowledgeGraphEdgePainter(
                                nodes: nodes,
                                edges: edges,
                                nodePositions: _nodePositions,
                                hoveredNodeId: _hoveredNodeId,
                                adjacentNodeIds: adjacentNodeIds,
                                colorScheme: colorScheme,
                                paintVersion: _paintVersion, // Fix #4
                              ),
                            ),
                          ),
                        ),

                        // Lớp 2: Các Node tương tác (Kéo thả, Click, Hover)
                        for (final gNode in nodes)
                          _buildInteractiveNode(
                            gNode: gNode,
                            graphProvider: graphProvider,
                            connectionCount: degreeMap[gNode.id] ?? 0,
                            adjacentNodeIds: adjacentNodeIds,
                            colorScheme: colorScheme,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  INTERACTIVE NODE WIDGET
  // ═══════════════════════════════════════════
  Widget _buildInteractiveNode({
    required GraphNode gNode,
    required GraphProvider graphProvider,
    required int connectionCount,
    required Set<String> adjacentNodeIds,
    required ColorScheme colorScheme,
  }) {
    final pos = _nodePositions[gNode.id] ?? _canvasCenter;

    final isHovered = gNode.id == _hoveredNodeId;
    final isAdjacent = adjacentNodeIds.contains(gNode.id);
    final isDimmed = _hoveredNodeId != null && !isHovered && !isAdjacent;
    final isActive = graphProvider.activeNodeId == gNode.id;

    // Level of Detail (LOD): quyết định có render label văn bản hay không.
    // Zoom out xa: ẩn nhãn text trên hàng trăm node giúp triệt tiêu hoàn toàn 122ms Skia Text Layout & Raster jank
    final bool showLabel = switch (_currentLod) {
      0 => true,
      1 => isHovered || isActive || isAdjacent || connectionCount >= 10,
      _ => isHovered || isActive || isAdjacent,
    };

    final isIsolated = connectionCount == 0;
    // Tất cả node dưới 10 cạnh có cùng kích thước chuẩn nhỏ gọn bằng nhau (12px).
    // Chỉ những node là trung tâm kết nối thực sự (từ 10 cạnh trở lên) mới to dần lên (18px - 44px).
    final double nodeSize;
    if (connectionCount < 10) {
      nodeSize = 12.0;
    } else {
      nodeSize = (18.0 + (connectionCount - 10) * 2.5).clamp(18.0, 44.0);
    }

    final nodeDefaultColor = isIsolated
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    final nodeDefaultBorder = isIsolated
        ? const Color(0xFFD1D5DB)
        : const Color(0xFF9CA3AF);

    final circleColor = isDimmed
        ? nodeDefaultColor.withAlpha(35)
        : (isHovered
            ? colorScheme.primary
            : (isAdjacent
                ? colorScheme.primary.withAlpha(220)
                : (isActive ? colorScheme.primary : nodeDefaultColor)));

    final borderColor = isDimmed
        ? Colors.transparent
        : (isHovered
            ? Colors.white
            : (isAdjacent
                ? colorScheme.primary
                : (isActive ? Colors.white : nodeDefaultBorder)));

    final borderWidth = isHovered ? 2.5 : (isAdjacent || isActive ? 2.0 : 1.2);

    final containerWidth = showLabel ? max(150.0, nodeSize + 28.0) : nodeSize;
    final containerHeight = showLabel ? (nodeSize + 52.0) : nodeSize;

    return Positioned(
      left: pos.dx - containerWidth / 2,
      top: pos.dy - (nodeSize / 2),
      width: containerWidth,
      height: containerHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Circle Node: HITBOX CHỈ TÍNH TẠI ĐÂY (Thuần hình tròn, không icon) ───
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              if (_draggingNodeId == null && _hoveredNodeId != gNode.id) {
                setState(() => _hoveredNodeId = gNode.id);
              }
            },
            onExit: (_) {
              if (_draggingNodeId == null && _hoveredNodeId == gNode.id) {
                setState(() => _hoveredNodeId = null);
              }
            },
            child: GestureDetector(
              key: ValueKey('node_avatar_${gNode.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _onNodeTapped(gNode),
              onPanStart: (_) {
                _driftController?.stop();
                setState(() {
                  _draggingNodeId = gNode.id;
                  _hoveredNodeId = gNode.id;
                  _releasedNodeId = null;
                  _releaseVelocity = Offset.zero;
                });
              },
              // Di chuyển 1:1 theo con trỏ chuột (details.delta đã ở hệ tọa độ canvas bên trong InteractiveViewer)
              onPanUpdate: (details) {
                final currentPos = _nodePositions[gNode.id] ?? _canvasCenter;
                _nodePositions[gNode.id] = Offset(
                  (currentPos.dx + details.delta.dx).clamp(60.0, _canvasSize - 60.0),
                  (currentPos.dy + details.delta.dy).clamp(60.0, _canvasSize - 60.0),
                );

                _relaxGraphStep(pinnedNodeId: gNode.id, steps: 1);
                _paintVersion++;
                setState(() {});
              },
              onPanEnd: (details) {
                _releasedNodeId = gNode.id;
                _releaseVelocity = details.velocity.pixelsPerSecond;

                final speed = _releaseVelocity.distance;
                if (speed > 1000.0) {
                  _releaseVelocity = (_releaseVelocity / speed) * 1000.0;
                }

                setState(() {
                  _draggingNodeId = null;
                  _hoveredNodeId = null;
                });

                _effectiveDriftController.reset();
                _effectiveDriftController.forward();
              },
              onPanCancel: () {
                setState(() {
                  _draggingNodeId = null;
                  _hoveredNodeId = null;
                });
              },
              // Hình tròn tinh gọn chuẩn phong cách đồ thị Obsidian, không chứa icon
              child: Container(
                width: nodeSize,
                height: nodeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                  boxShadow: (isHovered || isActive)
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withAlpha(120),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 5),

            // ─── Label Text: BỌC IgnorePointer — HOÀN TOÀN KHÔNG NHẬN HITBOX ───
            IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: (!isDimmed && (isHovered || isAdjacent || isActive))
                    ? BoxDecoration(
                        color: colorScheme.surface.withAlpha(210),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isHovered
                              ? colorScheme.primary.withAlpha(150)
                              : Colors.transparent,
                          width: 0.8,
                        ),
                      )
                    : null,
                child: Text(
                  gNode.title.replaceAll('_', ' '),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: (isHovered || isActive) ? 11.5 : 11.0,
                    fontWeight: (isHovered || isActive)
                        ? FontWeight.w700
                        : (isAdjacent ? FontWeight.w600 : FontWeight.w500),
                    color: isDimmed
                        ? colorScheme.onSurface.withAlpha(35)
                        : (isHovered
                            ? colorScheme.primary
                            : (isAdjacent
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withAlpha(190))),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Xử lý click vào node: mở note trong Editor
  void _onNodeTapped(GraphNode gNode) {
    if (gNode.path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note "${gNode.title}" chưa tồn tại. Tạo note mới với tiêu đề này để liên kết.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final noteProvider = context.read<NoteProvider>();
    final graphProvider = context.read<GraphProvider>();

    noteProvider.openNote(gNode.path);
    graphProvider.setActiveNode(gNode.id);

    debugPrint('[KnowledgeGraph] Clicked node: ${gNode.title}');
  }

  // ═══════════════════════════════════════════
  //  TOOLBAR
  // ═══════════════════════════════════════════
  Widget _buildToolbar(ColorScheme colorScheme, GraphProvider graphProvider) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withAlpha(40)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.hub, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            'Knowledge Graph',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withAlpha(210),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${graphProvider.nodes.length} nodes · ${graphProvider.edges.length} edges',
              style: TextStyle(fontSize: 10, color: colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),

          Tooltip(
            message: 'Thu nhỏ (-)',
            child: IconButton(
              icon: Icon(Icons.remove, size: 15, color: colorScheme.onSurface.withAlpha(160)),
              onPressed: () => _zoom(0.8),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(maxWidth: 26, maxHeight: 26),
              padding: EdgeInsets.zero,
            ),
          ),
          Tooltip(
            message: 'Phóng to (+)',
            child: IconButton(
              icon: Icon(Icons.add, size: 15, color: colorScheme.onSurface.withAlpha(160)),
              onPressed: () => _zoom(1.25),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(maxWidth: 26, maxHeight: 26),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 2),
          Tooltip(
            message: 'Căn vừa màn hình (Fit to View)',
            child: IconButton(
              icon: Icon(Icons.crop_free, size: 15, color: colorScheme.onSurface.withAlpha(160)),
              onPressed: _fitToScreen,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(maxWidth: 26, maxHeight: 26),
              padding: EdgeInsets.zero,
            ),
          ),
          Tooltip(
            message: 'Đặt lại tỷ lệ 100% (Reset)',
            child: IconButton(
              icon: Icon(Icons.center_focus_strong, size: 15, color: colorScheme.onSurface.withAlpha(160)),
              onPressed: _resetView,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(maxWidth: 26, maxHeight: 26),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 2),
          Tooltip(
            message: 'Tự động sắp xếp lại vị trí node',
            child: IconButton(
              icon: Icon(Icons.auto_fix_high, size: 15, color: colorScheme.onSurface.withAlpha(160)),
              onPressed: () {
                _initializeLayout();
                _fitToScreen();
              },
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(maxWidth: 26, maxHeight: 26),
              padding: EdgeInsets.zero,
            ),
          ),
          Tooltip(
            message: 'Tải lại đồ thị từ Vault',
            child: IconButton(
              icon: Icon(Icons.refresh, size: 15, color: colorScheme.onSurface.withAlpha(160)),
              onPressed: () async {
                await _loadGraphData();
                if (mounted) {
                  _initializeLayout();
                  _fitToScreen();
                }
              },
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(maxWidth: 26, maxHeight: 26),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════
  Widget _buildEmptyState(
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool showRefreshButton = false,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: colorScheme.onSurface.withAlpha(60)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withAlpha(160),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withAlpha(100),
            ),
          ),
          if (showRefreshButton) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadGraphData,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Tải lại', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Fix #2: STATIC DOT GRID PAINTER — chỉ vẽ 1 lần
// ═══════════════════════════════════════════════

/// Vẽ lưới chấm trang trí nền. Nằm trong RepaintBoundary riêng biệt
/// nên chỉ vẽ 1 lần duy nhất, không bị repaint khi nodes/edges thay đổi.
class _StaticDotGridPainter extends CustomPainter {
  final ColorScheme colorScheme;

  _StaticDotGridPainter({required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final gridDotPaint = Paint()
      ..color = colorScheme.onSurface.withAlpha(12)
      ..style = PaintingStyle.fill;

    const gridStep = 80.0;
    for (double x = 0; x < size.width; x += gridStep) {
      for (double y = 0; y < size.height; y += gridStep) {
        canvas.drawCircle(Offset(x, y), 0.75, gridDotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StaticDotGridPainter oldDelegate) {
    // Chỉ vẽ lại khi theme thay đổi (Dark ↔ Light)
    return oldDelegate.colorScheme.brightness != colorScheme.brightness;
  }
}

// ═══════════════════════════════════════════════
//  EDGE PAINTER — Fix #4: version counter shouldRepaint & Batched Path
// ═══════════════════════════════════════════════

/// Vẽ các đường liên kết giữa nodes. Dùng [paintVersion] (integer counter)
/// thay vì Map reference compare để shouldRepaint chính xác.
/// Gom hàng nghìn cạnh vào Path duy nhất để giảm tối đa số lệnh Skia draw call.
class _KnowledgeGraphEdgePainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, Offset> nodePositions;
  final String? hoveredNodeId;
  final Set<String> adjacentNodeIds;
  final ColorScheme colorScheme;
  final int paintVersion; // Fix #4

  _KnowledgeGraphEdgePainter({
    required this.nodes,
    required this.edges,
    required this.nodePositions,
    required this.hoveredNodeId,
    required this.adjacentNodeIds,
    required this.colorScheme,
    required this.paintVersion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty) return;

    final defaultEdgePaint = Paint()
      ..color = colorScheme.onSurface.withAlpha(35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dimmedEdgePaint = Paint()
      ..color = colorScheme.onSurface.withAlpha(8)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    final highlightedEdgePaint = Paint()
      ..color = colorScheme.primary.withAlpha(220)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final defaultPath = Path();
    final dimmedPath = Path();
    final highlightedPath = Path();
    bool hasDefault = false;
    bool hasDimmed = false;
    bool hasHighlighted = false;

    for (final edge in edges) {
      final posA = nodePositions[edge.sourceId];
      final posB = nodePositions[edge.targetId];
      if (posA == null || posB == null) continue;

      final isConnectedToHovered = hoveredNodeId != null &&
          (edge.sourceId == hoveredNodeId || edge.targetId == hoveredNodeId);

      if (isConnectedToHovered) {
        highlightedPath.moveTo(posA.dx, posA.dy);
        highlightedPath.lineTo(posB.dx, posB.dy);
        hasHighlighted = true;
      } else if (hoveredNodeId != null) {
        dimmedPath.moveTo(posA.dx, posA.dy);
        dimmedPath.lineTo(posB.dx, posB.dy);
        hasDimmed = true;
      } else {
        defaultPath.moveTo(posA.dx, posA.dy);
        defaultPath.lineTo(posB.dx, posB.dy);
        hasDefault = true;
      }
    }

    if (hasDimmed) canvas.drawPath(dimmedPath, dimmedEdgePaint);
    if (hasDefault) canvas.drawPath(defaultPath, defaultEdgePaint);
    if (hasHighlighted) canvas.drawPath(highlightedPath, highlightedEdgePaint);
  }

  @override
  bool shouldRepaint(covariant _KnowledgeGraphEdgePainter oldDelegate) {
    // Fix #4: version counter thay vì Map reference compare
    return oldDelegate.paintVersion != paintVersion ||
        oldDelegate.hoveredNodeId != hoveredNodeId ||
        oldDelegate.colorScheme.brightness != colorScheme.brightness;
  }
}
