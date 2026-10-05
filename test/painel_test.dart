import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_biblioteca/models/conquistas.dart';
import 'package:minha_biblioteca/models/livro.dart';
import 'package:minha_biblioteca/pages/painel_page.dart';
import 'package:minha_biblioteca/state/acervo.dart';
import 'package:minha_biblioteca/data/repositorio.dart';
import 'package:minha_biblioteca/widgets/roleta_leitura.dart';

import 'ajudante.dart';

void main() {
  setUpAll(carregarFontes);

  Future<Acervo> abrirPainel(WidgetTester tester, List<Livro> livros) async {
    final acervo = await montarApp(
      tester,
      livros: livros,
      tamanho: const Size(420, 2400),
    );
    await tester.tap(find.byTooltip('Painel e estatísticas'));
    await tester.pumpAndSettle();
    return acervo;
  }

  testWidgets('o painel mostra os números da coleção', (tester) async {
    await abrirPainel(tester, [
      livroDe('A', status: StatusLivro.lido, nota: 5, paginas: 10),
      livroDe('B', status: StatusLivro.lido, nota: 3, paginas: 20),
      livroDe('C'),
    ]);

    expect(find.text('30 pág.'), findsWidgets); // total e barra do formato
    expect(find.text('4,0'), findsOneWidget); // nota média
    expect(find.text('100%'), findsOneWidget); // 2 de 2 iniciados
  });

  testWidgets('a roleta sorteia só entre os livros "quero ler"', (
    tester,
  ) async {
    final acervo = await montarApp(
      tester,
      livros: [
        livroDe('Fila 1'),
        livroDe('Lendo', status: StatusLivro.lendo, paginas: 2),
      ],
      tamanho: const Size(420, 2400),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoletaLeitura(
            acervo: acervo,
            random: Random(1),
            aoAbrir: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sortear'));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Fila 1'), findsOneWidget);
    expect(find.text('Lendo'), findsNothing);
    expect(find.text('Sortear de novo'), findsOneWidget);
  });

  testWidgets('sem livros na fila o botão da roleta fica desligado', (
    tester,
  ) async {
    final acervo = Acervo(
      RepositorioMemoria([livroDe('X', status: StatusLivro.lido, paginas: 3)]),
    );
    await acervo.carregar();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoletaLeitura(acervo: acervo, aoAbrir: (_) {}),
        ),
      ),
    );

    final botao = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(botao.onPressed, isNull);
  });

  testWidgets('"Começar a ler" muda a situação do livro sorteado', (
    tester,
  ) async {
    final alvo = livroDe('Único');
    final acervo = Acervo(RepositorioMemoria([alvo]));
    await acervo.carregar();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoletaLeitura(acervo: acervo, aoAbrir: (_) {}),
        ),
      ),
    );

    await tester.tap(find.text('Sortear'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Começar a ler'));
    await tester.pumpAndSettle();

    expect(acervo.porId(alvo.id)!.status, StatusLivro.lendo);
  });

  group('conquistas', () {
    test('cada selo é liberado pela condição descrita', () {
      Conquista por(String titulo) =>
          conquistas.firstWhere((c) => c.titulo == titulo);

      expect(por('Primeiro livro').liberada([]), isFalse);
      expect(por('Primeiro livro').liberada([livroDe('A')]), isTrue);

      final dez = [for (var i = 0; i < 10; i++) livroDe('J$i')];
      expect(por('Colecionador').liberada(dez.take(9).toList()), isFalse);
      expect(por('Colecionador').liberada(dez), isTrue);

      expect(
        por('Leitor versátil').liberada([
          livroDe('A', formato: Formato.impresso),
          livroDe('B', formato: Formato.pdf),
        ]),
        isFalse,
      );
      expect(
        por('Leitor versátil').liberada([
          livroDe('A', formato: Formato.impresso),
          livroDe('B', formato: Formato.pdf),
          livroDe('C', formato: Formato.outro),
        ]),
        isTrue,
      );

      expect(
        por('Leitor dedicado').liberada([
          livroDe('A', paginas: 60, status: StatusLivro.lendo),
          livroDe('B', paginas: 40, status: StatusLivro.lendo),
        ]),
        isTrue,
      );
    });
  });

  test('o resumo em texto lista os livros por situação', () {
    final livros = [
      livroDe('1984', status: StatusLivro.lido, nota: 5, paginas: 30),
      livroDe('Dune'),
    ];
    final acervo = Acervo(RepositorioMemoria());
    acervo.adicionarVarios(livros);

    final texto = montarResumoTexto(acervo.todos, acervo.resumo);
    expect(
      texto,
      contains('2 livros · 1 lido · 30 pág. lidas · nota média 5,0'),
    );
    expect(texto, contains('Lido: 1984'));
    expect(texto, contains('Quero ler: Dune'));
  });
}
