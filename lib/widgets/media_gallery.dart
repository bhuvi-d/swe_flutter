
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/pending_media.dart';
import '../services/offline_storage_service.dart';

class MediaGallery extends StatefulWidget {
  const MediaGallery({super.key});

  @override
  State<MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> {
  List<PendingMedia> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await offlineStorageService.getAllPendingMedia();
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String id) async {
    await offlineStorageService.deletePendingMedia(id);
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 48,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No pending captures yet',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _buildMediaItem(item);
      },
    );
  }

  Widget _buildMediaItem(PendingMedia item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Thumbnail / Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
                image: _getImageProvider(item) != null 
                    ? DecorationImage(
                        image: _getImageProvider(item)!,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _getImageProvider(item) == null
                  ? Icon(
                      item.fileType == 'video' ? Icons.videocam : Icons.image,
                      size: 32,
                      color: AppColors.gray400,
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Crop Capture',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.gray800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amber100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(item.createdAt))} • ${item.durationSeconds}s',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                  if (item.voiceTranscription != null && item.voiceTranscription!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.voiceTranscription!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.red400),
              onPressed: () => _deleteItem(item.id),
            ),
          ],
        ),
      ),
    );
  }
  ImageProvider? _getImageProvider(PendingMedia item) {
    if (kIsWeb && item.base64Content != null && item.base64Content!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(item.base64Content!));
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return null;
      }
    }
    
    if (item.filePath.isNotEmpty && File(item.filePath).existsSync()) {
      return FileImage(File(item.filePath));
    }
    
    return null;
  }
}
