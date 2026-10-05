/// Situação de um livro na lista de leitura.
enum StatusLivro {
  queroLer('Quero ler'),
  lendo('Lendo'),
  lido('Lido'),
  abandonado('Abandonado');

  const StatusLivro(this.rotulo);

  final String rotulo;

  static StatusLivro daChave(String? chave) => StatusLivro.values.firstWhere(
    (s) => s.name == chave,
    orElse: () => StatusLivro.queroLer,
  );
}

enum Formato {
  impresso('Impresso'),
  ebook('E-book'),
  pdf('PDF'),
  bolso('Bolso'),
  outro('Outro');

  const Formato(this.rotulo);

  final String rotulo;

  static Formato daChave(String? chave) => Formato.values.firstWhere(
    (p) => p.name == chave,
    orElse: () => Formato.impresso,
  );
}

const generos = <String>[
  'Romance',
  'Aventura',
  'Fantasia',
  'Não ficção',
  'Biografia',
  'História',
  'Poesia',
  'Terror',
  'Contos',
  'Infantil',
  'Clássicos',
];

int _contador = 0;

/// Um livro do catálogo. O [id] é a identidade: editar um livro gera uma cópia
/// com o mesmo id, nunca um item novo.
class Livro {
  const Livro({
    required this.id,
    required this.titulo,
    required this.formato,
    required this.genero,
    required this.status,
    required this.adicionadoEm,
    this.nota = 0,
    this.paginas = 0,
    this.observacoes = '',
  });

  /// Cria um livro novo, já com um id inédito.
  factory Livro.novo({
    required String titulo,
    required Formato formato,
    required String genero,
    required StatusLivro status,
    int nota = 0,
    int paginas = 0,
    String observacoes = '',
    DateTime? adicionadoEm,
  }) {
    final agora = DateTime.now();
    _contador++;
    return Livro(
      id: '${agora.microsecondsSinceEpoch}-$_contador',
      titulo: titulo,
      formato: formato,
      genero: genero,
      status: status,
      adicionadoEm: adicionadoEm ?? agora,
      nota: nota,
      paginas: paginas,
      observacoes: observacoes,
    );
  }

  factory Livro.deJson(Map<String, dynamic> json) => Livro(
    id: json['id'] as String,
    titulo: json['titulo'] as String,
    formato: Formato.daChave(json['formato'] as String?),
    genero: (json['genero'] as String?) ?? generos.first,
    status: StatusLivro.daChave(json['status'] as String?),
    adicionadoEm:
        DateTime.tryParse((json['adicionadoEm'] as String?) ?? '') ??
        DateTime.now(),
    nota: (json['nota'] as num?)?.toInt() ?? 0,
    paginas: (json['paginas'] as num?)?.toInt() ?? 0,
    observacoes: (json['observacoes'] as String?) ?? '',
  );

  final String id;
  final String titulo;
  final Formato formato;
  final String genero;
  final StatusLivro status;
  final DateTime adicionadoEm;

  /// De 1 a 5; 0 significa "sem nota".
  final int nota;
  final int paginas;
  final String observacoes;

  bool get temNota => nota > 0;

  Livro copyWith({
    String? titulo,
    Formato? formato,
    String? genero,
    StatusLivro? status,
    int? nota,
    int? paginas,
    String? observacoes,
  }) => Livro(
    id: id,
    titulo: titulo ?? this.titulo,
    formato: formato ?? this.formato,
    genero: genero ?? this.genero,
    status: status ?? this.status,
    adicionadoEm: adicionadoEm,
    nota: nota ?? this.nota,
    paginas: paginas ?? this.paginas,
    observacoes: observacoes ?? this.observacoes,
  );

  Map<String, dynamic> paraJson() => {
    'id': id,
    'titulo': titulo,
    'formato': formato.name,
    'genero': genero,
    'status': status.name,
    'adicionadoEm': adicionadoEm.toIso8601String(),
    'nota': nota,
    'paginas': paginas,
    'observacoes': observacoes,
  };

  /// Descrição falada por leitores de tela.
  String get descricaoFalada {
    final partes = [
      titulo,
      formato.rotulo,
      status.rotulo,
      if (temNota) 'nota $nota de 5',
      if (paginas > 0) paginas == 1 ? '1 página lida' : '$paginas páginas lidas',
    ];
    return partes.join(', ');
  }
}
