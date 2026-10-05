import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/livro.dart';
import '../state/acervo.dart';
import '../widgets/capa_livro.dart';
import '../widgets/nota_estrelas.dart';

/// Formulário único para cadastrar e editar. Com [livro] ele abre preenchido e
/// preserva o id; sem [livro] cria um livro novo. Ao salvar devolve o [Livro] pelo
/// `pop`; ao cancelar devolve null e quem chamou não altera nada.
class FormularioPage extends StatefulWidget {
  const FormularioPage({super.key, this.livro});

  final Livro? livro;

  bool get edicao => livro != null;

  @override
  State<FormularioPage> createState() => _FormularioPageState();
}

class _FormularioPageState extends State<FormularioPage> {
  final _chave = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _paginas;
  late final TextEditingController _observacoes;

  late Formato _formato;
  late String _genero;
  late StatusLivro _status;
  late int _nota;

  @override
  void initState() {
    super.initState();
    final j = widget.livro;
    _titulo = TextEditingController(text: j?.titulo ?? '');
    _paginas = TextEditingController(
      text: j == null || j.paginas == 0 ? '' : '${j.paginas}',
    );
    _observacoes = TextEditingController(text: j?.observacoes ?? '');
    _formato = j?.formato ?? Formato.impresso;
    _genero = j?.genero ?? generos.first;
    _status = j?.status ?? StatusLivro.queroLer;
    _nota = j?.nota ?? 0;
    // O PopScope precisa saber, a cada tecla, se já existe algo a perder.
    for (final c in [_titulo, _paginas, _observacoes]) {
      c.addListener(_reconstruir);
    }
  }

  void _reconstruir() => setState(() {});

  @override
  void dispose() {
    _titulo.dispose();
    _paginas.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  int get _paginasDigitadas => int.tryParse(_paginas.text.trim()) ?? 0;

  /// Algo mudou em relação ao que o formulário abriu?
  bool get _alterado {
    final j = widget.livro;
    if (j == null) {
      return _titulo.text.trim().isNotEmpty ||
          _paginas.text.trim().isNotEmpty ||
          _observacoes.text.trim().isNotEmpty ||
          _nota != 0 ||
          _status != StatusLivro.queroLer ||
          _formato != Formato.impresso ||
          _genero != generos.first;
    }
    return _titulo.text.trim() != j.titulo ||
        _paginasDigitadas != j.paginas ||
        _observacoes.text.trim() != j.observacoes ||
        _nota != j.nota ||
        _status != j.status ||
        _formato != j.formato ||
        _genero != j.genero;
  }

  String? _validarTitulo(String? valor) {
    final titulo = (valor ?? '').trim();
    if (titulo.isEmpty) return 'Informe o título';
    if (titulo.length > 60) return 'Use no máximo 60 caracteres';
    final acervo = AcervoScope.of(context);
    if (acervo.jaExiste(titulo, _formato, ignorarId: widget.livro?.id)) {
      return 'Você já tem “$titulo” no formato ${_formato.rotulo}';
    }
    return null;
  }

  String? _validarPaginas(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isNotEmpty) {
      final n = int.tryParse(texto);
      if (n == null || n < 0 || n > 9999) {
        return 'Digite as páginas como número inteiro, de 0 a 9999';
      }
    }
    final n = int.tryParse(texto) ?? 0;
    if (_status == StatusLivro.queroLer && n > 0) {
      return 'Quem ainda não começou não tem páginas. Mude a situação.';
    }
    if (_status == StatusLivro.lido && n == 0) {
      return 'Informe ao menos 1 página para um livro lido';
    }
    return null;
  }

