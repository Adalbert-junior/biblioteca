import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/livro.dart';

/// Onde a coleção fica guardada. O app usa [RepositorioLocal]; os testes usam
/// [RepositorioMemoria] para não depender de armazenamento do dispositivo.
abstract class Repositorio {
  Future<List<Livro>> carregar();
  Future<void> salvar(List<Livro> livros);
}

class RepositorioMemoria implements Repositorio {
  RepositorioMemoria([List<Livro> inicial = const []])
    : _livros = List.of(inicial);

  List<Livro> _livros;

  @override
  Future<List<Livro>> carregar() async => List.of(_livros);

  @override
  Future<void> salvar(List<Livro> livros) async => _livros = List.of(livros);
}

class RepositorioLocal implements Repositorio {
  static const _chave = 'minha_biblioteca.livros.v1';

  @override
  Future<List<Livro>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chave);
    if (texto == null) return [];
    try {
      final lista = jsonDecode(texto) as List<dynamic>;
      return [
        for (final item in lista) Livro.deJson(item as Map<String, dynamic>),
      ];
    } on Object {
      // Dado corrompido não pode impedir o app de abrir.
      return [];
    }
  }

  @override
  Future<void> salvar(List<Livro> livros) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chave,
      jsonEncode([for (final j in livros) j.paraJson()]),
    );
  }
}
