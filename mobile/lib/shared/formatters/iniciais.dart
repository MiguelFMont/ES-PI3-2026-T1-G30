String iniciais(String nome) {
  final partes = nome.trim().split(' ');
  if (partes.length >= 2) return '${partes.first[0]}${partes.last[0]}';
  return partes.first[0];
}
