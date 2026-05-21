/*
Autora: Maria Júlia Lazarini Oleto
RA: 25006031
significado do arquivo:
widget do card principal da carteira
mostra o saldo disponível, valor total, investido, lucro e retorno
é compartilhado entre a tela de carteira (portfólio) e o dashboard
*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SaldoCard extends StatelessWidget {
  // saldo disponível em reais
  final double saldo;

  // valor total da carteira em reais
  final double valorTotalCarteira;

  // total investido em reais
  final double totalInvestido;

  // lucro total em reais
  final double lucroTotal;

  // retorno percentual
  final double retornoPercent;

  // função chamada ao clicar em "Negociar"
  final VoidCallback onNegociar;

  const SaldoCard({
    super.key,
    required this.saldo,
    required this.valorTotalCarteira,
    required this.totalInvestido,
    required this.lucroTotal,
    required this.retornoPercent,
    required this.onNegociar,
  });

  // formata números grandes
  String _formatarValor(double valor) {
    return valor
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final lucroPositivo = lucroTotal >= 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // saldo disponível + botão negociar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFFE91E63),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo Disponível (R\$)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF78909C),
                          ),
                        ),
                        // valor do saldo
                        Text(
                          'R\$ ${_formatarValor(saldo)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF37474F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // botão negociar
                GestureDetector(
                  onTap: onNegociar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.swap_horiz,
                          color: Color(0xFFE91E63),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Negociar',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE91E63),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFECEFF1), height: 1),
          // valor total + investido, lucro, retorno
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Valor Total em Tokens',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF78909C),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF78909C),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatarValor(valorTotalCarteira),
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF37474F),
                      ),
                    ),
                    Text(
                      ',00',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF78909C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // investido, lucro, retorno
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // investido
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INVESTIDO',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF78909C),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'R\$ ${_formatarValor(totalInvestido)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF37474F),
                          ),
                        ),
                      ],
                    ),
                    // lucro
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LUCRO',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF78909C),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lucroPositivo ? '+' : ''}R\$ ${_formatarValor(lucroTotal)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: lucroPositivo
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFF44336),
                          ),
                        ),
                      ],
                    ),
                    // retorno em porcentagem
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: lucroPositivo
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                            : const Color(0xFFF44336).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            lucroPositivo
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: lucroPositivo
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFF44336),
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${retornoPercent.toStringAsFixed(2)}%',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: lucroPositivo
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFF44336),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
