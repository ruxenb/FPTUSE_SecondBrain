import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/graph_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/vault_provider.dart';

/// Màn hình trực quan hóa mạng lưới liên kết tri thức (Knowledge Graph View).
/// Phụ trách: Member 4
class KnowledgeGraphScreen extends StatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen> {
  final FruchtermanReingoldAlgorithm _algorithm = FruchtermanReingoldAlgorithm(
    FruchtermanReingoldConfiguration()..iterations = 500,
  );

  @override
  Widget build(BuildContext context) {
    final graphProvider = context.watch<GraphProvider>();
    final noteProvider = context.watch<NoteProvider>();
    final vaultProvider = context.watch<VaultProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.hub_outlined, size: 18, color: AppColors.secondary),
            SizedBox(width: 8),
            Text('KNOWLEDGE GRAPH NETWORK'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại đồ thị',
            onPressed: () {
              graphProvider.loadGraph(vaultProvider.vaultPath ?? '/vault');
            },
          ),
        ],
      ),
      body: graphProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !graphProvider.hasNodes
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bubble_chart_outlined, size: 64, color: AppColors.textDisabled),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa có dữ liệu đồ thị',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          graphProvider.loadGraph(vaultProvider.vaultPath ?? '/vault');
                        },
                        child: const Text('Nạp Dữ Liệu Graph Mẫu'),
                      ),
                    ],
                  ),
                )
              : InteractiveViewer(
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(300),
                  minScale: 0.2,
                  maxScale: 3.0,
                  child: GraphView(
                    graph: graphProvider.graph,
                    algorithm: _algorithm,
                    paint: Paint()
                      ..color = AppColors.border
                      ..strokeWidth = 1.5
                      ..style = PaintingStyle.stroke,
                    builder: (Node node) {
                      final nodeTitle = node.key!.value.toString();
                      final isCurrent =
                          noteProvider.currentNote?.title.toLowerCase() ==
                              nodeTitle.toLowerCase();

                      return _buildNodeWidget(context, nodeTitle, isCurrent);
                    },
                  ),
                ),
    );
  }

  Widget _buildNodeWidget(BuildContext context, String title, bool isCurrent) {
    return InkWell(
      onTap: () {
        final vaultProvider = context.read<VaultProvider>();
        final noteProvider = context.read<NoteProvider>();
        final path = '${vaultProvider.vaultPath ?? "/vault"}/$title.md';
        noteProvider.openNote(path, vaultRoot: vaultProvider.vaultPath);
        // Đóng màn hình graph nếu đang mở dạng dialog/tab hoặc thông báo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chọn: $title.md'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent ? AppColors.wikilink : AppColors.border,
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: [
            if (isCurrent)
              BoxShadow(
                color: AppColors.primary.withAlpha(120),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 10,
              color: isCurrent ? Colors.white : AppColors.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
