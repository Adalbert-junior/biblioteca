import 'package:flutter_test/flutter_test.dart';
import 'package:minha_biblioteca/data/repositorio.dart';
import 'package:minha_biblioteca/models/livro.dart';
import 'package:minha_biblioteca/state/acervo.dart';

import 'ajudante.dart';

void main() {
  group('Livro', () {
    test('cada livro novo recebe um id diferente', () {
      final ids = {for (var i = 0; i < 200; i++) livroDe('Livro').id};
      expect(ids.length, 200);
    });

    test('copyWith mantém o id e a data de criação', () {
      final original = livroDe('O Pequeno Príncipe', paginas: 5);
      final copia = original.copyWith(titulo: 'O Pequeno Príncipe 2', paginas: 9);
      expect(copia.id, original.id);
      expect(copia.adicionadoEm, original.adicionadoEm);
      expect(copia.titulo, 'O Pequeno Príncipe 2');
      expect(copia.paginas, 9);
    });

    test('vai para JSON e volta sem perder nada', () {
      final original = livroDe(
        '1984',
        formato: Formato.bolso,
        status: StatusLivro.lido,
        genero: 'Infantil',
        nota: 4,
        paginas: 31,
        observacoes: 'Ótimo',
      );
      final volta = Livro.deJson(original.paraJson());
      expect(volta.id, original.id);
      expect(volta.titulo, '1984');
      expect(volta.formato, Formato.bolso);
      expect(volta.status, StatusLivro.lido);
      expect(volta.nota, 4);
      expect(volta.paginas, 31);
      expect(volta.observacoes, 'Ótimo');
    });

    test('a descrição falada resume o que aparece no cartão', () {
      final j = livroDe('1984', status: StatusLivro.lendo, nota: 4, paginas: 1);
      expect(
        j.descricaoFalada,
        '1984, Impresso, Lendo, nota 4 de 5, 1 página lida',
      );
    });
  });

  group('Acervo', () {
    late Acervo acervo;
    late RepositorioMemoria repositorio;

    setUp(() async {
      repositorio = RepositorioMemoria();
      acervo = Acervo(repositorio);
      await acervo.carregar();
    });

    test('começa vazio depois de carregar', () {
      expect(acervo.carregado, isTrue);
      expect(acervo.vazio, isTrue);
    });

    test('adicionar coloca o livro e grava no repositório', () async {
      acervo.adicionar(livroDe('Duna'));
      expect(acervo.todos.map((j) => j.titulo), ['Duna']);
      expect((await repositorio.carregar()).length, 1);
    });

    test('atualizar troca só o livro de mesmo id, sem duplicar', () {
      final a = livroDe('Duna', formato: Formato.impresso);
      final b = livroDe('Duna', formato: Formato.pdf);
      acervo
        ..adicionar(a)
        ..adicionar(b);

      acervo.atualizar(b.copyWith(status: StatusLivro.lido, paginas: 12));

      expect(acervo.todos.length, 2);
      expect(acervo.porId(a.id)!.status, StatusLivro.queroLer);
      expect(acervo.porId(b.id)!.status, StatusLivro.lido);
    });

    test('atualizar um id que não existe não faz nada', () {
      acervo.adicionar(livroDe('Duna'));
      acervo.atualizar(livroDe('Outro'));
      expect(acervo.todos.length, 1);
    });

    test('remover devolve a posição e restaurar recoloca no mesmo lugar', () {
      final a = livroDe('A');
      final b = livroDe('B');
      final c = livroDe('C');
      acervo.adicionarVarios([a, b, c]);

      final removido = acervo.remover(b.id)!;
      expect(acervo.todos.map((j) => j.titulo), ['A', 'C']);

      acervo.restaurar(removido.livro, removido.indice);
      expect(acervo.todos.map((j) => j.titulo), ['A', 'B', 'C']);
    });

    test('jaExiste considera o formato e ignora o próprio item', () {
      final a = livroDe('Duna', formato: Formato.impresso);
      acervo.adicionar(a);

      expect(acervo.jaExiste('  duna ', Formato.impresso), isTrue);
      expect(acervo.jaExiste('Duna', Formato.pdf), isFalse);
      expect(acervo.jaExiste('Duna', Formato.impresso, ignorarId: a.id), isFalse);
    });

    test(
      'a busca ignora acento e caixa e olha título, gênero e formato',
      () {
        acervo.adicionarVarios([
          livroDe('História Máxima', genero: 'Biografia'),
          livroDe('A Ilha do Tesouro', genero: 'Aventura', formato: Formato.bolso),
        ]);

        acervo.definirBusca('historia');
        expect(acervo.visiveis.map((j) => j.titulo), ['História Máxima']);

        acervo.definirBusca('bolso');
        expect(acervo.visiveis.map((j) => j.titulo), ['A Ilha do Tesouro']);

        acervo.definirBusca('AVENTURA');
        expect(acervo.visiveis.map((j) => j.titulo), ['A Ilha do Tesouro']);
      },
    );

    test('o filtro de situação e a ordenação funcionam juntos', () {
      acervo.adicionarVarios([
        livroDe('B', status: StatusLivro.lido, nota: 3, paginas: 10),
        livroDe('A', status: StatusLivro.lido, nota: 5, paginas: 2),
        livroDe('C', status: StatusLivro.lendo, nota: 4, paginas: 40),
      ]);

      acervo.definirFiltro(StatusLivro.lido);
      acervo.definirOrdenacao(Ordenacao.titulo);
      expect(acervo.visiveis.map((j) => j.titulo), ['A', 'B']);

      acervo.definirOrdenacao(Ordenacao.nota);
      expect(acervo.visiveis.map((j) => j.titulo), ['A', 'B']);

      acervo.definirOrdenacao(Ordenacao.paginas);
      expect(acervo.visiveis.map((j) => j.titulo), ['B', 'A']);
    });

    test('o resumo soma paginas, conta situações e tira a média das notas', () {
      acervo.adicionarVarios([
        livroDe('A', status: StatusLivro.lido, nota: 5, paginas: 10),
        livroDe('B', status: StatusLivro.lido, nota: 3, paginas: 20),
        livroDe('C', status: StatusLivro.lendo, paginas: 5),
        livroDe('D'),
      ]);

      final r = acervo.resumo;
      expect(r.total, 4);
      expect(r.paginas, 35);
      expect(r.quantos(StatusLivro.lido), 2);
      expect(r.mediaNota, 4);
      // 2 lidos entre 3 que foram iniciados (o "quero ler" não conta).
      expect(r.taxaDeConclusao, closeTo(2 / 3, 1e-9));
    });

    test('sem nenhuma nota a média é nula em vez de zero', () {
      acervo.adicionar(livroDe('A'));
      expect(acervo.resumo.mediaNota, isNull);
    });
  });
}
