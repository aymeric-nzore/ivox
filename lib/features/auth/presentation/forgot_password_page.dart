import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ivox/features/auth/services/api_auth_service.dart';
import 'package:ivox/shared/utils/my_button.dart';
import 'package:ivox/shared/utils/my_textfield.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _apiAuthService = ApiAuthService();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _infoMessage;
  int _resendCooldownSeconds = 0;
  Timer? _resendTimer;

  bool get _canResend => _resendCooldownSeconds == 0;

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() {
      _resendCooldownSeconds = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _resendCooldownSeconds = 0;
        });
        return;
      }

      setState(() {
        _resendCooldownSeconds -= 1;
      });
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (_otpSent && !_canResend) {
      setState(() {
        _errorMessage = null;
        _infoMessage = 'Renvoyez le code dans $_resendCooldownSeconds s';
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez saisir votre email';
        _infoMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final message = await _apiAuthService.forgotPassword(email: email);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _infoMessage = message;
        _isLoading = false;
      });
      _startResendCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (email.isEmpty || code.isEmpty || newPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez remplir tous les champs';
        _infoMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final message = await _apiAuthService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      if (!mounted) return;
      setState(() {
        _infoMessage = message;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe modifie. Connectez-vous.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublie'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Entrez votre email pour recevoir un code OTP, puis choisissez un nouveau mot de passe.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 18),
              MyTextfield(
                text: 'Email',
                controller: _emailController,
                icon: const Icon(Icons.email_outlined),
                isObscure: false,
              ),
              const SizedBox(height: 8),
              MyButton(
                text: _isLoading
                    ? 'Envoi...'
                    : (_otpSent ? 'Renvoyer le code OTP' : 'Envoyer le code OTP'),
                onTap: (_isLoading || (_otpSent && !_canResend)) ? () {} : _sendOtp,
              ),
              if (_otpSent)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _canResend
                          ? 'Vous pouvez renvoyer le code maintenant'
                          : 'Renvoyer dans $_resendCooldownSeconds s',
                      style: TextStyle(
                        fontSize: 12,
                        color: _canResend ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              if (_otpSent) ...[
                MyTextfield(
                  text: 'Code OTP',
                  controller: _codeController,
                  icon: const Icon(Icons.verified_user_outlined),
                  isObscure: false,
                ),
                MyTextfield(
                  text: 'Nouveau mot de passe',
                  controller: _newPasswordController,
                  icon: const Icon(Icons.lock_outline),
                  isObscure: _obscurePassword,
                  sicon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                MyButton(
                  text: _isLoading ? 'Validation...' : 'Reinitialiser le mot de passe',
                  onTap: _isLoading ? () {} : _resetPassword,
                ),
              ],
              if (_infoMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _infoMessage!,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
