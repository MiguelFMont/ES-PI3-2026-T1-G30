//representa um socio da startup
class Socio {
  final String nome;
  final String foto;
  final double participacao;

  socio({required this.nome, required this.foto, required this.participacao});

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

  membro({
    required this.nome,
    required this.foto,
    required this.cargo,
    required this.area,
  });

  factory Membro.fromJson(Map<String, dynamic> json) {
    return membro(
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

  video({required this.titulo, required this.url, required this.thumbnail});

  factory Video.fromJson(Map<String, dynamic> json) {
    return video(
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

  atualizacao({
    required this.titulo,
    required this.descricao,
    required this.data,
  });

  factory Atualizacao.fromJson(Map<String, dynamic> json) {
    return atualizacao(
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
}
