import 'package:flutter/material.dart';

import '../models/livro.dart';
import '../state/acervo.dart';
import 'detalhe_page.dart';
import 'formulario_page.dart';

/// Os fluxos de navegação ficam aqui para que lista, detalhe e painel os
/// reaproveitem sem repetir a mesma sequência (abrir, esperar, aplicar).

void mostrarAviso(
  BuildContext context,
  String mensagem, {
  SnackBarAction? acao,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem), action: acao));
}

Future<void> cadastrarLivro(BuildContext context) async {
  final acervo = AcervoScope.of(context);
  final novo = await Navigator.of(context)
      .push<Livro>(MaterialPageRoute(builder: (_) => const FormularioPage()));
  // Cancelar devolve null: a coleção não é tocada.
  if (novo == null || !context.mounted) return;
  acervo.adicionar(novo);
  mostrarAviso(context, '“${novo.titulo}” entrou no catálogo');
}

Future<void> editarLivro(BuildContext context, Livro livro) async {
  final acervo = AcervoScope.of(context);
  final editado = await Navigator.of(
    context,
  ).push<Livro>(MaterialPageRoute(builder: (_) => FormularioPage(livro: livro)));
  if (editado == null || !context.mounted) return;
  acervo.atualizar(editado);
  mostrarAviso(context, '“${editado.titulo}” atualizado');
}

Future<void> abrirDetalhe(BuildContext context, Livro livro) {
  return Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => DetalhePage(livroId: livro.id)));
}

/// Remove o livro e oferece desfazer. O aviso é mostrado pelo
/// [ScaffoldMessenger] raiz, então continua na tela mesmo que a página que
/// pediu a exclusão já tenha fechado.
void excluirComDesfazer(BuildContext context, Livro livro) {
  final acervo = AcervoScope.of(context);
  final removido = acervo.remover(livro.id);
  if (removido == null) return;
  mostrarAviso(
    context,
    '“${livro.titulo}” foi excluído',
    acao: SnackBarAction(
      label: 'Desfazer',
      onPressed: () => acervo.restaurar(removido.livro, removido.indice),
    ),
  );
}
