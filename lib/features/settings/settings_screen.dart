import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _autoMatchEnabled = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection('General'),
          _buildSettingTile(
            'Notifications',
            'Enable push notifications',
            Icons.notifications_outlined,
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
              activeColor: AppColors.primary,
            ),
          ),
          _buildSettingTile(
            'Sound',
            'Enable sound effects',
            Icons.volume_up_outlined,
            trailing: Switch(
              value: _soundEnabled,
              onChanged: (value) => setState(() => _soundEnabled = value),
              activeColor: AppColors.primary,
            ),
          ),
          _buildSettingTile(
            'Language',
            _language,
            Icons.language,
            onTap: () => _showLanguageDialog(),
          ),
          
          _buildSection('Matchmaking'),
          _buildSettingTile(
            'Auto-Match',
            'Automatically match drivers with jobs',
            Icons.auto_awesome,
            trailing: Switch(
              value: _autoMatchEnabled,
              onChanged: (value) => setState(() => _autoMatchEnabled = value),
              activeColor: AppColors.primary,
            ),
          ),
          _buildSettingTile(
            'Match Threshold',
            'Minimum match score: 75%',
            Icons.tune,
            onTap: () {},
          ),
          
          _buildSection('Account'),
          _buildSettingTile(
            'Change Password',
            'Update your password',
            Icons.lock_outline,
            onTap: () {},
          ),
          _buildSettingTile(
            'Privacy Policy',
            'View privacy policy',
            Icons.privacy_tip_outlined,
            onTap: () {},
          ),
          _buildSettingTile(
            'Terms of Service',
            'View terms and conditions',
            Icons.description_outlined,
            onTap: () {},
          ),
          
          _buildSection('Support'),
          _buildSettingTile(
            'Help Center',
            'Get help and support',
            Icons.help_outline,
            onTap: () {},
          ),
          _buildSettingTile(
            'Contact Us',
            'Reach out to our team',
            Icons.email_outlined,
            onTap: () {},
          ),
          _buildSettingTile(
            'About',
            'Version 2.0.0',
            Icons.info_outline,
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Logout'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.softGray,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.softGray),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'हिंदी (Hindi)'].map((lang) {
            return RadioListTile<String>(
              title: Text(lang),
              value: lang,
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
              },
              activeColor: AppColors.primary,
            );
          }).toList(),
        ),
      ),
    );
  }
}
