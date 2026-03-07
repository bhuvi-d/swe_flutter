import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/preferences_service.dart';
import '../services/offline_storage_service.dart';
import '../models/analysis_result.dart';
import '../models/pending_media.dart';
import '../widgets/crop_advice_card.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

/// A unified history view that combines analyzed results and pending media.
/// Provides a sleek, chronological feed of all farmer activity.
class HistoryView extends StatefulWidget {
  final VoidCallback onBack;

  const HistoryView({
    super.key,
    required this.onBack,
  });

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  List<dynamic> _unifiedHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllHistory();
  }

  Future<void> _loadAllHistory() async {
    setState(() => _isLoading = true);
    try {
      // 1. Load Analyzed History
      final historyData = await preferencesService.getAnalysisHistory();
      final analyzedResults = historyData.map((json) => AnalysisResult.fromJson(json)).toList();

      // 2. Load Pending Media
      final pendingMedia = await offlineStorageService.getAllPendingMedia();

      // 3. Combine and Sort by Date (Reverse Chronological)
      final combined = [...analyzedResults, ...pendingMedia];
      combined.sort((a, b) {
        final dateA = a is AnalysisResult ? a.date : DateTime.fromMillisecondsSinceEpoch((a as PendingMedia).createdAt);
        final dateB = b is AnalysisResult ? b.date : DateTime.fromMillisecondsSinceEpoch((b as PendingMedia).createdAt);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _unifiedHistory = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading unified history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAdvice(AnalysisResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CropAdviceCard(
        result: result,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.gray800),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Your Activity History',
          style: TextStyle(color: AppColors.gray800, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20, color: AppColors.gray600),
            onPressed: _loadAllHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryStats(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.nature600))
                : _unifiedHistory.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    final analysisCount = _unifiedHistory.whereType<AnalysisResult>().length;
    final mediaCount = _unifiedHistory.whereType<PendingMedia>().length;

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatItem('Analyzed', analysisCount.toString(), LucideIcons.leaf, const Color(0xFF10B981)),
          const SizedBox(width: 12),
          _buildStatItem('Media', mediaCount.toString(), LucideIcons.camera, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _unifiedHistory.length,
      itemBuilder: (context, index) {
        final item = _unifiedHistory[index];
        if (item is AnalysisResult) {
          return _buildAnalysisCard(item);
        } else {
          return _buildMediaCard(item as PendingMedia);
        }
      },
    );
  }

  Widget _buildAnalysisCard(AnalysisResult item) {
    final isHealthy = item.disease.toLowerCase() == 'healthy';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _showAdvice(item),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: isHealthy ? const Color(0xFF10B981).withOpacity(0.1) : Colors.amber[50], borderRadius: BorderRadius.circular(16)),
                child: Icon(LucideIcons.leaf, color: isHealthy ? const Color(0xFF10B981) : Colors.amber, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.crop, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(item.disease, style: TextStyle(color: isHealthy ? const Color(0xFF10B981) : Colors.amber[800], fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text(DateFormat.yMMMd().format(item.date), style: const TextStyle(color: Colors.black38, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18, color: Colors.black12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCard(PendingMedia item) {
    final isVideo = item.fileType == 'video';
    final date = DateTime.fromMillisecondsSinceEpoch(item.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(16)),
              child: Icon(isVideo ? LucideIcons.video : LucideIcons.image, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Captured Media', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(isVideo ? 'Video Recording' : 'Photo Capture', style: const TextStyle(color: Colors.blue, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(DateFormat.yMMMd().format(date), style: const TextStyle(color: Colors.black38, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8)),
              child: const Text('Pending Analysis', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)]),
            child: const Icon(LucideIcons.clipboardList, size: 64, color: AppColors.gray300),
          ),
          const SizedBox(height: 24),
          const Text('No Activity Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.gray800)),
          const SizedBox(height: 8),
          const Text('Your analyzed crops will appear here.', style: TextStyle(color: AppColors.gray500, fontSize: 14)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: widget.onBack,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.nature600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Start Diagnosis'),
          ),
        ],
      ),
    );
  }
}
