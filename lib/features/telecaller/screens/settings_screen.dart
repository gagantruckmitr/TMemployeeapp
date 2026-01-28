import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/config/api_config.dart';
import '../../../app/router/app_router.dart';
import '../../auth/login_page.dart';

/// Apple-style Settings Screen for TMConnect
/// Following iOS Human Interface Guidelines
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // iOS System Colors
  static const Color _systemBlue = Color(0xFF007AFF);
  static const Color _systemRed = Color(0xFFFF3B30);
  static const Color _systemGreen = Color(0xFF34C759);
  static const Color _whatsappGreen = Color(0xFF25D366);
  static const Color _labelPrimary = Color(0xFF000000);
  static const Color _labelTertiary = Color(0xFF8E8E93);
  static const Color _separatorColor = Color(0xFFC6C6C8);
  static const Color _backgroundPrimary = Color(0xFFFFFFFF);
  static const Color _backgroundSecondary = Color(0xFFFFFFFF);

  // Contact Information - HR
  static const String _hrPhone = '+917678361308';
  static String get _hrEmail => 'hr@${ApiConfig.domain}';

  // Contact Information - Command Centre
  static const String _commandCentrePhone = '+917678361237';
  static String get _commandCentreEmail => 'harneet.kaur@${ApiConfig.domain}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // iOS-style Large Title Navigation Bar
          SliverAppBar(
            backgroundColor: _backgroundPrimary,
            elevation: 0,
            pinned: true,
            expandedHeight: 60,
            leading: _buildBackButton(context),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 28, bottom: 19),
              title: const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _labelPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              centerTitle: false,
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // Account Section
                _buildSectionHeader('Account'),
                const SizedBox(height: 8),
                _buildGroupedCard([
                  _buildNavigationRow(
                    icon: Icons.lock_outline,
                    iconColor: _systemBlue,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () => _showChangePasswordSheet(context),
                  ),
                ]),

                const SizedBox(height: 32),

                // Contact Us Section
                _buildSectionHeader('Contact Us'),
                const SizedBox(height: 8),
                _buildGroupedCard([
                  _buildContactCardWithWhatsApp(
                    icon: Icons.badge_outlined,
                    iconColor: _systemGreen,
                    title: 'Contact HR',
                    label: 'Human Resources',
                    phone: _hrPhone,
                    email: _hrEmail,
                    showWhatsApp: true,
                  ),
                  _buildDivider(),
                  _buildContactCardWithWhatsApp(
                    icon: Icons.headset_mic_outlined,
                    iconColor: const Color(0xFFFF9500),
                    title: 'Contact Command Centre',
                    label: 'Operations / Command Centre',
                    phone: _commandCentrePhone,
                    email: _commandCentreEmail,
                    showWhatsApp: true,
                  ),
                ]),

                const SizedBox(height: 32),

                // Logout Button
                _buildLogoutButton(),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.pop();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.arrow_back_ios, size: 20, color: _systemBlue)],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(255, 64, 64, 67),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 60),
      height: 0.5,
      color: _separatorColor.withValues(alpha: 0.5),
    );
  }

  Widget _buildNavigationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: _labelPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _labelTertiary,
                        letterSpacing: -0.08,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: _labelTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCardWithWhatsApp({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String label,
    required String phone,
    required String email,
    required bool showWhatsApp,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with WhatsApp icon
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _labelPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _labelTertiary,
                        letterSpacing: -0.08,
                      ),
                    ),
                  ],
                ),
              ),
              // WhatsApp icon (only for HR)
              if (showWhatsApp)
                GestureDetector(
                  onTap: () => _openWhatsApp(phone),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _whatsappGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/whatsapp_icon.svg',
                        width: 22,
                        height: 22,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Contact actions - Phone and Email buttons
          Row(
            children: [
              Expanded(
                child: _buildContactAction(
                  icon: Icons.phone_outlined,
                  text: 'Call',
                  onTap: () => _makePhoneCall(phone),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactAction(
                  icon: Icons.email_outlined,
                  text: 'Email',
                  onTap: () => _sendEmail(email),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactAction({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _systemBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: _systemBlue),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _systemBlue,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutConfirmation(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _systemRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.logout_outlined,
                    size: 18,
                    color: _systemRed,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: _systemRed,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sign out of your account',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _labelTertiary,
                          letterSpacing: -0.08,
                        ),
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

  // Actions
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Could not launch phone dialer');
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    try {
      await launchUrl(emailUri);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Could not launch email client');
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    HapticFeedback.lightImpact();
    // Remove + and spaces from phone number for WhatsApp URL
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[+\s]'), '');
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');

    try {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Could not open WhatsApp');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _systemRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChangePasswordSheet(
        onForgotPassword: () {
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: const ForgotPasswordSheet(),
                ),
              );
            }
          });
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogoutConfirmationSheet(
        onLogout: () async {
          await RealAuthService.instance.logout();
          if (mounted) {
            context.go(AppRouter.roleSelection);
          }
        },
      ),
    );
  }
}

/// iOS-style Change Password Bottom Sheet
class _ChangePasswordSheet extends StatefulWidget {
  final VoidCallback? onForgotPassword;

  const _ChangePasswordSheet({this.onForgotPassword});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  static const Color _systemBlue = Color(0xFF007AFF);
  static const Color _labelPrimary = Color(0xFF000000);
  static const Color _labelTertiary = Color(0xFF8E8E93);
  static const Color _backgroundPrimary = Color(0xFFF2F2F7);
  static const Color _backgroundSecondary = Color(0xFFFFFFFF);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _backgroundPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: _labelTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 17,
                        color: _systemBlue,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _labelPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : _handleChangePassword,
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _isLoading ? _labelTertiary : _systemBlue,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E5EA)),
            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: _backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      placeholder: 'Current Password',
                      obscure: _obscureCurrent,
                      onToggle: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    const Divider(
                      height: 1,
                      indent: 16,
                      color: Color(0xFFE5E5EA),
                    ),
                    _buildPasswordField(
                      controller: _newPasswordController,
                      placeholder: 'New Password',
                      obscure: _obscureNew,
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    const Divider(
                      height: 1,
                      indent: 16,
                      color: Color(0xFFE5E5EA),
                    ),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      placeholder: 'Confirm New Password',
                      obscure: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ],
                ),
              ),
            ),

            if (widget.onForgotPassword != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: GestureDetector(
                  onTap: widget.onForgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 16,
                      color: _systemBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String placeholder,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        fontSize: 17,
        color: _labelPrimary,
        letterSpacing: -0.4,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(
          fontSize: 17,
          color: _labelTertiary,
          letterSpacing: -0.4,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _labelTertiary,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password changed successfully'),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// iOS-style Logout Confirmation Sheet
class _LogoutConfirmationSheet extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutConfirmationSheet({required this.onLogout});

  static const Color _systemRed = Color(0xFFFF3B30);
  static const Color _systemBlue = Color(0xFF007AFF);
  static const Color _labelTertiary = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action sheet
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(
                      fontSize: 13,
                      color: _labelTertiary,
                      letterSpacing: -0.08,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E5EA)),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      onLogout();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: _systemRed,
                          letterSpacing: -0.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Cancel button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _systemBlue,
                      letterSpacing: -0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
