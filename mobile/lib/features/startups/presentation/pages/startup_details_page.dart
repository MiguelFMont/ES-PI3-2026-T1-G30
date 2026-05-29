import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mesclainvest/core/state/app_data_refresh_bus.dart';
import 'package:mesclainvest/core/theme/app_colors.dart';
import 'package:mesclainvest/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:mesclainvest/shared/widgets/index.dart';

import '../../data/startup_service.dart';
import '../../domain/startup_model.dart';
import '../../domain/startup_price_point.dart';
import '../widgets/startup_video_player.dart';

class StartupDetailsPage extends StatefulWidget {
  final Startup startup;

  const StartupDetailsPage({super.key, required this.startup});

  @override
  State<StartupDetailsPage> createState() => _StartupDetailsPageState();
}

class _StartupDetailsPageState extends State<StartupDetailsPage> {
  final StartupService _service = StartupService();
  final DashboardDatasource _dashboardDatasource = DashboardDatasource();

  late Startup _startup;
  List<StartupPricePoint> _priceHistory = const [];
  int _tokensUsuario = 0;
  bool _isLoading = true;
  bool _isInvesting = false;
  String? _errorMessage;
  String _periodoSelecionado = '1M';
  String _tabSelecionada = 'Resumo';

  @override
  void initState() {
    super.initState();
    _startup = widget.startup;
    _fetchStartupDetails();
  }

  Future<void> _fetchStartupDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final startupFuture = _service.buscarStartupPorId(widget.startup.id);
      final historyFuture = _opcional(
        _service.buscarHistoricoPrecos(widget.startup.id),
      );
      final tokensFuture = _opcional(
        _service.buscarQuantidadeTokensUsuario(widget.startup.id),
      );

      final startup = await startupFuture;
      final history = await historyFuture;
      final tokens = await tokensFuture;

      if (!mounted) return;
      setState(() {
        _startup = startup;
        _priceHistory = history ?? const [];
        _tokensUsuario = tokens ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is StartupApiException
            ? e.message
            : 'Não foi possível carregar os detalhes da startup.';
      });
    }
  }

  Future<T?> _opcional<T>(Future<T> future) =>
      future.then<T?>((value) => value, onError: (_) => null);

  Future<void> _showTradeDialog() async {
    final precoToken = _startup.precoToken;

    if (precoToken <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preço do token indisponível para esta startup.'),
        ),
      );
      return;
    }

    setState(() => _isInvesting = true);

    double saldoDisponivel = 0;
    int tokensDisponiveis = _tokensUsuario;
    try {
      final summaryFuture = _dashboardDatasource.getSummary();
      final tokensFuture = _opcional(
        _service.buscarQuantidadeTokensUsuario(_startup.id),
      );
      final summary = await summaryFuture;
      final tokens = await tokensFuture;

      saldoDisponivel = summary.saldoDisponivel;
      tokensDisponiveis = tokens ?? _tokensUsuario;
    } catch (_) {
      if (!mounted) return;
      setState(() => _isInvesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível buscar os dados da carteira.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _tokensUsuario = tokensDisponiveis;
      _isInvesting = false;
    });

    final trade = await showDialog<_TradeRequest>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (_) => _TradeDialog(
        startup: _startup,
        saldoDisponivel: saldoDisponivel,
        tokensDisponiveis: tokensDisponiveis,
      ),
    );

    if (trade == null || !mounted) return;

    setState(() => _isInvesting = true);

    try {
      bool sucesso;
      if (trade.type == _TradeType.buy) {
        await _service.investirStartup(_startup.id, trade.quantity);
        sucesso = true;
      } else {
        sucesso = await _service.venderStartup(_startup.id, trade.quantity);
      }

      if (!mounted) return;

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              trade.type == _TradeType.buy
                  ? 'Compra realizada com sucesso!'
                  : 'Venda realizada com sucesso!',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        AppDataRefreshBus.instance.refresh(
          scopes: const {
            AppDataRefreshScope.dashboard,
            AppDataRefreshScope.portfolio,
            AppDataRefreshScope.catalog,
            AppDataRefreshScope.balcao,
            AppDataRefreshScope.perfilWallet,
          },
          reason: trade.type == _TradeType.buy
              ? 'startup-direct-buy'
              : 'startup-direct-sell',
        );

        await _fetchStartupDetails();
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is StartupApiException
          ? e.message
          : 'Não foi possível concluir a negociação.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isInvesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAction = !_isLoading && _errorMessage == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: _buildBody(),
      bottomNavigationBar: showAction
          ? _StickyInvestButton(
              isLoading: _isInvesting,
              onPressed: _showTradeDialog,
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return _DetailsErrorState(
        message: _errorMessage!,
        onRetry: _fetchStartupDetails,
      );
    }

    return _DetailsContent(
      startup: _startup,
      priceHistory: _priceHistory,
      tokensUsuario: _tokensUsuario,
      periodoSelecionado: _periodoSelecionado,
      tabSelecionada: _tabSelecionada,
      onBack: () {
        Navigator.maybePop(context);
      },
      onPeriodChanged: (periodo) =>
          setState(() => _periodoSelecionado = periodo),
      onTabChanged: (tab) => setState(() => _tabSelecionada = tab),
    );
  }
}

