import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_biblioteca/models/livro.dart';
import 'package:minha_biblioteca/widgets/livro_card.dart';

import 'ajudante.dart';

Finder campo(String rotulo) => find.widgetWithText(TextFormField, rotulo);

void main() {
  setUpAll(carregarFontes);

  // Tela alta para o formulário inteiro ficar construído de uma vez.
  const tela = Size(420, 1500);

  group('validação', () {
    testWidgets('título só com espaços é rejeitado e a tela continua aberta', (
      tester,
    ) async {
      final acervo = await montarApp(
        tester,
        livros: [livroDe('Alpha')],
        tamanho: tela,
      );

      await tester.tap(find.text('Adicionar livro'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Título do livro'), '     ');
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o título'), findsOneWidget);
      expect(find.text('Adicionar livro'), findsWidgets); // ainda no formulário
      expect(acervo.todos.length, 1);
    });

    testWidgets('o erro do título some assim que ele é corrigido', (
      tester,
    ) async {
      await montarApp(tester, tamanho: tela);

      await tester.tap(find.text('Registrar livro'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Título do livro'), '  ');
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();
      expect(find.text('Informe o título'), findsOneWidget);

      await tester.enterText(campo('Título do livro'), 'Duna');
      await tester.pumpAndSettle();
      expect(find.text('Informe o título'), findsNothing);
    });

    testWidgets('mensagem longa de paginas aparece inteira, sem corte', (
      tester,
    ) async {
      await montarApp(tester, tamanho: const Size(390, 1500));

      await tester.tap(find.text('Registrar livro'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Título do livro'), 'Duna');
      await tester.enterText(campo('Páginas lidas'), '12');
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      final texto = find.text(
        'Quem ainda não começou não tem páginas. Mude a situação.',
      );
      expect(texto, findsOneWidget);
      expect(tester.widget<Text>(texto).maxLines, 3);
    });

    testWidgets('paginas inválidas mostram mensagem útil', (tester) async {
      await montarApp(tester, tamanho: tela);

      await tester.tap(find.text('Registrar livro'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Título do livro'), 'Duna');
      await tester.enterText(campo('Páginas lidas'), '-3');
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Digite as páginas como número inteiro, de 0 a 9999'),
        findsOneWidget,
      );
    });

    testWidgets('livro lido exige ao menos uma página', (tester) async {
      await montarApp(tester, tamanho: tela);

      await tester.tap(find.text('Registrar livro'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Título do livro'), 'Duna');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Lido'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      expect(find.text('Informe ao menos 1 página para um livro lido'), findsOneWidget);
    });

    testWidgets('título repetido na mesmo formato é barrado', (
      tester,
    ) async {
      final acervo = await montarApp(
        tester,
        livros: [livroDe('Duna', formato: Formato.impresso)],
        tamanho: tela,
      );

      await tester.tap(find.text('Adicionar livro'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Título do livro'), 'duna');
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Você já tem'), findsOneWidget);
      expect(acervo.todos.length, 1);
    });
  });

  group('criação', () {
    testWidgets('um envio válido cria o livro e a lista mostra o novo cartão', (
      tester,
    ) async {
      final acervo = await montarApp(
        tester,
        livros: [livroDe('Alpha')],
        tamanho: tela,
      );
      expect(find.byType(LivroCard), findsOneWidget);

      await tester.tap(find.text('Adicionar livro'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Título do livro'), '  Duna  ');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Lendo'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Páginas lidas'), '7');
      await tester.tap(find.byTooltip('Dar nota 4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      expect(find.byType(LivroCard), findsNWidgets(2));
      expect(find.text('Duna'), findsOneWidget);
      expect(find.text('“Duna” entrou no catálogo'), findsOneWidget);

      final criado = acervo.todos.last;
      expect(criado.titulo, 'Duna'); // espaços das pontas removidos
      expect(criado.status, StatusLivro.lendo);
      expect(criado.paginas, 7);
      expect(criado.nota, 4);
    });

    testWidgets('cancelar sem digitar nada volta e não altera a coleção', (
      tester,
    ) async {
      final acervo = await montarApp(
        tester,
        livros: [livroDe('Alpha')],
        tamanho: tela,
      );

      await tester.tap(find.text('Adicionar livro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(LivroCard), findsOneWidget);
      expect(acervo.todos.length, 1);
    });

    testWidgets(
      'cancelar depois de digitar pergunta e, ao descartar, não salva',
      (tester) async {
        final acervo = await montarApp(
          tester,
          livros: [livroDe('Alpha')],
          tamanho: tela,
        );

        await tester.tap(find.text('Adicionar livro'));
        await tester.pumpAndSettle();
        await tester.enterText(campo('Título do livro'), 'Rascunho');
        await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
        await tester.pumpAndSettle();
        expect(find.text('Descartar alterações?'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'Descartar'));
        await tester.pumpAndSettle();

        expect(find.text('Rascunho'), findsNothing);
        expect(acervo.todos.length, 1);
      },
    );
  });

  group('edição', () {
    testWidgets('abre preenchida e atualiza o mesmo item, sem duplicar', (
      tester,
    ) async {
      // Dois títulos iguais em formatos diferentes: o id é que decide.
      final a = livroDe('Duna', formato: Formato.impresso);
      final b = livroDe(
        'Duna',
        formato: Formato.pdf,
        paginas: 4,
        status: StatusLivro.lendo,
      );
      final acervo = await montarApp(tester, livros: [a, b], tamanho: tela);

      // Abre o Duna do PDF pelo detalhe.
      await tester.tap(find.text('PDF · Romance'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar livro'));
      await tester.pumpAndSettle();

      expect(find.text('Editar livro'), findsWidgets);
      expect(
        tester.widget<TextFormField>(campo('Título do livro')).controller!.text,
        'Duna',
      );
      expect(
        tester.widget<TextFormField>(campo('Páginas lidas')).controller!.text,
        '4',
      );

      await tester.enterText(campo('Páginas lidas'), '15');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Lido'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      expect(acervo.todos.length, 2);
      expect(acervo.porId(b.id)!.paginas, 15);
      expect(acervo.porId(b.id)!.status, StatusLivro.lido);
      expect(acervo.porId(b.id)!.adicionadoEm, b.adicionadoEm);
      // O outro Duna ficou intacto.
      expect(acervo.porId(a.id)!.paginas, 0);
      expect(acervo.porId(a.id)!.status, StatusLivro.queroLer);
    });

    testWidgets('editar mantendo o próprio título não conta como repetido', (
      tester,
    ) async {
      final a = livroDe('Duna', paginas: 0);
      final acervo = await montarApp(tester, livros: [a], tamanho: tela);

      await tester.tap(find.text('Duna'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar livro'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Anotações (opcional)'), 'Leitura envolvente');
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Você já tem'), findsNothing);
      expect(acervo.porId(a.id)!.observacoes, 'Leitura envolvente');
    });

    testWidgets('cancelar a edição não muda o livro', (tester) async {
      final a = livroDe('Duna');
      final acervo = await montarApp(tester, livros: [a], tamanho: tela);

      await tester.tap(find.text('Duna'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar livro'));
      await tester.pumpAndSettle();
      await tester.enterText(campo('Título do livro'), 'Outro nome');
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Descartar'));
      await tester.pumpAndSettle();

      expect(acervo.porId(a.id)!.titulo, 'Duna');
    });
  });
}
