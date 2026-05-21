/*
Autora: Maria Júlia Lazarini Oleto
RA: 25006031
significado do arquivo:
widget do card de cada startup que o usuário possui tokens
mostra quantidade, preço médio, preço atual, valor da posição e lucro
*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/participacao_model.dart';
import '../../domain/models/startup_model.dart';

class ParticipacaoCard extends StatelessWidget {
  final ParticipacaoModel participacao;

  // startup vinculada a participação 
  final StartupModel? startup;

  // função chamada ao clicar no card — navega para o detalhe da startup
  final VoidCallback onTap;

  const ParticipacaoCard({
    super.key,
    required this.participacao,
    this.startup,
    required this.onTap,
  });

  // formata valores em reais
  String _formatarValor(double valor) {
    final partes = valor.abs().toStringAsFixed(2).split('.');
    final inteiro = partes.first.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '${valor < 0 ? '-' : ''}$inteiro,${partes.last}';
  }

  @override
  Widget build(BuildContext context) {
    final nomeStartup = startup?.nome.isNotEmpty == true
        ? startup!.nome
        : participacao.startupId;
    final segmento = startup?.estagio.isNotEmpty == true
        ? startup!.estagio
        : 'Startup';
    final precoAtual = startup?.precoAtualReais ?? participacao.precoMedio;
    final valorDaPosicao = participacao.quantidade * precoAtual;
    final lucro = valorDaPosicao - participacao.totalInvestido;
    final variacao = startup?.variacaoPercent ?? 0;
    final lucroPositivo = lucro >= 0;
    final variacaoPositiva = variacao >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // logo + nome + valorização 
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      nomeStartup.length >= 2
                          ? nomeStartup.substring(0, 2).toUpperCase()
                          : nomeStartup.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE91E63),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // nome da startup
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomeStartup,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              segmento,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF78909C),
                              ),
                            ),
                          ),
                          if (participacao.quantidadeBloqueada > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFECEFF1),
                                ),
                              ),
                              child: Text(
                                'Expansão',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF37474F),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: variacaoPositiva
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                        : const Color(0xFFF44336).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        variacaoPositiva
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 11,
                        color: variacaoPositiva
                            ? const Color(0xFF2EAD5B)
                            : const Color(0xFFF44336),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${variacao.abs().toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: variacaoPositiva
                              ? const Color(0xFF2EAD5B)
                              : const Color(0xFFF44336),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFECEFF1), height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                // tokens livres
                Expanded(
                  child: _Metrica(
                    label: 'Tokens',
                    valor: '${participacao.quantidade}',
                  ),
                ),
                const SizedBox(width: 12),
                // preço médio
                Expanded(
                  child: _Metrica(
                    label: 'Preço Médio',
                    valor: 'R\$ ${_formatarValor(participacao.precoMedio)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // valor da posição
                Expanded(
                  child: _Metrica(
                    label: 'Preço Atual',
                    valor: 'R\$ ${_formatarValor(precoAtual)}',
                  ),
                ),
                const SizedBox(width: 12),
                // valor da posição
                Expanded(
                  child: _Metrica(
                    label: 'Valor da Posição',
                    valor: 'R\$ ${_formatarValor(valorDaPosicao)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // valor total 
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: lucroPositivo
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.07)
                    : const Color(0xFFF44336).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total investido',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF78909C),
                    ),
                  ),
                  Text(
                    '${lucroPositivo ? '+' : '-'}R\$ ${_formatarValor(lucro.abs())}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: lucroPositivo
                          ? const Color(0xFF2EAD5B)
                          : const Color(0xFFF44336),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  final String label;
  final String valor;

  const _Metrica({
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF78909C),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF37474F),
          ),
        ),
      ],
    );
  }
}
