import 'package:flutter/material.dart';

import 'livro.dart';

/// Selos que o app libera conforme a coleção cresce. Não são gravados: são
/// recalculados a partir dos livros, então nunca ficam fora de sincronia.
class Conquista {
  const Conquista({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.liberada,
  });

  final String titulo;
  final String descricao;
  final IconData icone;
  final bool Function(List<Livro> livros) liberada;
}

int _paginas(List<Livro> livros) => livros.fold(0, (soma, j) => soma + j.paginas);

final conquistas = <Conquista>[
  Conquista(
    titulo: 'Primeiro livro',
    descricao: 'Cadastre seu primeiro livro.',
    icone: Icons.save_outlined,
    liberada: (livros) => livros.isNotEmpty,
  ),
  Conquista(
    titulo: 'Leitura concluída!',
    descricao: 'Termine um livro.',
    icone: Icons.flag_outlined,
    liberada: (livros) => livros.any((j) => j.status == StatusLivro.lido),
  ),
  Conquista(
    titulo: 'Colecionador',
    descricao: 'Tenha 10 livros no catálogo.',
    icone: Icons.inventory_2_outlined,
    liberada: (livros) => livros.length >= 10,
  ),
  Conquista(
    titulo: 'Crítico',
    descricao: 'Dê nota máxima para um livro.',
    icone: Icons.star_outline,
    liberada: (livros) => livros.any((j) => j.nota == 5),
  ),
  Conquista(
    titulo: 'Leitor versátil',
    descricao: 'Tenha livros em 3 formatos diferentes.',
    icone: Icons.book_outlined,
    liberada: (livros) => livros.map((j) => j.formato).toSet().length >= 3,
  ),
  Conquista(
    titulo: 'Leitor dedicado',
    descricao: 'Some 100 páginas lidas.',
    icone: Icons.auto_stories_outlined,
    liberada: (livros) => _paginas(livros) >= 100,
  ),
  Conquista(
    titulo: 'Persistente',
    descricao: 'Tenha 5 livros lidos.',
    icone: Icons.emoji_events_outlined,
    liberada: (livros) =>
        livros.where((j) => j.status == StatusLivro.lido).length >= 5,
  ),
  Conquista(
    titulo: 'Sem julgamentos',
    descricao: 'Assuma um livro abandonado.',
    icone: Icons.sentiment_neutral_outlined,
    liberada: (livros) => livros.any((j) => j.status == StatusLivro.abandonado),
  ),
];
