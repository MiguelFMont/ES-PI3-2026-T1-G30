/*
Autora: Maria Julia Lazarini Oleto
RA: 25006031

significado do arquivo:
card com grafico de evolução da carteira
usa pontos vindos do endpoint de dashboard da wallet
*/

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PerformanceChart extends StatefulWidget {
  final List<double> pontos;

  const PerformanceChart({super.key, required this.pontos});

  @override
  State<PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<PerformanceChart> {
  String _filtroSelecionado = '1M';

  final List<String> _filtros = const ['1D', '1W', '1M', '6M', 'YTD'];

  // valores que vão ser exibidos no gráfico
  List<double> get _valores {
    final pontos = widget.pontos;
    // se não tem pontos - linha plana
    if (pontos.isEmpty) return const [0, 0, 0, 0, 0];
    // se tem um só ponto - linha plana do valor do ponto
    if (pontos.length == 1) return [pontos.first, pontos.first];

    // limita a quantidade de pontos exibidos, baseado no filtro selecionado
    final limite = switch (_filtroSelecionado) {
      '1D' => 2,
      '1W' => 7,
      '1M' => 30,
      '6M' => 180,
      _ => pontos.length,
    };

    if (pontos.length <= limite) return pontos;
    // retorna apenas os últimos pontos, baseado no limite do filtro
    return pontos.sublist(pontos.length - limite);
  }

  // converte os valores em FlSpot para o gráfico
  // f1spot - integra as coordenads x e y do gráfico, em cada ponto
  List<FlSpot> get _spots => _valores
      .asMap()
      .entries
      .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
      .toList();

  double get _minY {
    final min = _valores.reduce((a, b) => a < b ? a : b);
    if (min == 0) return 0;
    return min * 0.85;
  }

  double get _maxY {
    final max = _valores.reduce((a, b) => a > b ? a : b);
    if (max == 0) return 100;
    return max * 1.15;
  }

  // formata o valor do eixo Y para exibir em reais, usando k para milhares
  String _formatarEixo(double valor) {
    if (valor >= 1000) {
      return 'R\$ ${(valor / 1000).toStringAsFixed(0)}k';
    }
    return 'R\$ ${valor.toStringAsFixed(0)}';
  }

  // formata o valor do tooltip para exibir em reais
  Widget _bottomTitle(double value, TitleMeta meta) {
    final index = value.toInt();
    final lastIndex = _spots.length - 1;
    if (index != 0 && index != lastIndex && index != lastIndex ~/ 2) {
      return const SizedBox.shrink();
    }

    final label = switch (index) {
      0 => '25/04',
      _ when index == lastIndex ~/ 2 => '07/05',
      _ => '20/05',
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF78909C)),
      ),
    );
  }

  // calcula o intervalo entre as linhas horizontais 
  double get _intervalo {
    final diff = _maxY - _minY;
    if (diff == 0) return 1;
    return diff / 4;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFFE91E63),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Evolução da Carteira',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF263238),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (_spots.length - 1).toDouble(),
                minY: _minY,
                maxY: _maxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    tooltipBorder: const BorderSide(color: Color(0xFFECEFF1)),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (spots) => spots
                        .map(
                          (spot) => LineTooltipItem(
                            _formatarEixo(spot.y),
                            GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF263238),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _intervalo,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFECEFF1), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: _intervalo,
                      getTitlesWidget: (value, meta) => Text(
                        _formatarEixo(value),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF78909C),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: _bottomTitle,
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    isCurved: true,
                    color: const Color(0xFFFF4D57),
                    barWidth: 2.4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF4D57).withValues(alpha: 0.18),
                          const Color(0xFFFF4D57).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _filtros.map((filtro) {
              final selecionado = filtro == _filtroSelecionado;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setState(() => _filtroSelecionado = filtro),
                    child: Container(
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selecionado
                            ? const Color(0xFFE91E63)
                            : const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        filtro,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selecionado
                              ? Colors.white
                              : const Color(0xFF78909C),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
