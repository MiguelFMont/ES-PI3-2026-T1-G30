// Autor: Miguel Fernandes Monteiro
// RA: 25014808

import 'package:flutter/material.dart';
import '../../../../shared/widgets/mescla_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mescla_auth_layout.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../shared/widgets/campo_texto.dart';


class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  // Controladores apenas para as senhas
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final AuthRepository _authRepository = AuthRepository();
  
  bool _isLoading = false;
  String? _email;
  String? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Extrai o Map (Dicionário) que foi enviado pela TokenVerificationPage
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      _email = args['email'];
      _token = args['token'];
    }
  }

  Future<void> _resetPassword() async {
    final novaSenha = _passwordController.text.trim();
    final confirmaSenha = _confirmPasswordController.text.trim();

    // 1. Validações de segurança e integridade
    if (_email == null || _token == null) {
      _showSnackBar('Erro de comunicação. Volte e tente novamente.', isError: true);
      return;
    }

    if (novaSenha.length < 6) {
      _showSnackBar('A nova senha deve ter pelo menos 6 caracteres.', isError: true);
      return;
    }

    if (novaSenha != confirmaSenha) {
      _showSnackBar('As senhas não coincidem.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Chama a API para efetivar a troca (o backend vai validar o token de novo por segurança)
      final mensagem = await _authRepository.redefinirSenha(
        _email!, 
        _token!, 
        novaSenha
      );

      _showSnackBar(mensagem, isError: false);

      // 3. Sucesso! Volta para a tela de Login, destruindo a pilha de telas de recuperação
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MesclaAuthLayout(
      children: [
        _cabecalho(),
        const SizedBox(height: 40),
        Column(
          children: [
            CampoTexto(
              controller: _passwordController,
              label: 'Nova Senha',
              obscureText: true, // Esconde a senha com asteriscos
            ),
            const SizedBox(height: 16),
            CampoTexto(
              controller: _confirmPasswordController,
              label: 'Confirmar Nova Senha',
              obscureText: true,
            ),
            const SizedBox(height: 32),
            _botaoConfirmar(),
          ],
        ),
      ],
    );
  }

  Widget _cabecalho() {
    return const Column(
      children: [
        Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
        SizedBox(height: 16),
        Text(
          'Criar nova senha',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 20, 
            fontWeight: FontWeight.bold
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Escolha uma nova senha forte e segura para a sua conta.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
        ),
      ],
    );
  }

  Widget _botaoConfirmar() {
    return _isLoading
        ? const CircularProgressIndicator(color: AppColors.primary)
        : MesclaButton(
            label: 'Redefinir Senha',
            onPressed: _resetPassword,
          );
  }
}
