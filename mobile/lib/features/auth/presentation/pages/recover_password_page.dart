// Autor: Miguel Fernandes Monteiro
// RA: 25014808
import 'package:flutter/material.dart';
import 'package:mobile/shared/widgets/mescla_button.dart';
import '../../../../shared/widgets/campo_texto.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mescla_auth_layout.dart';
import '../../data/repositories/auth_repository.dart';

class RecoverPasswordPage extends StatefulWidget {
  const RecoverPasswordPage({super.key});

  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends State<RecoverPasswordPage> {
  final _emailController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;

  Future<void> _recoverPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _mostrarMensagem('Por favor, digite seu e-mail.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final mensagem = await _authRepository.solicitarCodigoRecuperacao(email);

      _mostrarMensagem(mensagem, isError: false);

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/token-verification',
          arguments: {'email': email, 'fluxo': 'senha'},
        );
      }
    } catch (e) {
      _mostrarMensagem(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Função auxiliar para mostrar o Snackbar
  void _mostrarMensagem(String mensagem, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MesclaAuthLayout(
      children: [
        _imagemDeCadeado(),
        const SizedBox(height: 32),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _mensagemDeInstrucao(),
                CampoTexto(
                  controller: _emailController,
                  label: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),
                _botaoRecuperarSenha(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mensagemDeInstrucao() {
    final mensagem =
        'Digite seu e-mail cadastrado e enviaremos as instruções de recuperação.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 35, top: 8),
      child: Text(
        mensagem,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedForeground,
          height: 1.6,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _imagemDeCadeado() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 40),
    );
  }

  Widget _botaoRecuperarSenha() {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        : MesclaButton(label: 'Recuperar Senha', onPressed: _recoverPassword);
  }
}
