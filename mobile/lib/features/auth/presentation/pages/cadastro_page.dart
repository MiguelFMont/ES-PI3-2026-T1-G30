//Autor: Miguel Fernandes Monteiro
//RA: 25014808
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../shared/widgets/campo_texto.dart';
import '../../../../shared/widgets/campo_data.dart';
import '../../../../shared/widgets/mescla_auth_layout.dart';
import '../../../../shared/formatters/cpf_formatter.dart';
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
    _senhaController.addListener(() => setState(() {}));
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

  void _irAvancar() {
    FocusScope.of(context).unfocus();
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
    // 1. Validação simples antes de chamar a API
    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um e-mail válido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_senhaValida) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A senha não atende todos os requisitos.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _repository.iniciarCadastro(
        _dataNascimento!.toIso8601String(),
        _nomeController.text,
        _emailController.text,
        _cpfController.text,
        _telefoneController.text,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
        SingleChildScrollView(child: _etapaDataCpf()),
        SingleChildScrollView(child: _etapaTelefoneNome()),
        SingleChildScrollView(child: _etapaEmailSenha()),
      ],
    );
  }

  Widget _etapaDataCpf() {
    return Column(
      children: [
        _mensagemEtapa(0),
        CampoData(
          onDateChanged: (date) => setState(() => _dataNascimento = date),
        ),
        const SizedBox(height: 10),
        CampoTexto(
          controller: _cpfController,
          label: 'CPF',
          keyboardType: TextInputType.number,
          inputFormatters: [CpfFormatter()],
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
        ),
        const SizedBox(height: 10),
        CampoTexto(
          controller: _nomeController,
          label: 'Nome Completo',
          keyboardType: TextInputType.name,
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
        ),
        const SizedBox(height: 10),
        CampoTexto(
          controller: _senhaController,
          label: 'Senha',
          obscureText: true,
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

  Widget _botaoAvancar() =>
      MesclaButton(label: 'Avançar', onPressed: _irAvancar);

  Widget _botaoCadastrar() =>
      MesclaButton(label: 'Cadastrar', onPressed: _cadastrar);

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
