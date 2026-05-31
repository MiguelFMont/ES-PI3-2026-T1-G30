// Autor: Miguel Fernandes Monteiro
// RA: 25014808
import 'package:flutter/services.dart';

/// Formata telefone brasileiro enquanto o usuário digita:
/// (XX) XXXX-XXXX para fixo e (XX) XXXXX-XXXX para celular.
class TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = format(newValue.text);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Aplica a máscara a um valor qualquer (digitado ou já armazenado).
  static String format(String valor) {
    final digits = valor.replaceAll(RegExp(r'[^\d]'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final celular = limited.length > 10;

    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (!celular && i == 6) buffer.write('-');
      if (celular && i == 7) buffer.write('-');
      buffer.write(limited[i]);
    }
    return buffer.toString();
  }

  /// Remove toda a pontuação, deixando apenas os dígitos (formato do banco).
  static String somenteDigitos(String valor) =>
      valor.replaceAll(RegExp(r'[^\d]'), '');
}
