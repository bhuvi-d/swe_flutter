import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/utils/responsive_layout.dart';
import '../services/preferences_service.dart';
import '../models/analysis_result.dart';
import '../widgets/crop_advice_card.dart';
import '../widgets/media_gallery.dart';

/// History View — Premium dark theme with responsive grid/list.
///
/// Shows past diagnosis history and pending uploads in tabs.
class HistoryView extends StatefulWidget {
  final VoidCallback onBack;

  const HistoryView({super.key, required this.onBack});

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
      if (mounted) setState(() => _isLoading = false);
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
      backgroundColor: const Color(0xFF0F1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: widget.onBack,
          color: Colors.white70,
        ),
        title: const Text(
          'History & Uploads',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCcw, size: 20),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadHistory();
            },
            color: Colors.white54,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: Colors.white38,
          indicatorColor: const Color(0xFF10B981),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Analysis History'),
            Tab(text: 'Pending Uploads'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1A2E), Color(0xFF1A2940)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _history.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(context),
            const MediaGallery(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= Breakpoints.mobile;

    if (isWide) {
      // Grid for tablet/desktop
      return GridView.builder(
        padding: responsivePadding(context),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: width >= Breakpoints.tablet ? 3 : 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.5,
        ),
        itemCount: _history.length,
        itemBuilder: (context, index) => _buildHistoryCard(context, _history[index]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) => _buildHistoryCard(context, _history[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.history, size: 56, color: Color(0xFFFBBF24)),
          ),
          const SizedBox(height: 24),
          const Text(
            'No History Yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Your plant diagnosis history will appear here',
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, AnalysisResult item) {
    final isHealthy = item.disease.toLowerCase() == 'healthy';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _showAdvice(item),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isHealthy
                        ? const Color(0xFF10B981).withOpacity(0.15)
                        : const Color(0xFFFBBF24).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    LucideIcons.leaf,
                    size: 26,
                    color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFFBBF24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              item.crop,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildSeverityBadge(item.severity),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.disease,
                        style: TextStyle(
                          fontSize: 14,
                          color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFFBBF24),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(item.date),
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                          ),
                          Row(
                            children: [
                              Icon(LucideIcons.barChart, size: 13, color: const Color(0xFF38BDF8)),
                              const SizedBox(width: 4),
                              Text(
                                '${(item.confidence * 100).toInt()}%',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
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
    Color color;
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        color = const Color(0xFFEF4444);
        break;
      case 'moderate':
      case 'medium':
        color = const Color(0xFFFBBF24);
        break;
      case 'low':
        color = const Color(0xFF38BDF8);
        break;
      case 'healthy':
      case 'none':
        color = const Color(0xFF10B981);
        break;
      default:
        color = Colors.white38;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        severity.isEmpty ? 'N/A' : severity,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
