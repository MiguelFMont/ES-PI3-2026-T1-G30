// Auto: Miguel Fenandes Monteiro
// RA: 25014808
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mesclainvest/core/theme/app_colors.dart';

class CampoTexto extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;

  /// Estado de validação: null = neutro, true = válido (verde), false = inválido (vermelho).
  final bool? valido;

  /// Mensagem exibida abaixo do campo (normalmente o erro de validação).
  final String? mensagemErro;

  final ValueChanged<String>? onChanged;

  const CampoTexto({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.inputFormatters,
    this.valido,
    this.mensagemErro,
    this.onChanged,
  });

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  // Variável interna do componente para controlar se está escondido ou não
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    // A variável interna recebe o valor que foi passado quando o widget foi criado
    _isObscured = widget.obscureText;
  }

  // Cor da borda conforme o estado de validação (null = sem borda).
  Color? get _corBorda {
    if (widget.valido == null) return null;
    return widget.valido! ? AppColors.success : AppColors.destructive;
  }

  OutlineInputBorder _borda({double width = 1.5}) {
    final cor = _corBorda;
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: cor == null
          ? BorderSide.none
          : BorderSide(color: cor, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: 60,
            width: 250,
            child: TextField(
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              obscureText: _isObscured,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                suffixIcon: widget.obscureText
                    ? IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: Icon(
                          _isObscured
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.foreground,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscured = !_isObscured;
                          });
                        },
                      )
                    : null,
                hintText: widget.label,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                border: _borda(),
                enabledBorder: _borda(),
                focusedBorder: _borda(width: 2),
              ),
            ),
          ),
        ),
        if (widget.mensagemErro != null && widget.valido == false)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: SizedBox(
              width: 250,
              child: Text(
                widget.mensagemErro!,
                style: const TextStyle(
                  color: AppColors.destructive,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
