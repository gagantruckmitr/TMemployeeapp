import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = false;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Navigate back to profile
        context.go(AppRouter.profile);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.go(AppRouter.profile),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.grey.shade800,
            ),
          ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Notifications'),
            const SizedBox(height: 16),
            _buildSettingsCard([
              _buildSwitchTile(
                'Push Notifications',
                'Receive notifications for calls and updates',
                Icons.notifications_outlined,
                _notificationsEnabled,
                (value) => setState(() => _notificationsEnabled = value),
              ),
              _buildSwitchTile(
                'Sound',
                'Play sound for notifications',
                Icons.volume_up_outlined,
                _soundEnabled,
                (value) => setState(() => _soundEnabled = value),
              ),
              _buildSwitchTile(
                'Vibration',
                'Vibrate for notifications',
                Icons.vibration,
                _vibrationEnabled,
                (value) => setState(() => _vibrationEnabled = value),
              ),
            ]),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Appearance'),
            const SizedBox(height: 16),
            _buildSettingsCard([
              _buildSwitchTile(
                'Dark Mode',
                'Use dark theme',
                Icons.dark_mode_outlined,
                _darkModeEnabled,
                (value) => setState(() => _darkModeEnabled = value),
              ),
            ]),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Account'),
            const SizedBox(height: 16),
            _buildSettingsCard([
              _buildActionTile(
                'Change Password',
                'Update your account password',
                Icons.lock_outline,
                () => _showChangePasswordDialog(),
              ),
              _buildActionTile(
                'Privacy Policy',
                'Read our privacy policy',
                Icons.privacy_tip_outlined,
                () {},
              ),
              _buildActionTile(
                'Terms of Service',
                'Read our terms of service',
                Icons.description_outlined,
                () {},
              ),
            ]),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Support'),
            const SizedBox(height: 16),
            _buildSettingsCard([
              _buildActionTile(
                'Help Center',
                'Get help and support',
                Icons.help_outline,
                () {},
              ),
              _buildActionTile(
                'Contact Us',
                'Reach out to our support team',
                Icons.contact_support_outlined,
                () {},
              ),
              _buildActionTile(
                'Report a Bug',
                'Report issues or bugs',
                Icons.bug_report_outlined,
                () {},
              ),
            ]),
            
            const SizedBox(height: 32),
            _buildLogoutButton(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryBlue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.logout,
            color: Colors.red,
            size: 20,
          ),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        subtitle: Text(
          'Sign out of your account',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        onTap: () => _showLogoutDialog(),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('This feature will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle logout logic
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}