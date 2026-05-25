import 'package:flutter/material.dart';
import 'package:mesclainvest/app/routes.dart';
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

  // Alguns ambientes ainda não publicam "setor" no payload.
  // Quando isso acontecer, a UI oculta esse filtro em vez de exibir chips inertes.
  List<String> get _availableSectorOptions {
    final sectors = _startups
        .map((startup) => startup.setor.trim())
        .where((sector) => sector.isNotEmpty)
        .toSet()
        .toList();

    sectors.sort();
    return sectors;
  }

  // O ambiente remoto atual possui documentos duplicados da mesma startup.
  // A tela colapsa esses itens por assinatura funcional até o banco ser limpo.
  String _catalogKey(Startup startup) {
    return [
      startup.nome.trim().toLowerCase(),
      startup.descricao.trim().toLowerCase(),
      startup.estagio.trim().toLowerCase(),
    ].join('|');
  }

  @override
  void initState() {
    super.initState();
    _fetchStartups();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStartups() async {
    setState(() {
      _state = CatalogState.loading;
      _errorMessage = null;
      _startups = [];
    });

    try {
      final startups = await _service.listarStartups(estagio: _selectedStage);
      final uniqueStartupsByKey = <String, Startup>{};
      for (final startup in startups) {
        uniqueStartupsByKey.putIfAbsent(_catalogKey(startup), () => startup);
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
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.45, 0.45],
                  colors: [
                    AppColors.primary,
                    Color(0xFFC2185B),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -18,
            right: 55,
            child: Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catálogo de Startups',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ecossistema Mescla · PUC-Campinas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 14),
                _buildSearchBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
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
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Color(0xFFE2E8F0),
          ),
          GestureDetector(
            onTap: _showFilterSheet,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.filter_alt_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCount() {
    final filtered = _filteredStartups;
    final label = switch (_state) {
      CatalogState.loading => 'Carregando...',
      CatalogState.error => 'Catálogo indisponível',
      CatalogState.success =>
        '${filtered.length} startup${filtered.length != 1 ? 's' : ''} encontrada${filtered.length != 1 ? 's' : ''}',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: list.length,
        itemBuilder: (context, index) => StartupCard(
          startup: list[index],
          onTap: () => _onStartupTapped(list[index]),
        ),
      ),
    );
  }
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
