// Autor: Miguel Fernandes Monteiro — RA: 25014808

import 'package:flutter/material.dart';

/// Notificação que desliza a partir do topo da tela.
///
/// Uso:
/// ```dart
/// MesclaNotificacao.mostrar(context, label: 'Tudo certo!', cor: Colors.green);
/// ```
class MesclaNotificacao {
  MesclaNotificacao._();

  static OverlayEntry? _entryAtual;

  static void mostrar(
    BuildContext context, {
    required String label,
    required Color cor,
    Duration duracao = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);

    // Garante apenas uma notificação por vez
    _entryAtual?.remove();
    _entryAtual = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _NotificacaoView(
        label: label,
        cor: cor,
        duracao: duracao,
        onFechar: () {
          if (_entryAtual == entry) _entryAtual = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );

    _entryAtual = entry;
    overlay.insert(entry);
  }
}

class _NotificacaoView extends StatefulWidget {
  final String label;
  final Color cor;
  final Duration duracao;
  final VoidCallback onFechar;

  const _NotificacaoView({
    required this.label,
    required this.cor,
    required this.duracao,
    required this.onFechar,
  });

  @override
  State<_NotificacaoView> createState() => _NotificacaoViewState();
}

class _NotificacaoViewState extends State<_NotificacaoView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
    _aguardarEFechar();
  }

  Future<void> _aguardarEFechar() async {
    await Future.delayed(widget.duracao);
    if (!mounted) return;
    await _controller.reverse();
    widget.onFechar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topo = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topo + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.cor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
