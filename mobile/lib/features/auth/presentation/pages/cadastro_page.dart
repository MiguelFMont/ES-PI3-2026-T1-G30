//Autor: Miguel Fernandes Monteiro
//RA: 25014808
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../shared/widgets/campo_texto.dart';
import '../../../../shared/widgets/campo_data.dart';
import '../../../../shared/widgets/mescla_auth_layout.dart';
import '../../../../shared/widgets/mescla_notificacao.dart';
import '../../../../shared/formatters/cpf_formatter.dart';
import '../../../../shared/formatters/telefone_formatter.dart';
import '../../../../shared/validators/cpf_validator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mescla_button.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();

  DateTime? _dataNascimento;

  final _repository = AuthRepository();
  final _pageController = PageController();
  int _etapaAtual = 0;
  bool _isLoading = false;
  bool _verificandoCpf = false;

  // ── Estado de validação por campo (null = neutro) ──────────────────────────
  bool? _dataValida;
  bool? _cpfValido;
  bool? _telefoneValido;
  bool? _nomeValido;
  bool? _emailValido;
  bool? _senhaEstado;
  String? _dataErro;
  String? _cpfErro;
  String? _telefoneErro;
  String? _nomeErro;
  String? _emailErro;

  // ── Requisitos da senha ────────────────────────────────────────────────────
  bool get _temMinimo => _senhaController.text.length >= 8;
  bool get _temMaiuscula => _senhaController.text.contains(RegExp(r'[A-Z]'));
  bool get _temNumero => _senhaController.text.contains(RegExp(r'[0-9]'));
  bool get _temEspecial =>
      _senhaController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get _senhaValida =>
      _temMinimo && _temMaiuscula && _temNumero && _temEspecial;

  @override
  void initState() {
    super.initState();
    _senhaController.addListener(
      () => setState(() {
        _senhaEstado = _estado(
          ok: _senhaValida,
          vazio: _senhaController.text.isEmpty,
        );
      }),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // ── Validade de cada etapa (controla a cor do botão Avançar) ───────────────
  bool get _etapa0Ok =>
      CpfValidator.isValid(_cpfController.text) &&
      _dataNascimento != null &&
      !_dataNascimento!.isAfter(DateTime.now());

  bool get _etapa1Ok {
    final tel = TelefoneFormatter.somenteDigitos(_telefoneController.text);
    final nome = _nomeController.text.trim();
    return (tel.length == 10 || tel.length == 11) &&
        nome.length >= 3 &&
        nome.contains(' ');
  }

  bool get _etapa2Ok =>
      RegExp(
        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
      ).hasMatch(_emailController.text.trim()) &&
      _senhaValida;

  bool get _etapaAtualOk => _etapaAtual == 0 ? _etapa0Ok : _etapa1Ok;

  // Estado visual de um campo: null = vazio/neutro, true = verde, false = vermelho.
  bool? _estado({required bool ok, required bool vazio}) => vazio ? null : ok;

  Future<void> _irAvancar() async {
    FocusScope.of(context).unfocus();

    // Etapa 0: além do formato, confere no backend se o CPF já existe.
    if (_etapaAtual == 0) {
      setState(() => _verificandoCpf = true);
      final disponivel = await _repository.cpfDisponivel(_cpfController.text);
      if (!mounted) return;
      setState(() => _verificandoCpf = false);

      if (disponivel == false) {
        setState(() {
          _cpfValido = false;
          _cpfErro = 'Este CPF já está cadastrado.';
        });
        MesclaNotificacao.mostrar(
          context,
          label: 'Este CPF já está cadastrado.',
          cor: AppColors.destructive,
        );
        return;
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    );
    if (_etapaAtual < 2) {
      setState(() => _etapaAtual++);
    }
  }

  void _irVoltar() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    );
    if (_etapaAtual > 0) {
      setState(() => _etapaAtual--);
    }
  }

  Future<void> _cadastrar() async {
    if (!_etapa2Ok) return;

    setState(() => _isLoading = true);

    try {
      await _repository.iniciarCadastro(
        _dataNascimento!.toIso8601String(),
        _nomeController.text,
        _emailController.text,
        _cpfController.text,
        TelefoneFormatter.somenteDigitos(_telefoneController.text),
        _senhaController.text,
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/token-verification',
        arguments: {
          'email': _emailController.text,
          'senha': _senhaController.text,
          'fluxo':
              'cadastro', // <-- A "flag" que avisa a tela do token o que fazer depois
        },
      );
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Expanded(child: _paginasFormulario()),
                _indicadorEtapas(),
                const SizedBox(height: 8),
                _linkLogin(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _paginasFormulario() {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _paginaCentralizada(_etapaDataCpf()),
        _paginaCentralizada(_etapaTelefoneNome()),
        _paginaCentralizada(_etapaEmailSenha()),
      ],
    );
  }

  // Centraliza verticalmente o conteúdo da etapa, mantendo o scroll quando o
  // teclado abre (ex.: telas menores).
  Widget _paginaCentralizada(Widget conteudo) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [conteudo],
            ),
          ),
        ),
      ),
    );
  }

  Widget _etapaDataCpf() {
    return Column(
      children: [
        _mensagemEtapa(0),
        CampoData(
          valido: _dataValida,
          mensagemErro: _dataErro,
          initialDate: _dataNascimento,
          onDateChanged: (date) => setState(() {
            _dataNascimento = date;
            final ok = date != null && !date.isAfter(DateTime.now());
            _dataValida = ok ? true : null;
            _dataErro = null;
          }),
        ),
        const SizedBox(height: 10),
        CampoTexto(
          controller: _cpfController,
          label: 'CPF',
          keyboardType: TextInputType.number,
          inputFormatters: [CpfFormatter()],
          valido: _cpfValido,
          mensagemErro: _cpfErro,
          onChanged: (v) => setState(() {
            _cpfValido = _estado(
              ok: CpfValidator.isValid(v),
              vazio: v.trim().isEmpty,
            );
            _cpfErro = _cpfValido == false
                ? 'CPF inválido. Confira os números.'
                : null;
          }),
        ),
        const SizedBox(height: 20),
        _botaoAvancar(),
      ],
    );
  }

  Widget _etapaTelefoneNome() {
    return Column(
      children: [
        _mensagemEtapa(1),
        const SizedBox(height: 27.5),
        CampoTexto(
          controller: _telefoneController,
          label: 'Telefone',
          keyboardType: TextInputType.phone,
          inputFormatters: [TelefoneFormatter()],
          valido: _telefoneValido,
          mensagemErro: _telefoneErro,
          onChanged: (v) => setState(() {
            final tel = TelefoneFormatter.somenteDigitos(v);
            _telefoneValido = _estado(
              ok: tel.length == 10 || tel.length == 11,
              vazio: tel.isEmpty,
            );
            _telefoneErro = _telefoneValido == false
                ? 'Telefone inválido. Confira os números.'
                : null;
          }),
        ),
        const SizedBox(height: 10),
        CampoTexto(
          controller: _nomeController,
          label: 'Nome Completo',
          keyboardType: TextInputType.name,
          valido: _nomeValido,
          mensagemErro: _nomeErro,
          onChanged: (v) => setState(() {
            final nome = v.trim();
            _nomeValido = _estado(
              ok: nome.length >= 3 && nome.contains(' '),
              vazio: nome.isEmpty,
            );
            _nomeErro = _nomeValido == false
                ? 'Informe seu nome e sobrenome.'
                : null;
          }),
        ),
        const SizedBox(height: 20),
        _botaoAvancar(),
        const SizedBox(height: 10),
        _botaoVoltar(),
      ],
    );
  }

  Widget _etapaEmailSenha() {
    return Column(
      children: [
        CampoTexto(
          controller: _emailController,
          label: 'E-mail',
          keyboardType: TextInputType.emailAddress,
          valido: _emailValido,
          mensagemErro: _emailErro,
          onChanged: (v) => setState(() {
            _emailValido = _estado(
              ok: RegExp(
                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
              ).hasMatch(v.trim()),
              vazio: v.trim().isEmpty,
            );
            _emailErro = _emailValido == false
                ? 'E-mail inválido.'
                : null;
          }),
        ),
        const SizedBox(height: 10),
        CampoTexto(
          controller: _senhaController,
          label: 'Senha',
          obscureText: true,
          valido: _senhaEstado,
        ),
        // ── Requisitos em tempo real ───────────────────────────────────────
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.only(left: 20), child: _requisitos()),

        const SizedBox(height: 20),
        _isLoading
            ? const CircularProgressIndicator(
                color: AppColors.foreground,
                backgroundColor: AppColors.primary,
              )
            : Column(
                children: [
                  _botaoCadastrar(),
                  const SizedBox(height: 10),
                  _botaoVoltar(),
                ],
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

  Widget _mensagemEtapa(int index) {
    final mensagens = [
      'Precisamos verificar sua identidade. Seus dados estão protegidos.',
      'Informe seus dados de contato para continuarmos.',
      'Quase lá! Crie suas credenciais de acesso.',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 35),
      child: Text(
        mensagens[index],
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

  Widget _indicadorEtapas() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isAtiva = index == _etapaAtual;
          final isConcluida = index < _etapaAtual;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isAtiva ? 15 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isAtiva || isConcluida
                  ? AppColors.primary
                  : AppColors.muted,
            ),
          );
        }),
      ),
    );
  }

  Widget _linkLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Já tem uma conta?',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
          child: const Text(
            'Login',
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

  Widget _botaoAvancar() => MesclaButton(
    label: _verificandoCpf ? 'Verificando...' : 'Avançar',
    onPressed: (_etapaAtualOk && !_verificandoCpf) ? _irAvancar : null,
  );

  Widget _botaoCadastrar() =>
      MesclaButton(label: 'Cadastrar', onPressed: _etapa2Ok ? _cadastrar : null);

  Widget _botaoVoltar() {
    return TextButton(
      onPressed: _irVoltar,
      child: const Text(
        'Voltar',
        style: TextStyle(
          color: AppColors.foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
