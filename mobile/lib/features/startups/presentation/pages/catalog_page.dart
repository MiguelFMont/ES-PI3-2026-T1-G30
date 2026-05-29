import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mesclainvest/app/routes.dart';
import 'package:mesclainvest/core/state/app_data_refresh_bus.dart';
import 'package:mesclainvest/core/theme/app_colors.dart';

import '../../data/startup_service.dart';
import '../../domain/startup_model.dart';
import '../widgets/startup_card.dart';

enum CatalogState { loading, error, success }

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final StartupService _service = StartupService();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<AppDataRefreshEvent>? _refreshSubscription;

  List<Startup> _startups = [];
  CatalogState _state = CatalogState.loading;
  String? _errorMessage;

  String? _selectedStage;
  final Set<String> _selectedSectors = {};
  String _sortBy = 'recentes';

  static const List<String> _stageOptions = [
    'Nova',
    'Em Operação',
    'Em Expansão',
  ];

  List<String> get _availableSectorOptions {
    final sectors = _startups
        .map((startup) => startup.setor.trim())
        .where((sector) => sector.isNotEmpty)
        .toSet()
        .toList();

    sectors.sort();
    return sectors;
  }

  // Backend tem duplicatas; colapsamos por assinatura funcional até a limpeza.
  String _catalogKey(Startup startup) {
    final nomeNormalizado = startup.nome.trim().toLowerCase();
    if (nomeNormalizado.isNotEmpty) return nomeNormalizado;

    return [
      startup.descricao.trim().toLowerCase(),
      startup.estagio.trim().toLowerCase(),
    ].join('|');
  }

  int _catalogScore(Startup startup) {
    var score = 0;

    if (startup.nome.trim().isNotEmpty) score += 100;
    if (startup.descricao.trim().isNotEmpty) score += 20;
    if (startup.estagio.trim().isNotEmpty) score += 15;
    if (startup.setor.trim().isNotEmpty) score += 10;
    if (startup.logo.trim().isNotEmpty) score += 10;
    if (startup.resumoExecutivo.trim().isNotEmpty) score += 15;
    if (startup.totalTokens > 0) score += 20;
    if (startup.tokensDisponiveis >= 0) score += 24;
    if (startup.tokensDisponiveis > 0 &&
        startup.tokensDisponiveis != startup.totalTokens) {
      score += 8;
    }
    if (startup.precoToken > 0) score += 20;
    if (startup.variacaoPreco != null) score += 6;
    if (startup.socios.isNotEmpty) score += 10;
    if (startup.conselho.isNotEmpty) score += 6;
    if (startup.mentores.isNotEmpty) score += 6;
    if (startup.videos.isNotEmpty) score += 4;
    if (startup.atualizacoes.isNotEmpty) score += 4;

    return score;
  }

  Startup _preferCatalogStartup(Startup current, Startup candidate) {
    final currentScore = _catalogScore(current);
    final candidateScore = _catalogScore(candidate);

    if (candidateScore > currentScore) return candidate;
    return current;
  }

  @override
  void initState() {
    super.initState();
    _refreshSubscription = AppDataRefreshBus.instance.stream.listen((event) {
      if (!event.affects(AppDataRefreshScope.catalog) || !mounted) {
        return;
      }

      _fetchStartups(showLoading: false);
    });
    _fetchStartups();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStartups({bool showLoading = true}) async {
    if (showLoading || _startups.isEmpty) {
      setState(() {
        _state = CatalogState.loading;
        _errorMessage = null;
        _startups = [];
      });
    }

    try {
      final startups = await _service.listarStartups(estagio: _selectedStage);
      final uniqueStartupsByKey = <String, Startup>{};
      for (final startup in startups) {
        final key = _catalogKey(startup);
        final current = uniqueStartupsByKey[key];
        uniqueStartupsByKey[key] = current == null
            ? startup
            : _preferCatalogStartup(current, startup);
      }
      final uniqueStartups = uniqueStartupsByKey.values.toList();
      final availableSectors = uniqueStartups
          .map((startup) => startup.setor.trim())
          .where((sector) => sector.isNotEmpty)
          .toSet();

      if (!mounted) return;
      setState(() {
        _startups = uniqueStartups;
        _selectedSectors.removeWhere(
          (sector) => !availableSectors.contains(sector),
        );
        _state = CatalogState.success;
      });
    } catch (e) {
      if (!mounted) return;
      if (!showLoading && _startups.isNotEmpty) {
        debugPrint('Erro ao atualizar catálogo em segundo plano: $e');
        return;
      }

      setState(() {
        _errorMessage = e is StartupApiException
            ? e.message
            : 'Não foi possível carregar as startups agora.';
        _state = CatalogState.error;
      });
    }
  }

  List<Startup> get _filteredStartups {
    var list = List<Startup>.from(_startups);

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where(
            (s) =>
                s.nome.toLowerCase().contains(query) ||
                (s.setor.isNotEmpty && s.setor.toLowerCase().contains(query)),
          )
          .toList();
    }

    if (_selectedSectors.isNotEmpty) {
      list = list.where((s) => _selectedSectors.contains(s.setor)).toList();
    }

    if (_sortBy == 'preco') {
      list.sort((a, b) => b.precoToken.compareTo(a.precoToken));
    }

    return list;
  }

  int get _activeFilterCount {
    var count = _selectedSectors.length;
    if (_selectedStage != null) count++;
    if (_sortBy != 'recentes') count++;
    return count;
  }

  void _onStartupTapped(Startup startup) {
    Navigator.pushNamed(context, AppRoutes.startupDetail, arguments: startup);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        selectedStage: _selectedStage,
        selectedSectors: Set.of(_selectedSectors),
        sortBy: _sortBy,
        stageOptions: _stageOptions,
        sectorOptions: _availableSectorOptions,
        onApply: (stage, sectors, sortBy) {
          final stageChanged = stage != _selectedStage;

          setState(() {
            _selectedStage = stage;
            _selectedSectors
              ..clear()
              ..addAll(sectors);
            _sortBy = sortBy;
          });

          if (stageChanged) _fetchStartups();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildResultCount(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 182,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _CatalogHeaderPainter()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 46),
                child: Text(
                  'Catálogo de Startups',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 46),
                child: Text(
                  'Ecossistema Mescla · PUC-Campinas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 46),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 26),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final activeFilterCount = _activeFilterCount;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search_rounded,
            size: 19,
            color: AppColors.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: _searchController,
              cursorColor: AppColors.primary,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: _availableSectorOptions.isEmpty
                    ? 'Buscar startups...'
                    : 'Buscar startups ou setores...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            InkWell(
              onTap: _searchController.clear,
              borderRadius: BorderRadius.circular(18),
              child: const SizedBox(
                width: 32,
                height: 42,
                child: Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          const SizedBox(width: 6),
          InkWell(
            onTap: _showFilterSheet,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.filter_alt_outlined,
                        size: 17,
                        color: AppColors.primary,
                      ),
                    ),
                    if (activeFilterCount > 0)
                      Positioned(
                        top: -4,
                        right: -5,
                        child: Container(
                          height: 16,
                          constraints: const BoxConstraints(minWidth: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            activeFilterCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildResultCount() {
    final filtered = _filteredStartups;
    final label = switch (_state) {
      CatalogState.loading => 'Carregando...',
      CatalogState.error => 'Catálogo indisponível',
      CatalogState.success => '${filtered.length} '
          'startup${filtered.length != 1 ? 's' : ''} '
          'encontrada${filtered.length != 1 ? 's' : ''}',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(46, 17, 46, 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case CatalogState.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      case CatalogState.error:
        return _buildErrorState();
      case CatalogState.success:
        return _buildStartupList();
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.muted,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Erro desconhecido.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchStartups,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartupList() {
    final list = _filteredStartups;

    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: AppColors.muted),
            SizedBox(height: 16),
            Text(
              'Nenhuma startup encontrada\npara o filtro selecionado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchStartups,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 6, bottom: 24),
        itemCount: list.length,
        itemBuilder: (context, index) => StartupCard(
          startup: list[index],
          onTap: () => _onStartupTapped(list[index]),
        ),
      ),
    );
  }
}

class _CatalogHeaderPainter extends CustomPainter {
  const _CatalogHeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = AppColors.primary;
    canvas.drawRect(Offset.zero & size, basePaint);

    final accentPaint = Paint()..color = const Color(0xFFC22A7B);
    final accentPath = Path()
      ..moveTo(size.width * 0.47, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.34, size.height)
      ..close();
    canvas.drawPath(accentPath, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FilterSheet extends StatefulWidget {
  final String? selectedStage;
  final Set<String> selectedSectors;
  final String sortBy;
  final List<String> stageOptions;
  final List<String> sectorOptions;
  final void Function(String? stage, Set<String> sectors, String sortBy)
  onApply;

  const _FilterSheet({
    required this.selectedStage,
    required this.selectedSectors,
    required this.sortBy,
    required this.stageOptions,
    required this.sectorOptions,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _stage;
  late Set<String> _sectors;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _stage = widget.selectedStage;
    _sectors = Set.of(widget.selectedSectors);
    _sortBy = widget.sortBy;
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'Em Expansão':
        return 'Expansão';
      case 'Em Operação':
        return 'Operação';
      default:
        return stage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSectorFilters = widget.sectorOptions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('Estágio da Startup'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.stageOptions.map((stage) {
              final selected = _stage == stage;
              return _FilterChip(
                label: _stageLabel(stage),
                selected: selected,
                onTap: () => setState(() => _stage = selected ? null : stage),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (hasSectorFilters) ...[
            _buildSectionLabel('Setor'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.sectorOptions.map((sector) {
                final selected = _sectors.contains(sector);
                return _FilterChip(
                  label: sector,
                  selected: selected,
                  onTap: () => setState(() {
                    if (selected) {
                      _sectors.remove(sector);
                    } else {
                      _sectors.add(sector);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          _buildSectionLabel('Ordenar por'),
          const SizedBox(height: 10),
          _buildSortOption('recentes', 'Mais recentes'),
          const SizedBox(height: 8),
          _buildSortOption('preco', 'Preço'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(_stage, _sectors, _sortBy);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Aplicar filtros',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.mutedForeground,
      ),
    );
  }

  Widget _buildSortOption(String value, String label) {
    final selected = _sortBy == value;

    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
