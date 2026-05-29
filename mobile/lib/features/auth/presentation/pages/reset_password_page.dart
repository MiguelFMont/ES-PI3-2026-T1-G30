// Autor: Miguel Fernandes Monteiro
// RA: 25014808

import 'package:flutter/material.dart';
import '../../../../shared/widgets/mescla_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mescla_auth_layout.dart';
import '../../../../shared/widgets/mescla_notificacao.dart';
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

  // ── Requisitos da senha ────────────────────────────────────────────────────
  bool get _temMinimo => _passwordController.text.length >= 8;
  bool get _temMaiuscula => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _temNumero => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _temEspecial =>
      _passwordController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get _senhaValida =>
      _temMinimo && _temMaiuscula && _temNumero && _temEspecial;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Extrai o Map (Dicionário) que foi enviado pela TokenVerificationPage
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

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
      _showNotificacao(
        'Erro de comunicação. Volte e tente novamente.',
        isError: true,
      );
      return;
    }

    if (!_senhaValida) {
      _showNotificacao('A senha não atende todos os requisitos.', isError: true);
      return;
    }

    if (novaSenha != confirmaSenha) {
      _showNotificacao('As senhas não coincidem.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Chama a API para efetivar a troca (o backend vai validar o token de novo por segurança)
      final mensagem = await _authRepository.redefinirSenha(
        _email!,
        _token!,
        novaSenha,
      );

      _showNotificacao(mensagem, isError: false);

      // 3. Sucesso! Volta para a tela de Login, destruindo a pilha de telas de recuperação
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      _showNotificacao(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNotificacao(String message, {required bool isError}) {
    MesclaNotificacao.mostrar(
      context,
      label: message.replaceAll('Exception: ', ''),
      cor: isError ? AppColors.destructive : Colors.green,
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
        const SizedBox(height: 30),
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
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _requisitos(),
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _requisitos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requisitos da senha:',
          style: TextStyle(
            color: AppColors.mutedForeground.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        _itemRequisito('Mínimo 8 caracteres', _temMinimo),
        _itemRequisito('Letra maiúscula', _temMaiuscula),
        _itemRequisito('Número', _temNumero),
        _itemRequisito('Caractere especial', _temEspecial),
      ],
    );
  }

  Widget _itemRequisito(String texto, bool valido) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            valido ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 14,
            color: valido
                ? Colors.green
                : AppColors.mutedForeground.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              color: valido
                  ? Colors.green
                  : AppColors.mutedForeground.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoConfirmar() {
    return _isLoading
        ? const CircularProgressIndicator(color: AppColors.primary)
        : MesclaButton(label: 'Redefinir Senha', onPressed: _resetPassword);
  }
}
