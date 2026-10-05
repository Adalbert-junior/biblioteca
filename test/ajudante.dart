import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_biblioteca/app.dart';
import 'package:minha_biblioteca/data/repositorio.dart';
import 'package:minha_biblioteca/models/livro.dart';
import 'package:minha_biblioteca/state/acervo.dart';
import 'package:minha_biblioteca/state/modo_tema.dart';

/// Carrega as fontes reais do app. Sem isso o teste usaria a fonte padrão de
/// teste, cujos caracteres são quadrados largos, e mediria layouts falsos.
Future<void> carregarFontes() async {
  Future<void> carregar(String familia, List<String> arquivos) async {
    final loader = FontLoader(familia);
    for (final arquivo in arquivos) {
      loader.addFont(rootBundle.load('assets/fonts/$arquivo'));
    }
    await loader.load();
  }

  await carregar('ChakraPetch', [
    'ChakraPetch-Medium.ttf',
    'ChakraPetch-SemiBold.ttf',
    'ChakraPetch-Bold.ttf',
  ]);
  await carregar('Barlow', [
    'Barlow-Regular.ttf',
    'Barlow-Medium.ttf',
    'Barlow-SemiBold.ttf',
  ]);
}

Livro livroDe(
  String titulo, {
  Formato formato = Formato.impresso,
  StatusLivro status = StatusLivro.queroLer,
  String genero = 'Romance',
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
);

/// Monta o app completo com um acervo em memória e devolve esse acervo, para
/// o teste poder inspecionar o estado depois das interações.
Future<Acervo> montarApp(
  WidgetTester tester, {
  List<Livro> livros = const [],
  Size tamanho = const Size(390, 844),
  double escalaTexto = 1,
  ThemeMode tema = ThemeMode.dark,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final acervo = Acervo(RepositorioMemoria(livros));
  await acervo.carregar();
  final modo = ModoTema(persistir: false);
  await modo.definir(tema);

  tester.platformDispatcher.textScaleFactorTestValue = escalaTexto;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(BibliotecaApp(acervo: acervo, tema: modo));
  await tester.pumpAndSettle();
  return acervo;
}
