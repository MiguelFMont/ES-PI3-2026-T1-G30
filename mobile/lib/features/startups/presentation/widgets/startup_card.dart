import 'package:flutter/material.dart';
import 'package:mesclainvest/core/theme/app_colors.dart';

import '../../domain/startup_model.dart';

class StartupCard extends StatelessWidget {
  final Startup startup;
  final VoidCallback onTap;

  const StartupCard({super.key, required this.startup, required this.onTap});

  Color _estagioColor(String estagio) {
    switch (estagio) {
      case 'Em Expansão':
      case 'Em Expansao':
        return AppColors.stageExpansion;
      case 'Em Operação':
      case 'Em Operacao':
        return AppColors.stageOperation;
      case 'Nova':
        return AppColors.stageNew;
      default:
        return AppColors.mutedForeground;
    }
  }

  String _estagioLabel(String estagio) {
    switch (estagio) {
      case 'Em Expansão':
      case 'Em Expansao':
        return 'Expansão';
      case 'Em Operação':
      case 'Em Operacao':
        return 'Operação';
      default:
        return estagio;
    }
  }

  String _formatarCapital(double valor) {
    if (valor >= 1000000) {
      return 'R\$ ${(valor / 1000000).toStringAsFixed(1)}M';
    } else if (valor >= 1000) {
      return 'R\$ ${(valor / 1000).toStringAsFixed(0)}k';
    }
    return 'R\$ ${valor.toStringAsFixed(0)}';
  }

  String _formatarTokens(int tokens) {
    if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(0)}k';
    }
    return '$tokens';
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = _estagioColor(startup.estagio);
    final isPositive = (startup.variacaoPreco ?? 0) >= 0;
    final variacaoColor = isPositive
        ? AppColors.success
        : AppColors.destructive;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        startup.investido ? 80 : 16,
                        0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLogo(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  startup.nome,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  startup.descricao,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildEstagioChip(stageColor),
                          if (startup.setor.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                startup.setor,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          const Text(
                            '·',
                            style: TextStyle(color: AppColors.mutedForeground),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.toll_rounded,
                            size: 13,
                            color: AppColors.mutedForeground,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${_formatarTokens(startup.tokensDisponiveis)} disponíveis',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          if (startup.capitalAportado > 0) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.attach_money_rounded,
                              size: 13,
                              color: AppColors.mutedForeground,
                            ),
                            Text(
                              _formatarCapital(startup.capitalAportado),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Preço por token',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  startup.precoToken > 0
                                      ? 'R\$ ${startup.precoToken.toStringAsFixed(2)}'
                                      : 'Indisponível',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (startup.variacaoPreco != null)
                            _buildVariacaoBadge(isPositive, variacaoColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (startup.investido)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'INVESTIDO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        startup.logo,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.business_rounded,
            color: AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }

  Widget _buildEstagioChip(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _estagioLabel(startup.estagio),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildVariacaoBadge(bool isPositive, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.north_east_rounded : Icons.south_east_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${startup.variacaoPreco!.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
