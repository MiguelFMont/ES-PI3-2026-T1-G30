class StartupPricePoint {
  const StartupPricePoint({
    required this.preco,
    required this.createdAt,
    this.motivo = '',
  });

  final double preco;
  final DateTime createdAt;
  final String motivo;

  factory StartupPricePoint.fromJson(Map<String, dynamic> json) {
    return StartupPricePoint(
      preco: json.containsKey('precoCentavos')
          ? _centavosParaReais(json['precoCentavos'])
          : _toDouble(json['preco']),
      createdAt: _toDateTime(json['createdAt']),
      motivo: _toText(json['motivo']),
    );
  }
}

double _centavosParaReais(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble() / 100;
  return (double.tryParse('$value') ?? 0) / 100;
}

String _toText(dynamic value) => value == null ? '' : value.toString();

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

DateTime _toDateTime(dynamic value) {
  if (value is DateTime) return value;

  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  if (value is Map) {
    final seconds = _toInt(value['_seconds'] ?? value['seconds']);
    final nanoseconds = _toInt(value['_nanoseconds'] ?? value['nanoseconds']);

    if (seconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + (nanoseconds ?? 0) ~/ 1000000,
      );
    }
  }

  if (value is num) {
    final timestamp = value.toInt();
    return DateTime.fromMillisecondsSinceEpoch(
      timestamp < 10000000000 ? timestamp * 1000 : timestamp,
    );
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}
