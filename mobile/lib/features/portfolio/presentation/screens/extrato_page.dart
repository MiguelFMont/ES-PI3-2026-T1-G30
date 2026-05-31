// Autor: Gabriel Martins de Almeida
// RA: 25006162

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/http_client.dart';
import '../../../../core/storage/session_manager.dart';
import '../../data/datasource/portfolio_datasource.dart';
import '../../domain/models/operacao_model.dart';
import '../../domain/models/startup_model.dart';

class ExtratoPage extends StatefulWidget {
  const ExtratoPage({super.key});

  @override
  State<ExtratoPage> createState() => _ExtratoPageState();
}

class _ExtratoPageState extends State<ExtratoPage> {
  late Future<_ExtratoData> _extratoFuture;
  String _periodoSelecionado = 'Tudo';
  String _tipoSelecionado = 'Todas';

  @override
  void initState() {
    super.initState();
    _extratoFuture = _carregarExtrato();
  }

  Future<_ExtratoData> _carregarExtrato() async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    final datasource = PortfolioDatasource(AppHttpClient.baseUrl, token);
    final operacoes = await datasource.getTransactions();
    final startups = await _carregarStartups(datasource);

    return _ExtratoData(
      operacoes: operacoes,
      startupsPorId: {for (final startup in startups) startup.id: startup},
    );
  }

  Future<List<StartupModel>> _carregarStartups(
    PortfolioDatasource datasource,
  ) async {
    try {
      return await datasource.getStartups();
    } catch (_) {
      return const [];
    }
  }

  void _recarregar() {
    setState(() {
      _extratoFuture = _carregarExtrato();
    });
  }

  List<OperacaoModel> _filtrarOperacoes(List<OperacaoModel> operacoes) {
    final agora = DateTime.now();
    final filtradas = operacoes.where((operacao) {
      final dentroDoPeriodo = switch (_periodoSelecionado) {
        '7 dias' => operacao.createdAt.isAfter(
          agora.subtract(const Duration(days: 7)),
        ),
        '30 dias' => operacao.createdAt.isAfter(
          agora.subtract(const Duration(days: 30)),
        ),
        '90 dias' => operacao.createdAt.isAfter(
          agora.subtract(const Duration(days: 90)),
        ),
        _ => true,
      };

      final bateTipo = switch (_tipoSelecionado) {
        'Compras' => operacao.isCompra,
        'Vendas' => operacao.isVenda,
        _ => true,
      };

      return dentroDoPeriodo && bateTipo;
    }).toList();

    filtradas.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtradas;
  }

  List<_ExtratoRow> _buildRows(_ExtratoData data) {
    final operacoesFiltradas = _filtrarOperacoes(data.operacoes);
    final rows = <_ExtratoRow>[
      _ResumoRow(operacoesFiltradas),
      const _PeriodoFiltrosRow(),
      const _TipoFiltrosRow(),
    ];

    if (operacoesFiltradas.isEmpty) {
      rows.add(const _EmptyRow());
      return rows;
    }

    String? dataAtual;
    for (final operacao in operacoesFiltradas) {
      final dataLabel = _formatDateHeader(operacao.createdAt);
      if (dataAtual != dataLabel) {
        dataAtual = dataLabel;
        rows.add(_DataHeaderRow(dataLabel));
      }
      rows.add(_OperacaoRow(operacao));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(132),
        child: _ExtratoAppBar(onBack: () => Navigator.maybePop(context)),
      ),
      body: FutureBuilder<_ExtratoData>(
        future: _extratoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE91E63)),
            );
          }

          if (snapshot.hasError) {
            return _ErroExtrato(onRetry: _recarregar);
          }

          final data = snapshot.data ?? const _ExtratoData();
          final rows = _buildRows(data);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];

              if (row is _ResumoRow) {
                return _ResumoCards(operacoes: row.operacoes);
              }

              if (row is _PeriodoFiltrosRow) {
                return _PeriodoFiltros(
                  selecionado: _periodoSelecionado,
                  onChanged: (periodo) {
                    setState(() => _periodoSelecionado = periodo);
                  },
                );
              }

              if (row is _TipoFiltrosRow) {
                return _TipoFiltros(
                  selecionado: _tipoSelecionado,
                  onChanged: (tipo) {
                    setState(() => _tipoSelecionado = tipo);
                  },
                );
              }

              if (row is _DataHeaderRow) {
                return _DataHeader(label: row.label);
              }

              if (row is _OperacaoRow) {
                return _OperacaoCard(
                  operacao: row.operacao,
                  nomeStartup: data.startupsPorId[row.operacao.startupId]?.nome,
                );
              }

              return const _ExtratoEmptyState();
            },
          );
        },
      ),
      bottomNavigationBar: const _ExtratoBottomNav(),
    );
  }
}

