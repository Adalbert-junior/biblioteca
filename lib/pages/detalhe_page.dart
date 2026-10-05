import 'package:flutter/material.dart';

import '../models/livro.dart';
import '../state/acervo.dart';
import '../theme/app_theme.dart';
import '../widgets/capa_livro.dart';
import '../widgets/nota_estrelas.dart';
import '../widgets/status_tag.dart';
import 'fluxos.dart';

/// Detalhe de um livro. Recebe só o id e lê o livro do [Acervo], então uma
/// edição ou troca de situação aparece aqui na página.
class DetalhePage extends StatelessWidget {
  const DetalhePage({super.key, required this.livroId});

  final String livroId;

  @override
  Widget build(BuildContext context) {
    final acervo = AcervoScope.of(context);
    final livro = acervo.porId(livroId);

    // O livro pode sumir enquanto esta tela está aberta (exclusão em outra
    // parte do app); nesse caso não há o que mostrar.
    if (livro == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        actions: [
          IconButton(
            tooltip: 'Editar livro',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => editarLivro(context, livro),
          ),
          IconButton(
            tooltip: 'Excluir livro',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmarExclusao(context, livro),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, restricoes) {
            final largo = restricoes.maxWidth >= 720;
            final capa = Hero(
              tag: 'capa-${livro.id}',
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: CapaLivro(titulo: livro.titulo, raio: 24),
              ),
            );
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: largo
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 300, child: capa),
                            const SizedBox(width: 32),
                            Expanded(child: _Informacoes(livro: livro)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: SizedBox(width: 200, child: capa)),
                            const SizedBox(height: 24),
                            _Informacoes(livro: livro),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context, Livro livro) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Excluir livro?'),
        content: Text('“${livro.titulo}” sai do seu catálogo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 48),
              backgroundColor: Theme.of(dialogo).colorScheme.error,
              foregroundColor: Theme.of(dialogo).colorScheme.onError,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;
    excluirComDesfazer(context, livro);
    Navigator.of(context).pop();
  }
}

class _Informacoes extends StatelessWidget {
  const _Informacoes({required this.livro});

  final Livro livro;

  @override
  Widget build(BuildContext context) {
    final acervo = AcervoScope.of(context);
    final texto = Theme.of(context).textTheme;
    final cores = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(livro.titulo, style: texto.headlineMedium),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusTag(status: livro.status),
            NotaEstrelas(nota: livro.nota, tamanho: 22),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _Dado(
              icone: Icons.book_outlined,
              rotulo: 'Formato',
              valor: livro.formato.rotulo,
            ),
            _Dado(
              icone: Icons.category_outlined,
              rotulo: 'Gênero',
              valor: livro.genero,
            ),
            _Dado(
              icone: Icons.auto_stories_outlined,
              rotulo: 'Páginas lidas',
              valor: livro.paginas == 0 ? '—' : '${livro.paginas} pág.',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Situação', style: texto.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in StatusLivro.values)
              ChoiceChip(
                avatar: Icon(
                  AppTheme.iconeDoStatus(s),
                  size: 18,
                  color: livro.status == s
                      ? cores.onPrimaryContainer
                      : AppTheme.corDoStatus(context, s),
                ),
                label: Text(s.rotulo),
                selected: livro.status == s,
                showCheckmark: false,
                onSelected: (_) {
                  if (livro.status == s) return;
                  acervo.atualizar(livro.copyWith(status: s));
                },
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Anotações', style: texto.titleSmall),
        const SizedBox(height: 8),
        Text(
          livro.observacoes.isEmpty
              ? 'Nenhuma anotação ainda. Use “Editar” para registrar o que achou.'
              : livro.observacoes,
          style: texto.bodyLarge?.copyWith(
            color: livro.observacoes.isEmpty
                ? cores.onSurfaceVariant
                : cores.onSurface,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Adicionado em ${_data(livro.adicionadoEm)}',
          style: texto.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => editarLivro(context, livro),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar livro'),
        ),
      ],
    );
  }

  static String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _Dado extends StatelessWidget {
  const _Dado({required this.icone, required this.rotulo, required this.valor});

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final cores = Theme.of(context).colorScheme;
    return Expanded(
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 20, color: cores.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(
              rotulo,
              style: texto.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
            ),
            Text(
              valor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: texto.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
