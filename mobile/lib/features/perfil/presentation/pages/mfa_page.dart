// lib/features/perfil/presentation/pages/mfa_page.dart
// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/perfil_repository.dart';
import '../../domain/perfil_models.dart';
import '../../../../shared/widgets/index.dart';

class MfaPage extends StatefulWidget {
  const MfaPage({super.key});

  @override
  State<MfaPage> createState() => _MfaPageState();
}

class _MfaPageState extends State<MfaPage> {
  final _repo = PerfilRepository();
  late Future<PerfilModel> _perfilFuture;

  bool _inicializado = false;
  late bool _mfaAppAtivo;

  static const double _sobreposicaoCard = 120.0;

  @override
  void initState() {
    super.initState();
    _perfilFuture = _repo.buscarPerfil();
  }

  int _calcularMetodosAtivos() {
    int contagem = 1;
    if (_mfaAppAtivo) contagem++;
    return contagem;
  }

  Future<void> _desativarMfa() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Desativar App Autenticador',
          style: TextStyle(color: AppColors.foreground),
        ),
        content: const Text(
          'Tem certeza que deseja desativar o App Autenticador? Sua conta ficará menos protegida.',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Desativar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await _repo.disableMfa();
      if (!mounted) return;
      Navigator.pop(context); // fecha loading
      setState(() => _mfaAppAtivo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App Autenticador desativado com sucesso.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // fecha loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _abrirModalSetupMfa() async {
    // Exibe loading enquanto busca QR do backend
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final setupData = await _repo.setupMfa();
      if (!mounted) return;
      Navigator.pop(context); // fecha o loading

      final ativado = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ModalSetupMfa(
          qrCodeDataUrl: setupData['qrCodeDataUrl'] as String,
          secret: setupData['secret'] as String,
          onVerificar: (code) => _repo.verifyMfa(code),
        ),
      );

      if (ativado == true) {
        setState(() => _mfaAppAtivo = true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // fecha o loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      extendBodyBehindAppBar: true,
      body: FutureBuilder<PerfilModel>(
        future: _perfilFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return TelaErro(
              mensagem: snapshot.error.toString(),
              onTentarNovamente: () => setState(() {
                _perfilFuture = _repo.buscarPerfil();
              }),
            );
          }

          final data = snapshot.data!;

          if (!_inicializado) {
            _mfaAppAtivo = data.mfaAtivo;
            _inicializado = true;
          }

          final metodosAtivos = _calcularMetodosAtivos();

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Wrap(
                  direction: Axis.vertical,
                  spacing: -_sobreposicaoCard,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth,
                      child: const AppGradientHeader(titulo: ''),
                    ),
                    SizedBox(
                      width: constraints.maxWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Autenticação de Múltiplos Fatores (MFA)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            _cardStatusProtecao(metodosAtivos),
                            const SizedBox(height: 24),
                            _cardInformativo(),
                            const SizedBox(height: 32),
                            const RotuloSecao('MÉTODOS DE VERIFICAÇÃO'),
                            const SizedBox(height: 12),
                            _itemMetodo(
                              icon: Icons.smartphone_rounded,
                              titulo: 'App Autenticador',
                              descricao:
                                  'Google Authenticator, Authy, 1Password. Gera códigos de 6 dígitos a cada 30s, mesmo offline. Mais seguro.',
                              valor: _mfaAppAtivo,
                              onChanged: (_) => _mfaAppAtivo
                                  ? _desativarMfa()
                                  : _abrirModalSetupMfa(),
                            ),
                            const SizedBox(height: 12),
                            _itemMetodo(
                              icon: Icons.email_outlined,
                              titulo: 'Email',
                              descricao:
                                  'Código enviado por email. Envia para ${data.email}.',
                              valor: true,
                              onChanged: null,
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── widgets internos ────────────────────────────────────────────────────────

  Widget _cardStatusProtecao(int metodosAtivos) {
    final isProtegida = metodosAtivos >= 2;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isProtegida ? Colors.green : Colors.orange).withValues(
                alpha: 0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              color: isProtegida ? Colors.green : Colors.orange,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MFA Configurado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
                Text(
                  '$metodosAtivos método(s) de verificação ativo(s)',
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 14,
                  ),
                ),
                if (isProtegida) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Conta Protegida',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardInformativo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.2)),
      ),
      child: const Text(
        'A autenticação de múltiplos fatores (MFA) adiciona uma camada extra de segurança à sua conta MesclaInvest. Recomendamos manter o App Autenticador ativo.',
        style: TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _itemMetodo({
    required IconData icon,
    required String titulo,
    String? tag,
    required String descricao,
    required bool valor,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: valor
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: valor
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: valor
                  ? Colors.green.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: valor
                  ? Colors.green
                  : AppColors.primary.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                    ),
                    if (tag != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: valor,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.foreground;
              }
              if (states.contains(WidgetState.selected)) {
                return AppColors.foreground;
              }
              return Colors.white;
            }),
            trackColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.foreground.withValues(alpha: 0.3);
              }
              if (states.contains(WidgetState.selected)) {
                return AppColors.foreground.withValues(alpha: 0.5);
              }
              return Colors.grey.withValues(alpha: 0.3);
            }),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

// ── Modal de setup do App Autenticador ────────────────────────────────────────

class _ModalSetupMfa extends StatefulWidget {
  final String qrCodeDataUrl;
  final String secret;
  final Future<void> Function(String code) onVerificar;

  const _ModalSetupMfa({
    required this.qrCodeDataUrl,
    required this.secret,
    required this.onVerificar,
  });

  @override
  State<_ModalSetupMfa> createState() => _ModalSetupMfaState();
}

class _ModalSetupMfaState extends State<_ModalSetupMfa> {
  final _codeController = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _erro = 'Digite os 6 dígitos do código.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await widget.onVerificar(code);
      if (!mounted) return;
      Navigator.pop(context, true); // retorna true = ativado com sucesso
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceAll('Exception: ', '');
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final base64Str = widget.qrCodeDataUrl.split(',').last;
    final qrBytes = base64Decode(base64Str);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        // <- adiciona aqui
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de arraste
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Configurar App Autenticador',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escaneie o QR code com Google Authenticator, Authy ou similar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // QR Code
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.memory(qrBytes, width: 180, height: 180),
            ),
            const SizedBox(height: 16),

            // Secret para entrada manual
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.secret,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ou digite a chave manualmente no app',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 11),
            ),
            const SizedBox(height: 24),

            // Campo do código
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                color: AppColors.foreground,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: TextStyle(
                  color: AppColors.mutedForeground.withValues(alpha: 0.4),
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: AppColors.muted.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                errorText: _erro,
              ),
              onChanged: (_) => setState(() => _erro = null),
            ),
            const SizedBox(height: 20),

            // Botão de verificar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _carregando ? null : _verificar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _carregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verificar e Ativar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
