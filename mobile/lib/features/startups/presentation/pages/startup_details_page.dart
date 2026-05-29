import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mesclainvest/core/state/app_data_refresh_bus.dart';
import 'package:mesclainvest/core/theme/app_colors.dart';

import '../../data/startup_service.dart';
import '../../domain/startup_model.dart';

class StartupDetailsPage extends StatefulWidget {
  final Startup startup;

  const StartupDetailsPage({super.key, required this.startup});

  @override
  State<StartupDetailsPage> createState() => _StartupDetailsPageState();
}

class _StartupDetailsPageState extends State<StartupDetailsPage> {
  final StartupService _service = StartupService();

  late Startup _startup;
  int? _saldoDisponivelCentavos;
  bool _isLoading = true;
  bool _isInvesting = false;
  String? _errorMessage;
  String? _walletErrorMessage;

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
      final startup = await _service.buscarStartupPorId(widget.startup.id);
      int? saldoDisponivelCentavos = _saldoDisponivelCentavos;
      String? walletErrorMessage;

      try {
        saldoDisponivelCentavos = await _service
            .buscarSaldoDisponivelCentavos();
      } catch (e) {
        walletErrorMessage = e is StartupApiException
            ? e.message
            : 'Não foi possível carregar o saldo da carteira.';
      }

      if (!mounted) return;
      setState(() {
        _startup = startup;
        _saldoDisponivelCentavos = saldoDisponivelCentavos;
        _walletErrorMessage = walletErrorMessage;
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

  Future<bool> _refreshWalletBalance() async {
    try {
      final saldoDisponivelCentavos = await _service
          .buscarSaldoDisponivelCentavos();

      if (!mounted) return false;
      setState(() {
        _saldoDisponivelCentavos = saldoDisponivelCentavos;
        _walletErrorMessage = null;
      });
      return true;
    } catch (e) {
      final message = e is StartupApiException
          ? e.message
          : 'Não foi possível carregar o saldo da carteira.';

      if (!mounted) return false;
      setState(() => _walletErrorMessage = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.destructive,
        ),
      );
      return false;
    }
  }

  Future<void> _showInvestConfirmation() async {
    if (_startup.precoToken <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível calcular o preço do token agora.'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    if (_saldoDisponivelCentavos == null || _walletErrorMessage != null) {
      final refreshed = await _refreshWalletBalance();
      if (!refreshed || !mounted) return;
    }

    final quantidade = await showDialog<int>(
      context: context,
      builder: (context) {
        return _TokenPurchaseDialog(
          startupNome: _startup.nome,
          saldoDisponivelCentavos: _saldoDisponivelCentavos ?? 0,
          precoUnitarioCentavos: (_startup.precoToken * 100).round(),
          tokensDisponiveis: _startup.tokensDisponiveis,
        );
      },
    );

    if (quantidade == null || !mounted) return;

    setState(() => _isInvesting = true);

    try {
      final result = await _service.investirStartup(_startup.id, quantidade);
      Startup? startupAtualizada;

      try {
        startupAtualizada = await _service.buscarStartupPorId(
          widget.startup.id,
        );
      } catch (_) {
        startupAtualizada = null;
      }

      if (!mounted) return;

      setState(() {
        if (startupAtualizada != null) {
          _startup = startupAtualizada;
        }
        _saldoDisponivelCentavos = result.saldoNovoCentavos;
        _walletErrorMessage = null;
        _isInvesting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Compra aprovada: ${_formatInteger(result.quantidade)} tokens por ${_formatCurrencyCentavos(result.valorTotalCentavos)}.',
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
        reason: 'startup-direct-buy',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInvesting = false);

      final message = e is StartupApiException
          ? e.message
          : 'Não foi possível concluir a compra agora.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compra rejeitada: $message'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(_startup.nome, overflow: TextOverflow.ellipsis),
      ),
      body: _buildBody(),
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
      isInvesting: _isInvesting,
      onInvestPressed: _showInvestConfirmation,
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

class _DetailsContent extends StatelessWidget {
  final Startup startup;
  final bool isInvesting;
  final VoidCallback onInvestPressed;

  const _DetailsContent({
    required this.startup,
    required this.isInvesting,
    required this.onInvestPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DetailsHeader(startup: startup),
        const SizedBox(height: 16),
        _InfoSection(
          title: 'Resumo executivo',
          child: Text(
            startup.resumoExecutivo.isEmpty
                ? startup.descricao
                : startup.resumoExecutivo,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.foreground,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _InfoSection(
          title: 'Indicadores',
          child: Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.attach_money_rounded,
                  label: 'Capital',
                  value: _formatCurrency(startup.capitalAportado),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons.toll_rounded,
                  label: 'Disponíveis',
                  value:
                      '${_formatTokens(startup.tokensDisponiveis)} / ${_formatTokens(startup.totalTokens)}',
                ),
              ),
            ],
          ),
        ),
        if (startup.socios.isNotEmpty) ...[
          const SizedBox(height: 12),
          _PeopleSection(title: 'Socios', people: startup.socios),
        ],
        if (startup.conselho.isNotEmpty) ...[
          const SizedBox(height: 12),
          _MembersSection(title: 'Conselho', members: startup.conselho),
        ],
        if (startup.mentores.isNotEmpty) ...[
          const SizedBox(height: 12),
          _MembersSection(title: 'Mentores', members: startup.mentores),
        ],
        if (startup.atualizacoes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _UpdatesSection(updates: startup.atualizacoes),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isInvesting ? null : onInvestPressed,
            child: isInvesting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Comprar tokens'),
          ),
        ),
      ],
    );
  }
}

