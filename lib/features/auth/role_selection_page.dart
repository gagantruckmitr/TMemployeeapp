import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_router.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String? selectedRole;
  bool _isLoading = false;

  final List<RoleOption> roles = [
    RoleOption(
      id: 'telecaller',
      title: 'Telecaller',
      description: 'Handle driver calls, subscriptions, and customer support',
      icon: Icons.phone_in_talk_rounded,
      color: const Color(0xFF3D4A7A),
    ),
    RoleOption(
      id: 'margdarshak',
      title: 'Margdarshak (Field Agent)',
      description: 'Onboard shops, manage territory, and track field operations',
      icon: Icons.location_on_rounded,
      color: const Color(0xFF2E7D32),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE9ECEF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Header
                _buildHeader(),
                
                const SizedBox(height: 60),
                
                // Role Cards
                Expanded(
                  child: ListView.builder(
                    itemCount: roles.length,
                    itemBuilder: (context, index) {
                      final role = roles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildRoleCard(role, index),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Continue Button
                _buildContinueButton(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF3D4A7A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.work_outline_rounded,
            size: 50,
            color: Color(0xFF3D4A7A),
          ),
        )
        .animate()
        .scale(
          duration: 600.ms,
          curve: Curves.easeOutBack,
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Select Your Role',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D5F),
          ),
          textAlign: TextAlign.center,
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.3, end: 0),
        
        const SizedBox(height: 12),
        
        Text(
          'Choose your role to access the appropriate dashboard and features',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildRoleCard(RoleOption role, int index) {
    final isSelected = selectedRole == role.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? role.color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? role.color.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 20 : 10,
              offset: const Offset(0, 5),
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: role.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                role.icon,
                size: 32,
                color: role.color,
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? role.color : const Color(0xFF2D2D5F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    role.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? role.color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? role.color : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: Duration(milliseconds: 600 + (index * 200)))
    .slideX(begin: 0.3, end: 0);
  }

  Widget _buildContinueButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: selectedRole != null
          ? LinearGradient(
              colors: [
                const Color(0xFF3D4A7A),
                const Color(0xFF5C5C99),
              ],
            )
          : null,
        color: selectedRole == null ? Colors.grey.shade300 : null,
        boxShadow: selectedRole != null
          ? [
              BoxShadow(
                color: const Color(0xFF3D4A7A).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: selectedRole != null && !_isLoading ? _handleContinue : null,
          child: Center(
            child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Continue',
                  style: TextStyle(
                    color: selectedRole != null ? Colors.white : Colors.grey.shade500,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: 1000.ms)
    .slideY(begin: 0.3, end: 0);
  }

  void _handleContinue() async {
    if (selectedRole == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('🔍 Debug: Selected role: $selectedRole');
      
      // Don't save role yet, just navigate to appropriate login
      if (!mounted) return;
      
      // Navigate based on selected role
      if (selectedRole == 'telecaller') {
        print('🔍 Debug: Navigating to telecaller login');
        context.go(AppRouter.telecallerLogin);
      } else if (selectedRole == 'margdarshak') {
        print('🔍 Debug: Navigating to margdarshak login');
        context.go(AppRouter.margdarshakLogin);
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class RoleOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  RoleOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}