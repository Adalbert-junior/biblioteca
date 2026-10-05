import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_biblioteca/models/livro.dart';
import 'package:minha_biblioteca/widgets/estado_vazio.dart';
import 'package:minha_biblioteca/widgets/livro_card.dart';

import 'ajudante.dart';

void main() {
  setUpAll(carregarFontes);

  group('coleção e estado vazio', () {
    testWidgets('mostra o estado vazio, uma vez só, e nenhum cartão', (
      tester,
    ) async {
      await montarApp(tester);

      expect(find.byType(EstadoVazio), findsOneWidget);
      expect(find.text('Sua coleção ainda está vazia'), findsOneWidget);
      expect(find.byType(LivroCard), findsNothing);
      // A ação nomeada existe: a tela não fica só em branco.
      expect(find.text('Registrar livro'), findsOneWidget);
    });

    testWidgets('carregar exemplos preenche a lista e some com o vazio', (
      tester,
    ) async {
      await montarApp(tester);

      await tester.tap(find.text('Experimentar coleção de exemplo'));
      await tester.pumpAndSettle();

      expect(find.byType(EstadoVazio), findsNothing);
      expect(find.byType(LivroCard), findsWidgets);
      expect(find.text('Dom Casmurro'), findsOneWidget);
    });

    testWidgets('a lista reflete a coleção: um cartão por livro', (
      tester,
    ) async {
      await montarApp(
        tester,
        livros: [livroDe('Alpha'), livroDe('Beta'), livroDe('Gama')],
      );
      expect(find.byType(LivroCard), findsNWidgets(3));
    });

    testWidgets('busca sem resultado mostra o vazio de filtro', (tester) async {
      await montarApp(tester, livros: [livroDe('Alpha')]);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.byType(LivroCard), findsNothing);
      expect(find.text('Nada por aqui'), findsOneWidget);

      await tester.tap(find.text('Limpar filtros'));
      await tester.pumpAndSettle();
      expect(find.byType(LivroCard), findsOneWidget);
    });

    testWidgets('filtro por situação mostra só os livros daquela situação', (
      tester,
    ) async {
      await montarApp(
        tester,
        livros: [
          livroDe('Alpha', status: StatusLivro.lido, paginas: 3),
          livroDe('Beta', status: StatusLivro.lendo, paginas: 3),
        ],
      );

      final chip = find.widgetWithText(ChoiceChip, 'Lido (1)');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);
    });
  });

  testWidgets('o Sobre lista os integrantes do grupo', (tester) async {
    await montarApp(tester);

    await tester.tap(find.byTooltip('Sobre o projeto'));
    await tester.pumpAndSettle();

    expect(find.text('Luiz Ragi'), findsOneWidget);
    expect(find.text('Israel Messias'), findsOneWidget);
    expect(find.text('Adalbert'), findsOneWidget);
  });

  group('detalhe', () {
    testWidgets('tocar no cartão abre o detalhe do mesmo livro', (tester) async {
      await montarApp(
        tester,
        livros: [
          livroDe('Alpha'),
          livroDe(
            'O Hobbit',
            formato: Formato.pdf,
            genero: 'Aventura',
            status: StatusLivro.lendo,
            nota: 4,
            paginas: 12,
            observacoes: 'Livro melhor.',
          ),
        ],
      );

      await tester.tap(find.text('O Hobbit'));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes'), findsOneWidget);
      expect(find.text('O Hobbit'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('12 pág.'), findsOneWidget);
      expect(find.text('Livro melhor.'), findsOneWidget);
      // O outro livro não vaza para esta tela.
      expect(find.text('Alpha'), findsNothing);
    });

    testWidgets('mudar a situação no detalhe atualiza o livro certo', (
      tester,
    ) async {
      final a = livroDe('Alpha');
      final b = livroDe('Beta');
      final acervo = await montarApp(tester, livros: [a, b]);

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Lendo'));
      await tester.pumpAndSettle();

      expect(acervo.porId(b.id)!.status, StatusLivro.lendo);
      expect(acervo.porId(a.id)!.status, StatusLivro.queroLer);
    });

    testWidgets('excluir pede confirmação e permite desfazer', (tester) async {
      final acervo = await montarApp(tester, livros: [livroDe('Alpha')]);

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Excluir livro'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir livro?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();
      expect(acervo.vazio, isTrue);

      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();
      expect(acervo.todos.map((j) => j.titulo), ['Alpha']);
    });
  });

  group('dois espaços de tela', () {
    final livros = [
      for (final n in ['A', 'B', 'C', 'D']) livroDe('Livro $n'),
    ];

    testWidgets('390 px usa uma coluna', (tester) async {
      await montarApp(tester, livros: livros, tamanho: const Size(390, 844));

      final xs = {
        for (final e in tester.elementList(find.byType(LivroCard)))
          tester.getTopLeft(find.byWidget(e.widget)).dx.round(),
      };
      expect(xs.length, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('840 px usa duas colunas na mesma ordem de leitura', (
      tester,
    ) async {
      await montarApp(tester, livros: livros, tamanho: const Size(840, 900));

      final cartoes = tester.elementList(find.byType(LivroCard)).toList();
      final xs = {
        for (final e in cartoes)
          tester.getTopLeft(find.byWidget(e.widget)).dx.round(),
      };
      expect(xs.length, 2);

      // A ordem de leitura continua: esquerda, direita, depois a linha de baixo.
      final pos = [
        for (final e in cartoes) tester.getTopLeft(find.byWidget(e.widget)),
      ];
      expect(pos[0].dx, lessThan(pos[1].dx));
      expect(pos[2].dy, greaterThan(pos[0].dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('título muito longo é cortado com reticências, sem overflow', (
      tester,
    ) async {
      await montarApp(
        tester,
        livros: [
          livroDe(
            'Um título absurdamente comprido para testar o corte no cartão do catálogo',
            status: StatusLivro.lido,
            nota: 5,
            paginas: 9999,
          ),
        ],
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('texto ampliado a 200% não estoura o layout', (tester) async {
      await montarApp(
        tester,
        livros: [
          livroDe(
            'Um título bem comprido para forçar quebra de linha no cartão',
            status: StatusLivro.lendo,
            nota: 4,
            paginas: 120,
          ),
        ],
        escalaTexto: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
