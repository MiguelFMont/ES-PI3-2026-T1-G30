import 'package:flutter/material.dart';
import 'package:mesclainvest/core/theme/app_colors.dart';

import '../../data/startup_service.dart';
import '../../domain/startup_model.dart';

class StartupDetailsPage extends StatefulWidget {
  final Startup startup;

  const StartupDetailsPage({
    super.key,
    required this.startup,
  });

  @override
  State<StartupDetailsPage> createState() => _StartupDetailsPageState();
}

class _StartupDetailsPageState extends State<StartupDetailsPage> {
  final StartupService _service = StartupService();

  late Startup _startup;
  bool _isLoading = true;
  bool _isInvesting = false;
  String? _errorMessage;

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

      if (!mounted) return;
      setState(() {
        _startup = startup;
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

  Future<void> _showInvestConfirmation() async {
    const saldoUsuario = 5000.0;
    const investimentoMinimo = 500.0;
    const valorRecomendado = 1000.0;

    final valorController = TextEditingController(
      text: valorRecomendado.toStringAsFixed(0),
    );

    double valorDigitado() {
      final normalized = valorController.text.replaceAll(',', '.');
      return double.tryParse(normalized) ?? 0;
    }

    final valorAInvestir = await showDialog<double>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final valor = valorDigitado();
            final saldoInsuficiente = valor > saldoUsuario;
            final abaixoDoMinimo = valor < investimentoMinimo;
            final podeConfirmar = !saldoInsuficiente && !abaixoDoMinimo;

            return AlertDialog(
              title: const Text('Confirmar investimento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deseja confirmar o investimento nesta startup?',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Saldo disponível: ${saldoUsuario.toStringAsFixed(0)} tokens',
                  ),
                  Text(
                    'Investimento mínimo: ${investimentoMinimo.toStringAsFixed(0)} tokens',
                  ),
                  Text(
                    'Valor recomendado: ${valorRecomendado.toStringAsFixed(0)} tokens',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valorController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor a investir',
                      suffixText: 'tokens',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  if (saldoInsuficiente) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Saldo insuficiente para esta operação.',
                      style: TextStyle(color: Colors.red),
                    ),
                    TextButton(
                      onPressed: () {
                        print('TODO: Redirecionar para compra de tokens');
                      },
                      child: const Text('Comprar mais tokens'),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: podeConfirmar
                      ? () => Navigator.pop(context, valor)
                      : null,
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    valorController.dispose();

    if (valorAInvestir == null || !mounted) return;

    setState(() => _isInvesting = true);

    final success = await _service.investirStartup(
      _startup.id,
      valorAInvestir,
    );

    if (!mounted) return;

    setState(() => _isInvesting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Investimento realizado com sucesso!'),
          backgroundColor: Colors.green,
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
        title: Text(
          _startup.nome,
          overflow: TextOverflow.ellipsis,
        ),
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
      body: Center(
        child: Text('Nenhuma startup selecionada.'),
      ),
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
                  label: 'Tokens',
                  value: _formatTokens(startup.totalTokens),
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
                : const Text('Investir'),
          ),
        ),
      ],
    );
  }
}

class _DetailsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailsErrorState({
    required this.message,
    required this.onRetry,
  });

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

  const _StartupLogo({
    required this.url,
    required this.size,
  });

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

  const _InfoSection({
    required this.title,
    required this.child,
  });

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

  const _PeopleSection({
    required this.title,
    required this.people,
  });

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

  const _MembersSection({
    required this.title,
    required this.members,
  });

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

String _formatTokens(int value) {
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}k';
  }
  return value.toString();
}
