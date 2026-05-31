// Autor: Caio Ávila Marchi
// RA: 25008101

import 'package:mesclainvest/core/storage/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:mesclainvest/core/theme/app_colors.dart';

import '../../data/repositories/questions_repository.dart';
import '../../domain/question_model.dart';

class QuestionsTab extends StatefulWidget {
  final String startupId;
  final bool isInvestidor;

  const QuestionsTab({
    super.key,
    required this.startupId,
    required this.isInvestidor,
  });

  @override
  State<QuestionsTab> createState() => _QuestionsTabState();
}

class _QuestionsTabState extends State<QuestionsTab> {
  final _repo = QuestionsRepository();
  List<Question> _perguntas = [];
  bool _carregando = true;
  final Set<String> _expandidas = {};

  @override
  void initState() {
    super.initState();
    _carregarPerguntas();
  }

  Future<String?> _getToken() async {
    return SessionManager.getToken();
  }

  Future<void> _carregarPerguntas() async {
    if (!mounted) return;
    setState(() => _carregando = true);
    try {
      final token = await _getToken();
      if (token == null) {
        if (mounted) setState(() => _carregando = false);
        return;
      }
      final perguntas = await _repo.buscarPublicas(widget.startupId, token);
      if (mounted) {
        setState(() {
          _perguntas = perguntas;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _abrirModal() {
    final controller = TextEditingController();
    bool isPublica = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Nova pergunta',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Digite sua pergunta...',
                    filled: true,
                    fillColor: AppColors.secondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Visibilidade:',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _VisibilidadeChip(
                      label: 'Pública',
                      selected: isPublica,
                      onTap: () => setDialogState(() => isPublica = true),
                    ),
                    // Se for investidor, adiciona o espaçamento e o chip "Privada"
                    if (widget.isInvestidor) ...[
                      const SizedBox(width: 8),
                      _VisibilidadeChip(
                        label: 'Privada',
                        selected: !isPublica,
                        onTap: () => setDialogState(() => isPublica = false),
                      ),
                    ],
                  ],
                ),

                if (widget.isInvestidor) const SizedBox(height: 12),

                // Só renderiza o texto na tela se for investidor
                if (widget.isInvestidor)
                  const Text(
                    'Perguntas privadas são exclusivas para investidores.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                final texto = controller.text.trim();
                if (texto.isEmpty) return;
                Navigator.pop(context);
                await _enviar(texto, isPublica);
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviar(String texto, bool isPublica) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      await _repo.enviarPergunta(widget.startupId, texto, isPublica, token);
      await _carregarPerguntas();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar pergunta.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Perguntas Públicas (${_perguntas.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF17233C),
                ),
              ),
            ],
          ),
        ),
        if (_perguntas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Nenhuma pergunta publicada.',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                height: 1.45,
              ),
            ),
          )
        else
          for (final q in _perguntas) _buildCard(q),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lavanda,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.send, size: 15, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Enviar Pergunta Exclusiva',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17233C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Como investidor, você pode enviar perguntas\nprivadas diretamente à equipe.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _abrirModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Fazer uma pergunta'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Question q) {
    final expandida = _expandidas.contains(q.id);
    final inicial = q.autorNome.isNotEmpty ? q.autorNome[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  inicial,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                q.autorNome,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF17233C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            q.texto,
            style: const TextStyle(fontSize: 13, color: Color(0xFF17233C)),
          ),
          if (q.resposta != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() {
                if (expandida) {
                  _expandidas.remove(q.id);
                } else {
                  _expandidas.add(q.id);
                }
              }),
              child: Row(
                children: [
                  Text(
                    expandida ? 'Ocultar resposta' : 'Ver resposta',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    expandida
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (expandida) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lavanda,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.resposta!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF17233C),
                      ),
                    ),
                    if (q.respondidoPor != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '— ${q.respondidoPor}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _VisibilidadeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilidadeChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Icon(Icons.check, size: 14, color: AppColors.primary),
            if (selected) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.mutedForeground,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
