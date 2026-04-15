// Autor: Miguel Fernandes Monteiro
// RA: 25014808
import 'package:flutter/material.dart';
import 'package:mobile/shared/widgets/mescla_button.dart';
import '../../../../shared/widgets/campo_texto.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mescla_logo.dart';

class RecoverPasswordPage extends StatefulWidget {
  const RecoverPasswordPage({super.key});

  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends State<RecoverPasswordPage> {
  final _emailController = TextEditingController();

  Future<void> _recoverPassword() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Instruções de recuperação enviadas para o e-mail'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tecladoAberto = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: AppColors.card,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: tecladoAberto ? 40 : 80,
                ),
                _logo(),
                const SizedBox(height: 32),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return const MesclaLogo();
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
    return MesclaButton(label: 'Recuperar Senha', onPressed: _recoverPassword);
  }
}
