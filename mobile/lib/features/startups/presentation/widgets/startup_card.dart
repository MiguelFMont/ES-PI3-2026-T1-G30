import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../../domain/startup_model.dart';

class StartupCard extends StatelessWidget {
  // Recebe a startup e uma função de callback quando o card é tocado
  final Startup startup;
  final VoidCallback onTap;

  const StartupCard({
    super.key,
    required this.startup,
    required this.onTap,
  });

  // Retorna a cor do chip de estágio conforme o protótipo
  Color _estagioColor(String estagio) {
    switch (estagio) {
      case 'Em Expansão':
        return AppColors.stageExpansion; // roxo
      case 'Em Operação':
        return AppColors.stageOperation; // azul
      case 'Nova':
        return AppColors.stageNew; // verde
      default:
        return AppColors.mutedForeground;
    }
  }

  // Formata o capital aportado como "R$ 320k" ou "R$ 1.2M"
  String _formatarCapital(double valor) {
    if (valor >= 1000000) {
      return 'R\$ ${(valor / 1000000).toStringAsFixed(1)}M';
    } else if (valor >= 1000) {
      return 'R\$ ${(valor / 1000).toStringAsFixed(0)}k';
    }
    return 'R\$ ${valor.toStringAsFixed(0)}';
  }

  // Formata o total de tokens como "50k tokens"
  String _formatarTokens(int tokens) {
    if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(0)}k tokens';
    }
    return '$tokens tokens';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Linha superior: logo + nome + descrição
            Row(
              children: [
                // Logo da startup
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    startup.logo,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    // Fallback se a imagem não carregar
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Nome e descrição
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        startup.nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        startup.descricao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Linha do meio: chip de estágio + tokens + capital
            Row(
              children: [
                // Chip de estágio
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _estagioColor(startup.estagio).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    startup.estagio,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _estagioColor(startup.estagio),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Ícone + tokens
                Icon(Icons.toll, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatarTokens(startup.totalTokens),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),

                // Capital aportado
                if (startup.capitalAportado > 0) ...[
                  Icon(Icons.attach_money, size: 14, color: Colors.grey[500]),
                  Text(
                    _formatarCapital(startup.capitalAportado),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}