/* 
Autora: Maria Júlia Lazarini Oleto
RA: 25006031

significado do arquivo:
widget de cada operação do usuário
contém as informações principais de cada operação (compra ou venda) 
contém o nome da startup, quantidade, data e valor total da operação
*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/operacao_model.dart';

class OperacaoTile extends StatelessWidget {
  final OperacaoModel operacao;

  const OperacaoTile({
    super.key,
    required this.operacao,
  });

  // formata a data 
  String _formatarData(DateTime data) {
    final meses = [
      'jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.',
      'jul.', 'ago.', 'set.', 'out.', 'nov.', 'dez.'
    ];
    return '${data.day} de ${meses[data.month - 1]}';
  }

  // formata valores monetários 
  String _formatarValor(double valor) {
    return valor.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompra = operacao.tipo == 'compra';

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        // sombra baixa
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [

          // logo da startup com badge de tipo
          Stack(
            children: [
              // logo da startup
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    operacao.startupNome.substring(0, 2).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE91E63),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // nome + badge tipo + quantidade e data
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // badge de tipo compra/venda
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        // success para compra, destructive para venda
                        color: isCompra
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                            : const Color(0xFFF44336).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isCompra ? 'Compra' : 'Venda',
                        style: GoogleFonts.inter(
                          // tipo badge 
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isCompra
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFF44336),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // nome da startup 
                    Text(
                      operacao.startupNome,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // quantidade + data 
                Text(
                  '${operacao.quantidade} tokens · ${_formatarData(operacao.data)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF78909C),
                  ),
                ),
              ],
            ),
          ),

          // valor total da operação
          Text(
            // compra = negativo (saiu dinheiro), venda = positivo (entrou dinheiro)
            '${isCompra ? '-' : '+'}R\$ ${_formatarValor(operacao.valorTotal)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isCompra
                  ? const Color(0xFFF44336)
                  : const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}