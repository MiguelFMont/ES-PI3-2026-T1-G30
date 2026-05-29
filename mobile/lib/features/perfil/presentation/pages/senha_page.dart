// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/perfil_repository.dart';
import '../../domain/perfil_models.dart';
import '../../../../shared/widgets/index.dart';

class SenhaPage extends StatefulWidget {
  const SenhaPage({super.key});

  @override
  State<SenhaPage> createState() => _SenhaPageState();
}

class _SenhaPageState extends State<SenhaPage> {
  final _repo = PerfilRepository();
  late Future<PerfilModel> _perfilFuture;

  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _verSenhaAtual = false;
  bool _verNovaSenha = false;
  bool _verConfirmar = false;
  bool _isLoading = false;

  static const double _sobreposicaoCard = 100.0;

  // Requisitos da senha em tempo real
  bool get _temMinimo => _novaSenhaController.text.length >= 8;
  bool get _temMaiuscula =>
      _novaSenhaController.text.contains(RegExp(r'[A-Z]'));
  bool get _temNumero => _novaSenhaController.text.contains(RegExp(r'[0-9]'));
  bool get _temEspecial =>
      _novaSenhaController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get _senhasIguais =>
      _novaSenhaController.text == _confirmarSenhaController.text &&
      _novaSenhaController.text.isNotEmpty;
  bool get _formularioValido =>
      _temMinimo &&
      _temMaiuscula &&
      _temNumero &&
      _temEspecial &&
      _senhasIguais;

  @override
  void initState() {
    super.initState();
    _perfilFuture = _repo.buscarPerfil();
    _novaSenhaController.addListener(() => setState(() {}));
    _confirmarSenhaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _alterarSenha() async {
    if (!_formularioValido) return;
    if (_senhaAtualController.text.isEmpty) {
      _mostrarSnack('Digite sua senha atual.', erro: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _repo.alterarSenha(
        senhaAtual: _senhaAtualController.text,
        novaSenha: _novaSenhaController.text,
      );

      if (!mounted) return;
      _senhaAtualController.clear();
      _novaSenhaController.clear();
      _confirmarSenhaController.clear();
      _mostrarSnack('Senha alterada com sucesso!', erro: false);

      setState(() {
        _perfilFuture = _repo.buscarPerfil();
      });
    } catch (e) {
      _mostrarSnack(e.toString().replaceAll('Exception: ', ''), erro: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarSnack(String msg, {required bool erro}) {
    MesclaNotificacao.mostrar(
      context,
      label: msg,
      cor: erro ? AppColors.destructive : Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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

          final perfil = snapshot.data!;

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
                                'Segurança e Senha',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),

                            // ── Card de status da conta ──────────────────────
                            _cardStatus(perfil),

                            const SizedBox(height: 28),
                            const RotuloSecao('ALTERAR SENHA'),
                            const SizedBox(height: 12),

                            // ── Card que engloba toda a seção de alterar senha ─
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _campoSenha(
                                    controller: _senhaAtualController,
                                    label: 'Senha Atual',
                                    ver: _verSenhaAtual,
                                    onToggle: () => setState(
                                      () => _verSenhaAtual = !_verSenhaAtual,
                                    ),
                                    icone: Icons.lock_outline,
                                  ),
                                  const SizedBox(height: 12),
                                  _campoSenha(
                                    controller: _novaSenhaController,
                                    label: 'Nova Senha',
                                    hint: 'Mínimo 8 caracteres',
                                    ver: _verNovaSenha,
                                    onToggle: () => setState(
                                      () => _verNovaSenha = !_verNovaSenha,
                                    ),
                                    icone: Icons.vpn_key_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _campoSenha(
                                    controller: _confirmarSenhaController,
                                    label: 'Confirmar Nova Senha',
                                    hint: 'Repita a nova senha',
                                    ver: _verConfirmar,
                                    onToggle: () => setState(
                                      () => _verConfirmar = !_verConfirmar,
                                    ),
                                    icone: Icons.lock_outline,
                                  ),
                                  const SizedBox(height: 20),
                                  _requisitos(),
                                  const SizedBox(height: 24),

                                  // ── Botão com cor sólida ─────────────────
                                  _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: _formularioValido
                                                ? _alterarSenha
                                                : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              disabledBackgroundColor: AppColors
                                                  .primary
                                                  .withValues(alpha: 0.35),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: const Text(
                                              'Atualizar Senha',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),
                            const RotuloSecao('VERIFICAÇÃO E ACESSO'),
                            const SizedBox(height: 12),
                            _itemMfa(perfil),
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

  // ── Item de MFA (padrão igual ao _itemMetodo da MfaPage) ───────────────────

  Widget _itemMfa(PerfilModel perfil) {
    final ativo = perfil.mfaAtivo;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/mfa'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ativo
              ? Colors.green.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ativo
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
                color: ativo
                    ? Colors.green.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.vpn_key_outlined,
                color: ativo
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
                  const Text(
                    'Autenticação de Dois Fatores',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ativo
                        ? 'App Autenticador ativo'
                        : 'Ative para mais segurança',
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            BadgeVerificado(mfaAtivo: ativo),
          ],
        ),
      ),
    );
  }

  // ── Card de status ──────────────────────────────────────────────────────────

  Widget _cardStatus(PerfilModel perfil) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
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
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.green,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conta Protegida',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
                Text(
                  'Última alteração: ${perfil.ultimaAlteracaoSenha}',
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Badge de verificação puxado do perfil ─────────────────
                BadgeVerificado(mfaAtivo: perfil.mfaAtivo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _campoSenha({
    required TextEditingController controller,
    required String label,
    String? hint,
    required bool ver,
    required VoidCallback onToggle,
    required IconData icone,
  }) {
    return TextField(
      controller: controller,
      obscureText: !ver,
      style: const TextStyle(color: AppColors.foreground),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.mutedForeground),
        hintStyle: TextStyle(
          color: AppColors.mutedForeground.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(icone, color: AppColors.mutedForeground, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            ver ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.mutedForeground,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.muted.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _requisitos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requisitos:',
          style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
        ),
        const SizedBox(height: 8),
        _itemRequisito('Mínimo 8 caracteres', _temMinimo),
        _itemRequisito('Letra maiúscula', _temMaiuscula),
        _itemRequisito('Número', _temNumero),
        _itemRequisito('Caractere especial', _temEspecial),
      ],
    );
  }

  Widget _itemRequisito(String texto, bool valido) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            valido ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 16,
            color: valido
                ? Colors.green
                : AppColors.mutedForeground.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              color: valido
                  ? Colors.green
                  : AppColors.mutedForeground.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