class _TokenPurchaseDialog extends StatefulWidget {
  final String startupNome;
  final int saldoDisponivelCentavos;
  final int precoUnitarioCentavos;
  final int tokensDisponiveis;

  const _TokenPurchaseDialog({
    required this.startupNome,
    required this.saldoDisponivelCentavos,
    required this.precoUnitarioCentavos,
    required this.tokensDisponiveis,
  });

  @override
  State<_TokenPurchaseDialog> createState() => _TokenPurchaseDialogState();
}

class _TokenPurchaseDialogState extends State<_TokenPurchaseDialog> {
  late final TextEditingController _quantidadeController;

  @override
  void initState() {
    super.initState();
    _quantidadeController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  int? get _quantidade {
    final text = _quantidadeController.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  int get _valorTotalCentavos {
    final quantidade = _quantidade;
    if (quantidade == null || quantidade < 1) return 0;
    return quantidade * widget.precoUnitarioCentavos;
  }

  String get _statusMessage {
    if (widget.precoUnitarioCentavos <= 0) {
      return 'Compra rejeitada: preço do token indisponível.';
    }

    if (widget.tokensDisponiveis <= 0) {
      return 'Compra rejeitada: não há tokens disponíveis.';
    }

    final quantidade = _quantidade;
    if (quantidade == null || quantidade < 1) {
      return 'Informe uma quantidade inteira válida.';
    }

    if (quantidade > widget.tokensDisponiveis) {
      return 'Compra rejeitada: quantidade indisponível.';
    }

    if (_valorTotalCentavos > widget.saldoDisponivelCentavos) {
      return 'Compra rejeitada: saldo insuficiente.';
    }

    return 'Compra válida.';
  }

  bool get _canConfirm => _statusMessage == 'Compra válida.';

  Color get _statusColor =>
      _canConfirm ? AppColors.success : AppColors.destructive;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirmar compra',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.startupNome,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PurchaseInfoCard(
                      label: 'Saldo em conta',
                      value: _formatCurrencyCentavos(
                        widget.saldoDisponivelCentavos,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PurchaseInfoCard(
                      label: 'Preço por token',
                      value: _formatCurrencyCentavos(
                        widget.precoUnitarioCentavos,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PurchaseInfoCard(
                label: 'Custo da compra',
                value: _formatCurrencyCentavos(_valorTotalCentavos),
                caption:
                    '${_formatInteger(widget.tokensDisponiveis)} tokens disponíveis',
                highlighted: true,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _quantidadeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Quantidade de tokens',
                  suffixText: 'tokens',
                  filled: true,
                  fillColor: AppColors.secondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.muted),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.muted),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_canConfirm) {
                    Navigator.of(context).pop(_quantidade);
                  }
                },
              ),
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      _canConfirm
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: _statusColor,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _canConfirm
                        ? () => Navigator.of(context).pop(_quantidade)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Confirmar compra'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final bool highlighted;

  const _PurchaseInfoCard({
    required this.label,
    required this.value,
    this.caption,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.secondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.muted,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ],
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

class _DetailsHeader extends StatelessWidget {
  final Startup startup;

  const _DetailsHeader({required this.startup});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StartupLogo(url: startup.logo, size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  startup.nome,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  startup.descricao,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                _StageChip(label: startup.estagio),
              ],
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
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.business_rounded,
        color: AppColors.mutedForeground,
      ),
    );

    if (url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
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
    final color = switch (label) {
      'Em Expansao' || 'Em Expansão' => AppColors.stageExpansion,
      'Em Operacao' || 'Em Operação' => AppColors.stageOperation,
      'Nova' => AppColors.stageNew,
      _ => AppColors.mutedForeground,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.muted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeopleSection extends StatelessWidget {
  final String title;
  final List<Socio> people;

  const _PeopleSection({required this.title, required this.people});

  @override
  Widget build(BuildContext context) {
    return _InfoSection(
      title: title,
      child: Column(
        children: [
          for (final person in people)
            _SimpleListTile(
              title: person.nome,
              subtitle: '${person.participacao.toStringAsFixed(0)}%',
              icon: Icons.person_rounded,
            ),
        ],
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  final String title;
  final List<Membro> members;

  const _MembersSection({required this.title, required this.members});

  @override
  Widget build(BuildContext context) {
    return _InfoSection(
      title: title,
      child: Column(
        children: [
          for (final member in members)
            _SimpleListTile(
              title: member.nome,
              subtitle: '${member.cargo} - ${member.area}',
              icon: Icons.badge_rounded,
            ),
        ],
      ),
    );
  }
}

class _UpdatesSection extends StatelessWidget {
  final List<Atualizacao> updates;

  const _UpdatesSection({required this.updates});

  @override
  Widget build(BuildContext context) {
    return _InfoSection(
      title: 'Atualizacoes',
      child: Column(
        children: [
          for (final update in updates)
            _SimpleListTile(
              title: update.titulo,
              subtitle: update.data.isEmpty
                  ? update.descricao
                  : '${update.data} - ${update.descricao}',
              icon: Icons.campaign_rounded,
            ),
        ],
      ),
    );
  }
}

class _SimpleListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SimpleListTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.mutedForeground,
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

String _formatCurrency(double value) {
  if (value >= 1000000) {
    return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return 'R\$ ${(value / 1000).toStringAsFixed(0)}k';
  }
  return 'R\$ ${value.toStringAsFixed(0)}';
}

final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$ ',
  decimalDigits: 2,
);
final NumberFormat _integerFormat = NumberFormat.decimalPattern('pt_BR');

String _formatCurrencyCentavos(int value) {
  return _currencyFormat.format(value / 100);
}

String _formatInteger(int value) {
  return _integerFormat.format(value);
}

String _formatTokens(int value) {
  return _formatInteger(value);
}
