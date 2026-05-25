// MOCK UI: esta tela entrega apenas layout + navegação.
// Todos os valores marcados com `// MOCK` abaixo devem ser substituídos
// por dados reais quando a integração com back-end for feita.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: const [
          SliverToBoxAdapter(child: _DashboardHeader()),
          SliverToBoxAdapter(child: _PortfolioResumo()),
          SliverToBoxAdapter(child: _AcoesRapidas()),
          SliverToBoxAdapter(child: _SecaoOportunidades()),
          SliverToBoxAdapter(child: _SecaoAtividades()),
          SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MOCK: nome do investidor logado
                    Text(
                      'Olá, João',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 6),
                    Text(
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
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/perfil'),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
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
            child: const Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Saldo disponível',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                // MOCK: saldo disponível em carteira
                Text(
                  'R\$ 50.000,00',
                  style: TextStyle(
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
}

class _PortfolioResumo extends StatelessWidget {
  const _PortfolioResumo();

  @override
  Widget build(BuildContext context) {
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
            // MOCK: valor total + variação percentual da carteira
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'R\$ 41.105,00',
                    style: TextStyle(
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
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '+10,45%',
                    style: TextStyle(
                      color: AppColors.success,
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
            // MOCK: breakdown de investido vs. lucro acumulado
            const Row(
              children: [
                Expanded(
                  child: _ResumoItem(
                    label: 'Investido',
                    valor: 'R\$ 37.218,00',
                    cor: AppColors.foreground,
                  ),
                ),
                Expanded(
                  child: _ResumoItem(
                    label: 'Lucro',
                    valor: '+R\$ 3.887,50',
                    cor: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
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

class _AcoesRapidas extends StatelessWidget {
  const _AcoesRapidas();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: _AcaoRapida(
              icon: Icons.rocket_launch_rounded,
              label: 'Startups',
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, '/catalog'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _AcaoRapida(
              icon: Icons.swap_horiz_rounded,
              label: 'Balcão',
              color: AppColors.accent,
              onTap: () => Navigator.pushNamed(context, '/balcao'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _AcaoRapida(
              icon: Icons.work_outline_rounded,
              label: 'Carteira',
              color: AppColors.chart4,
              onTap: () => Navigator.pushNamed(context, '/portfolio'),
            ),
          ),
        ],
      ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.muted),
        ),
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
    );
  }
}

class _SecaoOportunidades extends StatelessWidget {
  const _SecaoOportunidades();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecaoTitulo(
            titulo: 'Oportunidades em destaque',
            acao: 'Ver todas',
          ),
          const SizedBox(height: 14),
          // MOCK: lista horizontal de oportunidades em destaque
          SizedBox(
            height: 132,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _OportunidadeCard(
                  nome: 'AgriTech Pro',
                  setor: 'Agritech',
                  variacao: '+8,2%',
                  cor: AppColors.success,
                ),
                _OportunidadeCard(
                  nome: 'HealthAI',
                  setor: 'Saúde',
                  variacao: '+6,4%',
                  cor: AppColors.chart5,
                ),
                _OportunidadeCard(
                  nome: 'EducaNext',
                  setor: 'Educação',
                  variacao: '+5,1%',
                  cor: AppColors.chart4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OportunidadeCard extends StatelessWidget {
  final String nome;
  final String setor;
  final String variacao;
  final Color cor;

  const _OportunidadeCard({
    required this.nome,
    required this.setor,
    required this.variacao,
    required this.cor,
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
                style: const TextStyle(
                  color: AppColors.success,
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

class _SecaoAtividades extends StatelessWidget {
  const _SecaoAtividades();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SecaoTitulo(titulo: 'Atividade recente', acao: 'Ver extrato'),
          SizedBox(height: 14),
          // MOCK: histórico de movimentações (compra/venda de tokens)
          _AtividadeCard(
            tipo: 'Compra',
            startup: 'HealthAI',
            detalhes: '80 tokens · 02 de mar.',
            valor: '-R\$ 11.052,00',
            cor: AppColors.destructive,
          ),
          _AtividadeCard(
            tipo: 'Venda',
            startup: 'AgriTech Pro',
            detalhes: '50 tokens · 25 de fev.',
            valor: '+R\$ 4.230,00',
            cor: AppColors.success,
          ),
          _AtividadeCard(
            tipo: 'Compra',
            startup: 'EducaNext',
            detalhes: '35 tokens · 20 de fev.',
            valor: '-R\$ 2.870,00',
            cor: AppColors.destructive,
          ),
        ],
      ),
    );
  }
}

class _AtividadeCard extends StatelessWidget {
  final String tipo;
  final String startup;
  final String detalhes;
  final String valor;
  final Color cor;

  const _AtividadeCard({
    required this.tipo,
    required this.startup,
    required this.detalhes,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
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
              tipo == 'Compra'
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
                  startup,
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
                  '$tipo · $detalhes',
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
            valor,
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

  const _SecaoTitulo({
    required this.titulo,
    required this.acao,
  });

  @override
  Widget build(BuildContext context) {
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
        Text(
          acao,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
