import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/preferences_service.dart';
import '../models/analysis_result.dart';
import '../widgets/crop_advice_card.dart';
import '../widgets/media_gallery.dart';

/// History View - View past diagnosis history
/// Matches React's HistoryView component in CropDiagnosisApp.jsx
class HistoryView extends StatefulWidget {
  final VoidCallback onBack;

  const HistoryView({
    super.key,
    required this.onBack,
  });

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AnalysisResult> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await preferencesService.getAnalysisHistory();
      if (mounted) {
        setState(() {
          _history = data.map((json) => AnalysisResult.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAdvice(AnalysisResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: CropAdviceCard(
            result: result,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
          color: AppColors.gray700,
        ),
        title: const Text(
          'History & Uploads',
          style: TextStyle(color: AppColors.gray800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadHistory();
            },
            color: AppColors.gray600,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.nature600,
          unselectedLabelColor: AppColors.gray500,
          indicatorColor: AppColors.nature600,
          tabs: const [
            Tab(text: 'Analysis History'),
            Tab(text: 'Pending Uploads'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.nature50, Color(0xFFD1FAE5)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Analysis History
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          return _buildHistoryCard(context, _history[index]);
                        },
                      ),
            
            // Tab 2: Pending Uploads (Media Gallery)
            const MediaGallery(),
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.amber100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 64,
              color: AppColors.amber600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your plant diagnosis history will appear here',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, AnalysisResult item) {
    final isHealthy = item.disease.toLowerCase() == 'healthy';
    
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showAdvice(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Plant Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isHealthy ? AppColors.nature100 : AppColors.amber100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.eco,
                    size: 32,
                    color: isHealthy ? AppColors.nature600 : AppColors.amber600,
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.crop,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray800,
                            ),
                          ),
                          _buildSeverityBadge(item.severity),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.disease,
                        style: TextStyle(
                          fontSize: 15,
                          color: isHealthy ? AppColors.nature600 : AppColors.amber700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(item.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.gray400,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.insights,
                                size: 14,
                                color: AppColors.blue500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(item.confidence * 100).toInt()}% conf.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.blue500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color bgColor;
    Color textColor;
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        bgColor = AppColors.red100;
        textColor = AppColors.red600;
        break;
      case 'moderate':
      case 'medium':
        bgColor = AppColors.amber100;
        textColor = AppColors.amber700;
        break;
      case 'low':
        bgColor = AppColors.blue100;
        textColor = AppColors.blue600;
        break;
      case 'healthy':
      case 'none':
        bgColor = AppColors.nature100;
        textColor = AppColors.nature600;
        break;
      default:
        bgColor = AppColors.gray100;
        textColor = AppColors.gray600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity.isEmpty ? 'Unknown' : severity,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

