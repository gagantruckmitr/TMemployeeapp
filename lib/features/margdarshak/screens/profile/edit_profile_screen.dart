import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/margdarshak_api_service.dart';
import '../../services/margdarshak_auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditProfileScreen({
    super.key,
    required this.profileData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = MargdarshakApiService();
  final _authService = MargdarshakAuthService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _accountHolderNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscCodeController;
  late TextEditingController _bankNameController;
  late TextEditingController _upiIdController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(
      text: widget.profileData['name'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.profileData['email'] ?? '',
    );

    final bankDetails = widget.profileData['bankDetails'] ?? {};
    _accountHolderNameController = TextEditingController(
      text: bankDetails['accountHolderName'] ?? '',
    );
    _accountNumberController = TextEditingController(
      text: bankDetails['accountNumber'] ?? '',
    );
    _ifscCodeController = TextEditingController(
      text: bankDetails['ifscCode'] ?? '',
    );
    _bankNameController = TextEditingController(
      text: bankDetails['bankName'] ?? '',
    );
    _upiIdController = TextEditingController(
      text: bankDetails['upiId'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _bankNameController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D5F),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2D2D5F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              _buildInfoBanner(),

              const SizedBox(height: 24),

              // Basic Information
              _buildSection(
                'Basic Information',
                Icons.person_outline_rounded,
                const Color(0xFF7B1FA2),
                [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          !value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Read-only fields
              _buildSection(
                'Account Information (Read-only)',
                Icons.lock_outline_rounded,
                const Color(0xFF757575),
                [
                  _buildReadOnlyField(
                    'Employee ID',
                    widget.profileData['employeeId'] ?? 'N/A',
                    Icons.badge,
                  ),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                    'Mobile Number',
                    widget.profileData['mobile'] ?? 'N/A',
                    Icons.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                    'Territory',
                    widget.profileData['territory']?['state'] ?? 'N/A',
                    Icons.map,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Bank Details
              _buildSection(
                'Bank Details',
                Icons.account_balance_rounded,
                const Color(0xFF388E3C),
                [
                  _buildTextField(
                    controller: _upiIdController,
                    label: 'UPI ID',
                    icon: Icons.payment,
                    hint: 'yourname@upi',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _accountHolderNameController,
                    label: 'Account Holder Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _accountNumberController,
                    label: 'Account Number',
                    icon: Icons.account_balance_wallet,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _bankNameController,
                    label: 'Bank Name',
                    icon: Icons.account_balance,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ifscCodeController,
                    label: 'IFSC Code',
                    icon: Icons.code,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Employee ID, Mobile, and Territory cannot be changed',
              style: TextStyle(
                color: Color(0xFF1565C0),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D5F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2D5F),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 16),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Build update data - only send fields that can be updated
      final updateData = <String, dynamic>{};

      // Basic info
      if (_nameController.text.isNotEmpty) {
        updateData['name'] = _nameController.text.trim();
      }
      if (_emailController.text.isNotEmpty) {
        updateData['email'] = _emailController.text.trim();
      }

      // Bank details
      if (_accountHolderNameController.text.isNotEmpty) {
        updateData['account_holder_name'] =
            _accountHolderNameController.text.trim();
      }
      if (_accountNumberController.text.isNotEmpty) {
        updateData['account_number'] = _accountNumberController.text.trim();
      }
      if (_ifscCodeController.text.isNotEmpty) {
        updateData['ifsc_code'] = _ifscCodeController.text.trim();
      }
      if (_bankNameController.text.isNotEmpty) {
        updateData['bank_name'] = _bankNameController.text.trim();
      }
      if (_upiIdController.text.isNotEmpty) {
        updateData['upi_id'] = _upiIdController.text.trim();
      }

      // Call API
      final response = await _apiService.updateProfile(updateData);

      if (response['status'] == true) {
        // Update local auth service with new data
        if (response['data'] != null) {
          // Optionally update the auth service's current user
          await _authService.loadSession(); // Reload session
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Profile updated successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Go back and refresh profile
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception(response['message'] ?? 'Update failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
