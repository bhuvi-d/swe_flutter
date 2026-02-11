import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/translation_service.dart';
import '../services/consent_service.dart';
import '../services/offline_storage_service.dart';

/// HomeView - Main app home screen with action grid.
/// 
/// Features:
/// - Dynamic greeting based on time of day.
/// - Guest mode banner (US6).
/// - Quick actions grid for main features (Scan, Upload, Voice, Record, History, LLM Advice).
/// - Weather widget.
/// - Pest alert and quick tips.
/// 
/// Matches React's `HomeView` component in `CropDiagnosisApp.jsx`.
class HomeView extends StatefulWidget {
  final Function(String) onNavigate;
  final bool isOnline;

  const HomeView({
    super.key,
    required this.onNavigate,
    this.isOnline = true,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isGuest = false;
  int _pendingSyncCount = 0; // US15: Pending offline sync count


  @override
  void initState() {
    super.initState();
    _checkGuestMode();
    _loadPendingSyncCount();
  }

  /// Checks if the user is in guest mode to display the banner.
  Future<void> _checkGuestMode() async {
    final isGuest = await consentService.isGuestMode();
    if (mounted) {
      setState(() {
        _isGuest = isGuest;
      });
    }
  }

  /// US15: Loads the count of pending offline media items.
  Future<void> _loadPendingSyncCount() async {
    final count = await offlineStorageService.getPendingCount();
    if (mounted) {
      setState(() => _pendingSyncCount = count);
    }
  }

  /// Returns the translation key for the greeting based on the current hour.
  String _getGreetingKey() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'homeView.greeting.morning';
    if (hour < 17) return 'homeView.greeting.afternoon';
    return 'homeView.greeting.evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.nature50,
            Color(0xFFD1FAE5), // emerald-50
            Color(0xFFCCFBF1), // teal-50
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 24),

              // US6: Guest Mode Banner
              if (_isGuest) ...[
                _buildGuestBanner(context),
                const SizedBox(height: 24),
              ],

              // Main Actions Grid
              _buildMainActionsGrid(context),
              const SizedBox(height: 16),

              // Pest Alert
              _buildPestAlert(context),
              const SizedBox(height: 16),

              // Weather Widget
              _buildWeatherWidget(context),
              const SizedBox(height: 24),

              // Quick Tip
              _buildQuickTip(context),
              const SizedBox(height: 16),

              // Status Footer
              _buildStatusFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the guest mode banner prompting users to sign up.
  Widget _buildGuestBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purple50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.purple100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_add, color: AppColors.purple600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guest Mode',
                  style: TextStyle(
                    color: AppColors.purple700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Sign up to save your diagnosis capability.',
                  style: TextStyle(
                    color: AppColors.purple600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => widget.onNavigate('login'), // Redirect to login
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }


  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // App Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.eco,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.t(_getGreetingKey())},',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  context.t('homeView.userTitle'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.gray800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
             // Audio Settings Button
            _buildHeaderButton(
              context,
              icon: Icons.volume_up,
              onTap: () => widget.onNavigate('audio-settings'),
            ),
            const SizedBox(width: 8),
            // Settings Button
            _buildHeaderButton(
              context,
              icon: Icons.settings,
              onTap: () => widget.onNavigate('settings'),
            ),
            const SizedBox(width: 8),
            // Profile Button
            Stack(
              children: [
                _buildHeaderButton(
                  context,
                  icon: Icons.person_outline,
                  onTap: () => widget.onNavigate('profile'),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(50),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 20, color: AppColors.gray600),
        ),
      ),
    );
  }

  /// Builds the main grid of action buttons.
  /// 
  /// layout adapts based on screen width.
  Widget _buildMainActionsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate aspect ratio dynamically based on width
        // Wider screens -> wider columns -> can translate to efficient ratio
        // Narrow screens -> thicker columns -> need taller cards (lower ratio)
        double aspectRatio = 0.8; 
        if (constraints.maxWidth < 360) {
          aspectRatio = 0.70; // Very small devices
        } else if (constraints.maxWidth < 600) {
          aspectRatio = 0.75; // Typical phones
        } else {
          aspectRatio = 1.0; // Tablets
        }

        return Column(
          children: [
            // Scan Plant - Full Width
            _buildScanPlantCard(context),
            const SizedBox(height: 16),

            // Action Grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: aspectRatio,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.upload_file,
                  label: context.t('homeView.actions.upload'),
                  color: AppColors.blue500,
                  bgColor: AppColors.blue100,
                  bgColorLight: AppColors.blue50,
                  onTap: () => widget.onNavigate('upload'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.mic,
                  label: context.t('homeView.actions.voice'),
                  color: AppColors.purple600,
                  bgColor: AppColors.purple100,
                  bgColorLight: AppColors.purple50,
                  onTap: () => widget.onNavigate('voice'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.videocam,
                  label: context.t('homeView.actions.record'),
                  color: AppColors.red500,
                  bgColor: AppColors.red100,
                  bgColorLight: AppColors.red50,
                  onTap: () => widget.onNavigate('video'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.history,
                  label: context.t('homeView.actions.history'),
                  color: AppColors.amber600,
                  bgColor: AppColors.amber100,
                  bgColorLight: AppColors.amber50,
                  onTap: () => widget.onNavigate('history'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.auto_awesome,
                  label: context.t('homeView.actions.llmAdvice'),
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFD1FAE5),
                  bgColorLight: AppColors.teal50,
                  onTap: () => widget.onNavigate('llm-advice'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildScanPlantCard(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: const Color(0xFF10B981).withOpacity(0.3),
      child: InkWell(
        onTap: () => widget.onNavigate('camera'),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF10B981), Color(0xFF22C55E)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        context.t('homeView.aiPowered'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        context.t('homeView.scanPlant'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.t('homeView.scanPlantDesc'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color bgColorLight,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced padding slightly
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [bgColor, bgColorLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: color), // Slightly smaller icon
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.gray700,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPestAlert(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFEF3C7), Color(0xFFFED7AA)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amber100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 24,
              color: AppColors.amber600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('homeView.pestAlert.title'),
                  style: TextStyle(
                    color: AppColors.amber700,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  context.t('homeView.pestAlert.desc'),
                  style: TextStyle(
                    color: AppColors.amber600.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.sky100, AppColors.sky50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cloud,
                  size: 40,
                  color: AppColors.sky500,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '24°C',
                    style: TextStyle(
                      color: AppColors.gray800,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Partly Cloudy',
                    style: TextStyle(
                      color: AppColors.gray500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildWeatherStat(Icons.water_drop, '62%'),
              const SizedBox(width: 24),
              _buildWeatherStat(Icons.air, '8km/h'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.blue500),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.gray600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), AppColors.teal600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                context.t('homeView.quickTip.title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.t('homeView.quickTip.desc'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatusItem(
          widget.isOnline ? Colors.green : AppColors.amber600,
          widget.isOnline ? context.t('homeView.status.online') : context.t('homeView.status.offline'),
        ),
        const SizedBox(width: 24),
        // US15: Offline sync indicator
        if (_pendingSyncCount > 0)
          _buildStatusItem(
            AppColors.amber600,
            '$_pendingSyncCount pending',
            icon: Icons.cloud_upload,
          ),
        if (_pendingSyncCount > 0)
          const SizedBox(width: 24),
        _buildStatusItem(
          AppColors.gray500,
          context.t('homeView.status.mobile'),
          icon: Icons.smartphone,
        ),
      ],
    );
  }

  Widget _buildStatusItem(Color color, String label, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
        ] else ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.gray500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
