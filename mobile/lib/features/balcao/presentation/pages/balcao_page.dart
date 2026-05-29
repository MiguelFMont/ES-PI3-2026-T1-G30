import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mesclainvest/core/theme/app_colors.dart';
import 'package:mesclainvest/features/balcao/data/balcao_api_service.dart';
import 'package:mesclainvest/features/balcao/models/holding_model.dart';
import 'package:mesclainvest/features/balcao/models/offer_model.dart';
import 'package:mesclainvest/features/portfolio/domain/models/startup_model.dart';
import 'package:mesclainvest/shared/widgets/index.dart';

class BalcaoPage extends StatefulWidget {
  const BalcaoPage({super.key});

  @override
  State<BalcaoPage> createState() => _BalcaoPageState();
}

class _BalcaoPageState extends State<BalcaoPage> {
  final BalcaoApiService _service = BalcaoApiService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  bool _isLoading = true;
  String? _errorMessage;
  String? _pendingOfferActionId;
  String? _pendingOfferActionType;

  List<HoldingModel> _holdings = [];
  List<OfferModel> _myOffers = [];
  List<OfferModel> _marketOffers = [];
  Map<String, StartupModel> _startupsById = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  List<HoldingModel> get _sellableHoldings {
    final holdings = _holdings
        .where((holding) => holding.quantidade > 0)
        .toList();
    holdings.sort(
      (a, b) => _startupName(a.startupId).compareTo(_startupName(b.startupId)),
    );
    return holdings;
  }

  bool get _isOfferActionRunning => _pendingOfferActionId != null;

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _fetchData();
      if (!mounted) return;

      setState(() {
        _applyData(data);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _errorText(error);
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      final data = await _fetchData();
      if (!mounted) return;

      setState(() {
        _applyData(data);
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      _showFeedback(_errorText(error), isError: true);
    }
  }

  Future<_BalcaoDataBundle> _fetchData() async {
    final results = await Future.wait<Object>([
      _service.getMyHoldings(),
      _service.getMyActiveOffers(),
      _service.getMarketOffers(),
      _service.getStartups(),
    ]);

    return _BalcaoDataBundle(
      holdings: results[0] as List<HoldingModel>,
      myOffers: results[1] as List<OfferModel>,
      marketOffers: results[2] as List<OfferModel>,
      startups: results[3] as List<StartupModel>,
    );
  }

  void _applyData(_BalcaoDataBundle data) {
    _holdings = data.holdings;
    _myOffers = data.myOffers;
    _marketOffers = data.marketOffers;
    _startupsById = _mapearStartupsPorId(data.startups);
  }

  Map<String, StartupModel> _mapearStartupsPorId(List<StartupModel> startups) {
    final startupsPorId = <String, StartupModel>{};

    for (final startup in startups) {
      final id = startup.id.trim();
      if (id.isNotEmpty) {
        startupsPorId[id] = startup;
      }

      for (final aliasId in startup.aliasIds) {
        final aliasNormalizado = aliasId.trim();
        if (aliasNormalizado.isNotEmpty) {
          startupsPorId[aliasNormalizado] = startup;
        }
      }
    }

    return startupsPorId;
  }

  String _errorText(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) {
      return 'Não foi possível carregar o balcão agora.';
    }

    return message;
  }

  String _startupName(String startupId) {
    final startup = _startupsById[startupId];
    if (startup == null || startup.nome.trim().isEmpty) {
      return 'Startup';
    }

    return startup.nome.trim();
  }

  String _formatCurrencyFromCents(int cents) {
    return _currencyFormat.format(cents / 100);
  }

  String _formatDate(DateTime date) {
    return _dateFormat.format(date.toLocal());
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

  Future<void> _openDirectSellSheet() async {
    if (_sellableHoldings.isEmpty) {
      _showFeedback(
        'Você não possui tokens livres para realizar uma venda direta.',
        isError: true,
      );
      return;
    }

    final result = await showModalBottomSheet<_SheetActionResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DirectSellSheet(
        service: _service,
        holdings: _sellableHoldings,
        startupsById: _startupsById,
        currencyFormat: _currencyFormat,
      ),
    );

    if (!mounted || result == null) return;

    _showFeedback(result.message);
    await _refreshData();
  }

  Future<void> _openCreateOfferSheet() async {
    if (_sellableHoldings.isEmpty) {
      _showFeedback(
        'Você não possui tokens livres para criar uma oferta.',
        isError: true,
      );
      return;
    }

    final result = await showModalBottomSheet<_SheetActionResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateOfferSheet(
        service: _service,
        holdings: _sellableHoldings,
        startupsById: _startupsById,
        currencyFormat: _currencyFormat,
      ),
    );

    if (!mounted || result == null) return;

    _showFeedback(result.message);
    await _refreshData();
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.mutedForeground,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Voltar',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _cancelOffer(OfferModel offer) async {
    final confirmed = await _confirmAction(
      title: 'Cancelar oferta',
      message:
          'Deseja cancelar a oferta de ${offer.quantidade} tokens de ${_startupName(offer.startupId)}?',
      confirmLabel: 'Cancelar oferta',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _pendingOfferActionId = offer.offerId;
      _pendingOfferActionType = 'cancel';
    });

