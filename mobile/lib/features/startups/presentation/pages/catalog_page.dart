import 'package:flutter/material.dart';
import '../../data/startup_service.dart';
import '../../domain/startup_model.dart';
import '../widgets/startup_card.dart';

/// Estado possível da tela de catálogo separando em 3
enum CatalogState { loading, error, success }

/// Tela principal do catálogo de startups do MesclaInvest
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  /// Serviço responsável pelas chamadas HTTP ao backend
  final StartupService _service = StartupService();

  /// Lista de startups retornadas pela API
  List<Startup> _startups = [];

  /// Estado atual da tela.
  CatalogState _state = CatalogState.loading;

  // tratamento de erro
  String? _errorMessage;

  String? _selectedStage;

  static const List<String> _stages = [
    'Todos',
    'Nova',
    'Em Operação',
    'Em Expansão',
  ];

  @override
  void initState() {
    super.initState();
    _fetchStartups();
  }

  /// Busca startups na API aplicando o filtro de estágio atual
  Future<void> _fetchStartups() async {
    setState(() {
      _state = CatalogState.loading;
      _errorMessage = null;
    });

    try {
      final startups = await _service.listarStartups(
        estagio: _selectedStage,
      );

      setState(() {
        _startups = startups;
        _state = CatalogState.success;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Não foi possível carregar as startups.\n'
            'Verifique sua conexão e tente novamente.';
        _state = CatalogState.error;
      });
    }
  }

  /// Atualiza o filtro selecionado e recarrega as startups
  void _onStageSelected(String stage) {
    final selected = stage == 'Todos' ? null : stage;

    if (selected == _selectedStage) return;

    setState(() => _selectedStage = selected);
    _fetchStartups();
  }

  /// Navega para a tela de detalhe da [startup] selecionada
  void _onStartupTapped(Startup startup) {
    Navigator.pushNamed(
      context,
      '/startup-detail',
      arguments: startup,
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
            _buildStageFilters(),
            _buildResultCount(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  /// Constrói o cabeçalho com título e subtítulo do catálogo
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE91E8C), Color(0xFFC2185B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catálogo de Startups',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ecossistema Mescla · PUC-Campinas',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a barra de filtros por estágio de desenvolvimento
  Widget _buildStageFilters() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _stages.length,
        itemBuilder: (context, index) {
          final stage = _stages[index];
          final isActive = stage == 'Todos'
              ? _selectedStage == null
              : _selectedStage == stage;

          return GestureDetector(
            onTap: () => _onStageSelected(stage),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFE91E8C)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFFE91E8C)
                      : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Text(
                  stage,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Constrói o contador de resultados abaixo dos filtros.
  Widget _buildResultCount() {
    final label = _state == CatalogState.loading
        ? 'Carregando...'
        : '${_startups.length} startup${_startups.length != 1 ? 's' : ''} encontrada${_startups.length != 1 ? 's' : ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
    );
  }

  /// Constrói o conteúdo principal da tela conforme o [_state] atual
  Widget _buildContent() {
    switch (_state) {
      case CatalogState.loading:
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE91E8C),
          ),
        );

      case CatalogState.error:
        return _buildErrorState();

      case CatalogState.success:
        return _buildStartupList();
    }
  }

  /// Constrói o estado de erro com mensagem e botão para tentar novamente
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Erro desconhecido.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchStartups,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E8C),
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

  /// Exibe um estado vazio quando nenhuma startup é retornada pela API
  Widget _buildStartupList() {
    if (_startups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma startup encontrada\npara o filtro selecionado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFE91E8C),
      onRefresh: _fetchStartups,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _startups.length,
        itemBuilder: (context, index) {
          return StartupCard(
            startup: _startups[index],
            onTap: () => _onStartupTapped(_startups[index]),
          );
        },
      ),
    );
  }
}