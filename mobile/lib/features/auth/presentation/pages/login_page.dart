// Autor: Miguel Fernandes Monteiro
// RA: 25014808
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../shared/widgets/campo_texto.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mescla_auth_layout.dart';
import '../../../../shared/widgets/mescla_button.dart';


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
      await _repository.login(_emailController.text, _senhaController.text);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
              _linkEsqueceuSenha(),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator(
                      color: AppColors.foreground,
                      backgroundColor: AppColors.primary,
                    )
                  : _botaoLogin(),
              const SizedBox(height: 55),
              _linkCadastro(),
            ],
          ),
        ),
      ],
    );
  }

  // --- Widgets auxiliares ---

  Widget _botaoLogin() {
    return MesclaButton(label: 'Entrar', onPressed: _login);
  }

  Widget _titulo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 30, top: 20),
      child: const Text(
        'Login',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.foreground, // Alterado
        ),
      ),
    );
  }

  Widget _linkEsqueceuSenha() {
    return Transform.translate(
      offset: const Offset(-16, -8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/forgot-password');
          },
          style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
          child: const Text(
            'Esqueceu sua senha?',
            style: TextStyle(
              color: AppColors.accent, // Alterado
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
            color: AppColors.mutedForeground, // Alterado
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/register');
          },
          style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
          child: const Text(
            'Cadastre-se',
            style: TextStyle(
              color: AppColors.accent, // Alterado
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
