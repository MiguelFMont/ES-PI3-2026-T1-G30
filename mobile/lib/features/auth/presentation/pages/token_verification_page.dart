// Autor: Miguel Fernandes Monteiro
// RA: 25014808

import 'package:flutter/material.dart';
import '../../../../shared/widgets/mescla_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mescla_auth_layout.dart';
import '../../data/repositories/auth_repository.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';

class TokenVerificationPage extends StatefulWidget {
  const TokenVerificationPage({super.key});

  @override
  State<TokenVerificationPage> createState() => _TokenVerificationPageState();
}

class _TokenVerificationPageState extends State<TokenVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  final AuthRepository _authRepository = AuthRepository();

  int _segundosRestantes = 120; // 2 minutos
  Timer? _timer;

  bool _isLoading = false;

  Future<void> _reenviarToken() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String email = args['email'];
    final String fluxo = args['fluxo'];

    try {
      if (fluxo == 'cadastro') {
        await _authRepository.reenviarTokenCadastro(email);
      } else if (fluxo == 'senha') {
        await _authRepository.solicitarCodigoRecuperacao(email);
      }

      setState(() {
        _segundosRestantes = 120;
        _otpController.clear();
      });
      _iniciarTimer();
      _showSnackBar('Novo código enviado!', isError: false);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _verificarToken() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String email = args['email'];
    final String fluxo = args['fluxo']; // Vai ser 'cadastro' ou 'senha'

    final token = _otpController.text;

    if (token.length != 5) {
      _showSnackBar('O código deve ter 5 dígitos', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (fluxo == 'cadastro') {
        // ---- FLUXO DE CADASTRO ----
        await _authRepository.concluirCadastro(email, token);

        if (mounted) {
          _showSnackBar('Conta ativada com sucesso!', isError: false);
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else if (fluxo == 'senha') {
        // ---- FLUXO DE RECUPERAR SENHA ----
        await _authRepository.validarToken(email, token);

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/reset-password',
            arguments: {
              'email': email,
              'token': token,
            }, // Repassa pra próxima tela
          );
        }
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() => _segundosRestantes--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _iniciarTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Para mudar o texto dinamicamente, pescamos o fluxo aqui no visual também:
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool isCadastro = args?['fluxo'] == 'cadastro';

    return MesclaAuthLayout(
      children: [
        _header(isCadastro),
        const SizedBox(height: 80),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _campoTokens(),
            const SizedBox(height: 20),
            _botaoConfirmar(),
            _botaoReenviarToken(),
          ],
        ),
      ],
    );
  }

  Widget _header(bool isCadastro) {
    return Column(
      children: [
        const Text(
          '* * * * *',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 47,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isCadastro ? 'Ativar Conta' : 'Validação do token',
          style: const TextStyle(
            color: AppColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Insira o código enviado para o seu e-mail.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
        ),
      ],
    );
  }

  Widget _botaoConfirmar() {
    return _isLoading
        ? const CircularProgressIndicator(color: AppColors.primary)
        : MesclaButton(label: 'Verificar', onPressed: _verificarToken);
  }

  Widget _botaoReenviarToken() {
    return Column(
      children: [
        const SizedBox(height: 16),
        if (_segundosRestantes > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'O código expira em ',
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 14,
                ),
              ),
              Text(
                '${_segundosRestantes ~/ 60}:${(_segundosRestantes % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

        TextButton(
          onPressed: _segundosRestantes > 0 ? null : _reenviarToken,
          style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Não recebeu o código?',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '  Reenviar código',
                style: TextStyle(
                  color: _segundosRestantes > 0
                      ? AppColors.mutedForeground
                      : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _campoTokens() {
    final defaultTheme = PinTheme(
      width: 47,
      height: 47,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.foreground,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color.fromARGB(40, 233, 30, 98), width: 2),
        ),
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.primary, width: 2)),
      ),
    );

    return Pinput(
      length: 5,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: focusedTheme,
      keyboardType: TextInputType.number,
      onCompleted: (pin) => _verificarToken(),
      onChanged: (value) => setState(() {}),
      controller: _otpController,
      focusNode: _otpFocusNode,
    );
  }
}
