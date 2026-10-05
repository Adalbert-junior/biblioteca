import '../models/livro.dart';

/// Dados demonstrativos: páginas e notas são ilustrativas, sem edição específica.
/// Coleção de partida oferecida no estado vazio, para o app poder ser
/// explorado sem cadastrar tudo à mão. A ordem em que aparecem é a ordem em
/// que estão escritos aqui: cada um é "adicionado" um minuto antes do anterior.
List<Livro> livrosDeExemplo() {
  final agora = DateTime.now();
  var posicao = 0;

  Livro j(
    String titulo,
    Formato formato,
    String genero,
    StatusLivro status, {
    int nota = 0,
    int paginas = 0,
    String observacoes = '',
  }) => Livro.novo(
    titulo: titulo,
    formato: formato,
    genero: genero,
    status: status,
    nota: nota,
    paginas: paginas,
    observacoes: observacoes,
    adicionadoEm: agora.subtract(Duration(minutes: posicao++)),
  );

  return [
    j(
      'Dom Casmurro',
      Formato.impresso,
      'Aventura',
      StatusLivro.lido,
      nota: 5,
      paginas: 240,
      observacoes: 'Gostei da narrativa e das dúvidas que ela deixa.',
    ),
    j(
      'O Hobbit',
      Formato.ebook,
      'Fantasia',
      StatusLivro.lendo,
      nota: 5,
      paginas: 120,
      observacoes: 'Leitura em andamento; quero continuar no fim de semana.',
    ),
    j(
      'O Pequeno Príncipe',
      Formato.bolso,
      'Infantil',
      StatusLivro.lido,
      nota: 5,
      paginas: 96,
    ),
    j(
      '1984',
      Formato.impresso,
      'Romance',
      StatusLivro.lendo,
      nota: 4,
      paginas: 80,
      observacoes: 'Anotando os trechos que mais chamam a atenção.',
    ),
    j(
      'A Revolução dos Bichos',
      Formato.impresso,
      'Fantasia',
      StatusLivro.queroLer,
      observacoes: 'Recomendação de um amigo do grupo.',
    ),
    j(
      'Drácula',
      Formato.ebook,
      'Terror',
      StatusLivro.queroLer,
    ),
    j(
      'Orgulho e Preconceito',
      Formato.outro,
      'Clássicos',
      StatusLivro.abandonado,
      nota: 3,
      paginas: 40,
      observacoes: 'Parei a leitura por enquanto.',
    ),
    j(
      'O Cortiço',
      Formato.pdf,
      'Biografia',
      StatusLivro.lendo,
      nota: 3,
      paginas: 120,
    ),
  ];
}
