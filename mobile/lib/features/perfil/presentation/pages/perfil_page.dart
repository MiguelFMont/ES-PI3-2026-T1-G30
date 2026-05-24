// lib/features/perfil/presentation/pages/perfil_page.dart
// Autor: Miguel Fernandes Monteiro — RA: 25014808
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/perfil_repository.dart';
import '../../domain/perfil_models.dart';
import '../widgets/carteira_digital_sheets.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../../shared/widgets/index.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _repo = PerfilRepository();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  late Future<PerfilModel> _perfilFuture;
  WalletBalanceModel? _wallet;
  String? _walletErrorMessage;
  bool _isWalletLoading = true;

  static const double _sobreposicaoCard = 48.0;

  @override
  void initState() {
    super.initState();
    _perfilFuture = _repo.buscarPerfil();
    _loadWallet();
  }

  void _informacoesPessoais() {
    Navigator.pushNamed(context, '/informacoes-pessoais');
  }

  void _mfa() {
    Navigator.pushNamed(context, '/mfa');
  }

  void _senha() {
    Navigator.pushNamed(context, '/seguranca-senha');
  }

  Future<void> _loadWallet({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isWalletLoading = true;
        _walletErrorMessage = null;
      });
    }

    try {
      final wallet = await _repo.buscarCarteira();
      if (!mounted) return;

      setState(() {
        _wallet = wallet;
        _walletErrorMessage = null;
        _isWalletLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _walletErrorMessage = error
            .toString()
            .replaceFirst('Exception: ', '')
            .trim();
        _isWalletLoading = false;
      });
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? AppColors.destructive
            : const Color(0xFF263238),
      ),
    );
  }

  Future<void> _abrirSaldoEDepositos() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WalletBalanceSheet(
        repository: _repo,
        initialWallet: _wallet,
        onWalletUpdated: (update) {
          if (!mounted) return;
          setState(() {
            _wallet = update.wallet;
            _walletErrorMessage = null;
            _isWalletLoading = false;
          });
          _showFeedback(update.message);
        },
      ),
    );
  }

  Future<void> _abrirMetodosPagamento() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaymentMethodsSheet(),
    );
  }

  String _saldoCarteiraLabel(PerfilModel data) {
    if (_wallet != null) {
      return 'Saldo: ${_currencyFormat.format(_wallet!.saldoReais)}';
    }

    if (_isWalletLoading) {
      return 'Carregando saldo...';
    }

    if (_walletErrorMessage != null) {
      return 'Saldo indisponível';
    }

    return 'Saldo: ${_currencyFormat.format(data.saldo)}';
  }

  void _confirmarSaida() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sair da conta?',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Você precisará fazer login novamente para acessar sua conta.',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.mutedForeground),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );

              try {
                await AuthRepository().logout();
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              } catch (e) {
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao sair. Tente novamente.'),
                  ),
                );
              }
            },
            child: const Text(
              'Sair',
              style: TextStyle(
                color: AppColors.destructive,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
          return _conteudoRolavel(snapshot.data!);
        },
      ),
    );
  }

  Widget _conteudoRolavel(PerfilModel data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppGradientHeader(titulo: 'Meu Perfil'),
          Transform.translate(
            offset: const Offset(0, -_sobreposicaoCard),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cartaoPerfil(data),
                  const SizedBox(height: 24),
                  const RotuloSecao('CONTA'),
                  const SizedBox(height: 8),
                  SecaoMenu(
                    itens: [
                      ItemMenu(
                        icon: Icons.person_outline,
                        titulo: 'Informações Pessoais',
                        subtitulo: 'Nome, email, telefone',
                        onTap: _informacoesPessoais,
                      ),
                      ItemMenu(
                        icon: Icons.lock_outline,
                        titulo: 'Segurança e Senha',
                        subtitulo: 'Alterar senha, verificação',
                        onTap: _senha,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const RotuloSecao('CARTEIRA DIGITAL'),
                  const SizedBox(height: 8),
                  SecaoMenu(
                    itens: [
                      ItemMenu(
                        icon: Icons.account_balance_wallet_outlined,
                        titulo: 'Saldo e Depósitos',
                        subtitulo: _saldoCarteiraLabel(data),
                        onTap: () {
                          _abrirSaldoEDepositos();
                        },
                      ),
                      ItemMenu(
                        icon: Icons.credit_card_outlined,
                        titulo: 'Métodos de Pagamento',
                        subtitulo: 'Cartões e contas vinculadas',
                        onTap: () {
                          _abrirMetodosPagamento();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const RotuloSecao('SEGURANÇA ADICIONAL'),
                  const SizedBox(height: 8),
                  SecaoMenu(
                    itens: [
                      ItemMenu(
                        icon: Icons.vpn_key_outlined,
                        titulo: 'Autenticação de Dois Fatores',
                        subtitulo:
                            'Proteja sua conta com 2FA. Recomendado para todos os investidores do ecossistema Mescla.',
                        onTap: _mfa,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MesclaOutlineButton(
                    label: 'Sair da conta',
                    icon: Icons.logout_rounded,
                    width: double.infinity,
                    onPressed: _confirmarSaida,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartaoPerfil(PerfilModel data) {
    final saldoExibido = _wallet?.saldoReais ?? data.saldo;

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
      child: Column(
        children: [
          Row(
            children: [
              PerfilAvatar(nome: data.nome),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              const PerfilBadge(
                texto: 'Investidor Mescla',
                cor: AppColors.muted,
                textoCor: AppColors.accent,
              ),
              const SizedBox(width: 6),
              BadgeVerificado(mfaAtivo: data.mfaAtivo),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.muted, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ItemEstatistica(
                label: 'Patrimônio',
                valor: _currencyFormat.format(saldoExibido),
              ),
              Container(width: 1, height: 32, color: AppColors.muted),
              ItemEstatistica(label: 'Desde', valor: data.desde),
            ],
          ),
        ],
      ),
    );
  }
}
