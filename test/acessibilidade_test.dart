import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_biblioteca/models/livro.dart';
import 'package:minha_biblioteca/theme/app_theme.dart';

import 'ajudante.dart';

double _luminancia(Color c) => c.computeLuminance();

double contraste(Color a, Color b) {
  final claro = _luminancia(a) > _luminancia(b) ? a : b;
  final escuro = identical(claro, a) ? b : a;
  return (_luminancia(claro) + 0.05) / (_luminancia(escuro) + 0.05);
}

void main() {
  setUpAll(carregarFontes);

  group('contraste das cores do tema (mínimo 4,5:1 para texto)', () {
    for (final (nome, tema) in [
      ('escuro', AppTheme.escuro),
      ('claro', AppTheme.claro),
    ]) {
      test('tema $nome: texto sobre as superfícies', () {
        final c = tema.colorScheme;
        final fundos = [
          c.surface,
          c.surfaceContainerLowest,
          c.surfaceContainer,
          c.surfaceContainerHigh,
        ];
        for (final fundo in fundos) {
          expect(contraste(c.onSurface, fundo), greaterThanOrEqualTo(4.5));
          expect(
            contraste(c.onSurfaceVariant, fundo),
            greaterThanOrEqualTo(4.5),
            reason: 'texto secundário sobre $fundo',
          );
        }
        expect(contraste(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
        expect(
          contraste(c.onPrimaryContainer, c.primaryContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(contraste(c.error, c.surface), greaterThanOrEqualTo(4.5));
        expect(contraste(c.primary, c.surface), greaterThanOrEqualTo(4.5));
      });

      testWidgets('tema $nome: cores de situação legíveis nos cartões', (
        tester,
      ) async {
        late BuildContext contexto;
        await tester.pumpWidget(
          MaterialApp(
            theme: tema,
            home: Builder(
              builder: (c) {
                contexto = c;
                return const SizedBox();
              },
            ),
          ),
        );
        final fundo = tema.colorScheme.surfaceContainer;
        for (final s in StatusLivro.values) {
          final cor = AppTheme.corDoStatus(contexto, s);
          // A etiqueta pinta um véu de 14% da própria cor sobre o cartão.
          final etiqueta = Color.alphaBlend(cor.withValues(alpha: 0.14), fundo);
          expect(
            contraste(cor, etiqueta),
            greaterThanOrEqualTo(4.5),
            reason: '${s.rotulo} no tema $nome',
          );
        }
      });
    }
  });

  group('diretrizes de acessibilidade do Flutter', () {
    final livros = [
      livroDe(
        '1984',
        status: StatusLivro.lendo,
        nota: 4,
        paginas: 31,
        observacoes: 'Boa demais.',
      ),
      livroDe('O Pequeno Príncipe', status: StatusLivro.lido, nota: 5, paginas: 14),
    ];

    for (final modo in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets('lista: áreas de toque, rótulos e contraste ($modo)', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await montarApp(tester, livros: livros, tema: modo);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('formulário: áreas de toque, rótulos e contraste ($modo)', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await montarApp(
          tester,
          livros: livros,
          tema: modo,
          tamanho: const Size(420, 1500),
        );
        await tester.tap(find.text('Adicionar livro'));
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets('detalhe: áreas de toque, rótulos e contraste ($modo)', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await montarApp(tester, livros: livros, tema: modo);
        await tester.tap(find.text('1984'));
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    testWidgets('o cartão é um botão com descrição falada completa', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await montarApp(tester, livros: [livros.first]);

      expect(
        find.bySemanticsLabel(
          '1984, Impresso, Lendo, nota 4 de 5, 31 páginas lidas',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('botões só com ícone têm tooltip', (tester) async {
      await montarApp(tester, livros: livros);
      expect(find.byTooltip('Painel e estatísticas'), findsOneWidget);
      expect(find.byTooltip('Aparência do app'), findsOneWidget);
      expect(find.byTooltip('Ordenar: Mais recentes'), findsOneWidget);
    });
  });
}
