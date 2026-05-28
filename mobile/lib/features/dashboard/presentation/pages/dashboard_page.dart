import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/perfil/data/datasource/perfil_datasource.dart';
import '../../../../features/perfil/domain/perfil_models.dart';
import '../../../../features/startups/data/startup_service.dart';
import '../../../../features/startups/domain/startup_model.dart';
import '../../../../shared/formatters/reais_formatter.dart';
import '../../data/datasources/dashboard_datasource.dart';
import '../../data/models/dashboard_models.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardDatasource _datasource = DashboardDatasource();
  final PerfilDatasource _perfilDatasource = PerfilDatasource();
  final StartupService _startupService = StartupService();

  bool _isLoading = true;
  DashboardSummaryModel? _summary;
  List<HoldingModel>? _holdings;
  List<TransactionModel>? _transactions;
  List<Startup>? _startupsDestaque;
  String _primeiroNome = '';

  String _periodoSelecionado = '1M';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final summaryFuture = _datasource.getSummary();
      final holdingsFuture = _datasource.getHoldings();
      final transactionsFuture = _datasource.getTransactions();
      final perfilFuture = _opcional(
        _perfilDatasource.buscarPerfil().then(PerfilModel.fromJson),
      );
      final startupsFuture = _opcional(_startupService.listarStartups());

      final summary = await summaryFuture;
      final holdings = await holdingsFuture;
      final transactions = await transactionsFuture;
      final perfil = await perfilFuture;
      final startups = await startupsFuture;

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _holdings = holdings;
        _transactions = transactions;
        _primeiroNome = _primeiroNomeDe(perfil?.nome);
        _startupsDestaque = _selecionarDestaques(startups);
        _isLoading = false;
      });
    } catch (e) {
      if (e.toString().toLowerCase().contains('sessao expirada') ||
          e.toString().toLowerCase().contains('sessão expirada')) {
        await SessionManager.fazerLogout();
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        return;
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<T?> _opcional<T>(Future<T> future) =>
      future.then<T?>((v) => v, onError: (_) => null);

  String _primeiroNomeDe(String? nomeCompleto) {
    final partes = (nomeCompleto ?? '').trim().split(RegExp(r'\s+'));
    return partes.first;
  }

  List<DashboardChartPointModel> _filtrarPontosPorPeriodo(
    List<DashboardChartPointModel> pontos,
    String periodo,
  ) {
    if (pontos.isEmpty) return pontos;

    final agora = DateTime.now();
    DateTime inicio;
    switch (periodo) {
      case '1D':
        inicio = agora.subtract(const Duration(days: 1));
        break;
      case '1W':
        inicio = agora.subtract(const Duration(days: 7));
        break;
      case '1M':
        inicio = agora.subtract(const Duration(days: 30));
        break;
      case '6M':
        inicio = agora.subtract(const Duration(days: 180));
        break;
      case 'YTD':
        inicio = DateTime(agora.year);
        break;
      default:
        return pontos;
    }

    final filtrados = pontos.where((p) {
      final data = DateTime.tryParse(p.data);
      if (data == null) return true;
      return !data.isBefore(inicio);
    }).toList();

    return filtrados.isEmpty ? pontos : filtrados;
  }

  List<Startup> _selecionarDestaques(List<Startup>? startups) {
    if (startups == null || startups.isEmpty) return const [];
    final ordenadas = [...startups]..sort((a, b) {
      final varA = a.variacaoPreco ?? 0;
      final varB = b.variacaoPreco ?? 0;
      return varB.compareTo(varA);
    });
    return ordenadas.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: _buildDashboardContent());
  }

  void _abrirExtrato() {
    Navigator.pushNamed(context, AppRoutes.extrato);
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = _summary;
    if (summary == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Não foi possível carregar o painel.\nTente novamente mais tarde.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedForeground),
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(summary)),
        SliverToBoxAdapter(child: _buildHeroCard(summary)),
        SliverToBoxAdapter(child: _buildAcoesRapidas()),
        SliverToBoxAdapter(child: _buildGraficoEvolucao(summary.pontosGrafico)),
        SliverToBoxAdapter(child: _buildStartupsDestaque()),
        SliverToBoxAdapter(child: _buildMinhasPosicoes(_holdings ?? const [])),
        SliverToBoxAdapter(
          child: _buildAtividadeRecente(_transactions ?? const []),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildHeader(DashboardSummaryModel summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _primeiroNome.isEmpty ? 'Olá!' : 'Olá, $_primeiroNome',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Painel do Investidor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Ink(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.perfil),
                  borderRadius: BorderRadius.circular(18),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Saldo disponível',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                Text(
                  _formatBRL(summary.saldoDisponivel),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(DashboardSummaryModel summary) {
    final retornoCor = summary.retorno >= 0
        ? AppColors.success
        : AppColors.destructive;
    final lucroCor = summary.lucro >= 0
        ? AppColors.success
        : AppColors.destructive;

    return Transform.translate(
      offset: const Offset(0, -18),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Valor total da carteira',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatBRL(summary.valorTotalCarteira),
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: retornoCor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatPercent(summary.retorno),
                    style: TextStyle(
                      color: retornoCor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ResumoItem(
                    label: 'Investido',
                    valor: _formatBRL(summary.totalInvestido),
                    cor: AppColors.foreground,
                  ),
                ),
                Expanded(
                  child: _ResumoItem(
                    label: 'Lucro',
                    valor: _formatSignedBRL(summary.lucro),
                    cor: lucroCor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcoesRapidas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: _AcaoRapida(
              icon: Icons.rocket_launch_rounded,
              label: 'Startups',
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, AppRoutes.catalog),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _AcaoRapida(
              icon: Icons.swap_horiz_rounded,
              label: 'Balcão',
              color: AppColors.accent,
              onTap: () => Navigator.pushNamed(context, AppRoutes.balcao),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _AcaoRapida(
              icon: Icons.work_outline_rounded,
              label: 'Carteira',
              color: AppColors.chart4,
              onTap: () => Navigator.pushNamed(context, AppRoutes.portfolio),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoEvolucao(List<DashboardChartPointModel> pontos) {
    final pontosFiltrados = _filtrarPontosPorPeriodo(
      pontos,
      _periodoSelecionado,
    );
    final temDados = _summary != null && pontosFiltrados.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Evolução da Carteira',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 180,
              child: temDados
                  ? _EvolucaoLineChart(pontos: pontosFiltrados)
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart_rounded,
                            color: AppColors.mutedForeground,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Sem dados de evolução ainda',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            _buildPeriodoSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodoSelector() {
    const periodos = ['1D', '1W', '1M', '6M', 'YTD'];

    return Row(
      children: periodos.map((periodo) {
        final selecionado = periodo == _periodoSelecionado;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => setState(() => _periodoSelecionado = periodo),
              child: Container(
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selecionado ? AppColors.primary : AppColors.muted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  periodo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selecionado
                        ? Colors.white
                        : AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStartupsDestaque() {
    final startups = _startupsDestaque ?? const <Startup>[];
    const cores = [AppColors.success, AppColors.chart5, AppColors.chart4];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SecaoTitulo(
            titulo: 'Startups em destaque',
            acao: 'Ver todas',
            onAcaoTap: () =>
                Navigator.pushNamed(context, AppRoutes.catalog),
          ),
          const SizedBox(height: 14),
          if (startups.isEmpty)
            const _EstadoVazio(
              icone: Icons.rocket_launch_outlined,
              mensagem: 'Sem startups em destaque por enquanto.',
            )
          else
            SizedBox(
              height: 132,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: startups.length,
                itemBuilder: (_, i) {
                  final startup = startups[i];
                  return _OportunidadeCard(
                    nome: startup.nome,
                    setor: startup.setor,
                    variacao: _formatPercent(startup.variacaoPreco ?? 0),
                    cor: cores[i % cores.length],
                    corVariacao: (startup.variacaoPreco ?? 0) >= 0
                        ? AppColors.success
                        : AppColors.destructive,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMinhasPosicoes(List<HoldingModel> holdings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SecaoTitulo(
            titulo: 'Minhas posições',
            acao: 'Ver carteira',
            onAcaoTap: () =>
                Navigator.pushNamed(context, AppRoutes.portfolio),
          ),
          const SizedBox(height: 14),
          if (holdings.isEmpty)
            _EstadoVazio(
              icone: Icons.work_outline_rounded,
              mensagem: 'Você ainda não possui posições.',
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: holdings.length,
              itemBuilder: (_, i) => _PosicaoCard(holding: holdings[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildAtividadeRecente(List<TransactionModel> transactions) {
    final transacoesExibidas = transactions.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SecaoTitulo(
            titulo: 'Atividade recente',
            acao: 'Ver extrato',
            onAcaoTap: _abrirExtrato,
          ),
          const SizedBox(height: 14),
          if (transacoesExibidas.isEmpty)
            _EstadoVazio(
              icone: Icons.receipt_long_outlined,
              mensagem: 'Sem movimentações por enquanto.',
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transacoesExibidas.length,
              itemBuilder: (_, i) =>
                  _AtividadeCard(transaction: transacoesExibidas[i]),
            ),
        ],
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;

  const _ResumoItem({
    required this.label,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            color: cor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AcaoRapida extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AcaoRapida({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.muted),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OportunidadeCard extends StatelessWidget {
  final String nome;
  final String setor;
  final String variacao;
  final Color cor;
  final Color corVariacao;

  const _OportunidadeCard({
    required this.nome,
    required this.setor,
    required this.variacao,
    required this.cor,
    required this.corVariacao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.muted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: cor.withValues(alpha: 0.12),
            child: Icon(Icons.business_rounded, color: cor, size: 20),
          ),
          const Spacer(),
          Text(
            nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  setor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                variacao,
                style: TextStyle(
                  color: corVariacao,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PosicaoCard extends StatelessWidget {
  final HoldingModel holding;

  const _PosicaoCard({required this.holding});

  @override
  Widget build(BuildContext context) {
    final cor = holding.percentualRetorno >= 0
        ? AppColors.success
        : AppColors.destructive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.muted),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cor.withValues(alpha: 0.12),
            child: Icon(Icons.business_rounded, color: cor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.nomeStartup.isEmpty ? '—' : holding.nomeStartup,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  holding.setor.isEmpty
                      ? 'Setor não informado'
                      : holding.setor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatBRL(holding.valorInvestido),
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatPercent(holding.percentualRetorno),
                style: TextStyle(
                  color: cor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AtividadeCard extends StatelessWidget {
  final TransactionModel transaction;

  const _AtividadeCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final tipoUpper = transaction.tipo.toUpperCase();
    final isCompra = tipoUpper.startsWith('COMPRA');
    final tipoExibido = isCompra
        ? 'Compra'
        : tipoUpper.startsWith('VENDA')
            ? 'Venda'
            : transaction.tipo;
    final cor = isCompra ? AppColors.destructive : AppColors.success;
    final dtParsed = transaction.data.isNotEmpty ? DateTime.tryParse(transaction.data) : null;
    final dataFormatada = (dtParsed != null && dtParsed.millisecondsSinceEpoch != 0)
        ? DateFormat('dd/MM/yyyy').format(dtParsed)
        : '';
    final subtitle = [
      if (transaction.detalhes.isNotEmpty) transaction.detalhes,
      if (dataFormatada.isNotEmpty) dataFormatada,
    ].join(' · ');
    final valorExibido = isCompra
        ? -transaction.valor.abs()
        : transaction.valor.abs();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.muted),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCompra
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: cor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.nomeStartup.isEmpty
                      ? '—'
                      : transaction.nomeStartup,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle.isEmpty
                      ? tipoExibido
                      : '$tipoExibido · $subtitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatSignedBRL(valorExibido),
            style: TextStyle(
              color: cor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  final String titulo;
  final String acao;
  final VoidCallback? onAcaoTap;

  const _SecaoTitulo({
    required this.titulo,
    required this.acao,
    this.onAcaoTap,
  });

  @override
  Widget build(BuildContext context) {
    const acaoStyle = TextStyle(
      color: AppColors.primary,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );

    final acaoWidget = onAcaoTap == null
        ? Text(acao, style: acaoStyle)
        : InkWell(
            onTap: onAcaoTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(acao, style: acaoStyle),
            ),
          );

    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        acaoWidget,
      ],
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String mensagem;

  const _EstadoVazio({required this.icone, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.muted),
      ),
      child: Row(
        children: [
          Icon(icone, color: AppColors.mutedForeground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolucaoLineChart extends StatelessWidget {
  final List<DashboardChartPointModel> pontos;

  const _EvolucaoLineChart({required this.pontos});

  @override
  Widget build(BuildContext context) {
    final datas = pontos.map((p) => _parseData(p.data)).toList(growable: false);

    final spots = <FlSpot>[
      for (var i = 0; i < pontos.length; i++)
        FlSpot(i.toDouble(), pontos[i].valor),
    ];

    final valores = pontos.map((p) => p.valor).toList();
    final minValor = valores.reduce((a, b) => a < b ? a : b);
    final maxValor = valores.reduce((a, b) => a > b ? a : b);
    final folga = (maxValor - minValor).abs() * 0.15;
    final minY = (minValor - folga).clamp(0, double.infinity).toDouble();
    final maxY = maxValor + (folga == 0 ? maxValor * 0.15 + 1 : folga);
    final intervalY = (maxY - minY) / 4;

    final ultimoIndice = (pontos.length - 1).clamp(0, pontos.length);
    final intervalX = pontos.length <= 4
        ? 1.0
        : (ultimoIndice / 3).ceilToDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: ultimoIndice.toDouble().clamp(1, double.infinity),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervalY > 0 ? intervalY : null,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.muted.withValues(alpha: 0.7),
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: intervalY > 0 ? intervalY : null,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  _formatarValorEixoCompacto(value),
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: intervalX,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= datas.length) return const SizedBox.shrink();
                final dt = datas[i];
                if (dt == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('dd/MM').format(dt),
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.foreground,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItems: (touched) => touched.map((spot) {
              final i = spot.x.toInt().clamp(0, pontos.length - 1);
              final dt = datas[i];
              final dataLegivel = dt == null
                  ? '—'
                  : DateFormat('dd/MM/yyyy').format(dt);
              return LineTooltipItem(
                '${formatarReais(spot.y)}\nData: $dataLegivel',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.primary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatarValorEixoCompacto(double valor) {
    final abs = valor.abs();
    if (abs >= 1_000_000) {
      return 'R\$ ${(valor / 1_000_000).toStringAsFixed(1)}M';
    }
    if (abs >= 1_000) {
      return 'R\$ ${(valor / 1_000).toStringAsFixed(0)}k';
    }
    return 'R\$ ${valor.toStringAsFixed(0)}';
  }

  static DateTime? _parseData(String raw) {
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

String _formatBRL(double valor) {
  final negative = valor < 0;
  final abs = valor.abs().toStringAsFixed(2);
  final parts = abs.split('.');
  final intPart = parts[0];
  final decPart = parts[1];
  final buffer = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
    buffer.write(intPart[i]);
  }
  return '${negative ? '-' : ''}R\$ $buffer,$decPart';
}

String _formatSignedBRL(double valor) {
  if (valor >= 0) return '+${_formatBRL(valor)}';
  return _formatBRL(valor);
}

String _formatPercent(double valor) {
  final sign = valor >= 0 ? '+' : '';
  final formatted = valor.toStringAsFixed(2).replaceAll('.', ',');
  return '$sign$formatted%';
}
