//representa um socio da startup
class Socio {
  final String nome;
  final String foto;
  final double participacao;

  Socio({required this.nome, required this.foto, required this.participacao});

  //converte o json da api para o objeto dart
  factory Socio.fromJson(Map<String, dynamic> json) {
    return Socio(
      nome: _stringFromJson(json['nome']),
      foto: _stringFromJson(json['foto']),
      participacao: _doubleFromJson(json['participacao']),
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
      nome: _stringFromJson(json['nome']),
      foto: _stringFromJson(json['foto']),
      cargo: _stringFromJson(json['cargo'] ?? json['participacao']),
      area: _stringFromJson(json['area']),
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
      titulo: _stringFromJson(json['titulo']),
      url: _stringFromJson(json['url']),
      thumbnail: _stringFromJson(json['thumbnail'] ?? json['thumnail']),
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
      titulo: _stringFromJson(json['titulo']),
      descricao: _stringFromJson(json['descricao']),
      data: _dateStringFromJson(json['data']),
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
      id: _stringFromJson(json['id']),
      nome: _stringFromJson(json['nome']),
      logo: _stringFromJson(json['logo']),
      descricao: _stringFromJson(json['descricao']),
      estagio: _stringFromJson(json['estagio']),
      setor: _stringFromJson(json['setor']),
      precoToken: _doubleFromJson(
        json['precoToken'] ?? json['precoTokenAtualCentavos'],
        fromCentavos: json['precoToken'] == null,
      ),
      variacaoPreco: json['variacaoPreco'] == null
          ? null
          : _doubleFromJson(json['variacaoPreco']),
      investido: json['investido'] == true,
      capitalAportado: _doubleFromJson(json['capitalAportado']),
      totalTokens: _intFromJson(json['totalTokens']),
      resumoExecutivo: _stringFromJson(
        json['resumoExecutivo'] ?? json['resumoExecutive'],
      ),
      // Converte cada item da lista JSON para o objeto correspondente
      socios: _listFromJson(
        json['socios'],
      ).map((s) => Socio.fromJson(_mapFromJson(s))).toList(),
      conselho: _listFromJson(
        json['conselho'],
      ).map((c) => Membro.fromJson(_mapFromJson(c))).toList(),
      mentores: _listFromJson(
        json['mentores'],
      ).map((m) => Membro.fromJson(_mapFromJson(m))).toList(),
      videos: _listFromJson(
        json['videos'],
      ).map((v) => Video.fromJson(_mapFromJson(v))).toList(),
      atualizacoes: _listFromJson(
        json['atualizacoes'],
      ).map((a) => Atualizacao.fromJson(_mapFromJson(a))).toList(),
    );
  }
}

double _doubleFromJson(dynamic value, {bool fromCentavos = false}) {
  if (value == null) return 0;
  final number = value is num
      ? value.toDouble()
      : double.tryParse('$value') ?? 0;
  return fromCentavos ? number / 100 : number;
}

int _intFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

String _stringFromJson(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return '$value';
}

List<dynamic> _listFromJson(dynamic value) {
  if (value is List<dynamic>) return value;
  if (value is List) return List<dynamic>.from(value);
  return const [];
}

Map<String, dynamic> _mapFromJson(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

// O backend remoto serializa datas do Firestore como mapa com _seconds.
// A UI precisa de string estável para não quebrar durante o parse.
String _dateStringFromJson(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;

  final map = _mapFromJson(value);
  final seconds = map['_seconds'];
  if (seconds is num) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      seconds.toInt() * 1000,
      isUtc: true,
    );
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  return _stringFromJson(value);
}
