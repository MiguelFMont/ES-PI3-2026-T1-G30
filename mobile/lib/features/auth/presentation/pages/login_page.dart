// Autor: Miguel Fernandes Monteiro
// RA: 25014808

import 'package:flutter/material.dart';
import 'package:mesclainvest/app/routes.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../shared/widgets/campo_texto.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mescla_auth_layout.dart';
import '../../../../shared/widgets/mescla_button.dart';
import '../../../../shared/widgets/mescla_notificacao.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _repository = AuthRepository();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final user = await _repository.login(
        _emailController.text,
        _senhaController.text,
      );

      if (!mounted) return;

      if (user.mfaRequired) {
        Navigator.pushNamed(
          context,
          AppRoutes.mfaChallenge,
          arguments: {'uid': user.id, 'tempToken': user.tempToken},
        );
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    } catch (e) {
      if (!mounted) return;
      MesclaNotificacao.mostrar(
        context,
        label: e.toString().replaceAll('Exception: ', ''),
        cor: AppColors.destructive,
      );
    } finally {
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
              _titulo(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CampoTexto(
                      controller: _emailController,
                      label: 'E-mail',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    CampoTexto(
                      controller: _senhaController,
                      label: 'Senha',
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    _linkEsqueceuSenha(),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const CircularProgressIndicator(
                            color: AppColors.foreground,
                            backgroundColor: AppColors.primary,
                          )
                        : _botaoLogin(),
                  ],
                ),
              ),
              _linkCadastro(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _botaoLogin() => MesclaButton(label: 'Entrar', onPressed: _login);

  Widget _titulo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 30, top: 20),
      child: const Text(
        'Login',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.foreground,
        ),
      ),
    );
  }

  Widget _linkEsqueceuSenha() {
    return SizedBox(
      width: 250,
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
          child: const Text(
            'Esqueceu sua senha?',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _linkCadastro() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Não tem uma conta?',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
          style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
          child: const Text(
            'Cadastre-se',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
