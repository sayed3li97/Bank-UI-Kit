import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String _pin = '';
  bool _showTimeout = false;

  @override
  Widget build(BuildContext context) {
    final theme = BankThemeData.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Auth & Security'),
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BankTokens.space4),
        children: [
          Text('PIN Dots', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          Center(
            child: BankPinDots(
              filledCount: _pin.length,
              totalCount: 6,
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('PIN Keypad', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankPinKeypad(
            onDigitPressed: (d) => setState(() {
              if (_pin.length < 6) _pin += d;
            }),
            onDeletePressed: () =>
                setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1)),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Biometric Button', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          Center(
            child: BankBiometricPromptButton(
              onAuthenticate: () async {
                await Future.delayed(const Duration(seconds: 1));
                return true;
              },
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Privacy Toggle', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          const Center(child: BankPrivacyToggle()),
          const SizedBox(height: BankTokens.space4),
          Text('Device Trust Banner', style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankDeviceTrustBanner(
            isNewDevice: true,
            deviceName: 'iPhone 16 Pro',
            onTrustDevice: () {},
            onDismiss: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          FilledButton(
            onPressed: () => setState(() => _showTimeout = !_showTimeout),
            child: Text(_showTimeout ? 'Hide timeout dialog' : 'Show Session Timeout'),
          ),
          if (_showTimeout)
            BankSessionTimeoutDialog(
              remainingSeconds: 60,
              onExtendSession: () => setState(() => _showTimeout = false),
              onLogout: () => setState(() => _showTimeout = false),
            ),
        ],
      ),
    );
  }
}