    try {
      await _service.cancelOffer(offer.offerId);
      if (!mounted) return;

      _showFeedback('Oferta cancelada com sucesso.');
      await _refreshData();
    } catch (error) {
      if (!mounted) return;
      _showFeedback(_errorText(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _pendingOfferActionId = null;
          _pendingOfferActionType = null;
        });
      }
    }
  }

  Future<void> _acceptOffer(OfferModel offer) async {
    final confirmed = await _confirmAction(
      title: 'Comprar tokens',
      message:
          'Confirmar compra de ${offer.quantidade} tokens de ${_startupName(offer.startupId)} por ${_formatCurrencyFromCents(offer.valorTotalCentavos)}?',
      confirmLabel: 'Comprar',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _pendingOfferActionId = offer.offerId;
      _pendingOfferActionType = 'accept';
    });

    try {
      await _service.acceptOffer(offer.offerId);
      if (!mounted) return;

      _showFeedback('Oferta aceita com sucesso.');
      await _refreshData();
    } catch (error) {
      if (!mounted) return;
      _showFeedback(_errorText(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _pendingOfferActionId = null;
          _pendingOfferActionType = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.secondary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.secondary,
        body: TelaErro(
          mensagem: _errorMessage!,
          onTentarNovamente: _loadInitialData,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            const AppGradientHeader(titulo: 'Balcão de Negociação'),
            Transform.translate(
              offset: const Offset(0, -48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSellCard(),
                    const SizedBox(height: 24),
                    const RotuloSecao('MINHAS OFERTAS ATIVAS'),
                    const SizedBox(height: 8),
                    _buildMyOffersSection(),
                    const SizedBox(height: 24),
                    const RotuloSecao('OFERTAS DISPONÍVEIS'),
                    const SizedBox(height: 8),
                    _buildMarketOffersSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellCard() {
    final hasHoldings = _sellableHoldings.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.sell_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Vender tokens',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Escolha entre venda direta para a startup ou publicação de uma oferta aberta no balcão. A validação final de posse, saldo e execução permanece no backend.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              hasHoldings
                  ? 'Você possui ${_sellableHoldings.length} ${_sellableHoldings.length == 1 ? 'posição com tokens livres' : 'posições com tokens livres'} para negociar.'
                  : 'Você ainda não possui tokens livres disponíveis para negociação.',
              style: const TextStyle(fontSize: 13, color: AppColors.foreground),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Venda direta',
                  icon: Icons.flash_on_outlined,
                  onPressed: hasHoldings && !_isOfferActionRunning
                      ? _openDirectSellSheet
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Criar oferta',
                  icon: Icons.add_chart_rounded,
                  isPrimary: false,
                  onPressed: hasHoldings && !_isOfferActionRunning
                      ? _openCreateOfferSheet
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyOffersSection() {
    if (_myOffers.isEmpty) {
      return const _EmptyStateCard(
        icon: Icons.receipt_long_outlined,
        title: 'Nenhuma oferta ativa',
        message:
            'As ofertas criadas por você aparecerão aqui enquanto estiverem abertas.',
      );
    }

    return Column(
      children: _myOffers.map((offer) {
        final isProcessing =
            _pendingOfferActionId == offer.offerId &&
            _pendingOfferActionType == 'cancel';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OfferCard(
            startupName: _startupName(offer.startupId),
            offer: offer,
            currencyFormat: _currencyFormat,
            dateLabel: _formatDate(offer.createdAt),
            actionLabel: 'Cancelar',
            actionIcon: Icons.close_rounded,
            isProcessing: isProcessing,
            onAction: _isOfferActionRunning ? null : () => _cancelOffer(offer),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMarketOffersSection() {
    if (_marketOffers.isEmpty) {
      return const _EmptyStateCard(
        icon: Icons.storefront_outlined,
        title: 'Mercado sem ofertas abertas',
        message:
            'Quando outros investidores publicarem ofertas ativas, elas aparecerão aqui.',
      );
    }

    return Column(
      children: _marketOffers.map((offer) {
        final isProcessing =
            _pendingOfferActionId == offer.offerId &&
            _pendingOfferActionType == 'accept';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OfferCard(
            startupName: _startupName(offer.startupId),
            offer: offer,
            currencyFormat: _currencyFormat,
            dateLabel: _formatDate(offer.createdAt),
            sellerName: offer.vendedorNome,
            actionLabel: 'Comprar',
            actionIcon: Icons.shopping_cart_checkout_rounded,
            isProcessing: isProcessing,
            onAction: _isOfferActionRunning ? null : () => _acceptOffer(offer),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          );

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );

    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: child,
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.startupName,
    required this.offer,
    required this.currencyFormat,
    required this.dateLabel,
    required this.actionLabel,
    required this.actionIcon,
    required this.isProcessing,
    required this.onAction,
    this.sellerName,
  });

  final String startupName;
  final OfferModel offer;
  final NumberFormat currencyFormat;
  final String dateLabel;
  final String actionLabel;
  final IconData actionIcon;
  final bool isProcessing;
  final VoidCallback? onAction;
  final String? sellerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startupName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Criada em $dateLabel',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(label: offer.status),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoPill(
                label: 'Quantidade',
                value: '${offer.quantidade} tokens',
              ),
              _InfoPill(
                label: 'Preço unitário',
                value: currencyFormat.format(offer.precoUnitarioReais),
              ),
              _InfoPill(
                label: 'Valor total',
                value: currencyFormat.format(offer.valorTotalReais),
              ),
              if (sellerName != null && sellerName!.trim().isNotEmpty)
                _InfoPill(label: 'Vendedor', value: sellerName!),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isProcessing ? null : onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.45,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(actionIcon, size: 18),
              label: Text(
                isProcessing ? 'Processando...' : actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.mutedForeground),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectSellSheet extends StatefulWidget {
  const _DirectSellSheet({
    required this.service,
    required this.holdings,
    required this.startupsById,
    required this.currencyFormat,
  });

  final BalcaoApiService service;
  final List<HoldingModel> holdings;
  final Map<String, StartupModel> startupsById;
  final NumberFormat currencyFormat;

  @override
  State<_DirectSellSheet> createState() => _DirectSellSheetState();
}

class _DirectSellSheetState extends State<_DirectSellSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();

  String? _selectedStartupId;
  bool _isSubmitting = false;
  String? _backendError;

  HoldingModel? get _selectedHolding {
    final startupId = _selectedStartupId;
    if (startupId == null) return null;

    for (final holding in widget.holdings) {
      if (holding.startupId == startupId) {
        return holding;
      }
    }

    return null;
  }

  StartupModel? get _selectedStartup {
    final startupId = _selectedStartupId;
    if (startupId == null) return null;
    return widget.startupsById[startupId];
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final holding = _selectedHolding;
    final startupId = _selectedStartupId;
    final quantidade = int.tryParse(_quantityController.text.trim());
    if (holding == null || startupId == null || quantidade == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _backendError = null;
    });

    try {
      await widget.service.directSell(
        startupId: startupId,
        quantidade: quantidade,
      );

      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(const _SheetActionResult('Venda direta realizada com sucesso.'));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _backendError = error.toString().replaceFirst('Exception: ', '').trim();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final holding = _selectedHolding;
    final startup = _selectedStartup;

    return _SheetContainer(
      title: 'Venda direta',
      subtitle:
          'Venda tokens livres de volta para a startup. O backend valida saldo, posse e preço final.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HoldingDropdownField(
              holdings: widget.holdings,
              startupsById: widget.startupsById,
              value: _selectedStartupId,
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _selectedStartupId = value;
                      });
                    },
            ),
            if (holding != null) ...[
              const SizedBox(height: 12),
              _HoldingSummary(
                holding: holding,
                startup: startup,
                currencyFormat: widget.currencyFormat,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              enabled: !_isSubmitting,
              decoration: _inputDecoration(
                label: 'Quantidade de tokens',
                hint: 'Ex.: 10',
              ),
              validator: (value) {
                if (_selectedStartupId == null) {
                  return 'Selecione uma startup.';
                }

                final quantidade = int.tryParse(value?.trim() ?? '');
                if (quantidade == null || quantidade <= 0) {
                  return 'Informe uma quantidade válida.';
                }

                final available = _selectedHolding?.quantidade ?? 0;
                if (quantidade > available) {
                  return 'A quantidade não pode exceder seus tokens livres.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                startup == null
                    ? 'Selecione uma startup para conferir seus tokens livres antes de enviar.'
                    : 'Preço indicativo atual: ${widget.currencyFormat.format(startup.precoAtualReais)} por token. O valor efetivo será validado pelo backend.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
            if (_backendError != null) ...[
              const SizedBox(height: 12),
              Text(
                _backendError!,
                style: const TextStyle(
                  color: AppColors.destructive,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            MesclaButton(
              label: _isSubmitting ? 'Enviando...' : 'Confirmar venda direta',
              width: double.infinity,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateOfferSheet extends StatefulWidget {
  const _CreateOfferSheet({
    required this.service,
    required this.holdings,
    required this.startupsById,
    required this.currencyFormat,
  });

  final BalcaoApiService service;
  final List<HoldingModel> holdings;
  final Map<String, StartupModel> startupsById;
  final NumberFormat currencyFormat;

  @override
  State<_CreateOfferSheet> createState() => _CreateOfferSheetState();
}

class _CreateOfferSheetState extends State<_CreateOfferSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final NumberFormat _inputPriceFormat = NumberFormat.decimalPatternDigits(
    locale: 'pt_BR',
    decimalDigits: 2,
  );

  String? _selectedStartupId;
  bool _isSubmitting = false;
  String? _backendError;

  HoldingModel? get _selectedHolding {
    final startupId = _selectedStartupId;
    if (startupId == null) return null;

    for (final holding in widget.holdings) {
      if (holding.startupId == startupId) {
        return holding;
      }
    }

    return null;
  }

  StartupModel? get _selectedStartup {
    final startupId = _selectedStartupId;
    if (startupId == null) return null;
    return widget.startupsById[startupId];
  }

  int? get _quantityValue => int.tryParse(_quantityController.text.trim());
  int? get _priceInCents => _parseCurrencyToCents(_priceController.text);

  void _useCurrentTokenPrice() {
    final startup = _selectedStartup;
    if (startup == null) return;

    _priceController.text = _inputPriceFormat.format(startup.precoAtualReais);
    setState(() {
      _backendError = null;
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final startupId = _selectedStartupId;
    final quantity = _quantityValue;
    final priceInCents = _priceInCents;
    if (startupId == null || quantity == null || priceInCents == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _backendError = null;
    });

    try {
      await widget.service.createSellOffer(
        startupId: startupId,
        quantidade: quantity,
        precoUnitarioCentavos: priceInCents,
      );

      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(const _SheetActionResult('Oferta criada com sucesso.'));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _backendError = error.toString().replaceFirst('Exception: ', '').trim();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final holding = _selectedHolding;
    final startup = _selectedStartup;
    final quantity = _quantityValue ?? 0;
    final priceInCents = _priceInCents ?? 0;
    final totalInCents = quantity > 0 && priceInCents > 0
        ? quantity * priceInCents
        : 0;

    return _SheetContainer(
      title: 'Criar oferta',
      subtitle:
          'Publique uma oferta aberta definindo a quantidade e o preço unitário. O backend valida bloqueio, saldo e consistência final.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HoldingDropdownField(
              holdings: widget.holdings,
              startupsById: widget.startupsById,
              value: _selectedStartupId,
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _selectedStartupId = value;
                      });
                    },
            ),
            if (holding != null) ...[
              const SizedBox(height: 12),
              _HoldingSummary(
                holding: holding,
                startup: startup,
                currencyFormat: widget.currencyFormat,
              ),
            ],
            if (startup != null) ...[
              const SizedBox(height: 12),
              _CurrentTokenPriceCard(
                startup: startup,
                currencyFormat: widget.currencyFormat,
                onUseCurrentPrice: _isSubmitting ? null : _useCurrentTokenPrice,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              enabled: !_isSubmitting,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration(
                label: 'Quantidade de tokens',
                hint: 'Ex.: 10',
              ),
              validator: (value) {
                if (_selectedStartupId == null) {
                  return 'Selecione uma startup.';
                }

                final quantidade = int.tryParse(value?.trim() ?? '');
                if (quantidade == null || quantidade <= 0) {
                  return 'Informe uma quantidade válida.';
                }

                final available = _selectedHolding?.quantidade ?? 0;
                if (quantidade > available) {
                  return 'A quantidade não pode exceder seus tokens livres.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !_isSubmitting,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration(
                label: 'Preço unitário (R\$)',
                hint: 'Ex.: 12,50',
              ),
              validator: (value) {
                final cents = _parseCurrencyToCents(value ?? '');
                if (cents == null || cents <= 0) {
                  return 'Informe um preço unitário válido.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            _OfferSummaryCard(
              quantity: quantity,
              priceInCents: priceInCents,
              totalInCents: totalInCents,
              currencyFormat: widget.currencyFormat,
            ),
            if (_backendError != null) ...[
              const SizedBox(height: 12),
              Text(
                _backendError!,
                style: const TextStyle(
                  color: AppColors.destructive,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            MesclaButton(
              label: _isSubmitting ? 'Publicando...' : 'Publicar oferta',
              width: double.infinity,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetContainer extends StatelessWidget {
  const _SheetContainer({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoldingDropdownField extends StatelessWidget {
  const _HoldingDropdownField({
    required this.holdings,
    required this.startupsById,
    required this.value,
    required this.onChanged,
  });

  final List<HoldingModel> holdings;
  final Map<String, StartupModel> startupsById;
  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey<String?>(value),
      initialValue: value,
      decoration: _inputDecoration(
        label: 'Startup',
        hint: 'Selecione uma startup',
      ),
      items: holdings.map((holding) {
        final startup = startupsById[holding.startupId];
        final startupName = startup?.nome.trim().isNotEmpty == true
            ? startup!.nome.trim()
            : holding.startupId;

        return DropdownMenuItem<String>(
          value: holding.startupId,
          child: Text('$startupName • ${holding.quantidade} livres'),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione uma startup.';
        }

        return null;
      },
      onChanged: onChanged,
    );
  }
}

class _HoldingSummary extends StatelessWidget {
  const _HoldingSummary({
    required this.holding,
    required this.startup,
    required this.currencyFormat,
  });

  final HoldingModel holding;
  final StartupModel? startup;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            startup?.nome ?? 'Startup selecionada',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você possui ${holding.quantidade} tokens livres e ${holding.quantidadeBloqueada} bloqueados.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Preço médio da posição: ${currencyFormat.format(holding.precoMedioReais)}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentTokenPriceCard extends StatelessWidget {
  const _CurrentTokenPriceCard({
    required this.startup,
    required this.currencyFormat,
    required this.onUseCurrentPrice,
  });

  final StartupModel startup;
  final NumberFormat currencyFormat;
  final VoidCallback? onUseCurrentPrice;

  @override
  Widget build(BuildContext context) {
    final variation = startup.variacaoPercent;
    final variationPrefix = variation > 0 ? '+' : '';
    final variationColor = variation > 0
        ? AppColors.success
        : variation < 0
        ? AppColors.destructive
        : AppColors.mutedForeground;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preço atual do token',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      startup.nome,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onUseCurrentPrice,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: const Text('Usar valor'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(startup.precoAtualReais),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  'por token',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PriceReferenceChip(
                icon: Icons.flag_outlined,
                label:
                    'Inicial ${currencyFormat.format(startup.precoInicialReais)}',
              ),
              _PriceReferenceChip(
                icon: variation >= 0
                    ? Icons.north_east_rounded
                    : Icons.south_east_rounded,
                label:
                    'Variação $variationPrefix${variation.toStringAsFixed(1)}%',
                color: variationColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Use esse valor como referência para definir o preço unitário da oferta. A validação final continua no backend.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceReferenceChip extends StatelessWidget {
  const _PriceReferenceChip({
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferSummaryCard extends StatelessWidget {
  const _OfferSummaryCard({
    required this.quantity,
    required this.priceInCents,
    required this.totalInCents,
    required this.currencyFormat,
  });

  final int quantity;
  final int priceInCents;
  final int totalInCents;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo da oferta',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Quantidade', value: '$quantity tokens'),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Preço unitário',
            value: priceInCents > 0
                ? currencyFormat.format(priceInCents / 100)
                : '—',
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Valor total',
            value: totalInCents > 0
                ? currencyFormat.format(totalInCents / 100)
                : '—',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.mutedForeground,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required String hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
    ),
  );
}

int? _parseCurrencyToCents(String rawValue) {
  var normalized = rawValue.trim();
  if (normalized.isEmpty) return null;

  normalized = normalized.replaceAll('R\$', '').replaceAll(' ', '');
  if (normalized.contains(',') && normalized.contains('.')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else {
    normalized = normalized.replaceAll(',', '.');
  }

  final value = double.tryParse(normalized);
  if (value == null || value <= 0) {
    return null;
  }

  return (value * 100).round();
}

class _SheetActionResult {
  const _SheetActionResult(this.message);

  final String message;
}

class _BalcaoDataBundle {
  const _BalcaoDataBundle({
    required this.holdings,
    required this.myOffers,
    required this.marketOffers,
    required this.startups,
  });

  final List<HoldingModel> holdings;
  final List<OfferModel> myOffers;
  final List<OfferModel> marketOffers;
  final List<StartupModel> startups;
}
