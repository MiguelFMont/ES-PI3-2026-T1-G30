// shared/formatters/cpf_formatter.dart
import 'package:flutter/services.dart';

class CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
// \d: Representa qualquer dígito numérico (equivalente a [0-9]).
// ^: Quando usado dentro de colchetes [] no início, ele funciona como uma negação.
// Portanto, [^\d] significa "qualquer caractere que não seja um dígito".
// '': É uma string vazia usada como substituta. Isso significa que todos
// os caracteres "não dígitos" encontrados serão substituídos por nada (ou seja, deletados)
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}