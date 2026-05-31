// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'package:flutter/material.dart';
import 'package:mesclainvest/app/routes.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mescla_auth_layout.dart';
import '../../../../shared/widgets/mescla_button.dart';
import '../../../../shared/widgets/mescla_notificacao.dart';

class MfaChallengePage extends StatefulWidget {
  const MfaChallengePage({super.key});

  @override
  State<MfaChallengePage> createState() => _MfaChallengePageState();
}

class _MfaChallengePageState extends State<MfaChallengePage> {
  final _codeController = TextEditingController();
  final _repository = AuthRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      MesclaNotificacao.mostrar(
        context,
        label: 'Digite os 6 dígitos do código.',
        cor: AppColors.destructive,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final uid = args['uid'] as String;
      final tempToken = args['tempToken'] as String;

      await _repository.mfaChallenge(uid, tempToken, code);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } catch (e) {
      if (!mounted) return;
      MesclaNotificacao.mostrar(
        context,
        label: e.toString().replaceAll('Exception: ', ''),
        cor: AppColors.destructive,
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MesclaAuthLayout(
      children: [
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 50),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: const Text(
                  'Verificação em dois fatores',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: const Text(
                  'Abra seu app autenticador e digite o código de 6 dígitos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  letterSpacing: 10,
                  color: AppColors.foreground,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  hintStyle: TextStyle(
                    color: AppColors.mutedForeground.withValues(alpha: 0.4),
                    letterSpacing: 10,
                  ),
                  filled: true,
                  fillColor: AppColors.muted.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator(
                      color: AppColors.foreground,
                      backgroundColor: AppColors.primary,
                    )
                  : MesclaButton(label: 'Verificar', onPressed: _verificar),
            ],
          ),
        ),
      ],
    );
  }
}
