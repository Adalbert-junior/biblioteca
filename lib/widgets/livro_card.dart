import 'package:flutter/material.dart';

import '../models/livro.dart';
import 'capa_livro.dart';
import 'nota_estrelas.dart';
import 'status_tag.dart';

/// Cartão de um livro. Aparece na lista principal e no sorteio do painel, por
/// isso recebe só o [Livro] e o que fazer ao tocar.
class LivroCard extends StatelessWidget {
  const LivroCard({
    super.key,
    required this.livro,
    required this.aoAbrir,
    this.comHero = true,
  });

  final Livro livro;
  final VoidCallback aoAbrir;
  final bool comHero;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    Widget capa = SizedBox(
      width: 84,
      height: 108,
      child: CapaLivro(titulo: livro.titulo, raio: 14),
    );
    if (comHero) capa = Hero(tag: 'capa-${livro.id}', child: capa);

    return Semantics(
      button: true,
      label: livro.descricaoFalada,
      onTapHint: 'Abrir detalhes',
      excludeSemantics: true,
      child: Card(
        child: InkWell(
          onTap: aoAbrir,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                capa,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        livro.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: texto.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${livro.formato.rotulo} · ${livro.genero}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: texto.bodyMedium?.copyWith(
                          color: cores.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StatusTag(status: livro.status),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          NotaEstrelas(nota: livro.nota, tamanho: 17),
                          const SizedBox(width: 6),
                          if (livro.paginas > 0)
                            Flexible(
                              child: Text(
                                '${livro.paginas} pág.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: texto.bodyMedium?.copyWith(
                                  color: cores.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
