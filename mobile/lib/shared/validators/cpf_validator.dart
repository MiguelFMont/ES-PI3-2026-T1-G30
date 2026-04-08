
class CpfValidator {
  
  static bool isValid(String cpf) {
    // Remove pontos e traço
    cpf = cpf.replaceAll(RegExp(r'[^\d]'), '');

    // Rejeita CPFs com tamanho errado ou todos dígitos iguais (ex: 111.111.111-11)
    if (cpf.length != 11 || RegExp(r'^(\d)\1+$').hasMatch(cpf)) return false;

    // Calcula e valida os dois dígitos verificadores
    for (int i = 9; i < 11; i++) {
      int soma = 0;
      for (int j = 0; j < i; j++) {
        soma += int.parse(cpf[j]) * (i + 1 - j);
      }
      final digito = (soma * 10) % 11 % 10;
      if (digito != int.parse(cpf[i])) return false;
    }

    return true;
  }
}