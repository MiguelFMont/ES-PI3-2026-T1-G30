// lib/features/perfil/presentation/pages/informacoes_pessoais_page.dart
// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/perfil_repository.dart';
import '../../domain/perfil_models.dart';
import '../../../../shared/widgets/index.dart';
import '../../../../shared/formatters/censura.dart';
import '../../../../shared/formatters/telefone_formatter.dart';

class InformacoesPage extends StatefulWidget {
  const InformacoesPage({super.key});

  @override
  State<InformacoesPage> createState() => _InformacoesPageState();
}

class _InformacoesPageState extends State<InformacoesPage> {
  final _repo = PerfilRepository();
  late Future<PerfilModel> _perfilFuture;

  // Estado local dos campos editáveis
  late String _nome;
  late String _email;
  late String _telefone;

  // Controla se há alterações não salvas
  bool _alterado = false;
  bool _salvando = false;

  static const double _sobreposicaoCard = 100.0;

  @override
  void initState() {
    super.initState();
    _perfilFuture = _repo.buscarPerfil();
  }

  /// Preenche o estado local a partir do modelo carregado.
  void _inicializarCampos(PerfilModel data) {
    _nome = data.nome;
    _email = data.email;
    _telefone = data.telefone;
  }

  /// Abre um bottom sheet para editar um campo de texto.
  Future<void> _editarCampo({
    required String titulo,
    required String valorAtual,
    required ValueChanged<String> onSalvar,
    TextInputType teclado = TextInputType.text,
    String? Function(String?)? validador,
    List<TextInputFormatter>? inputFormatters,
  }) async {
    final controller = TextEditingController(text: valorAtual);
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alça visual
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Editar $titulo',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: teclado,
                  inputFormatters: inputFormatters,
                  style: const TextStyle(color: AppColors.foreground),
                  validator:
                      validador ??
                      (v) => (v == null || v.trim().isEmpty)
                          ? 'Campo obrigatório'
                          : null,
                  decoration: InputDecoration(
                    labelText: titulo,
                    labelStyle: const TextStyle(
                      color: AppColors.mutedForeground,
                    ),
                    filled: true,
                    fillColor: AppColors.secondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.destructive,
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.destructive,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.mutedForeground,
                          side: const BorderSide(color: AppColors.muted),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            onSalvar(controller.text.trim());
                            Navigator.pop(ctx);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Confirmar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Persiste as alterações no repositório.
  Future<void> _salvarAlteracoes() async {
    setState(() => _salvando = true);

    try {
      await _repo.atualizarPerfil(nome: _nome, telefone: _telefone);

      if (!mounted) return;

      setState(() {
        _alterado = false;
        _salvando = false;
        _perfilFuture = _repo.buscarPerfil();
      });

      MesclaNotificacao.mostrar(
        context,
        label: 'Informações atualizadas!',
        cor: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      MesclaNotificacao.mostrar(
        context,
        label: 'Erro ao salvar. Tente novamente.',
        cor: AppColors.destructive,
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
              onTentarNovamente: () =>
                  setState(() => _perfilFuture = _repo.buscarPerfil()),
            );
          }

          final data = snapshot.data!;

          // Inicializa campos apenas na primeira carga (evita sobrescrever edições)
          if (!_alterado) _inicializarCampos(data);

          return _conteudoRolavel(data);
        },
      ),
    );
  }

  Widget _conteudoRolavel(PerfilModel data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Wrap(
            direction: Axis.vertical,
            spacing:
                -_sobreposicaoCard, // Subtrai o espaço exato da sobreposição
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
                          'Informações Pessoais',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      _cartaoIdentidade(data),
                      const SizedBox(height: 24),
                      const RotuloSecao('DADOS CADASTRAIS'),
                      const SizedBox(height: 8),
                      CampoInfo(
                        icon: Icons.person_outline,
                        label: 'Nome Completo',
                        valor: _nome,
                        onTap: () => _editarCampo(
                          titulo: 'Nome Completo',
                          valorAtual: _nome,
                          onSalvar: (v) => setState(() {
                            _nome = v;
                            _alterado = true;
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CampoInfo(
                        icon: Icons.email_outlined,
                        label: 'Email  •  Não editável',
                        valor: _email,
                        editavel: false,
                      ),
                      const SizedBox(height: 8),
                      CampoInfo(
                        icon: Icons.phone_outlined,
                        label: 'Telefone',
                        valor: Censura.telefone(_telefone),
                        onTap: () => _editarCampo(
                          titulo: 'Telefone',
                          valorAtual: TelefoneFormatter.format(_telefone),
                          teclado: TextInputType.phone,
                          inputFormatters: [TelefoneFormatter()],
                          onSalvar: (v) => setState(() {
                            _telefone = TelefoneFormatter.somenteDigitos(v);
                            _alterado = true;
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CampoInfo(
                        icon: Icons.badge_outlined,
                        label: 'CPF  •  Não editável',
                        valor: Censura.cpf(data.cpf),
                        editavel: false,
                      ),
                      const SizedBox(height: 8),
                      CampoInfo(
                        icon: Icons.calendar_today_outlined,
                        label: 'Data de Nascimento  •  Não editável',
                        valor: data.dataNascimento,
                        editavel: false,
                      ),

                      // Botão salvar
                      if (_alterado) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _salvando ? null : _salvarAlteracoes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primary
                                  .withValues(alpha: 0.6),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: _salvando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: Text(
                              _salvando ? 'Salvando...' : 'Salvar alterações',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cartaoIdentidade(PerfilModel data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          PerfilAvatar(nome: _nome, mostrarBotaoFoto: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nome,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 6),
                BadgeVerificado(mfaAtivo: data.mfaAtivo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
