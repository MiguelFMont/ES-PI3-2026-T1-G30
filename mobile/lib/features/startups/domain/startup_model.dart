//representa um socio da startup
class Socio {
  final String nome;
  final String foto;
  final double participacao;

  Socio({required this.nome, required this.foto, required this.participacao});

  //converte o json da api para o objeto dart
  factory Socio.fromJson(Map<String, dynamic> json) {
    return Socio(
      nome: json['nome'] ?? '',
      foto: json['foto'] ?? '',
      participacao: (json['participacao'] ?? 0).toDouble(),
    );
  }
}

// representa um membro do conselho ou mentor
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
      nome: json['nome'] ?? '',
      foto: json['foto'] ?? '',
      cargo: json['cargo'] ?? '',
      area: json['area'] ?? '',
    );
  }
}

// representa um video da startup
class Video {
  final String titulo;
  final String url;
  final String thumbnail;

  Video({required this.titulo, required this.url, required this.thumbnail});

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      titulo: json['titulo'] ?? '',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
    );
  }
}

// representa uma atualização da startup
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
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      data: json['data'] ?? '',
    );
  }
}

// representa uma startup completa
class Startup {
  final String id;
  final String nome;
  final String logo;
  final String descricao;
  final String estagio;
  final String setor;
  final double precoToken;
  final double? variacaoPreco;
  final bool investido;
  final double capitalAportado;
  final int totalTokens;
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
    this.precoToken = 0,
    this.variacaoPreco,
    this.investido = false,
    required this.capitalAportado,
    required this.totalTokens,
    required this.resumoExecutivo,
    required this.socios,
    required this.conselho,
    required this.mentores,
    required this.videos,
    required this.atualizacoes,
  });

  factory Startup.fromJson(Map<String, dynamic> json) {
    return Startup(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      logo: json['logo'] ?? '',
      descricao: json['descricao'] ?? '',
      estagio: json['estagio'] ?? '',
      setor: json['setor'] ?? '',
      precoToken: _doubleFromJson(
        json['precoToken'] ?? json['precoTokenAtualCentavos'],
        fromCentavos: json['precoToken'] == null,
      ),
      variacaoPreco: json['variacaoPreco'] == null
          ? null
          : _doubleFromJson(json['variacaoPreco']),
      investido: json['investido'] == true,
      capitalAportado: (json['capitalAportado'] ?? 0).toDouble(),
      totalTokens: json['totalTokens'] ?? 0,
      resumoExecutivo: json['resumoExecutivo'] ?? '',
      // Converte cada item da lista JSON para o objeto correspondente
      socios: (json['socios'] as List<dynamic>? ?? [])
          .map((s) => Socio.fromJson(s))
          .toList(),
      conselho: (json['conselho'] as List<dynamic>? ?? [])
          .map((c) => Membro.fromJson(c))
          .toList(),
      mentores: (json['mentores'] as List<dynamic>? ?? [])
          .map((m) => Membro.fromJson(m))
          .toList(),
      videos: (json['videos'] as List<dynamic>? ?? [])
          .map((v) => Video.fromJson(v))
          .toList(),
      atualizacoes: (json['atualizacoes'] as List<dynamic>? ?? [])
          .map((a) => Atualizacao.fromJson(a))
          .toList(),
    );
  }

  static double _doubleFromJson(dynamic value, {bool fromCentavos = false}) {
    if (value == null) return 0;
    final number = value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? 0;
    return fromCentavos ? number / 100 : number;
  }
}
