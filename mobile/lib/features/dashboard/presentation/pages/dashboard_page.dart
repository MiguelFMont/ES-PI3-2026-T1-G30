import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes.dart';
import '../../../../core/state/app_data_refresh_bus.dart';
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
  StreamSubscription<AppDataRefreshEvent>? _refreshSubscription;

  bool _isLoading = true;
  DashboardSummaryModel? _summary;
  List<HoldingModel>? _holdings;
  List<TransactionModel>? _transactions;
  List<Startup>? _startupsDestaque;
  Map<String, Startup> _startupsPorId = const {};
  String _primeiroNome = '';

  String _periodoSelecionado = '1M';

  @override
  void initState() {
    super.initState();
    _refreshSubscription = AppDataRefreshBus.instance.stream.listen((event) {
      if (!event.affects(AppDataRefreshScope.dashboard) || !mounted) {
        return;
      }

      _carregarDados();
    });
    _carregarDados();
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
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
        _startupsPorId = _mapearStartupsPorId(startups);
        _isLoading = false;
      });
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final sessaoExpirada =
          msg.contains('sessao expirada') || msg.contains('sessão expirada');
      if (sessaoExpirada && !await SessionManager.emModoTeste()) {
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
    final ordenadas = [...startups]
      ..sort((a, b) {
        final varA = a.variacaoPreco ?? 0;
        final varB = b.variacaoPreco ?? 0;
        return varB.compareTo(varA);
      });
    return ordenadas.take(3).toList();
  }

  Map<String, Startup> _mapearStartupsPorId(List<Startup>? startups) {
    if (startups == null || startups.isEmpty) return const {};

    final startupsPorId = <String, Startup>{};

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

  String _resolverNomeStartup(String nomeOuId) {
    final valor = nomeOuId.trim();
    if (valor.isEmpty) return '-';

    final startup = _startupsPorId[valor];
    if (startup != null && startup.nome.trim().isNotEmpty) {
      return startup.nome.trim();
    }

    return valor;
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

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _carregarDados,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildTopSection(summary)),
          SliverToBoxAdapter(child: _buildAcoesRapidas()),
          SliverToBoxAdapter(
            child: _buildGraficoEvolucao(summary.pontosGrafico),
          ),
          SliverToBoxAdapter(
            child: _buildMinhasPosicoes(_holdings ?? const []),
          ),
          SliverToBoxAdapter(child: _buildStartupsDestaque()),
          SliverToBoxAdapter(
            child: _buildAtividadeRecente(_transactions ?? const []),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildTopSection(DashboardSummaryModel summary) {
    final greeting = _primeiroNome.isEmpty ? 'Olá!' : 'Olá, $_primeiroNome 👋';

    return SizedBox(
      height: 338,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 226,
            child: CustomPaint(
              painter: const _DashboardHeaderPainter(),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: 32,
            left: 27,
            right: 22,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Painel do Investidor',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _SaldoPill(valor: summary.saldoDisponivel),
              ],
            ),
          ),
          Positioned(
            top: 102,
            left: 27,
            right: 22,
            child: _ResumoCarteiraCard(
              summary: summary,
              pontos: _filtrarPontosPorPeriodo(
                summary.pontosGrafico,
                '1M',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcoesRapidas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 22, 22, 22),
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
          const SizedBox(width: 8),
          Expanded(
            child: _AcaoRapida(
              icon: Icons.swap_horiz_rounded,
              label: 'Balcão',
              color: AppColors.accent,
              onTap: () => Navigator.pushNamed(context, AppRoutes.balcao),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AcaoRapida(
              icon: Icons.business_center_outlined,
              label: 'Carteira',
              color: AppColors.chart4,
              onTap: () => Navigator.pushNamed(context, AppRoutes.portfolio),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AcaoRapida(
              icon: Icons.receipt_long_outlined,
              label: 'Extrato',
              color: AppColors.chart3,
              onTap: _abrirExtrato,
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
      padding: const EdgeInsets.fromLTRB(27, 0, 22, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 17, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                  size: 15,
                ),
                SizedBox(width: 8),
                Text(
                  'Evolução da Carteira',
                  style: TextStyle(
                    color: Color(0xFF17233C),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 23),
            SizedBox(
              height: 198,
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
            const SizedBox(height: 10),
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
      padding: const EdgeInsets.fromLTRB(27, 0, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SecaoTitulo(
            titulo: 'Startups em destaque',
            acao: 'Ver todas',
            onAcaoTap: () => Navigator.pushNamed(context, AppRoutes.catalog),
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
      padding: const EdgeInsets.fromLTRB(27, 0, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SecaoTitulo(
            titulo: 'Minhas participações',
            acao: 'Ver carteira',
            onAcaoTap: () => Navigator.pushNamed(context, AppRoutes.portfolio),
          ),
          const SizedBox(height: 14),
          if (holdings.isEmpty)
            _EstadoVazio(
              icone: Icons.work_outline_rounded,
              mensagem: 'Você ainda não possui participações.',
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: holdings.length,
              itemBuilder: (_, i) => _PosicaoCard(
                holding: holdings[i],
                nomeStartup: _resolverNomeStartup(holdings[i].nomeStartup),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAtividadeRecente(List<TransactionModel> transactions) {
    final transacoesExibidas = transactions.take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 0, 22, 0),
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
              itemBuilder: (_, i) => _AtividadeCard(
                transaction: transacoesExibidas[i],
                nomeStartup: _resolverNomeStartup(
                  transacoesExibidas[i].nomeStartup,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardHeaderPainter extends CustomPainter {
  const _DashboardHeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = AppColors.primary;
    canvas.drawRect(Offset.zero & size, basePaint);

    final accentPaint = Paint()..color = const Color(0xFFC22A7B);
    final accentPath = Path()
      ..moveTo(size.width * 0.49, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.34, size.height)
      ..close();
    canvas.drawPath(accentPath, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SaldoPill extends StatelessWidget {
  final double valor;

  const _SaldoPill({required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Saldo disponível',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatBRLInteiro(valor),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoCarteiraCard extends StatelessWidget {
  final DashboardSummaryModel summary;
  final List<DashboardChartPointModel> pontos;

  const _ResumoCarteiraCard({required this.summary, required this.pontos});

  @override
  Widget build(BuildContext context) {
    final retornoCor = summary.retorno >= 0
        ? AppColors.success
        : AppColors.destructive;
    final lucroCor = summary.lucro >= 0
        ? AppColors.success
        : AppColors.destructive;

    return Container(
      height: 235,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valor Total da Carteira',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _MoneyHighlight(value: summary.valorTotalCarteira),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _RetornoBadge(valor: summary.retorno, color: retornoCor),
            ],
          ),
          const SizedBox(height: 17),
          const Divider(height: 1, color: AppColors.muted),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ResumoItem(
                  label: 'Investido',
                  valor: _formatBRLInteiro(summary.totalInvestido),
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
          const Spacer(),
          SizedBox(
            height: 40,
            child: _MiniLineChart(
              pontos: pontos,
              fallbackValue: summary.valorTotalCarteira,
              color: lucroCor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RetornoBadge extends StatelessWidget {
  final double valor;
  final Color color;

  const _RetornoBadge({required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    final icon = valor >= 0
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Container(
      height: 29,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            _formatPercent(valor),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyHighlight extends StatelessWidget {
  final double value;

  const _MoneyHighlight({required this.value});

  @override
  Widget build(BuildContext context) {
    final parts = _moneyParts(value);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: parts.prefix,
              style: const TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: parts.integer,
              style: const TextStyle(
                color: Color(0xFF152033),
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            TextSpan(
              text: ',${parts.decimals}',
              style: const TextStyle(
                color: Color(0xFFB3BBC7),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  final List<DashboardChartPointModel> pontos;
  final double fallbackValue;
  final Color color;

  const _MiniLineChart({
    required this.pontos,
    required this.fallbackValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final values = pontos.isEmpty
        ? [fallbackValue, fallbackValue]
        : pontos.map((p) => p.valor).toList(growable: false);
    final normalizedValues = values.length == 1
        ? [values.first, values.first]
        : values;
    final minValor = normalizedValues.reduce((a, b) => a < b ? a : b);
    final maxValor = normalizedValues.reduce((a, b) => a > b ? a : b);
    final diff = (maxValor - minValor).abs();
    final padding = diff == 0 ? (maxValor.abs() * 0.05 + 1) : diff * 0.22;
    final minY = (minValor - padding).clamp(0, double.infinity).toDouble();
    final maxY = maxValor + padding;
    final spots = <FlSpot>[
      for (var i = 0; i < normalizedValues.length; i++)
        FlSpot(i.toDouble(), normalizedValues[i]),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (normalizedValues.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.14),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
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
  final String nomeStartup;

  const _PosicaoCard({required this.holding, required this.nomeStartup});

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
                  nomeStartup,
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
                  holding.setor.isEmpty ? 'Setor não informado' : holding.setor,
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
  final String nomeStartup;

  const _AtividadeCard({required this.transaction, required this.nomeStartup});

  String _labelTipo(String tipoUpper) {
    if (tipoUpper.startsWith('COMPRA')) return 'Compra';
    if (tipoUpper.startsWith('VENDA')) return 'Venda';
    if (tipoUpper == 'ADICIONAR_SALDO') return 'Depósito';
    if (tipoUpper == 'SACAR_SALDO') return 'Saque';
    return transaction.tipo;
  }

  String _tituloFallback(String tipoUpper) {
    if (tipoUpper == 'ADICIONAR_SALDO' || tipoUpper == 'SACAR_SALDO') {
      return 'Saldo da carteira';
    }

    return 'Transação';
  }

  @override
  Widget build(BuildContext context) {
    final tipoUpper = transaction.tipo.toUpperCase();
    final isCompra = tipoUpper.startsWith('COMPRA');
    final isSaque = tipoUpper == 'SACAR_SALDO';
    final isDebito = isCompra || isSaque;
    final tipoExibido = _labelTipo(tipoUpper);
    final cor = isDebito ? AppColors.destructive : AppColors.success;
    final titulo = nomeStartup.trim().isEmpty
        ? _tituloFallback(tipoUpper)
        : nomeStartup.trim();
    final subtitle = <String>[
      tipoExibido,
      if (transaction.detalhes.isNotEmpty) transaction.detalhes,
      if (transaction.data.isNotEmpty) _formatarDataCurta(transaction.data),
    ].join(' · ');
    final valorExibido = isDebito
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
              isDebito ? Icons.south_west_rounded : Icons.north_east_rounded,
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
                  titulo,
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
                  subtitle,
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

class _EvolucaoLineChart extends StatefulWidget {
  final List<DashboardChartPointModel> pontos;

  const _EvolucaoLineChart({required this.pontos});

  @override
  State<_EvolucaoLineChart> createState() => _EvolucaoLineChartState();
}

class _EvolucaoLineChartState extends State<_EvolucaoLineChart> {
  double? _activeX;

  @override
  void didUpdateWidget(covariant _EvolucaoLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pontos != widget.pontos) {
      _activeX = null;
    }
  }

  void _updateActivePosition(Offset localPosition, double width) {
    if (width <= 0) return;
    final maxX = (widget.pontos.length - 1).toDouble();
    final chartMaxX = maxX < 1 ? 1.0 : maxX;
    final clampedDx = localPosition.dx.clamp(0.0, width).toDouble();
    final activeX = (clampedDx / width) * chartMaxX;

    setState(() => _activeX = activeX.clamp(0.0, maxX).toDouble());
  }

  _EvolucaoChartSample _sampleAt(
    double x,
    List<DateTime?> datas,
  ) {
    final pontos = widget.pontos;
    if (pontos.length == 1) {
      return _EvolucaoChartSample(
        x: 0,
        value: pontos.first.valor,
        date: datas.first,
      );
    }

    final lowerIndex = x.floor().clamp(0, pontos.length - 1).toInt();
    final upperIndex = x.ceil().clamp(0, pontos.length - 1).toInt();
    final lower = pontos[lowerIndex];
    final upper = pontos[upperIndex];
    final progress = upperIndex == lowerIndex ? 0.0 : x - lowerIndex;
    final value = lower.valor + ((upper.valor - lower.valor) * progress);

    final lowerDate = datas[lowerIndex];
    final upperDate = datas[upperIndex];
    DateTime? date;
    if (lowerDate != null && upperDate != null) {
      final diff =
          upperDate.millisecondsSinceEpoch - lowerDate.millisecondsSinceEpoch;
      date = lowerDate.add(Duration(milliseconds: (diff * progress).round()));
    } else {
      date = lowerDate ?? upperDate;
    }

    return _EvolucaoChartSample(x: x, value: value, date: date);
  }

  @override
  Widget build(BuildContext context) {
    final pontos = widget.pontos;
    final datas = pontos.map((p) => _parseData(p.data)).toList(growable: false);

    final spots = <FlSpot>[
      for (var i = 0; i < pontos.length; i++)
        FlSpot(i.toDouble(), pontos[i].valor),
    ];

    final valores = pontos.map((p) => p.valor).toList();
    final minValor = valores.reduce((a, b) => a < b ? a : b);
    final maxValor = valores.reduce((a, b) => a > b ? a : b);
    final folga = (maxValor - minValor).abs() * 0.15;
    final rawMinY = (minValor - folga).clamp(0, double.infinity).toDouble();
    final rawMaxY = maxValor + (folga == 0 ? maxValor * 0.15 + 1 : folga);

    final intervalY = _niceInterval(rawMaxY - rawMinY, 4);
    final minY = (rawMinY / intervalY).floor() * intervalY;
    final maxY = (rawMaxY / intervalY).ceil() * intervalY;

    final ultimoIndice = pontos.length <= 1 ? 0 : pontos.length - 1;
    final chartMaxX = ultimoIndice < 1 ? 1.0 : ultimoIndice.toDouble();
    final xLabelIndices = _selecionarIndicesEquidistantes(pontos.length, 4);

    const reservedLeft = 52.0;
    const reservedBottom = 32.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;
        final plotWidth = (totalWidth - reservedLeft).clamp(0.0, totalWidth);
        final plotHeight = (totalHeight - reservedBottom)
            .clamp(0.0, totalHeight);
        final active = _activeX == null ? null : _sampleAt(_activeX!, datas);
        final activeDx = active == null
            ? 0.0
            : (active.x / chartMaxX) * plotWidth;
        final range = (maxY - minY).abs();
        final activeDy = active == null || range == 0
            ? plotHeight / 2
            : ((maxY - active.value) / range * plotHeight)
                  .clamp(0.0, plotHeight)
                  .toDouble();
        const tooltipWidth = 112.0;
        const tooltipHeight = 54.0;
        final tooltipLeft = active == null
            ? 0.0
            : (reservedLeft + activeDx - tooltipWidth / 2)
                  .clamp(
                    0.0,
                    (totalWidth - tooltipWidth).clamp(0.0, totalWidth),
                  )
                  .toDouble();
        final tooltipTop = active == null
            ? 0.0
            : (activeDy - tooltipHeight - 12)
                  .clamp(
                    0.0,
                    (plotHeight - tooltipHeight).clamp(0.0, plotHeight),
                  )
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
                      reservedSize: reservedLeft,
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
                      reservedSize: reservedBottom,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= datas.length) {
                          return const SizedBox.shrink();
                        }
                        if (!xLabelIndices.contains(i)) {
                          return const SizedBox.shrink();
                        }
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
                lineTouchData: const LineTouchData(enabled: false),
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
            ),
            if (active != null) ...[
              Positioned(
                left: reservedLeft + activeDx,
                top: 0,
                height: plotHeight,
                child: Container(width: 1, color: const Color(0xFFD4D8DE)),
              ),
              Positioned(
                left: reservedLeft + activeDx - 4,
                top: activeDy - 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: tooltipLeft,
                top: tooltipTop,
                child: _EvolucaoChartTooltip(sample: active),
              ),
            ],
            Positioned(
              left: reservedLeft,
              top: 0,
              width: plotWidth,
              height: plotHeight,
              child: MouseRegion(
                cursor: SystemMouseCursors.precise,
                onHover: (event) =>
                    _updateActivePosition(event.localPosition, plotWidth),
                onExit: (_) => setState(() => _activeX = null),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      _updateActivePosition(details.localPosition, plotWidth),
                  onHorizontalDragStart: (details) =>
                      _updateActivePosition(details.localPosition, plotWidth),
                  onHorizontalDragUpdate: (details) =>
                      _updateActivePosition(details.localPosition, plotWidth),
                ),
              ),
            ),
          ],
        );
      },
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

  static double _niceInterval(double range, int targetSteps) {
    if (range <= 0 || targetSteps <= 0) return 1;
    final raw = range / targetSteps;
    final magnitude = math
        .pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    final normalized = raw / magnitude;

    double nice;
    if (normalized < 1.5) {
      nice = 1;
    } else if (normalized < 3) {
      nice = 2;
    } else if (normalized < 7) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
  }

  static Set<int> _selecionarIndicesEquidistantes(int total, int alvo) {
    if (total <= 0) return const {};
    if (total <= alvo) {
      return {for (var i = 0; i < total; i++) i};
    }
    final passo = (total - 1) / (alvo - 1);
    return {for (var k = 0; k < alvo; k++) (k * passo).round()};
  }
}

class _EvolucaoChartSample {
  final double x;
  final double value;
  final DateTime? date;

  const _EvolucaoChartSample({
    required this.x,
    required this.value,
    required this.date,
  });
}

class _EvolucaoChartTooltip extends StatelessWidget {
  final _EvolucaoChartSample sample;

  const _EvolucaoChartTooltip({required this.sample});

  @override
  Widget build(BuildContext context) {
    final date = sample.date;
    return Container(
      width: 112,
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
            date == null ? '—' : DateFormat('dd/MM/yyyy').format(date),
            style: const TextStyle(
              color: Color(0xFF7890A5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatarReais(sample.value),
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

String _formatBRLInteiro(double valor) {
  final negative = valor < 0;
  final intPart = valor.abs().toInt().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
    buffer.write(intPart[i]);
  }
  return '${negative ? '-' : ''}R\$ $buffer';
}

({String prefix, String integer, String decimals}) _moneyParts(double valor) {
  final negative = valor < 0;
  final abs = valor.abs().toStringAsFixed(2);
  final dotIdx = abs.indexOf('.');
  final intStr = abs.substring(0, dotIdx);
  final decStr = abs.substring(dotIdx + 1);
  final buffer = StringBuffer();
  for (int i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buffer.write('.');
    buffer.write(intStr[i]);
  }
  return (
    prefix: '${negative ? '-' : ''}R\$ ',
    integer: buffer.toString(),
    decimals: decStr,
  );
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

String _formatarDataCurta(String raw) {
  final data = DateTime.tryParse(raw)?.toLocal();
  if (data == null) return raw;

  const meses = [
    'jan.',
    'fev.',
    'mar.',
    'abr.',
    'mai.',
    'jun.',
    'jul.',
    'ago.',
    'set.',
    'out.',
    'nov.',
    'dez.',
  ];

  return '${data.day} de ${meses[data.month - 1]}';
}
