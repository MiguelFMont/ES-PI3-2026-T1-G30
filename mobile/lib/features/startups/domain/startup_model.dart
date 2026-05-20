double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _asString(dynamic value) {
  return value?.toString() ?? '';
}

String _asDateString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;

  if (value is Map<String, dynamic>) {
    final seconds = value['_seconds'] ?? value['seconds'];
    if (seconds is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (seconds * 1000).toInt(),
      ).toIso8601String();
    }
  }

  return value.toString();
}

class Socio {
  final String nome;
  final String foto;
  final double participacao;

  Socio({required this.nome, required this.foto, required this.participacao});

  factory Socio.fromJson(Map<String, dynamic> json) {
    return Socio(
      nome: _asString(json['nome'] ?? json['name']),
      foto: _asString(json['foto']),
      participacao: _asDouble(json['participacao']),
    );
  }
}

class Membro {
  final String nome;
  final String foto;
  final String cargo;
  final String area;

  Membro({
    required this.nome,
    required this.foto,
    required this.cargo,
    required this.area,
  });

  factory Membro.fromJson(Map<String, dynamic> json) {
    return Membro(
      nome: _asString(json['nome']),
      foto: _asString(json['foto']),
      cargo: _asString(json['cargo']),
      area: _asString(json['area']),
    );
  }
}

class Video {
  final String titulo;
  final String url;
  final String thumbnail;

  Video({required this.titulo, required this.url, required this.thumbnail});

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      titulo: _asString(json['titulo'] ?? json['title']),
      url: _asString(json['url']),
      thumbnail: _asString(json['thumbnail']),
    );
  }
}

class Atualizacao {
  final String titulo;
  final String descricao;
  final String data;

  Atualizacao({
    required this.titulo,
    required this.descricao,
    required this.data,
  });

  factory Atualizacao.fromJson(Map<String, dynamic> json) {
    return Atualizacao(
      titulo: _asString(json['titulo']),
      descricao: _asString(json['descricao']),
      data: _asDateString(json['data']),
    );
  }
}

class Startup {
  final String id;
  final String nome;
  final String logo;
  final String descricao;
  final String estagio;
  final String setor;
  final double capitalAportado;
  final int totalTokens;
  final double precoToken;
  final double? variacaoPreco;
  final bool investido;
  final String resumoExecutivo;
  final List<Socio> socios;
  final List<Membro> conselho;
  final List<Membro> mentores;
  final List<Video> videos;
  final List<Atualizacao> atualizacoes;

  Startup({
    required this.id,
    required this.nome,
    required this.logo,
    required this.descricao,
    required this.estagio,
    this.setor = '',
    required this.capitalAportado,
    required this.totalTokens,
    this.precoToken = 0,
    this.variacaoPreco,
    this.investido = false,
    required this.resumoExecutivo,
    required this.socios,
    required this.conselho,
    required this.mentores,
    required this.videos,
    required this.atualizacoes,
  });

  factory Startup.fromJson(Map<String, dynamic> json) {
    final precoToken = json['precoToken'] ??
        (json['precoTokenAtualCentavos'] != null
            ? _asDouble(json['precoTokenAtualCentavos']) / 100
            : 0);

    return Startup(
      id: _asString(json['id']),
      nome: _asString(json['nome']),
      logo: _asString(json['logo']),
      descricao: _asString(json['descricao']),
      estagio: _asString(json['estagio']),
      setor: _asString(json['setor']),
      capitalAportado: _asDouble(json['capitalAportado']),
      totalTokens: _asInt(json['totalTokens']),
      precoToken: _asDouble(precoToken),
      variacaoPreco: json['variacaoPreco'] != null ? _asDouble(json['variacaoPreco']) : null,
      investido: json['investido'] == true,
      resumoExecutivo: _asString(json['resumoExecutivo']),
      socios: _listFromJson(json['socios'], Socio.fromJson),
      conselho: _listFromJson(json['conselho'], Membro.fromJson),
      mentores: _listFromJson(json['mentores'], Membro.fromJson),
      videos: _listFromJson(json['videos'], Video.fromJson),
      atualizacoes: _listFromJson(json['atualizacoes'], Atualizacao.fromJson),
    );
  }

  static List<T> _listFromJson<T>(
    dynamic value,
    T Function(Map<String, dynamic>) mapper,
  ) {
    final items = value is List ? value : const [];
    return items
        .whereType<Map>()
        .map((item) => mapper(Map<String, dynamic>.from(item)))
        .toList();
  }
}
