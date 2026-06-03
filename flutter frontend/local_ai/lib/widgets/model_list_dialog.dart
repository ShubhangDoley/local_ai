import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/model_provider.dart';

class ModelListDialog extends StatelessWidget {
  const ModelListDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModelListDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modelProvider = Provider.of<ModelProvider>(context);
    final isLocal = modelProvider.isLocalMode;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF475569),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Model Manager',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLocal ? 'Offline (On-Device AI)' : 'Online (Backend AI)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isLocal ? const Color(0xFF0EA5E9) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Toggle mode
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Local Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isLocal ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: isLocal,
                      activeThumbColor: const Color(0xFF0EA5E9),
                      activeTrackColor: const Color(0xFF083344),
                      inactiveThumbColor: const Color(0xFF94A3B8),
                      inactiveTrackColor: const Color(0xFF1E293B),
                      onChanged: (val) {
                        modelProvider.setLocalMode(val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 24),

          // Models List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: modelProvider.availableModels.length,
              itemBuilder: (context, index) {
                final model = modelProvider.availableModels[index];
                final status = modelProvider.getDownloadStatus(model.id);
                final progress = modelProvider.getDownloadProgress(model.id);
                final isActive = modelProvider.activeModel?.id == model.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? const Color(0xFF0F2B48).withOpacity(0.4) 
                        : const Color(0xFF1E293B).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive 
                          ? const Color(0xFF0EA5E9) 
                          : const Color(0xFF334155).withOpacity(0.5),
                      width: isActive ? 1.5 : 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title / Specialty row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                model.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Text(
                                model.specialty,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF38BDF8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Description
                        Text(
                          model.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Action / Progress bar row
                        _buildActionRow(context, modelProvider, model, status, progress, isActive),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    ModelProvider provider,
    LocalModel model,
    DownloadStatus status,
    double progress,
    bool isActive,
  ) {
    switch (status) {
      case DownloadStatus.notDownloaded:
        return SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0EA5E9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              foregroundColor: const Color(0xFF0EA5E9),
            ),
            onPressed: () => provider.downloadModel(model),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_rounded, size: 18),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Download Model (1-2 GB)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      
      case DownloadStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Downloading...',
                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFF1E293B),
                color: const Color(0xFF0EA5E9),
                minHeight: 6,
              ),
            ),
          ],
        );
      
      case DownloadStatus.downloaded:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isActive)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Selected & Active',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),
                    onPressed: () => provider.setActiveModel(model),
                    child: const Text('Use this model', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              tooltip: 'Delete Model',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF0F172A),
                    title: const Text('Delete Model?', style: TextStyle(color: Colors.white)),
                    content: Text(
                      'Are you sure you want to delete ${model.name}? This will free up storage space.',
                      style: const TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.deleteModel(model);
                          Navigator.pop(context);
                        },
                        child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );

      case DownloadStatus.error:
        return Row(
          children: [
            const Expanded(
              child: Text(
                'Download failed',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 13),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.replay_rounded, color: Color(0xFF0EA5E9)),
              onPressed: () => provider.downloadModel(model),
            ),
          ],
        );
    }
  }
}
