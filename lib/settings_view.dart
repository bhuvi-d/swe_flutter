// Add these imports at the top
import '../services/notification_pause_service.dart';

// Add this state variable in _SettingsViewState
String _pauseStatus = 'Loading...';

// Add this method to load pause status
Future<void> _loadPauseStatus() async {
  final status = await NotificationPauseService.getPauseStatusText();
  if (mounted) {
    setState(() {
      _pauseStatus = status;
    });
  }
}

// Add this method to show pause options
void _showPauseOptions() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pause Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how long to pause notifications',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 20),
          _buildPauseOption('Pause 1 Day', 24),
          _buildPauseOption('Pause 3 Days', 72),
          _buildPauseOption('Pause 1 Week', 168),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await NotificationPauseService.resumeNotifications();
                Navigator.pop(context);
                _loadPauseStatus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nature600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Resume Notifications'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

Widget _buildPauseOption(String title, int hours) {
  return ListTile(
    title: Text(title),
    onTap: () async {
      await NotificationPauseService.pauseNotifications(hours);
      Navigator.pop(context);
      _loadPauseStatus();
    },
  );
}

// Add this to your settings list
_buildSettingsItem(
  context: context,
  icon: Icons.notifications_off,
  title: 'Pause Notifications',
  subtitle: _pauseStatus,
  onTap: _showPauseOptions,
),