  void _salvar() {
    if (!_chave.currentState!.validate()) return;

    final titulo = _titulo.text.trim();
    final paginas = _paginasDigitadas;
    final observacoes = _observacoes.text.trim();
    // Quem ainda não leu não tem o que avaliar.
    final nota = _status == StatusLivro.queroLer ? 0 : _nota;

    final livro = widget.livro == null
        ? Livro.novo(
            titulo: titulo,
            formato: _formato,
            genero: _genero,
            status: _status,
            nota: nota,
            paginas: paginas,
            observacoes: observacoes,
          )
        : widget.livro!.copyWith(
            titulo: titulo,
            formato: _formato,
            genero: _genero,
            status: _status,
            nota: nota,
            paginas: paginas,
            observacoes: observacoes,
          );
    Navigator.of(context).pop(livro);
  }

  Future<void> _cancelar() async {
    if (!_alterado) {
      Navigator.of(context).pop();
      return;
    }
    final descartar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text('O que você digitou nesta tela será perdido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (descartar == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final cores = Theme.of(context).colorScheme;

    return PopScope(
      // Se há algo digitado, o botão voltar também pergunta antes de sair.
      canPop: !_alterado,
      onPopInvokedWithResult: (jaSaiu, _) {
        if (!jaSaiu) _cancelar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.edicao ? 'Editar livro' : 'Adicionar livro'),
          leading: IconButton(
            tooltip: 'Cancelar',
            icon: const Icon(Icons.close),
            onPressed: _cancelar,
          ),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _chave,
                // Depois do primeiro toque no campo, o erro some assim que for corrigido.
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Center(
                      child: ListenableBuilder(
                        listenable: _titulo,
                        builder: (_, _) => SizedBox(
                          width: 110,
                          height: 146,
                          child: CapaLivro(titulo: _titulo.text, raio: 18),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        child: Text(
                          'A capa é gerada a partir do título',
                          style: texto.bodyMedium?.copyWith(
                            color: cores.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _titulo,
                      autofocus: !widget.edicao,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Título do livro',
                        hintText: 'Ex.: Dom Casmurro',
                        counterText: '',
                      ),
                      validator: _validarTitulo,
                    ),
                    const SizedBox(height: 20),
                    _Grupo(
                      titulo: 'Formato',
                      filhos: [
                        for (final p in Formato.values)
                          ChoiceChip(
                            label: Text(p.rotulo),
                            selected: _formato == p,
                            onSelected: (_) => setState(() => _formato = p),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _genero,
                      decoration: const InputDecoration(labelText: 'Gênero'),
                      items: [
                        for (final g in generos)
                          DropdownMenuItem(value: g, child: Text(g)),
                      ],
                      onChanged: (g) => setState(() => _genero = g ?? _genero),
                    ),
                    const SizedBox(height: 20),
                    _Grupo(
                      titulo: 'Situação',
                      filhos: [
                        for (final s in StatusLivro.values)
                          ChoiceChip(
                            label: Text(s.rotulo),
                            selected: _status == s,
                            onSelected: (_) => setState(() {
                              _status = s;
                              if (s == StatusLivro.queroLer) _nota = 0;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _paginas,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Páginas lidas',
                        hintText: '0',
                        suffixText: 'pág.',
                      ),
                      validator: _validarPaginas,
                    ),
                    const SizedBox(height: 20),
                    Text('Nota', style: texto.titleSmall),
                    const SizedBox(height: 4),
                    if (_status == StatusLivro.queroLer)
                      Text(
                        'Disponível depois que você começar a ler.',
                        style: texto.bodyMedium?.copyWith(
                          color: cores.onSurfaceVariant,
                        ),
                      )
                    else
                      NotaEstrelas(
                        nota: _nota,
                        aoMudar: (n) => setState(() => _nota = n),
                      ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _observacoes,
                      maxLines: 4,
                      maxLength: 280,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Anotações (opcional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cancelar,
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _salvar,
                            icon: const Icon(Icons.check),
                            label: Text(
                              widget.edicao ? 'Salvar alterações' : 'Adicionar',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.titulo, required this.filhos});

  final String titulo;
  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: filhos),
      ],
    );
  }
}
