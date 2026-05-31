// Autor: Miguel Fernandes Monteiro
// RA: 25014808
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CampoData extends StatefulWidget {
  final ValueChanged<DateTime?> onDateChanged;
  final String label;

  /// Estado de validação: null = neutro, true = válido (verde), false = inválido (vermelho).
  final bool? valido;
  final String? mensagemErro;

  /// Valor inicial — preenche os campos ao reconstruir o widget
  /// (ex.: ao voltar para esta etapa do cadastro).
  final DateTime? initialDate;

  const CampoData({
    super.key,
    required this.onDateChanged,
    this.label = 'Data de Nascimento',
    this.valido,
    this.mensagemErro,
    this.initialDate,
  });

  @override
  State<CampoData> createState() => _CampoDataState();
}

class _CampoDataState extends State<CampoData> {
  final _diaController = TextEditingController();
  final _mesController = TextEditingController();
  final _anoController = TextEditingController();

  final _diaFocus = FocusNode();
  final _mesFocus = FocusNode();
  final _anoFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final d = widget.initialDate;
    if (d != null) {
      _diaController.text = d.day.toString().padLeft(2, '0');
      _mesController.text = d.month.toString().padLeft(2, '0');
      _anoController.text = d.year.toString();
    }
  }

  // Tenta montar o DateTime sempre que algum campo muda
  void _onChanged() {
    final dia = int.tryParse(_diaController.text);
    final mes = int.tryParse(_mesController.text);
    final ano = int.tryParse(_anoController.text);

    if (dia != null && mes != null && ano != null && ano > 999) {
      try {
        final date = DateTime(ano, mes, dia);
        // Valida se a data é real (ex: 31/02 seria inválido)
        if (date.day == dia && date.month == mes && date.year == ano) {
          widget.onDateChanged(date);
          return;
        }
      } catch (_) {}
    }
    widget.onDateChanged(null);
  }

  @override
  void dispose() {
    _diaController.dispose();
    _mesController.dispose();
    _anoController.dispose();
    _diaFocus.dispose();
    _mesFocus.dispose();
    _anoFocus.dispose();
    super.dispose();
  }

  // Campo individual (dia, mês ou ano)
  Widget _buildSubCampo({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode? proximoFocus,
    required String hint,
    required int maxLength,
    required int maxValue,
  }) {
    return SizedBox(
      width: maxLength == 4 ? 90 : 60,
      height: 44,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(maxLength),
        ],
        onChanged: (value) {
          if (value.length == maxLength && proximoFocus != null) {
            proximoFocus.requestFocus();
          }
          _onChanged();
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14),
          filled: true,
          fillColor: const Color.fromARGB(15, 158, 158, 158),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF4A3F8F), width: 1.5),
          ),
        ),
      ),
    );
  }

  Color? get _corBorda {
    if (widget.valido == null) return null;
    return widget.valido!
        ? const Color(0xFF4CAF50)
        : const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    final corBorda = _corBorda;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 65,
          width: 250,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: corBorda == null
                ? null
                : Border.all(color: corBorda, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSubCampo(
                controller: _diaController,
                focusNode: _diaFocus,
                proximoFocus: _mesFocus,
                hint: 'DD',
                maxLength: 2,
                maxValue: 31,
              ),
              _buildSubCampo(
                controller: _mesController,
                focusNode: _mesFocus,
                proximoFocus: _anoFocus,
                hint: 'MM',
                maxLength: 2,
                maxValue: 12,
              ),
              _buildSubCampo(
                controller: _anoController,
                focusNode: _anoFocus,
                proximoFocus: null,
                hint: 'AAAA',
                maxLength: 4,
                maxValue: DateTime.now().year,
              ),
            ],
          ),
        ),
        if (widget.mensagemErro != null && widget.valido == false)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: SizedBox(
              width: 250,
              child: Text(
                widget.mensagemErro!,
                style: const TextStyle(
                  color: Color(0xFFF44336),
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
