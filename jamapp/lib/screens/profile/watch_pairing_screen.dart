import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme_config.dart';
import '../../services/pairing_service.dart';

class WatchPairingScreen extends StatefulWidget {
  const WatchPairingScreen({Key? key}) : super(key: key);

  @override
  State<WatchPairingScreen> createState() => _WatchPairingScreenState();
}

class _WatchPairingScreenState extends State<WatchPairingScreen> {
  final PairingService _pairingService = PairingService();

  String? _pairingCode;
  DateTime? _expiryTime;
  Duration _timeRemaining = const Duration(minutes: 5);
  Timer? _countdownTimer;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateNewCode();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateNewCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final codeData = await _pairingService.generatePairingCode();

      setState(() {
        _pairingCode = codeData['code'];
        _expiryTime = codeData['expiryTime'];
        _isLoading = false;
      });

      // Start countdown timer
      _startCountdown();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate pairing code: $e';
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expiryTime == null) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      if (now.isAfter(_expiryTime!)) {
        setState(() {
          _timeRemaining = Duration.zero;
          _pairingCode = null;
        });
        timer.cancel();
      } else {
        setState(() {
          _timeRemaining = _expiryTime!.difference(now);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Connect Smartwatch',
          style: GoogleFonts.poppins(
            color: ThemeConfig.textIvory,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ThemeConfig.textIvory),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Watch Connection Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ThemeConfig.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.watch_outlined,
                size: 80,
                color: ThemeConfig.primaryGreen,
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Text(
              'Connect Your Android Smartwatch',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textIvory,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Don\'t miss a single step! Pair your watch to track your fitness completely.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: ThemeConfig.textIvory.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 36),

            // Pairing code display
            if (_isLoading)
              const CircularProgressIndicator(color: ThemeConfig.primaryGreen)
            else if (_pairingCode != null)
              Column(
                children: [
                  Text(
                    'Enter this code on your watch:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: ThemeConfig.textIvory.withOpacity(0.8),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Code display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ThemeConfig.primaryGreen,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          _pairingCode!.split('').map((digit) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ThemeConfig.primaryGreen.withOpacity(
                                  0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                digit,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeConfig.primaryGreen,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Countdown timer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, color: ThemeConfig.primaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        'Expires in ${_formatDuration(_timeRemaining)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              _timeRemaining.inSeconds < 60
                                  ? Colors.redAccent
                                  : ThemeConfig.textIvory,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              )
            else
              Text(
                'Code has expired. Generate a new one.',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 36),

            // Regenerate button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateNewCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(
                'Generate New Code',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions for watch app
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to pair your watch:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.textIvory,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionStep(
                    '1',
                    'Install JamSync on your smartwatch',
                  ),
                  _buildInstructionStep('2', 'Open the app on your watch'),
                  _buildInstructionStep('3', 'Select "Pair with Phone"'),
                  _buildInstructionStep(
                    '4',
                    'Enter the 6-digit code shown above',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: ThemeConfig.primaryGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: ThemeConfig.primaryGreen,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              instruction,
              style: GoogleFonts.poppins(
                color: ThemeConfig.textIvory.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
