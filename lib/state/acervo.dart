import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/repositorio.dart';
import '../models/livro.dart';

enum Ordenacao {
  recentes('Mais recentes'),
  titulo('Título (A–Z)'),
  nota('Maior nota'),
  paginas('Mais páginas');

  const Ordenacao(this.rotulo);

  final String rotulo;
}

/// Números do painel, calculados sempre a partir da coleção atual.
class Resumo {
  const Resumo({
    required this.total,
    required this.paginas,
    required this.porStatus,
    required this.paginasPorFormato,
    required this.mediaNota,
  });

  final int total;
  final int paginas;
  final Map<StatusLivro, int> porStatus;
  final Map<Formato, int> paginasPorFormato;

  /// Média só dos livros que têm nota; nula quando nenhum foi avaliado.
  final double? mediaNota;

  int quantos(StatusLivro status) => porStatus[status] ?? 0;

  /// Fração (0 a 1) de livros lidos entre os que já foram lidos de fato.
  double get taxaDeConclusao {
    final iniciados = total - quantos(StatusLivro.queroLer);
    if (iniciados == 0) return 0;
    return quantos(StatusLivro.lido) / iniciados;
  }
}

/// Estado da coleção. As telas só leem daqui e pedem alterações pelos
/// métodos; cada alteração é gravada no [Repositorio].
class Acervo extends ChangeNotifier {
  Acervo(this._repositorio);

  final Repositorio _repositorio;
  final List<Livro> _livros = [];

  bool _carregado = false;
  String _busca = '';
  StatusLivro? _filtro;
  Ordenacao _ordenacao = Ordenacao.recentes;

  bool get carregado => _carregado;
  String get busca => _busca;
  StatusLivro? get filtro => _filtro;
  Ordenacao get ordenacao => _ordenacao;
  List<Livro> get todos => List.unmodifiable(_livros);
  bool get vazio => _livros.isEmpty;

  Future<void> carregar() async {
    _livros
      ..clear()
      ..addAll(await _repositorio.carregar());
    _carregado = true;
    notifyListeners();
  }

  /// Livros que passam pela busca e pelo filtro, já na ordem escolhida.
  List<Livro> get visiveis {
    final termo = _normalizar(_busca.trim());
    final lista = _livros.where((j) {
      if (_filtro != null && j.status != _filtro) return false;
      if (termo.isEmpty) return true;
      return _normalizar(j.titulo).contains(termo) ||
          _normalizar(j.genero).contains(termo) ||
          _normalizar(j.formato.rotulo).contains(termo);
    }).toList();

    lista.sort(switch (_ordenacao) {
      Ordenacao.recentes => (a, b) => b.adicionadoEm.compareTo(a.adicionadoEm),
      Ordenacao.titulo => (a, b) => _normalizar(
        a.titulo,
      ).compareTo(_normalizar(b.titulo)),
      Ordenacao.nota => (a, b) => b.nota.compareTo(a.nota),
      Ordenacao.paginas => (a, b) => b.paginas.compareTo(a.paginas),
    });
    return lista;
  }

  Livro? porId(String id) {
    final i = _livros.indexWhere((j) => j.id == id);
    return i == -1 ? null : _livros[i];
  }

  /// Já existe um livro com esse título nesse formato? Na edição o próprio
  /// item é ignorado, senão ele conflitaria consigo mesmo.
  bool jaExiste(String titulo, Formato formato, {String? ignorarId}) {
    final alvo = _normalizar(titulo.trim());
    return _livros.any(
      (j) =>
          j.id != ignorarId &&
          j.formato == formato &&
          _normalizar(j.titulo) == alvo,
    );
  }

  void adicionar(Livro livro) {
    _livros.add(livro);
    _mudou();
  }

  void adicionarVarios(Iterable<Livro> livros) {
    _livros.addAll(livros);
    _mudou();
  }

  /// Troca o item de mesmo id. Comparar por id (e não por título) é o que
  /// impede a edição de duplicar ou de mexer em outro livro homônimo.
  void atualizar(Livro livro) {
    final i = _livros.indexWhere((j) => j.id == livro.id);
    if (i == -1) return;
    _livros[i] = livro;
    _mudou();
  }

  /// Remove e devolve o livro e a posição em que ele estava, para o "Desfazer".
  ({Livro livro, int indice})? remover(String id) {
    final i = _livros.indexWhere((j) => j.id == id);
    if (i == -1) return null;
    final removido = _livros.removeAt(i);
    _mudou();
    return (livro: removido, indice: i);
  }

  void restaurar(Livro livro, int indice) {
    _livros.insert(indice.clamp(0, _livros.length), livro);
    _mudou();
  }

  void definirBusca(String valor) {
    _busca = valor;
    notifyListeners();
  }

  void definirFiltro(StatusLivro? valor) {
    _filtro = valor;
    notifyListeners();
  }

  void definirOrdenacao(Ordenacao valor) {
    _ordenacao = valor;
    notifyListeners();
  }

  Resumo get resumo {
    final porStatus = <StatusLivro, int>{};
    final paginasPorFormato = <Formato, int>{};
    var paginas = 0;
    var somaNotas = 0;
    var avaliados = 0;
    for (final j in _livros) {
      porStatus[j.status] = (porStatus[j.status] ?? 0) + 1;
      paginasPorFormato[j.formato] =
          (paginasPorFormato[j.formato] ?? 0) + j.paginas;
      paginas += j.paginas;
      if (j.temNota) {
        somaNotas += j.nota;
        avaliados++;
      }
    }
    return Resumo(
      total: _livros.length,
      paginas: paginas,
      porStatus: porStatus,
      paginasPorFormato: paginasPorFormato,
      mediaNota: avaliados == 0 ? null : somaNotas / avaliados,
    );
  }

  void _mudou() {
    notifyListeners();
    unawaited(_repositorio.salvar(List.of(_livros)));
  }

  static String _normalizar(String texto) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const para = 'aaaaaeeeeiiiiooooouuuucn';
    final minusculo = texto.toLowerCase();
    final saida = StringBuffer();
    for (final c in minusculo.split('')) {
      final i = de.indexOf(c);
      saida.write(i == -1 ? c : para[i]);
    }
    return saida.toString();
  }
}

/// Entrega o [Acervo] para a árvore de widgets e reconstrói quem depender dele.
class AcervoScope extends InheritedNotifier<Acervo> {
  const AcervoScope({super.key, required Acervo acervo, required super.child})
    : super(notifier: acervo);

  static Acervo of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AcervoScope>();
    assert(scope != null, 'AcervoScope não encontrado acima deste widget');
    return scope!.notifier!;
  }
}
