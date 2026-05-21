// Autor: Miguel Fernandes Monteiro — RA: 25014808
String formatarReais(double valor) {
  final partes = valor.toStringAsFixed(0).split('');
  final buffer = StringBuffer();
  int count = 0;
  for (int i = partes.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buffer.write('.');
    buffer.write(partes[i]);
    count++;
  }
  return 'R\$ ${buffer.toString().split('').reversed.join()}';
}
