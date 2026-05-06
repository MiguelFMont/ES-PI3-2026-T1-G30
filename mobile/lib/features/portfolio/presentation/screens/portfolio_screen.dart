/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031

significado do arquivo:
junta todos os widgets 
tela principal do portfólio
contém o resumo da carteira, suas participações e últimas operações (do usuário)
*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/storage/session_manager.dart';
import '../../data/datasource/portfolio_datasource.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../../domain/models/wallet_model.dart';
import '../widgets/saldo_card.dart';
import '../widgets/participacao_card.dart';
import '../widgets/operacao_tile.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  // instancia o repository com o datasource
  final _repository = PortfolioRepository(
    PortfolioDatasource(url do firebase),
  );

  // armazena os dados da wallet
  WalletModel? _wallet;

  // controla o estado de carregamento
  bool _isLoading = true;

  // armazena erros
  String? _erro;

  @override
  void initState() {
    super.initState();
    // carrega os dados ao abrir a tela
    _carregarDados();
  }

  // busca os dados da wallet no backend
  Future<void> _carregarDados() async {
    try {
      setState(() {
        _isLoading = true;
        _erro = null;
      });

      final uid = await SessionManager.lerUid();
      if (uid == null) {
        throw Exception('Usuário não autenticado');
      }

      final wallet = await _repository.getWallet(uid);

      setState(() {
        _wallet = wallet;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // fundo do app 
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 56,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE91E63),
                  Color(0xFFC2185B),
                ],
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
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'O que eu tenho · Visão consolidada',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // conteúdo scrollável
          Expanded(
            child: _isLoading
                // estado de carregamento
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE91E63),
                    ),
                  )
                : _erro != null
                    // estado de erro
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFF44336),
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Erro ao carregar dados',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF37474F),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // botão tentar novamente
                            TextButton(
                              onPressed: _carregarDados,
                              child: Text(
                                'Tentar novamente',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFE91E63),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    // estado com dados
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // card de saldo — sobe sobre o header
                            Transform.translate(
                              // sobe o card para sobrepor o header
                              offset: const Offset(0, -40),
                              child: SaldoCard(
                                wallet: _wallet!,
                                onNegociar: () {
                                  Navigator.pushNamed(context, '/balcao');
                                },
                              ),
                            ),

                            // minhas participações
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // título da seção
                                Text(
                                  'Minhas Participações (${_wallet!.participacoes.length})',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF37474F),
                                  ),
                                ),
                                // botão ver performance
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/dashboard');
                                  },
                                  child: Text(
                                    'Ver performance >',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE91E63),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // lista de participações
                            if (_wallet!.participacoes.isEmpty)
                              Center(
                                child: Text(
                                  'Nenhuma participação encontrada',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF78909C),
                                  ),
                                ),
                              )
                            else
                              // space-y-3 entre cards
                              ...(_wallet!.participacoes.map(
                                (participacao) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ParticipacaoCard(
                                    participacao: participacao,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/startup-detail',
                                        arguments: participacao,
                                      );
                                    },
                                  ),
                                ),
                              )),

                            const SizedBox(height: 24),

                            // últimas operações
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.receipt_long_outlined,
                                      size: 16,
                                      color: Color(0xFF37474F),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Últimas Operações',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF37474F),
                                      ),
                                    ),
                                  ],
                                ),
                                // botão ver extrato completo
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/extratos');
                                  },
                                  child: Text(
                                    'Ver extrato completo >',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE91E63),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // lista das últimas 3 operações
                            if (_wallet!.operacoes.isEmpty)
                              Center(
                                child: Text(
                                  'Nenhuma operação encontrada',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF78909C),
                                  ),
                                ),
                              )
                            else
                              ...(_wallet!.operacoes
                                  // mostra só as 3 últimas
                                  .take(3)
                                  .map((operacao) => OperacaoTile(
                                        operacao: operacao,
                                      ))),

                            const SizedBox(height: 24),

                            // botões explorar mais e ir ao balcão 
                            Row(
                              children: [
                                // botão explorar mais — secondary
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/startups');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFFFF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFECEFF1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.trending_up,
                                            size: 16,
                                            color: Color(0xFF37474F),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Explorar Mais',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF37474F),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // botão ir ao balcão — primary
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/balcao');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE91E63),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.swap_horiz,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Ir ao Balcão',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
    );
  }
}
