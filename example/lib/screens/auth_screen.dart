import 'package:bank_ui_kit/core.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String _pin = '';

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
          Text('PIN Dots',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          Center(
            child: BankPinDots(
              length: 6,
              filled: _pin.length,
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('PIN Keypad',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankPinKeypad(
            onDigit: (d) => setState(() {
              if (_pin.length < 6) _pin += d;
            }),
            onDelete: () => setState(
              () =>
                  _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1),
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Biometric Button',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          Center(
            child: BankBiometricPromptButton(
              label: 'Log in with Face ID',
              type: BankBiometricType.face,
              onAuthenticate: () async {
                await Future<void>.delayed(const Duration(seconds: 1));
                return true;
              },
              onSuccess: () {},
            ),
          ),
          const SizedBox(height: BankTokens.space4),
          Text('Privacy Toggle',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          const Center(child: BankPrivacyToggle()),
          const SizedBox(height: BankTokens.space4),
          Text('Device Trust Banner',
              style: BankTokens.labelLarge.copyWith(color: theme.onSurface)),
          const SizedBox(height: BankTokens.space3),
          BankDeviceTrustBanner(
            state: BankDeviceTrustState.newDevice,
            onLearnMore: () {},
            onDismiss: () {},
          ),
          const SizedBox(height: BankTokens.space4),
          FilledButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => BankSessionTimeoutDialog(
                remainingTime: const Duration(seconds: 60),
                onExtend: () => Navigator.of(dialogContext).pop(),
                onLogout: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            child: const Text('Show Session Timeout'),
          ),
        ],
      ),
    );
  }
}