class StartupDetailsArgumentErrorPage extends StatelessWidget {
  const StartupDetailsArgumentErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Nenhuma startup selecionada.')),
    );
  }
}

enum _TradeType { buy, sell }

class _TradeRequest {
  final _TradeType type;
  final int quantity;

  const _TradeRequest({required this.type, required this.quantity});
}

class _TradeDialog extends StatefulWidget {
  final Startup startup;
  final double saldoDisponivel;
  final int tokensDisponiveis;

  const _TradeDialog({
    required this.startup,
    required this.saldoDisponivel,
    required this.tokensDisponiveis,
  });

  @override
  State<_TradeDialog> createState() => _TradeDialogState();
}

class _TradeDialogState extends State<_TradeDialog> {
  final TextEditingController _quantityController = TextEditingController();
  _TradeType _selectedType = _TradeType.buy;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  int get _quantity {
    final digits = _quantityController.text.replaceAll(RegExp(r'\D'), '');
    return int.tryParse(digits) ?? 0;
  }

  bool get _isBuy => _selectedType == _TradeType.buy;
  double get _unitPrice {
    if (_isBuy) return widget.startup.precoToken;
    final discountBps = widget.startup.descontoVendaDiretaBps
        .clamp(0, 10000)
        .toDouble();
    return widget.startup.precoToken * ((10000 - discountBps) / 10000);
  }

  double get _total => _quantity * _unitPrice;

  bool get _hasEnoughBalance => _total <= widget.saldoDisponivel;
  bool get _hasEnoughTokens => _quantity <= widget.tokensDisponiveis;

  bool get _canSubmit {
    if (_quantity <= 0) return false;
    return _isBuy ? _hasEnoughBalance : _hasEnoughTokens;
  }

  String? get _validationMessage {
    if (_quantity <= 0) return null;
    if (_isBuy && !_hasEnoughBalance) {
      return 'Saldo insuficiente para esta compra.';
    }
    if (!_isBuy && !_hasEnoughTokens) {
      return 'Você possui apenas ${widget.tokensDisponiveis} tokens.';
    }
    return null;
  }

  String get _submitLabel {
    if (_quantity <= 0) return 'Informe a quantidade';
    final action = _isBuy ? 'Comprar' : 'Vender';
    final plural = _quantity == 1 ? 'token' : 'tokens';
    return '$action $_quantity $plural';
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.pop(
      context,
      _TradeRequest(type: _selectedType, quantity: _quantity),
    );
  }

