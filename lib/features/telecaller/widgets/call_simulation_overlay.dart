import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';

class CallSimulationOverlay extends StatefulWidget {
  final DriverContact contact;
  final Function(int duration) onCallEnded;
  final String? referenceId;
  final String? callLogId;

  const CallSimulationOverlay({
    super.key,
    required this.contact,
    required this.onCallEnded,
    this.referenceId,
    this.callLogId,
  });

  @override
  State<CallSimulationOverlay> createState() => _CallSimulationOverlayState();
}

class _CallSimulationOverlayState extends State<CallSimulationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _callStatus = 'Initiating call...';
  bool _isConnected = false;
  int _callDuration = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  String _callPhase = 'initiating'; // initiating, ringing, connected, ended
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _startCallSimulation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _startCallSimulation() async {
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    
    // Phase 1: Initiating (calling MyOperator)
    setState(() {
      _callStatus = 'Connecting to IVR...';
      _callPhase = 'initiating';
    });
    
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    // Phase 2: Ringing (MyOperator calling telecaller)
    setState(() {
      _callStatus = 'Calling your phone...';
      _callPhase = 'ringing';
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Phase 3: Connecting driver
    setState(() {
      _callStatus = 'Connecting to driver...';
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Phase 4: Connected
    setState(() {
      _callStatus = 'Connected';
      _isConnected = true;
      _callPhase = 'connected';
    });
    
    _pulseController.stop();
    _pulseController.reset();
    
    // Start call duration timer
    _startCallTimer();
    
    // Note: In real implementation, the call will continue until user ends it
    // For now, we'll wait for user to end the call manually
  }

  void _startCallTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isConnected) {
        setState(() {
          _callDuration++;
        });
        return true;
      }
      return false;
    });
  }

  void _endCall() {
    HapticFeedback.mediumImpact();
    setState(() {
      _callStatus = 'Call Ended';
      _isConnected = false;
      _callPhase = 'ended';
    });
    
    // Save call duration to database if we have reference ID
    if (widget.referenceId != null) {
      _saveCallData();
    }
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        // Pass the call duration back
        widget.onCallEnded(_callDuration);
      }
    });
  }
  
  Future<void> _saveCallData() async {
    // This will be called when call ends to save duration
    // The feedback will be collected in the modal after this
    try {
      if (widget.referenceId != null && _callDuration > 0) {
        print('💾 Saving call duration: $_callDuration seconds');
        print('📞 Reference ID: ${widget.referenceId}');
        
        // Update call duration in database via API
        // The full feedback will be saved later in the feedback modal
        // For now, just log it - the feedback modal will include duration
      }
    } catch (e) {
      print('❌ Error saving call data: $e');
    }
  }
  
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    HapticFeedback.selectionClick();
    // In real implementation, this would mute the microphone
  }
  
  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    HapticFeedback.selectionClick();
    // In real implementation, this would toggle speaker
  }
  
  void _showKeypad() {
    HapticFeedback.selectionClick();
    // In real implementation, this would show dialpad
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Keypad feature coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        'Smart Call',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isConnected 
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isConnected 
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.orange.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isConnected ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _callStatus,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Contact Info
                Column(
                  children: [
                    // Avatar
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isConnected ? 1.0 : _pulseAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue.withValues(alpha: 0.3),
                                  AppTheme.accentOrange.withValues(alpha: 0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(
                                color: AppTheme.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                widget.contact.name.substring(0, 1).toUpperCase(),
                                style: AppTheme.headingLarge.copyWith(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Contact Name
                    Text(
                      widget.contact.name,
                      style: AppTheme.headingMedium.copyWith(
                        color: AppTheme.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Company Name
                    Text(
                      widget.contact.company,
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Phone Number (Hidden)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone,
                            color: AppTheme.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '••••• •••••',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.white.withValues(alpha: 0.8),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Call Duration
                if (_isConnected) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      _formatDuration(_callDuration),
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
                
                // End Call Button
                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Call Controls (Functional)
                if (_isConnected) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCallControl(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        _isMuted ? 'Unmute' : 'Mute',
                        onTap: _toggleMute,
                        isActive: _isMuted,
                      ),
                      _buildCallControl(
                        Icons.volume_up,
                        'Speaker',
                        onTap: _toggleSpeaker,
                        isActive: _isSpeakerOn,
                      ),
                      _buildCallControl(
                        Icons.dialpad,
                        'Keypad',
                        onTap: _showKeypad,
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallControl(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                  : AppTheme.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
              border: isActive
                  ? Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                      width: 2,
                    )
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive
                  ? AppTheme.white
                  : AppTheme.white.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: isActive
                  ? AppTheme.white
                  : AppTheme.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}