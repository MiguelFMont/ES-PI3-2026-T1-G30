// lib/features/perfil/presentation/pages/perfil_page.dart
// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ─── Página principal ──────────────────────────────────────────────────────
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  bool _notificacoesAtivas = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  _ProfileCard(
                    nome: 'João da Silva',
                    email: 'joao.silva@puccampinas.edu.br',
                    patrimonio: 'R\$ 91.105',
                    startups: 3,
                    desde: 'Fev 2026',
                  ),

                  const SizedBox(height: 24),

                  const _SectionLabel(titulo: 'CONTA'),
                  const SizedBox(height: 8),
                  _MenuSection(
                    tiles: [
                      _MenuTileData(
                        icon: Icons.person_outline,
                        titulo: 'Informações Pessoais',
                        subtitulo: 'Nome, email, telefone',
                        onTap: () {},
                      ),
                      _MenuTileData(
                        icon: Icons.lock_outline,
                        titulo: 'Segurança e Senha',
                        subtitulo: 'Alterar senha, verificação',
                        onTap: () {},
                      ),
                      _MenuTileData(
                        icon: Icons.notifications_outlined,
                        titulo: 'Notificações',
                        subtitulo: 'Push, email, alertas de preço',
                        trailing: Switch(
                          value: _notificacoesAtivas,
                          onChanged: (v) => setState(() => _notificacoesAtivas = v),
                          activeColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const _SectionLabel(titulo: 'CARTEIRA DIGITAL'),
                  const SizedBox(height: 8),
                  _MenuSection(
                    tiles: [
                      _MenuTileData(
                        icon: Icons.account_balance_wallet_outlined,
                        titulo: 'Saldo e Depósitos',
                        subtitulo: 'Saldo: R\$ 50.000',
                        onTap: () {},
                      ),
                      _MenuTileData(
                        icon: Icons.credit_card_outlined,
                        titulo: 'Métodos de Pagamento',
                        subtitulo: 'Cartões e contas vinculadas',
                        onTap: () {},
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

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: const Text(
          'Meu Perfil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        background: Container(
          // primary (pink) → accent (navy azul) — mesma lógica visual do design
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════════════════════

// ─── Card do perfil ───────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final String nome;
  final String email;
  final String patrimonio;
  final int startups;
  final String desde;

  const _ProfileCard({
    required this.nome,
    required this.email,
    required this.patrimonio,
    required this.startups,
    required this.desde,
  });

  String get _iniciais {
    final partes = nome.trim().split(' ');
    if (partes.length >= 2) return '${partes.first[0]}${partes.last[0]}';
    return partes.first[0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(iniciais: _iniciais),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _BadgesRow(),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.muted, height: 1),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Patrimônio', valor: patrimonio),
              _StatDivider(),
              _StatItem(label: 'Startups', valor: startups.toString()),
              _StatDivider(),
              _StatItem(label: 'Desde', valor: desde),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Avatar circular com iniciais ─────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String iniciais;
  const _Avatar({required this.iniciais});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          iniciais.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─── Badges "Investidor Mescla" e "Verificado" ────────────────────────────────
class _BadgesRow extends StatelessWidget {
  const _BadgesRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Badge(
          texto: 'Investidor Mescla',
          cor: AppColors.muted,
          textoCor: AppColors.accent,
        ),
        const SizedBox(width: 6),
        _Badge(
          texto: 'Verificado',
          cor: AppColors.success.withOpacity(0.12),
          textoCor: AppColors.success,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  final Color cor;
  final Color textoCor;
  const _Badge({
    required this.texto,
    required this.cor,
    required this.textoCor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textoCor,
        ),
      ),
    );
  }
}

// ─── Item de estatística ──────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label;
  final String valor;
  const _StatItem({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.muted);
  }
}

// ─── Label de seção (ex: "CONTA") ────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String titulo;
  const _SectionLabel({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.mutedForeground,
      ),
    );
  }
}

// ─── Seção de menu agrupado ───────────────────────────────────────────────────
class _MenuTileData {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;
  final Widget? trailing;

  _MenuTileData({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    this.onTap,
    this.trailing,
  });
}

class _MenuSection extends StatelessWidget {
  final List<_MenuTileData> tiles;
  const _MenuSection({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(tiles.length, (i) {
          final isLast = i == tiles.length - 1;
          return Column(
            children: [
              _MenuTile(data: tiles[i]),
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.muted,
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Tile individual do menu ──────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final _MenuTileData data;
  const _MenuTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: data.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(data.icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        data.titulo,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
      ),
      subtitle: Text(
        data.subtitulo,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
      ),
      trailing: data.trailing ??
          const Icon(Icons.chevron_right, color: AppColors.mutedForeground, size: 20),
    );
  }
}