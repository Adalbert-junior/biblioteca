import 'package:flutter/material.dart';

import '../data/exemplos.dart';
import '../models/livro.dart';
import '../state/acervo.dart';
import '../state/modo_tema.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/filtros_catalogo.dart';
import '../widgets/livro_card.dart';
import 'fluxos.dart';
import 'painel_page.dart';
import 'sobre.dart';

class ListaPage extends StatelessWidget {
  const ListaPage({super.key, required this.tema});

  final ModoTema tema;

  @override
  Widget build(BuildContext context) {
    final acervo = AcervoScope.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const _Marca(),
        actions: [
          IconButton(
            tooltip: 'Painel e estatísticas',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push<void>(MaterialPageRoute(builder: (_) => const PainelPage())),
          ),
          IconButton(
            tooltip: 'Sobre o projeto',
            icon: const Icon(Icons.info_outline),
            onPressed: () => mostrarSobre(context),
          ),
          _MenuTema(tema: tema),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: acervo.carregado && !acervo.vazio
          ? FloatingActionButton.extended(
              onPressed: () => cadastrarLivro(context),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar livro'),
            )
          : null,
      body: SafeArea(child: _Corpo(acervo: acervo)),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      label: 'Minha Biblioteca, coleção pessoal de livros',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cores.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.menu_book_rounded, color: cores.onPrimary, size: 22),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Minha Biblioteca'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTema extends StatelessWidget {
  const _MenuTema({required this.tema});

  final ModoTema tema;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tema,
      builder: (context, _) => PopupMenuButton<ThemeMode>(
        tooltip: 'Aparência do app',
        icon: const Icon(Icons.brightness_6_outlined),
        initialValue: tema.modo,
        onSelected: tema.definir,
        itemBuilder: (_) => const [
          PopupMenuItem(value: ThemeMode.dark, child: Text('Escuro')),
          PopupMenuItem(value: ThemeMode.light, child: Text('Claro')),
          PopupMenuItem(value: ThemeMode.system, child: Text('Do sistema')),
        ],
      ),
    );
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo({required this.acervo});

  final Acervo acervo;

  @override
  Widget build(BuildContext context) {
    if (!acervo.carregado) {
      return const Center(child: CircularProgressIndicator());
    }

    if (acervo.vazio) {
      return EstadoVazio(
        icone: Icons.menu_book_outlined,
        titulo: 'Sua coleção ainda está vazia',
        mensagem:
            'Comece sua coleção. Registre seu primeiro livro ou carregue '
            'uma coleção de exemplo para explorar o app.',
        acoes: [
          FilledButton.icon(
            onPressed: () => cadastrarLivro(context),
            icon: const Icon(Icons.add),
            label: const Text('Registrar livro'),
          ),
          OutlinedButton.icon(
            onPressed: () => acervo.adicionarVarios(livrosDeExemplo()),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Experimentar coleção de exemplo'),
          ),
        ],
      );
    }

    final visiveis = acervo.visiveis;
    final escala = MediaQuery.textScalerOf(context).scale(16) / 16;
    // Uma coluna em telas estreitas, duas ou mais a partir de ~800 px.
    final grade = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 460,
      mainAxisExtent: 136 * escala.clamp(1.0, 2.2),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Faixa(acervo: acervo),
                    const SizedBox(height: 16),
                    FiltrosCatalogo(acervo: acervo),
                  ],
                ),
              ),
            ),
            if (visiveis.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EstadoVazio(
                  icone: Icons.search_off,
                  titulo: 'Nada por aqui',
                  mensagem:
                      'Nenhum livro combina com a busca e o filtro atuais.',
                  acoes: [
                    OutlinedButton(
                      onPressed: () {
                        acervo.definirBusca('');
                        acervo.definirFiltro(null);
                      },
                      child: const Text('Limpar filtros'),
                    ),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverGrid.builder(
                  gridDelegate: grade,
                  itemCount: visiveis.length,
                  itemBuilder: (context, i) {
                    final livro = visiveis[i];
                    return _ItemDispensavel(key: ValueKey(livro.id), livro: livro);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Deslizar para o lado exclui (com desfazer); tocar abre o detalhe.
class _ItemDispensavel extends StatelessWidget {
  const _ItemDispensavel({super.key, required this.livro});

  final Livro livro;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey('dismiss-${livro.id}'),
      onDismissed: (_) => excluirComDesfazer(context, livro),
      background: _FundoExcluir(
        cor: cores.error,
        alinhamento: Alignment.centerLeft,
      ),
      secondaryBackground: _FundoExcluir(
        cor: cores.error,
        alinhamento: Alignment.centerRight,
      ),
      child: LivroCard(livro: livro, aoAbrir: () => abrirDetalhe(context, livro)),
    );
  }
}

class _FundoExcluir extends StatelessWidget {
  const _FundoExcluir({required this.cor, required this.alinhamento});

  final Color cor;
  final Alignment alinhamento;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alinhamento,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(Icons.delete_outline, color: cor),
    );
  }
}

/// Resumo de uma linha no topo; toca para abrir o painel completo.
class _Faixa extends StatelessWidget {
  const _Faixa({required this.acervo});

  final Acervo acervo;

  @override
  Widget build(BuildContext context) {
    final resumo = acervo.resumo;
    final cores = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    Widget item(String valor, String rotulo) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor, style: texto.titleLarge?.copyWith(color: cores.primary)),
          Text(
            rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: texto.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label:
          '${resumo.total} livros, ${resumo.quantos(StatusLivro.lido)} lidos, '
          '${resumo.paginas} páginas lidas. Abrir painel',
      excludeSemantics: true,
      child: Card(
        child: InkWell(
          onTap: () => Navigator.of(
            context,
          ).push<void>(MaterialPageRoute(builder: (_) => const PainelPage())),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                item('${resumo.total}', 'no catálogo'),
                item('${resumo.quantos(StatusLivro.lido)}', 'lidos'),
                item('${resumo.paginas} pág.', 'lidas'),
                Icon(Icons.chevron_right, color: cores.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