  void _selectType(_TradeType type) {
    if (_selectedType == type) return;
    setState(() => _selectedType = type);
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final maxHeight = mediaSize.height * 0.92;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: mediaSize.width < 560 ? 0 : 24,
        vertical: mediaSize.width < 560 ? 0 : 20,
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 512, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TradeHeader(startup: widget.startup),
            const Divider(height: 1, color: Color(0xFFE4E8EC)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TradeSegmentedControl(
                      selectedType: _selectedType,
                      onChanged: _selectType,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Quantidade de Tokens',
                      style: TextStyle(
                        color: Color(0xFF374957),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _TradeQuantityField(
                      controller: _quantityController,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 22),
                    _TradeInfoCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: _isBuy
                          ? 'Saldo disponível'
                          : 'Tokens disponíveis',
                      value: _isBuy
                          ? _formatCurrencyFull(widget.saldoDisponivel)
                          : '${_formatInt(widget.tokensDisponiveis)} tokens',
                    ),
                    const SizedBox(height: 12),
                    _TradeTotalCard(
                      isBuy: _isBuy,
                      value: _total,
                    ),
                    if (_validationMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _validationMessage!,
                        style: const TextStyle(
                          color: AppColors.destructive,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _TradeFooter(
              label: _submitLabel,
              enabled: _canSubmit,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _TradeHeader extends StatelessWidget {
  final Startup startup;

  const _TradeHeader({required this.startup});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.13),
            AppColors.primary.withValues(alpha: 0.04),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _TradeLogo(url: startup.logo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startup.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (startup.setor.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        startup.setor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF66819B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.78),
                  foregroundColor: const Color(0xFF374957),
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.primary,
                  size: 17,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Preço Atual',
                  style: TextStyle(
                    color: Color(0xFF7890A5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatCurrencyFull(startup.precoToken),
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeLogo extends StatelessWidget {
  final String url;

  const _TradeLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFFCFE0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.business_rounded, color: AppColors.primary),
    );

    if (url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _TradeSegmentedControl extends StatelessWidget {
  final _TradeType selectedType;
  final ValueChanged<_TradeType> onChanged;

  const _TradeSegmentedControl({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TradeSegmentButton(
              label: 'Comprar',
              selected: selectedType == _TradeType.buy,
              onTap: () => onChanged(_TradeType.buy),
            ),
          ),
          Expanded(
            child: _TradeSegmentButton(
              label: 'Vender',
              selected: selectedType == _TradeType.sell,
              onTap: () => onChanged(_TradeType.sell),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeSegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TradeSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: const Color(0xFF17233C),
            fontSize: 15,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TradeQuantityField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _TradeQuantityField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      style: const TextStyle(
        color: Color(0xFF263238),
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: const TextStyle(
          color: Color(0xFF8CA0B3),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE2E8), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _TradeInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TradeInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7890A5), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7890A5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF374957),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeTotalCard extends StatelessWidget {
  final bool isBuy;
  final double value;

  const _TradeTotalCard({required this.isBuy, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = isBuy ? AppColors.primary : AppColors.success;

    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 1.6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isBuy ? 'Total a pagar' : 'Você receberá',
              style: const TextStyle(
                color: Color(0xFF374957),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            _formatCurrencyFull(value),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeFooter extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _TradeFooter({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E8EC))),
      ),
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.52),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            elevation: enabled ? 3 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _DetailsContent extends StatelessWidget {
  final Startup startup;
  final List<StartupPricePoint> priceHistory;
  final int tokensUsuario;
  final String periodoSelecionado;
  final String tabSelecionada;
  final VoidCallback onBack;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String> onTabChanged;

  const _DetailsContent({
    required this.startup,
    required this.priceHistory,
    required this.tokensUsuario,
    required this.periodoSelecionado,
    required this.tabSelecionada,
    required this.onBack,
    required this.onPeriodChanged,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _StartupHero(
          startup: startup,
          tokensUsuario: tokensUsuario,
          onBack: onBack,
        ),
        _MetricsRow(startup: startup),
        const SizedBox(height: 20),
        _PerformanceSection(
          startup: startup,
          priceHistory: priceHistory,
          selectedPeriod: periodoSelecionado,
          onPeriodChanged: onPeriodChanged,
        ),
        const SizedBox(height: 22),
        _DetailsTabs(
          selectedTab: tabSelecionada,
          onChanged: onTabChanged,
        ),
        const SizedBox(height: 12),
        _TabContent(startup: startup, selectedTab: tabSelecionada),
        const SizedBox(height: 96),
      ],
    );
  }
}

class _StartupHero extends StatelessWidget {
  final Startup startup;
  final int tokensUsuario;
  final VoidCallback onBack;

  const _StartupHero({
    required this.startup,
    required this.tokensUsuario,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final valorPosicao = tokensUsuario * startup.precoToken;

    return SizedBox(
      height: 398,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 150,
            child: CustomPaint(
              painter: const _StartupHeaderPainter(),
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 32, top: 26),
                    child: InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Voltar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: 42,
            right: 42,
            child: _StartupSummaryCard(
              startup: startup,
              tokensUsuario: tokensUsuario,
              valorPosicao: valorPosicao,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartupHeaderPainter extends CustomPainter {
  const _StartupHeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = AppColors.primary;
    canvas.drawRect(Offset.zero & size, basePaint);

    final accentPaint = Paint()..color = const Color(0xFFC02A79);
    final path = Path()
      ..moveTo(size.width * 0.47, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.32, size.height)
      ..close();
    canvas.drawPath(path, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StartupSummaryCard extends StatelessWidget {
  final Startup startup;
  final int tokensUsuario;
  final double valorPosicao;

  const _StartupSummaryCard({
    required this.startup,
    required this.tokensUsuario,
    required this.valorPosicao,
  });

  @override
  Widget build(BuildContext context) {
    final variacao = startup.variacaoPreco ?? 0;
    final variacaoColor = variacao >= 0 ? AppColors.success : AppColors.destructive;

    return Container(
      height: 318,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StartupLogo(url: startup.logo, size: 58),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startup.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF17233C),
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StageChip(label: startup.estagio),
                        if (startup.setor.isNotEmpty)
                          Text(
                            startup.setor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7890A5),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(height: 1, color: Color(0xFFECEFF1)),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _ValueBlock(
                  label: 'Preço Atual',
                  value: _formatCurrencyFull(startup.precoToken),
                  valueSize: 22,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Variação',
                      style: TextStyle(
                        color: Color(0xFF7890A5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _VariationBadge(value: variacao, color: variacaoColor),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'Você possui',
            style: TextStyle(
              color: Color(0xFF7890A5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$tokensUsuario tokens',
                  style: const TextStyle(
                    color: Color(0xFF17233C),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: '  ≈ ${_formatCurrencyFull(valorPosicao)}',
                  style: const TextStyle(
                    color: Color(0xFF7890A5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final Startup startup;

  const _MetricsRow({required this.startup});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(42, 22, 42, 0),
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
              icon: Icons.attach_money_rounded,
              label: 'Capital\nAportado',
              value: _formatCompactCurrency(startup.capitalAportado),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              icon: Icons.generating_tokens_outlined,
              label: 'Tokens\nEmitidos',
              value: _formatInt(startup.totalTokens),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              icon: Icons.business_outlined,
              label: 'Fundada',
              value: startup.createdAt == null
                  ? '-'
                  : startup.createdAt!.year.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const Spacer(),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7890A5),
              fontSize: 11,
              height: 1.15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF17233C),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceSection extends StatelessWidget {
  final Startup startup;
  final List<StartupPricePoint> priceHistory;
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  const _PerformanceSection({
    required this.startup,
    required this.priceHistory,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final series = _seriesForPeriod(
      points: priceHistory,
      period: selectedPeriod,
      fallbackValue: startup.precoToken,
    );
    final stats = _PriceStats.from(series, startup.totalTokens);
    final color = stats.variation >= 0 ? AppColors.success : AppColors.destructive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 42),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 17, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 16),
                SizedBox(width: 7),
                Text(
                  'Performance',
                  style: TextStyle(
                    color: Color(0xFF17233C),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _PeriodSelector(
              selectedPeriod: selectedPeriod,
              onChanged: onPeriodChanged,
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 190,
              child: _StartupPriceChart(points: series, color: color),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    icon: Icons.north_east_rounded,
                    label: 'Máxima',
                    value: _formatCurrencyFull(stats.max),
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatPill(
                    icon: Icons.south_east_rounded,
                    label: 'Mínima',
                    value: _formatCurrencyFull(stats.min),
                    color: AppColors.destructive,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatPill(
                    icon: null,
                    label: 'Volume',
                    value: _formatCompactNumber(stats.volume),
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Variação no período',
                      style: TextStyle(
                        color: Color(0xFF7890A5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    stats.variation >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 15,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatPercent(stats.variation),
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupPriceChart extends StatefulWidget {
  final List<StartupPricePoint> points;
  final Color color;

  const _StartupPriceChart({required this.points, required this.color});

  @override
  State<_StartupPriceChart> createState() => _StartupPriceChartState();
}

class _StartupPriceChartState extends State<_StartupPriceChart> {
  double? _activeX;

  @override
  void didUpdateWidget(covariant _StartupPriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _activeX = null;
    }
  }

  void _updateActivePosition(Offset localPosition, double width) {
    if (width <= 0) return;
    final maxX = (widget.points.length - 1).toDouble();
    final chartMaxX = maxX < 1 ? 1.0 : maxX;
    final clampedDx = localPosition.dx.clamp(0.0, width).toDouble();
    final activeX = (clampedDx / width) * chartMaxX;

    setState(() => _activeX = activeX.clamp(0.0, maxX).toDouble());
  }

  _ChartSample _sampleAt(double x) {
    if (widget.points.length == 1) {
      final point = widget.points.first;
      return _ChartSample(x: 0, value: point.preco, date: point.createdAt);
    }

    final lowerIndex = x.floor().clamp(0, widget.points.length - 1).toInt();
    final upperIndex = x.ceil().clamp(0, widget.points.length - 1).toInt();
    final lower = widget.points[lowerIndex];
    final upper = widget.points[upperIndex];
    final progress = upperIndex == lowerIndex ? 0.0 : x - lowerIndex;
    final value = lower.preco + ((upper.preco - lower.preco) * progress);
    final dateDiff =
        upper.createdAt.millisecondsSinceEpoch -
        lower.createdAt.millisecondsSinceEpoch;
    final date = lower.createdAt.add(
      Duration(milliseconds: (dateDiff * progress).round()),
    );

    return _ChartSample(x: x, value: value, date: date);
  }

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < widget.points.length; i++)
        FlSpot(i.toDouble(), widget.points[i].preco),
    ];
    final values = widget.points.map((point) => point.preco).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final diff = (maxValue - minValue).abs();
    final padding = diff == 0 ? (maxValue.abs() * 0.08 + 1) : diff * 0.2;
    final minY = (minValue - padding).clamp(0, double.infinity).toDouble();
    final maxY = maxValue + padding;
    final maxX = (widget.points.length - 1).toDouble();
    final chartMaxX = maxX < 1 ? 1.0 : maxX;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final active = _activeX == null ? null : _sampleAt(_activeX!);
        final activeDx = active == null ? 0.0 : (active.x / chartMaxX) * width;
        final range = (maxY - minY).abs();
        final activeDy = active == null || range == 0
            ? height / 2
            : ((maxY - active.value) / range * height)
                  .clamp(0.0, height)
                  .toDouble();
        final tooltipWidth = 96.0;
        final tooltipHeight = 54.0;
        final tooltipLeft = active == null
            ? 0.0
            : (activeDx - tooltipWidth / 2)
                  .clamp(0.0, (width - tooltipWidth).clamp(0.0, width))
                  .toDouble();
        final tooltipTop = active == null
            ? 0.0
            : (activeDy - tooltipHeight - 12)
                  .clamp(0.0, (height - tooltipHeight).clamp(0.0, height))
                  .toDouble();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            LineChart(
              LineChartData(
                minX: 0,
                maxX: chartMaxX,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(show: false),
                lineTouchData: LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.28,
                    color: widget.color,
                    barWidth: 2.4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.color.withValues(alpha: 0.14),
                          widget.color.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (active != null) ...[
              Positioned(
                left: activeDx,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: const Color(0xFFD4D8DE),
                ),
              ),
              Positioned(
                left: activeDx - 4,
                top: activeDy - 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.28),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: tooltipLeft,
                top: tooltipTop,
                child: _ChartTooltip(sample: active),
              ),
            ],
            Positioned.fill(
              child: MouseRegion(
                cursor: SystemMouseCursors.precise,
                onHover: (event) =>
                    _updateActivePosition(event.localPosition, width),
                onExit: (_) => setState(() => _activeX = null),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      _updateActivePosition(details.localPosition, width),
                  onHorizontalDragStart: (details) =>
                      _updateActivePosition(details.localPosition, width),
                  onHorizontalDragUpdate: (details) =>
                      _updateActivePosition(details.localPosition, width),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartSample {
  final double x;
  final double value;
  final DateTime date;

  const _ChartSample({
    required this.x,
    required this.value,
    required this.date,
  });
}

class _ChartTooltip extends StatelessWidget {
  final _ChartSample sample;

  const _ChartTooltip({required this.sample});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFECEFF1)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd/MM/yyyy').format(sample.date),
            style: const TextStyle(
              color: Color(0xFF7890A5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrencyFull(sample.value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF17233C),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const periods = ['1D', '1W', '1M', '6M', 'YTD'];

    return Row(
      children: periods.map((period) {
        final selected = period == selectedPeriod;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => onChanged(period),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF7890A5),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon, color: color, size: 11),
                if (icon != null) const SizedBox(width: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7890A5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF17233C),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsTabs extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onChanged;

  const _DetailsTabs({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const tabs = ['Resumo', 'Societária', 'Equipe', 'Q&A', 'Vídeos'];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 42),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final tab = tabs[index];
          final selected = tab == selectedTab;
          return InkWell(
            onTap: () => onChanged(tab),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 78,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF7890A5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: tabs.length,
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  final Startup startup;
  final String selectedTab;

  const _TabContent({required this.startup, required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    return switch (selectedTab) {
      'Societária' => _SocietariaContent(startup: startup),
      'Equipe' => _EquipeContent(startup: startup),
      'Q&A' => const _EmptyContent(message: 'Nenhuma pergunta publicada.'),
      'Vídeos' => _VideosContent(startup: startup),
      _ => _ResumoContent(startup: startup),
    };
  }
}

class _ResumoContent extends StatelessWidget {
  final Startup startup;

  const _ResumoContent({required this.startup});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          title: 'Resumo Executivo',
          child: Text(
            startup.resumoExecutivo.isEmpty
                ? startup.descricao
                : startup.resumoExecutivo,
            style: const TextStyle(
              color: Color(0xFF66819B),
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Informações Gerais',
          child: Column(
            children: [
              _InfoRow(label: 'Setor', value: startup.setor),
              _InfoRow(
                label: 'Fundada em',
                value: startup.createdAt?.year.toString() ?? '-',
              ),
              _InfoRow(
                label: 'Estágio',
                valueWidget: Align(
                  alignment: Alignment.centerRight,
                  child: _StageChip(label: startup.estagio),
                ),
              ),
              _InfoRow(
                label: 'Capital Aportado',
                value: _formatCurrencyFull(startup.capitalAportado),
              ),
              _InfoRow(
                label: 'Tokens Emitidos',
                value: _formatInt(startup.totalTokens),
              ),
              _InfoRow(
                label: 'Preço/Token',
                value: _formatCurrencyFull(startup.precoToken),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocietariaContent extends StatelessWidget {
  final Startup startup;

  const _SocietariaContent({required this.startup});

  @override
  Widget build(BuildContext context) {
    if (startup.socios.isEmpty && startup.conselho.isEmpty) {
      return const _EmptyContent(message: 'Nenhum sócio cadastrado.');
    }

    return Column(
      children: [
        for (final socio in startup.socios)
          _PersonCard(
            name: socio.nome,
            role: 'Sócio',
            details: '${socio.participacao.toStringAsFixed(0)}%',
            description: '',
            imageUrl: socio.foto,
          ),
        if (startup.conselho.isNotEmpty)
          const _SectionLabel(label: 'Conselho'),
        for (final member in startup.conselho)
          _PersonCard(
            name: member.nome,
            role: member.cargo,
            details: member.area,
            description: '',
            imageUrl: member.foto,
          ),
      ],
    );
  }
}

class _EquipeContent extends StatelessWidget {
  final Startup startup;

  const _EquipeContent({required this.startup});

  @override
  Widget build(BuildContext context) {
    if (startup.mentores.isEmpty) {
      return const _EmptyContent(message: 'Nenhum membro de equipe cadastrado.');
    }

    return Column(
      children: [
        _SectionLabel(label: 'Equipe (${startup.mentores.length})'),
        for (final member in startup.mentores)
          _PersonCard(
            name: member.nome,
            role: member.cargo,
            details: member.area,
            description: '',
            imageUrl: member.foto,
          ),
      ],
    );
  }
}

class _VideosContent extends StatelessWidget {
  final Startup startup;

  const _VideosContent({required this.startup});

  @override
  Widget build(BuildContext context) {
    final video = _videoAssetForStartup(startup);

    if (video == null) {
      return const _EmptyContent(message: 'Nenhum vídeo publicado.');
    }

    return Column(
      children: [
        _VideoCard(video: video),
      ],
    );
  }
}

class _StartupVideoAsset {
  final String title;
  final String description;
  final String dateLabel;
  final String durationLabel;
  final String assetPath;

  const _StartupVideoAsset({
    required this.title,
    required this.description,
    required this.dateLabel,
    required this.durationLabel,
    required this.assetPath,
  });
}

class _VideoCard extends StatelessWidget {
  final _StartupVideoAsset video;

  const _VideoCard({required this.video});

  void _openPlayer(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => _VideoPlayerDialog(video: video),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPlayer(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 126,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.08),
                          const Color(0xFFF7F8FB),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: StartupVideoPlayer(
                      assetPath: video.assetPath,
                      borderRadius: BorderRadius.zero,
                      controls: false,
                      preview: true,
                      objectFit: 'cover',
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 9,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF263238).withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.durationLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      color: Color(0xFF17233C),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    video.description,
                    style: const TextStyle(
                      color: Color(0xFF66819B),
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    video.dateLabel,
                    style: const TextStyle(
                      color: Color(0xFF7890A5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerDialog extends StatelessWidget {
  final _StartupVideoAsset video;

  const _VideoPlayerDialog({required this.video});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    video.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF17233C),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: StartupVideoPlayer(
                assetPath: video.assetPath,
                autoplay: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_StartupVideoAsset? _videoAssetForStartup(Startup startup) {
  final key = _normalizeVideoKey(
    '${startup.nome} ${startup.id} ${startup.setor}',
  );

  if (key.contains('agro')) {
    return const _StartupVideoAsset(
      title: 'Pitch AgroIA',
      description: 'Visão geral da solução de IA para monitoramento de lavouras.',
      dateLabel: '19 de janeiro de 2026',
      durationLabel: '0:10',
      assetPath: 'assets/videos/agro.mp4',
    );
  }

  if (key.contains('med') || key.contains('health') || key.contains('saude')) {
    return const _StartupVideoAsset(
      title: 'Demo MedFácil',
      description: 'Apresentação da jornada de consulta online e prontuário digital.',
      dateLabel: '19 de janeiro de 2026',
      durationLabel: '0:10',
      assetPath: 'assets/videos/med.mp4',
    );
  }

  if (key.contains('edu')) {
    return const _StartupVideoAsset(
      title: 'Demo EduBlocks',
      description: 'Experiência de aprendizagem por jogos e desafios de programação.',
      dateLabel: '19 de janeiro de 2026',
      durationLabel: '0:10',
      assetPath: 'assets/videos/edu.mp4',
    );
  }

  if (key.contains('fin')) {
    return const _StartupVideoAsset(
      title: 'Pitch FinTrack',
      description: 'Resumo da plataforma de gestão financeira com categorização por IA.',
      dateLabel: '19 de janeiro de 2026',
      durationLabel: '0:10',
      assetPath: 'assets/videos/fin.mp4',
    );
  }

  if (key.contains('green') ||
      key.contains('eco') ||
      key.contains('sust') ||
      key.contains('verde')) {
    return const _StartupVideoAsset(
      title: 'Demo GreenRoute',
      description: 'Como a rota sustentável reduz emissões no deslocamento urbano.',
      dateLabel: '19 de janeiro de 2026',
      durationLabel: '0:10',
      assetPath: 'assets/videos/green.mp4',
    );
  }

  return null;
}

String _normalizeVideoKey(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF17233C),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _InfoRow({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7890A5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: valueWidget ??
                Text(
                  value?.isNotEmpty == true ? value! : '-',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF17233C),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final String name;
  final String role;
  final String details;
  final String description;
  final String imageUrl;

  const _PersonCard({
    required this.name,
    required this.role,
    required this.details,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StartupLogo(url: imageUrl, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF17233C),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        details,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  role,
                  style: const TextStyle(
                    color: Color(0xFF17233C),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF66819B),
                      fontSize: 13,
                      height: 1.4,
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
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF66819B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  final String message;

  const _EmptyContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Informações',
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF66819B),
          fontSize: 13,
          height: 1.45,
        ),
      ),
    );
  }
}

class _StickyInvestButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _StickyInvestButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: MesclaButton(
        label: isLoading ? 'Processando...' : 'Negociar Tokens',
        onPressed: isLoading ? null : onPressed,
        width: double.infinity,
      ),
    );
  }
}

class _DetailsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueBlock extends StatelessWidget {
  final String label;
  final String value;
  final double valueSize;

  const _ValueBlock({
    required this.label,
    required this.value,
    this.valueSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7890A5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: const Color(0xFF17233C),
              fontSize: valueSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _VariationBadge extends StatelessWidget {
  final double value;
  final Color color;

  const _VariationBadge({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            _formatPercent(value),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartupLogo extends StatelessWidget {
  final String url;
  final double size;

  const _StartupLogo({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD9E7),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.business_rounded,
        color: AppColors.primary,
        size: size * 0.48,
      ),
    );

    if (url.isEmpty) return placeholder;

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final String label;

  const _StageChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final display = switch (label) {
      'Em Expansao' || 'Em Expansão' => 'Expansão',
      'Em Operacao' || 'Em Operação' => 'Operação',
      _ => label,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        display,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF17233C),
        ),
      ),
    );
  }
}

class _PriceStats {
  final double max;
  final double min;
  final double variation;
  final int volume;

  const _PriceStats({
    required this.max,
    required this.min,
    required this.variation,
    required this.volume,
  });

  factory _PriceStats.from(List<StartupPricePoint> points, int volume) {
    final values = points.map((point) => point.preco).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final first = values.first;
    final last = values.last;
    final double variation = first == 0 ? 0.0 : ((last - first) / first) * 100;

    return _PriceStats(
      max: max,
      min: min,
      variation: variation,
      volume: volume,
    );
  }
}

List<StartupPricePoint> _seriesForPeriod({
  required List<StartupPricePoint> points,
  required String period,
  required double fallbackValue,
}) {
  final now = DateTime.now();
  final validPoints = points
      .where((point) => point.preco > 0)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final normalizedPoints = <StartupPricePoint>[
    for (var i = 0; i < validPoints.length; i++)
      StartupPricePoint(
        preco: validPoints[i].preco,
        createdAt: validPoints[i].createdAt.millisecondsSinceEpoch == 0
            ? now.subtract(Duration(days: validPoints.length - i))
            : validPoints[i].createdAt,
        motivo: validPoints[i].motivo,
      ),
  ];

  final base = normalizedPoints.isEmpty
      ? [
          StartupPricePoint(
            preco: fallbackValue > 0 ? fallbackValue : 1.0,
            createdAt: now.subtract(const Duration(days: 30)),
          ),
          StartupPricePoint(
            preco: fallbackValue > 0 ? fallbackValue : 1.0,
            createdAt: now,
          ),
        ]
      : normalizedPoints;

  final start = switch (period) {
    '1D' => now.subtract(const Duration(days: 1)),
    '1W' => now.subtract(const Duration(days: 7)),
    '1M' => now.subtract(const Duration(days: 30)),
    '6M' => now.subtract(const Duration(days: 180)),
    'YTD' => DateTime(now.year),
    _ => DateTime.fromMillisecondsSinceEpoch(0),
  };

  final filtered = base.where((point) {
    final date = point.createdAt;
    if (date.millisecondsSinceEpoch == 0) return true;
    return !date.isBefore(start);
  }).toList();

  final series = filtered.isEmpty ? base : filtered;

  if (series.length == 1) {
    return [
      StartupPricePoint(
        preco: series.first.preco,
        createdAt: series.first.createdAt.subtract(const Duration(days: 1)),
      ),
      series.first,
    ];
  }

  return series;
}

String _formatCurrencyFull(double value) {
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final integer = parts.first;
  final decimals = parts.last;
  final buffer = StringBuffer();

  for (var i = 0; i < integer.length; i++) {
    if (i > 0 && (integer.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(integer[i]);
  }

  final sign = value < 0 ? '-' : '';
  return '${sign}R\$ ${buffer.toString()},$decimals';
}

String _formatCompactCurrency(double value) {
  if (value >= 1000000) {
    return 'R\$ ${(value / 1000000).toStringAsFixed(2)}M';
  }
  if (value >= 1000) {
    return 'R\$ ${(value / 1000).toStringAsFixed(0)}k';
  }
  return _formatCurrencyFull(value);
}

String _formatCompactNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}

String _formatInt(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(raw[i]);
  }

  return buffer.toString();
}

String _formatPercent(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2).replaceAll('.', ',')}%';
}
