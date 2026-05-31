// Autor: Miguel Fernandes Monteiro
// RA: 25014808

/// Censura dados sensíveis para exibição, mantendo apenas o início e o fim
/// visíveis e substituindo o miolo por asteriscos.
class Censura {
  Censura._();

  /// CPF -> 123.***.***-00
  static String cpf(String valor) {
    final d = valor.replaceAll(RegExp(r'[^\d]'), '');
    if (d.length != 11) return valor.isEmpty ? '—' : valor;

    final m = '${d.substring(0, 3)}******${d.substring(9)}';
    return '${m.substring(0, 3)}.${m.substring(3, 6)}.${m.substring(6, 9)}-${m.substring(9)}';
  }

  /// Telefone -> (11) *****-**21 (celular) ou (11) ****-**44 (fixo)
  static String telefone(String valor) {
    final d = valor.replaceAll(RegExp(r'[^\d]'), '');

    if (d.length == 11) {
      final m = '${d.substring(0, 2)}*******${d.substring(9)}';
      return '(${m.substring(0, 2)}) ${m.substring(2, 7)}-${m.substring(7)}';
    }
    if (d.length == 10) {
      final m = '${d.substring(0, 2)}******${d.substring(8)}';
      return '(${m.substring(0, 2)}) ${m.substring(2, 6)}-${m.substring(6)}';
    }
    return valor.isEmpty ? '—' : valor;
  }
}
