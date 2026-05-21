/*
Autora: Maria Júlia Lazarini Oleto
RA: 25006031
significado do arquivo:
widget de cada operação no histórico de transações
mostra tipo, startup, quantidade, data e valor
*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/operacao_model.dart';

class OperacaoTile extends StatelessWidget {
  final OperacaoModel operacao;

  // nome da startup
  final String? nomeStartup;

  const OperacaoTile({
    super.key,
    required this.operacao,
    this.nomeStartup,
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
    return valor.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  // retorna o label do tipo de operação em português
  String get _labelTipo {
    switch (operacao.tipo) {
      case 'COMPRA_DIRETA':
        return 'Compra';
      case 'VENDA_DIRETA':
        return 'Venda';
      case 'COMPRA_BALCAO':
        return 'Compra Balcão';
      case 'VENDA_BALCAO':
        return 'Venda Balcão';
      case 'ADICIONAR_SALDO':
        return 'Depósito';
      default:
        return operacao.tipo;
    }
  }

  // retorna a cor do tipo de operação
  Color get _corTipo {
    if (operacao.isCompra) return const Color(0xFF4CAF50);
    if (operacao.isVenda) return const Color(0xFFF44336);
    return const Color(0xFF01579B);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _corTipo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                operacao.isCompra
                    ? Icons.arrow_downward
                    : operacao.isVenda
                        ? Icons.arrow_upward
                        : Icons.add,
                color: _corTipo,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // tipo + nome startup + quantidade e data
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _corTipo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _labelTipo,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _corTipo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // nome da startup ou "saldo"
                    Text(
                      nomeStartup ?? (operacao.tipo == 'ADICIONAR_SALDO' ? 'Saldo' : operacao.startupId ?? ''),
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
                  '${operacao.quantidade != null ? '${operacao.quantidade} tokens · ' : ''}${_formatarData(operacao.createdAt)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF78909C),
                  ),
                ),
              ],
            ),
          ),
          // valor total
          Text(
            '${operacao.isCompra ? '-' : '+'}R\$ ${_formatarValor(operacao.valorTotalReais)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _corTipo,
            ),
          ),
        ],
      ),
    );
  }
}