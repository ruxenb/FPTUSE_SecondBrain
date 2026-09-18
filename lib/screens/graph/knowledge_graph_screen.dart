import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/graph_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/vault_provider.dart';

/// [Member 4 - T4.5] Màn hình trực quan hóa mạng lưới liên kết tri thức (Knowledge Graph).
///
/// Thiết kế chuẩn Obsidian Desktop:
/// - Tất cả các node có màu xám nhạt đồng nhất, kích thước tỷ lệ thuận với số liên kết.
/// - Không node nào có màu tím khi chưa hover (chỉ khi hover mới chuyển sang tím).
/// - Khi hover: không nhảy kích thước, không glow, chỉ đổi màu tím và viền trắng nổi bật.
/// - Cạnh liên kết thanh mảnh (1.0 - 1.5px), không có mũi tên.
/// - Kéo thả & thả tay: node có quán tính trôi nhẹ (drift) và các node liên kết tự động co giãn cân bằng lại theo lực đàn hồi lò xo.
/// - Pan/Zoom mượt mà trên Desktop với scaleFactor 1200 và bộ nút Zoom In/Out/Fit/Reset.
class KnowledgeGraphScreen extends StatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen>
    with SingleTickerProviderStateMixin {
  static const double _canvasSize = 2500.0;
  static const Offset _canvasCenter = Offset(_canvasSize / 2, _canvasSize / 2);

  final TransformationController _transformController = TransformationController();

  // Tọa độ các node trên canvas ảo (nodeId → Offset)
  final Map<String, Offset> _nodePositions = {};

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

  @override
  void initState() {
    super.initState();

    _effectiveDriftController; // Khởi tạo controller

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

  /// Tính toán bố trí ban đầu bằng thuật toán Force-Directed Physics
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

    final rnd = Random(42);
    final radius = (nodes.length * 40.0).clamp(180.0, 450.0);

    // 1. Phân bố vòng tròn ban đầu quanh tâm canvas
    for (int i = 0; i < nodes.length; i++) {
      final angle = (2 * pi * i) / nodes.length;
      _nodePositions[nodes[i].id] = Offset(
        _canvasCenter.dx + radius * cos(angle) + (rnd.nextDouble() - 0.5) * 30,
        _canvasCenter.dy + radius * sin(angle) + (rnd.nextDouble() - 0.5) * 30,
      );
    }

    // 2. Chạy 120 vòng lặp mô phỏng lực vật lý ban đầu (Force Simulation)
    const kRepulsion = 160000.0;
    const kSpring = 0.04;
    const idealDistance = 160.0;
    double temperature = 45.0;

    for (int iter = 0; iter < 120; iter++) {
      final displacements = <String, Offset>{
        for (final n in nodes) n.id: Offset.zero,
      };

      // Lực đẩy giữa mọi cặp node (Coulomb's Law)
      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final idA = nodes[i].id;
          final idB = nodes[j].id;
          final posA = _nodePositions[idA]!;
          final posB = _nodePositions[idB]!;
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

      // Trọng lực kéo nhẹ về tâm canvas
      for (final node in nodes) {
        final pos = _nodePositions[node.id]!;
        final deltaToCenter = _canvasCenter - pos;
        displacements[node.id] = displacements[node.id]! + deltaToCenter * 0.02;
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

      temperature *= 0.96;
    }
  }

  /// Tự động cân bằng vị trí các node liên kết theo cơ chế lực lò xo đàn hồi (Spring relaxation)
  void _relaxGraphStep({String? pinnedNodeId, int steps = 4, double maxStepScale = 1.0}) {
    final graphProvider = context.read<GraphProvider>();
    final nodes = graphProvider.nodes;
    final edges = graphProvider.edges;

    const kRepulsion = 120000.0;
    const kSpring = 0.045;
    const idealDistance = 150.0;
    const maxStep = 8.0;
    final effectiveMaxStep = maxStep * maxStepScale;

    for (int s = 0; s < steps; s++) {
      final displacements = <String, Offset>{
        for (final n in nodes) n.id: Offset.zero,
      };

      // 1. Lực đẩy giữa các cặp node
      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final idA = nodes[i].id;
          final idB = nodes[j].id;
          final posA = _nodePositions[idA];
          final posB = _nodePositions[idB];
          if (posA == null || posB == null) continue;

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

      // 3. Trọng lực hướng tâm nhẹ nhàng để đồ thị không bị dạt ra quá xa
      for (final node in nodes) {
        if (node.id == pinnedNodeId) continue;
        final pos = _nodePositions[node.id];
        if (pos == null) continue;
        final deltaToCenter = _canvasCenter - pos;
        displacements[node.id] = displacements[node.id]! + deltaToCenter * 0.005;
      }

      // 4. Cập nhật vị trí các node không bị pin (tự cân bằng lại)
      for (final node in nodes) {
        if (node.id == pinnedNodeId) continue;
        final disp = displacements[node.id]!;
        final len = disp.distance;
        if (len > 0) {
          final step = (disp / len) * min(len, effectiveMaxStep);
          final cur = _nodePositions[node.id]!;
          _nodePositions[node.id] = Offset(
            (cur.dx + step.dx).clamp(80.0, _canvasSize - 80.0),
            (cur.dy + step.dy).clamp(80.0, _canvasSize - 80.0),
          );
        }
      }
    }
  }

  /// Khi người dùng thả tay, node tiếp tục trôi chậm dần theo quán tính và cả hệ thống tự cân bằng êm ái
  void _onDriftTick() {
    if (!mounted || _nodePositions.isEmpty) return;

    final progress = _driftController?.value ?? 1.0;
    // Giảm tốc êm dịu kéo dài ~2.5 giây, duy trì quán tính trôi bồng bềnh tự nhiên
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

    // Cân bằng vật lý nhẹ nhàng trên toàn bộ đồ thị theo tiến trình giảm tốc
    _relaxGraphStep(pinnedNodeId: null, steps: 2, maxStepScale: decay);
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

  /// Phóng to / Thu nhỏ mượt mà quanh tâm khung nhìn
  void _zoom(double factor) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final vp = renderBox.size;
    final center = Offset(vp.width / 2, (vp.height - 36) / 2);

    final currentMatrix = _transformController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.15, 3.5);
    final actualFactor = newScale / currentScale;

    final translation = Matrix4.translationValues(center.dx, center.dy, 0.0);
    final scale = Matrix4.diagonal3Values(actualFactor, actualFactor, 1.0);
    final negTranslation = Matrix4.translationValues(-center.dx, -center.dy, 0.0);

    setState(() {
      _transformController.value = translation * scale * negTranslation * currentMatrix;
    });
  }

  /// Căn vừa màn hình (Fit to View)
  void _fitToScreen() {
    if (_nodePositions.isEmpty || !mounted) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final vp = renderBox.size;
    final vpHeight = vp.height - 36; // trừ chiều cao toolbar
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

    const padding = 140.0;
    final graphWidth = (maxX - minX) + padding * 2;
    final graphHeight = (maxY - minY) + padding * 2;
    final graphCenter = Offset((minX + maxX) / 2, (minY + maxY) / 2);

    final scaleX = vp.width / graphWidth;
    final scaleY = vpHeight / graphHeight;
    final targetScale = min(scaleX, scaleY).clamp(0.25, 1.6);

    final vpCenter = Offset(vp.width / 2, vpHeight / 2);
    final translation = vpCenter - (graphCenter * targetScale);

    final targetMatrix = Matrix4.translationValues(translation.dx, translation.dy, 0.0) *
        Matrix4.diagonal3Values(targetScale, targetScale, 1.0);

    setState(() {
      _transformController.value = targetMatrix;
    });
  }

  /// Đặt lại zoom về tỷ lệ 100% tại tâm canvas
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
                  boundaryMargin: const EdgeInsets.all(1200),
                  minScale: 0.15,
                  maxScale: 3.5,
                  scaleFactor: 1200.0, // Zoom mượt mà trên Desktop khi lăn chuột
                  transformationController: _transformController,
                  child: SizedBox(
                    width: _canvasSize,
                    height: _canvasSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Lớp 1: Vẽ các đường nối (Edges) và lưới nền
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _KnowledgeGraphEdgePainter(
                              nodes: nodes,
                              edges: edges,
                              nodePositions: _nodePositions,
                              hoveredNodeId: _hoveredNodeId,
                              adjacentNodeIds: adjacentNodeIds,
                              colorScheme: colorScheme,
                            ),
                          ),
                        ),

                        // Lớp 2: Các Node tương tác (Kéo thả, Click, Hover)
                        for (final gNode in nodes)
                          _buildInteractiveNode(
                            gNode: gNode,
                            graphProvider: graphProvider,
                            edges: edges,
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
    required List<GraphEdge> edges,
    required Set<String> adjacentNodeIds,
    required ColorScheme colorScheme,
  }) {
    final pos = _nodePositions[gNode.id] ?? _canvasCenter;

    final isHovered = gNode.id == _hoveredNodeId;
    final isAdjacent = adjacentNodeIds.contains(gNode.id);
    final isDimmed = _hoveredNodeId != null && !isHovered && !isAdjacent;
    final isActive = graphProvider.activeNodeId == gNode.id;
    final isPhantom = gNode.path.isEmpty;

    // Đếm số cạnh để xác định độ to nhỏ của node
    final connectionCount = edges
        .where((e) => e.sourceId == gNode.id || e.targetId == gNode.id)
        .length;
    final isIsolated = connectionCount == 0;
    final nodeSize = (26.0 + connectionCount * 4.0).clamp(26.0, 52.0);

    // Node có liên kết: xám trung tính (Color(0xFF6B7280))
    // Node rời không liên kết gì: màu xám nhạt hơn 1 chút (Color(0xFF9CA3AF))
    final nodeDefaultColor = isIsolated
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    final nodeDefaultBorder = isIsolated
        ? const Color(0xFFD1D5DB)
        : const Color(0xFF9CA3AF);

    const containerWidth = 140.0;
    const containerHeight = 98.0;

    return Positioned(
      left: pos.dx - containerWidth / 2,
      top: pos.dy - (nodeSize / 2),
      width: containerWidth,
      height: containerHeight,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (_draggingNodeId == null) {
            setState(() => _hoveredNodeId = gNode.id);
          }
        },
        onExit: (_) {
          if (_draggingNodeId == null) {
            setState(() => _hoveredNodeId = null);
          }
        },
        child: GestureDetector(
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
          onPanUpdate: (details) {
            final currentScale = _transformController.value.getMaxScaleOnAxis();
            final delta = details.delta / currentScale;

            setState(() {
              final currentPos = _nodePositions[gNode.id] ?? _canvasCenter;
              _nodePositions[gNode.id] = Offset(
                (currentPos.dx + delta.dx).clamp(60.0, _canvasSize - 60.0),
                (currentPos.dy + delta.dy).clamp(60.0, _canvasSize - 60.0),
              );

              // Tự động kéo và cân bằng các node liên kết theo cơ chế vật lý
              _relaxGraphStep(pinnedNodeId: gNode.id, steps: 4);
            });
          },
          onPanEnd: (details) {
            final currentScale = _transformController.value.getMaxScaleOnAxis();
            _releasedNodeId = gNode.id;
            _releaseVelocity = details.velocity.pixelsPerSecond / currentScale;

            // Giới hạn vận tốc ném để tránh văng quá xa
            final speed = _releaseVelocity.distance;
            if (speed > 800.0) {
              _releaseVelocity = (_releaseVelocity / speed) * 800.0;
            }

            setState(() {
              _draggingNodeId = null;
            });

            // Kích hoạt trôi theo quán tính và tự cân bằng
            _effectiveDriftController.reset();
            _effectiveDriftController.forward();
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 140),
            opacity: isDimmed ? 0.22 : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circle Node Avatar (Kích thước cố định, không nhảy, không glow)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: nodeSize,
                  height: nodeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // CHỈ KHI HOVER MỚI ĐỔI SANG MÀU TÍM. Bình thường tất cả có màu xám nhạt đồng nhất!
                    color: isHovered
                        ? colorScheme.primary
                        : nodeDefaultColor,
                    border: Border.all(
                      // Khi hover: viền trắng. Khi liền kề: viền tím. Khi active: viền trắng. Bình thường: viền xám nhạt.
                      color: isHovered
                          ? Colors.white
                          : isAdjacent
                              ? colorScheme.primary
                              : isActive
                                  ? Colors.white
                                  : nodeDefaultBorder,
                      width: isHovered ? 2.2 : (isAdjacent || isActive ? 2.0 : 1.2),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isPhantom ? Icons.add : Icons.description_outlined,
                      size: (nodeSize * 0.42).clamp(13.0, 20.0),
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 5),

                // Label Text
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: (isHovered || isAdjacent || isActive)
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
                      fontSize: 9.5,
                      fontWeight: (isHovered || isActive)
                          ? FontWeight.w700
                          : (isAdjacent ? FontWeight.w600 : FontWeight.w500),
                      color: isHovered
                          ? colorScheme.primary
                          : isAdjacent
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withAlpha(190),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

          // Nút Thu nhỏ (-)
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

          // Nút Phóng to (+)
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

          // Nút Căn vừa màn hình (Fit to View)
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

          // Nút Đặt lại vị trí ban đầu (Reset View)
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

          // Nút Sắp xếp lại đồ thị (Force Layout)
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

          // Nút Tải lại dữ liệu (Refresh)
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
//  CUSTOM PAINTER: VẼ CẠNH (KHÔNG MŨI TÊN, NÉT MẢNH)
// ═══════════════════════════════════════════════
class _KnowledgeGraphEdgePainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, Offset> nodePositions;
  final String? hoveredNodeId;
  final Set<String> adjacentNodeIds;
  final ColorScheme colorScheme;

  _KnowledgeGraphEdgePainter({
    required this.nodes,
    required this.edges,
    required this.nodePositions,
    required this.hoveredNodeId,
    required this.adjacentNodeIds,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Vẽ họa tiết lưới chấm tinh tế (Dot Matrix Grid) theo phong cách Obsidian
    final gridDotPaint = Paint()
      ..color = colorScheme.onSurface.withAlpha(12)
      ..style = PaintingStyle.fill;

    const gridStep = 40.0;
    for (double x = 0; x < size.width; x += gridStep) {
      for (double y = 0; y < size.height; y += gridStep) {
        canvas.drawCircle(Offset(x, y), 0.75, gridDotPaint);
      }
    }

    if (edges.isEmpty) return;

    // 2. Chuẩn bị Paints cho các đường liên kết (nét mảnh, không glow dày)
    final defaultEdgePaint = Paint()
      ..color = colorScheme.onSurface.withAlpha(35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dimmedEdgePaint = Paint()
      ..color = colorScheme.onSurface.withAlpha(10)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final highlightedEdgePaint = Paint()
      ..color = colorScheme.primary.withAlpha(220)
      ..strokeWidth = 1.5 // Nét mảnh tinh tế khi hover
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 3. Duyệt và vẽ từng cạnh đường thẳng (không mũi tên)
    for (final edge in edges) {
      final posA = nodePositions[edge.sourceId];
      final posB = nodePositions[edge.targetId];
      if (posA == null || posB == null) continue;

      final isConnectedToHovered = hoveredNodeId != null &&
          (edge.sourceId == hoveredNodeId || edge.targetId == hoveredNodeId);
      final isDimmed = hoveredNodeId != null && !isConnectedToHovered;

      if (isConnectedToHovered) {
        canvas.drawLine(posA, posB, highlightedEdgePaint);
      } else if (isDimmed) {
        canvas.drawLine(posA, posB, dimmedEdgePaint);
      } else {
        canvas.drawLine(posA, posB, defaultEdgePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KnowledgeGraphEdgePainter oldDelegate) {
    return oldDelegate.hoveredNodeId != hoveredNodeId ||
        oldDelegate.nodePositions != nodePositions ||
        oldDelegate.edges != edges ||
        oldDelegate.colorScheme != colorScheme;
  }
}
