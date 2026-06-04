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
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Color(0xFF262626), width: 1.0),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLocal ? 'Offline (On-Device AI)' : 'Online (Backend AI)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isLocal ? Colors.white : const Color(0xFF48484A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: isLocal,
                      activeThumbColor: Colors.black,
                      activeTrackColor: Colors.white,
                      inactiveThumbColor: const Color(0xFF48484A),
                      inactiveTrackColor: const Color(0xFF1C1C1E),
                      onChanged: (val) {
                        modelProvider.setLocalMode(val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1C1C1E), height: 24),

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
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? const Color(0xFF161616) 
                        : const Color(0xFF0D0D0D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive 
                          ? Colors.white 
                          : const Color(0xFF262626),
                      width: 1.0,
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF262626)),
                              ),
                              child: Text(
                                model.specialty.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
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
                            fontSize: 12.5,
                            color: Color(0xFF8E8E93),
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
          height: 38,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              foregroundColor: Colors.white,
            ),
            onPressed: () => provider.downloadModel(model),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_rounded, size: 16),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Download Model (1-2 GB)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFF1C1C1E),
                color: Colors.white,
                minHeight: 4,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Active',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                  height: 38,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF1C1C1E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFF262626)),
                      ),
                    ),
                    onPressed: () => provider.setActiveModel(model),
                    child: const Text('Use this model', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF453A)),
              tooltip: 'Delete Model',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF0D0D0D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF262626)),
                    ),
                    title: const Text('Delete Model?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    content: Text(
                      'Are you sure you want to delete ${model.name}? This will free up storage space.',
                      style: const TextStyle(color: Color(0xFF8E8E93)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E8E93))),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.deleteModel(model);
                          Navigator.pop(context);
                        },
                        child: const Text('Delete', style: TextStyle(color: Color(0xFFFF453A))),
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
                style: TextStyle(color: Color(0xFFFF453A), fontSize: 12),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.replay_rounded, color: Colors.white),
              onPressed: () => provider.downloadModel(model),
            ),
          ],
        );
    }
  }
}