class _ExtratoAppBar extends StatelessWidget {
  const _ExtratoAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -24,
            right: -54,
            bottom: -18,
            child: Transform.rotate(
              angle: 0.22,
              child: Container(
                width: 190,
                color: const Color(0xFF4B235E).withValues(alpha: 0.32),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Voltar',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Extrato de Operações',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumoCards extends StatelessWidget {
  const _ResumoCards({required this.operacoes});

  final List<OperacaoModel> operacoes;

  @override
  Widget build(BuildContext context) {
    final totalComprado = operacoes
        .where((operacao) => operacao.isCompra)
        .fold<double>(0, (total, operacao) => total + operacao.valorTotalReais);
    final totalVendido = operacoes
        .where((operacao) => operacao.isVenda)
        .fold<double>(0, (total, operacao) => total + operacao.valorTotalReais);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: _ResumoCard(
              label: 'TOTAL COMPRADO',
              value: _formatReais(totalComprado, centavos: false),
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ResumoCard(
              label: 'TOTAL VENDIDO',
              value: _formatReais(totalVendido, centavos: false),
              color: const Color(0xFFF44336),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  const _ResumoCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF8CA0B3),
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodoFiltros extends StatelessWidget {
  const _PeriodoFiltros({required this.selecionado, required this.onChanged});

  final String selecionado;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filtros = ['Tudo', '7 dias', '30 dias', '90 dias'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: filtros.map((filtro) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: filtro == filtros.last ? 0 : 8),
              child: _FiltroChip(
                label: filtro,
                selected: selecionado == filtro,
                selectedColor: const Color(0xFFE91E63),
                onTap: () => onChanged(filtro),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TipoFiltros extends StatelessWidget {
  const _TipoFiltros({required this.selecionado, required this.onChanged});

  final String selecionado;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filtros = ['Todas', 'Compras', 'Vendas'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: filtros.map((filtro) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FiltroChip(
              label: filtro,
              selected: selecionado == filtro,
              selectedColor: const Color(0xFF263238),
              minWidth: filtro == 'Todas' ? 52 : 74,
              onTap: () => onChanged(filtro),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
    this.minWidth,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 28,
        constraints: BoxConstraints(minWidth: minWidth ?? 0),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? selectedColor : const Color(0xFFEFF2F5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : const Color(0xFF78909C),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DataHeader extends StatelessWidget {
  const _DataHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 9),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 13,
            color: Color(0xFF78909C),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF607D8B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OperacaoCard extends StatelessWidget {
  const _OperacaoCard({required this.operacao, this.nomeStartup});

  final OperacaoModel operacao;
  final String? nomeStartup;

  @override
  Widget build(BuildContext context) {
    final isCompra = operacao.isCompra;
    final isVenda = operacao.isVenda;
    final statusColor = isCompra
        ? const Color(0xFFF44336)
        : isVenda
        ? const Color(0xFF4CAF50)
        : const Color(0xFF01579B);
    final totalPrefix = isVenda
        ? '+'
        : isCompra
        ? '-'
        : '+';
    final totalColor = isVenda
        ? const Color(0xFF4CAF50)
        : isCompra
        ? const Color(0xFF263238)
        : const Color(0xFF01579B);

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: Color(0xFFE91E63),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _nomeOperacao,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF263238),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _TipoBadge(
                              label: isCompra
                                  ? 'Compra'
                                  : isVenda
                                  ? 'Venda'
                                  : 'Saldo',
                              color: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatHora(operacao.createdAt),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF607D8B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Divider(height: 1, color: Color(0xFFECEFF1)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _OperacaoInfo(
                      label: 'Quantidade',
                      value: operacao.quantidade == null
                          ? '-'
                          : '${operacao.quantidade} tokens',
                    ),
                  ),
                  Expanded(
                    child: _OperacaoInfo(
                      label: 'Preço Unit.',
                      value: operacao.precoUnitarioCentavos == null
                          ? '-'
                          : _formatReais(operacao.precoUnitarioReais),
                    ),
                  ),
                  Expanded(
                    child: _OperacaoInfo(
                      label: 'Total',
                      value:
                          '$totalPrefix ${_formatReais(operacao.valorTotalReais)}',
                      alignEnd: true,
                      color: totalColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '✓ Executada',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF4CAF50),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
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

  String get _nomeOperacao {
    final nome = nomeStartup?.trim();
    if (nome != null && nome.isNotEmpty) return nome;
    if (operacao.startupId != null && operacao.startupId!.isNotEmpty) {
      return operacao.startupId!;
    }
    return operacao.tipo == 'ADICIONAR_SALDO' ? 'Saldo' : 'Operação';
  }
}

class _TipoBadge extends StatelessWidget {
  const _TipoBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OperacaoInfo extends StatelessWidget {
  const _OperacaoInfo({
    required this.label,
    required this.value,
    this.alignEnd = false,
    this.color = const Color(0xFF263238),
  });

  final String label;
  final String value;
  final bool alignEnd;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF8CA0B3),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _ExtratoEmptyState extends StatelessWidget {
  const _ExtratoEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          'Nenhuma operação encontrada',
          style: GoogleFonts.inter(
            color: const Color(0xFF78909C),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ErroExtrato extends StatelessWidget {
  const _ErroExtrato({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFF44336), size: 44),
          const SizedBox(height: 10),
          Text(
            'Erro ao carregar extrato',
            style: GoogleFonts.inter(
              color: const Color(0xFF37474F),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Tentar novamente',
              style: GoogleFonts.inter(
                color: const Color(0xFFE91E63),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtratoBottomNav extends StatelessWidget {
  const _ExtratoBottomNav();

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(Icons.grid_view_outlined, 'Dashboard', 0, false),
      _NavItem(Icons.rocket_launch_outlined, 'Startups', 2, false),
      _NavItem(Icons.swap_horiz_rounded, 'Balcão', 3, false),
      _NavItem(Icons.business_center_outlined, 'Portfólio', 1, true),
      _NavItem(Icons.person_outline, 'Perfil', 4, false),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: items
                .map(
                  (item) => Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        '/main',
                        arguments: item.index,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: item.selected
                                ? const Color(0xFF607D8B)
                                : const Color(0xFF78909C),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: item.selected
                                  ? const Color(0xFF607D8B)
                                  : const Color(0xFF78909C),
                              fontSize: 10,
                              fontWeight: item.selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ExtratoData {
  const _ExtratoData({
    this.operacoes = const [],
    this.startupsPorId = const {},
  });

  final List<OperacaoModel> operacoes;
  final Map<String, StartupModel> startupsPorId;
}

sealed class _ExtratoRow {
  const _ExtratoRow();
}

class _ResumoRow extends _ExtratoRow {
  const _ResumoRow(this.operacoes);

  final List<OperacaoModel> operacoes;
}

class _PeriodoFiltrosRow extends _ExtratoRow {
  const _PeriodoFiltrosRow();
}

class _TipoFiltrosRow extends _ExtratoRow {
  const _TipoFiltrosRow();
}

class _DataHeaderRow extends _ExtratoRow {
  const _DataHeaderRow(this.label);

  final String label;
}

class _OperacaoRow extends _ExtratoRow {
  const _OperacaoRow(this.operacao);

  final OperacaoModel operacao;
}

class _EmptyRow extends _ExtratoRow {
  const _EmptyRow();
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.index, this.selected);

  final IconData icon;
  final String label;
  final int index;
  final bool selected;
}

String _formatReais(double valor, {bool centavos = true}) {
  final negative = valor < 0;
  final fixed = valor.abs().toStringAsFixed(centavos ? 2 : 0);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts.length > 1 ? parts[1] : '00';
  final buffer = StringBuffer();

  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(intPart[i]);
  }

  final decimal = centavos ? ',$decPart' : '';
  return '${negative ? '-' : ''}R\$ $buffer$decimal';
}

String _formatHora(DateTime data) {
  final hour = data.hour.toString().padLeft(2, '0');
  final minute = data.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatDateHeader(DateTime data) {
  const meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  final mes = meses[data.month - 1];
  final dia = data.day.toString().padLeft(2, '0');
  return '$dia de $mes de ${data.year}';
}
