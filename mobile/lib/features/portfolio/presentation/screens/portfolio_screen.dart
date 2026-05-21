/*
Autora: Maria Julia Lazarini Oleto
RA: 25006031
significado do arquivo:
tela principal da carteira do usuario
mostra saldo, participacoes, grafico e ultimas operacoes
se conecta com o backend via repository
*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/http_client.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../shared/widgets/saldo_card.dart';
import '../../data/datasource/portfolio_datasource.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../../domain/models/startup_model.dart';
import '../../domain/models/wallet_model.dart';
import '../widgets/operacao_tile.dart';
import '../widgets/participacao_card.dart';
import '../widgets/performance_chart.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  WalletModel? _wallet;
  Map<String, StartupModel> _startupsPorId = {};
  bool _isLoading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // carrega os dados da carteira (saldo, participações e operações) e os nomes das startups
  Future<void> _carregarDados() async {
    try {
      setState(() {
        _isLoading = true;
        _erro = null;
      });

      // busca o token JWT e o uid do usuário autenticado na sessão
      final token = await SessionManager.getToken();
      final uid = await SessionManager.lerUid();

      if (token == null || uid == null) {
        throw Exception('Sessão expirada. Faça login novamente.');
      }

      // cria o repository da carteira com o datasource que tem a url do backend e o token para autenticação
      final repository = PortfolioRepository(
        PortfolioDatasource(AppHttpClient.baseUrl, token),
      );

      // pega os dados da carteira e das startups pelo repository
      final wallet = await repository.getWallet(uid);
      final startups = await repository.getStartups();

      if (!mounted) return;
      setState(() {
        _wallet = wallet;
        _startupsPorId = {for (final startup in startups) startup.id: startup};
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _isLoading = false;
      });
    }
  }

  // busca a startup pelo id
  StartupModel? _startupPorId(String? startupId) {
    if (startupId == null) return null;
    return _startupsPorId[startupId];
  }

  String? _nomeStartup(String? startupId) => _startupPorId(startupId)?.nome;

  void _mostrarEmBreve(String recurso) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$recurso em breve'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF263238),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE91E63)),
            )
          : _erro != null
          ? _ErroCarteira(onRetry: _carregarDados)
          : _PortfolioContent(
              wallet: _wallet!,
              startupPorId: _startupPorId,
              nomeStartup: _nomeStartup,
              onAcaoIndisponivel: _mostrarEmBreve,
            ),
    );
  }
}

// widget que mostra o conteúdo da carteira (saldo, participações, gráfico e operações)
// depois dos dados serem carregados com sucesso
class _PortfolioContent extends StatelessWidget {
  final WalletModel wallet;
  final StartupModel? Function(String? startupId) startupPorId;
  final String? Function(String? startupId) nomeStartup;
  // função para mostrar mensagem de recurso indisponível quando tem ações ainda não implementadas
  final void Function(String recurso) onAcaoIndisponivel;

  const _PortfolioContent({
    required this.wallet,
    required this.startupPorId,
    required this.nomeStartup,
    required this.onAcaoIndisponivel,
  });

  @override
  Widget build(BuildContext context) {
    // se não tem pontos do gráfico
    // mostra o valor total da carteira como um único ponto
    final pontosGrafico = wallet.pontosGrafico.isEmpty
        ? [wallet.valorTotalCarteira]
        : wallet.pontosGrafico;

    return Column(
      children: [
        const _PortfolioHeader(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SaldoCard(
                      saldo: wallet.saldo,
                      valorTotalCarteira: wallet.valorTotalCarteira,
                      totalInvestido: wallet.totalInvestido,
                      lucroTotal: wallet.lucroTotal,
                      retornoPercent: wallet.retornoPercent,
                      onNegociar: () => onAcaoIndisponivel('Balcão'),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SecaoTitulo(
                          titulo:
                              'Minhas Participações (${wallet.participacoes.length})',
                          acao: 'Ver performance',
                          onAcao: () => onAcaoIndisponivel('Performance'),
                        ),
                        const SizedBox(height: 12),
                        if (wallet.participacoes.isEmpty)
                          const _EmptyState('Nenhuma participação encontrada')
                        else
                          ...wallet.participacoes.map(
                            (participacao) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ParticipacaoCard(
                                participacao: participacao,
                                startup: startupPorId(participacao.startupId),
                                onTap: () =>
                                    onAcaoIndisponivel('Detalhe da startup'),
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        PerformanceChart(pontos: pontosGrafico),
                        const SizedBox(height: 24),
                        _SecaoTitulo(
                          titulo: 'Últimas Operações',
                          icone: Icons.receipt_long_outlined,
                          acao: 'Ver extrato completo',
                          onAcao: () => onAcaoIndisponivel('Extrato'),
                        ),
                        const SizedBox(height: 12),
                        if (wallet.operacoes.isEmpty)
                          const _EmptyState('Nenhuma operação encontrada')
                        else
                          ...wallet.operacoes
                              .take(3)
                              .map(
                                (operacao) => OperacaoTile(
                                  operacao: operacao,
                                  nomeStartup: nomeStartup(operacao.startupId),
                                ),
                              ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _BotaoPortfolio(
                                label: 'Explorar Mais',
                                icon: Icons.trending_up,
                                outlined: true,
                                onTap: () => onAcaoIndisponivel('Catálogo'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _BotaoPortfolio(
                                label: 'Ir ao Balcão',
                                icon: Icons.swap_horiz,
                                onTap: () => onAcaoIndisponivel('Balcão'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// widget do cabeçalho da carteira (header)
class _PortfolioHeader extends StatelessWidget {
  const _PortfolioHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 56, left: 24, right: 24, bottom: 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minha Carteira',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'O que eu tenho · Visão consolidada',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

// widget que mostra o título de cada seção
class _SecaoTitulo extends StatelessWidget {
  final String titulo;
  final IconData? icone;
  // texto to botão de ação
  final String acao;
  // função chamada quando clica no botão da ação
  final VoidCallback onAcao;

  const _SecaoTitulo({
    required this.titulo,
    this.icone,
    required this.acao,
    required this.onAcao,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icone != null) ...[
          Icon(icone, size: 16, color: const Color(0xFF78909C)),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            titulo,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF607D8B),
            ),
          ),
        ),
        // opção (ação) de cada seção (ex: ver performance)
        InkWell(
          onTap: onAcao,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Text(
                  acao,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Color(0xFFE91E63),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// botões de explorar mais e ir ao balcão que estão no final da tela
class _BotaoPortfolio extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool outlined;
  final VoidCallback onTap;

  const _BotaoPortfolio({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = outlined ? const Color(0xFF263238) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: outlined ? Colors.white : const Color(0xFFE91E63),
          borderRadius: BorderRadius.circular(14),
          border: outlined ? Border.all(color: const Color(0xFFECEFF1)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: foreground),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// se o estado está vazio - ainda não tem participações ou operações
class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF78909C),
          ),
        ),
      ),
    );
  }
}

// mostra erro quando tem falha ao carregar
class _ErroCarteira extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErroCarteira({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFF44336), size: 48),
          const SizedBox(height: 12),
          Text(
            'Erro ao carregar dados',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Tentar novamente',
              style: GoogleFonts.inter(
                color: const Color(0xFFE91E63),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
