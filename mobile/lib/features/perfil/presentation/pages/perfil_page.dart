// lib/features/perfil/presentation/pages/perfil_page.dart
// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/perfil_repository.dart';
import '../../domain/perfil_models.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  bool _notificacoesAtivas = true;
  final _repo = PerfilRepository();
  late Future<PerfilModel> _perfilFuture;

  static const double _cardOverlap = 48.0;

  @override
  void initState() {
    super.initState();
    _perfilFuture = _repo.buscarPerfil();
  }

  void _recarregarPerfil() {
    setState(() => _perfilFuture = _repo.buscarPerfil());
  }

  Future<void> _abrirDepositoDialog() async {
    final controller = TextEditingController();
    final valorDigitado = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar saldo'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor em reais',
              hintText: 'Ex: 150.00',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (valorDigitado == null) return;

    final valor = double.tryParse(valorDigitado.trim().replaceAll(',', '.'));
    if (valor == null || valor <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor monetário válido.')),
      );
      return;
    }

    try {
      await _repo.adicionarSaldo(valor);
      if (!mounted) return;

      _recarregarPerfil();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saldo adicionado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(' ');
    if (partes.length >= 2) return '${partes.first[0]}${partes.last[0]}';
    return partes.first[0];
  }

  String _formatarCentavos(int valorEmCentavos) {
    final valorAbsoluto = valorEmCentavos.abs();
    final reais = valorAbsoluto ~/ 100;
    final centavos = valorAbsoluto % 100;
    final partes = reais.toString().split('');
    final buffer = StringBuffer();
    int count = 0;

    for (int i = partes.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(partes[i]);
      count++;
    }

    final prefixo = valorEmCentavos < 0 ? '-R\$ ' : 'R\$ ';
    final reaisFormatados = buffer.toString().split('').reversed.join();
    return '$prefixo$reaisFormatados,${centavos.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      extendBodyBehindAppBar: true,
      body: FutureBuilder<PerfilModel>(
        future: _perfilFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return _buildErro(snapshot.error.toString());
          }
          return _buildScrollContent(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildScrollContent(PerfilModel data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradiente + título rolam junto com o conteúdo
          _buildGradientHeader(),

          // Card e seções sobem sobre o gradiente via translate negativo
          Transform.translate(
            offset: const Offset(0, -_cardOverlap),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(data),
                  const SizedBox(height: 24),
                  _buildSectionLabel('CONTA'),
                  const SizedBox(height: 8),
                  _buildMenuSection([
                    _buildMenuTile(
                      icon: Icons.person_outline,
                      titulo: 'Informações Pessoais',
                      subtitulo: 'Nome, email, telefone',
                      onTap: () {},
                    ),
                    _buildMenuTile(
                      icon: Icons.lock_outline,
                      titulo: 'Segurança e Senha',
                      subtitulo: 'Alterar senha, verificação',
                      onTap: () {},
                    ),
                    _buildMenuTile(
                      icon: Icons.notifications_outlined,
                      titulo: 'Notificações',
                      subtitulo: 'Push, email, alertas de preço',
                      trailing: Switch(
                        value: _notificacoesAtivas,
                        onChanged: (v) =>
                            setState(() => _notificacoesAtivas = v),
                        activeColor: AppColors.primary,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionLabel('CARTEIRA DIGITAL'),
                  const SizedBox(height: 8),
                  _buildMenuSection([
                    _buildMenuTile(
                      icon: Icons.account_balance_wallet_outlined,
                      titulo: 'Saldo e Depósitos',
                      subtitulo:
                          'Saldo: ${_formatarCentavos(data.saldoCentavos)}',
                      onTap: _abrirDepositoDialog,
                    ),
                    _buildMenuTile(
                      icon: Icons.credit_card_outlined,
                      titulo: 'Métodos de Pagamento',
                      subtitulo: 'Cartões e contas vinculadas',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: _cardOverlap + 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader() {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      height: statusBarHeight + 160,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.55, 0.55],
          colors: [AppColors.primary, Color(0xFFE92C6B)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: statusBarHeight + 8,
          left: 24,
          bottom: _cardOverlap + 8,
        ),
        child: const Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            'Meu Perfil',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 26,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErro(String mensagem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              color: AppColors.mutedForeground,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              onPressed: _recarregarPerfil,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(PerfilModel data) {
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
              _buildAvatar(data.nome),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildBadge(
                texto: 'Investidor Mescla',
                cor: AppColors.muted,
                textoCor: AppColors.accent,
              ),
              const SizedBox(width: 6),
              _buildBadge(

                // TODO: Criar uma função que verifica se o usuario tem MFA ativo
                // se tiver → badge 
                //texto: verificado,
                //cor: sucess 
                texto: 'Não Verificado',
                cor: AppColors.destructive.withOpacity(0.12),
                textoCor: AppColors.destructive,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // linha de separar as informações
          const Divider(color: AppColors.muted, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                label: 'Patrimônio',
                valor: _formatarCentavos(data.patrimonioCentavos),
              ),
              Container(width: 1, height: 32, color: AppColors.muted),
              _buildStatItem(
                label: 'Startups',
                valor: data.totalStartups.toString(),
              ),
              Container(width: 1, height: 32, color: AppColors.muted),
              _buildStatItem(label: 'Desde', valor: data.desde),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String nome) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: Center(
        child: Text(
          _iniciais(nome).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String texto,
    required Color cor,
    required Color textoCor,
  }) {
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

  Widget _buildStatItem({required String label, required String valor}) {
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

  Widget _buildSectionLabel(String titulo) {
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

  Widget _buildMenuSection(List<Widget> tiles) {
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
              tiles[i],
              if (!isLast)
                const Divider(height: 1, indent: 56, color: AppColors.muted),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        titulo,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
      ),
      subtitle: Text(
        subtitulo,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
      ),
      trailing:
          trailing ??
          const Icon(
            Icons.chevron_right,
            color: AppColors.mutedForeground,
            size: 20,
          ),
    );
  }
}
