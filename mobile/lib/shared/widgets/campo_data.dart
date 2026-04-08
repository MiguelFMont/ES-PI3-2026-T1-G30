// Autor: Miguel Fernandes Monteiro
// RA: 25014808
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CampoData extends StatefulWidget {
  final ValueChanged<DateTime?> onDateChanged;
  final String label;

  const CampoData({
    super.key,
    required this.onDateChanged,
    this.label = 'Data de Nascimento',
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        // Dia e mês são menores, ano é maior
        width: maxLength == 4 ? 90 : 60,
        height: 60,
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
            // Avança para o próximo campo automaticamente quando completo
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
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4A3F8F),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            width: double.infinity,
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
                  proximoFocus: null, // último campo, não avança
                  hint: 'AAAA',
                  maxLength: 4,
                  maxValue: DateTime.now().year,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
