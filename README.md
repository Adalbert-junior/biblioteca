# Minha Biblioteca

Catálogo pessoal local de livros em Flutter. Registre o que quer ler, o que
está lendo, o que já leu e as leituras abandonadas.

## Funcionalidades

- Lista no celular e grade em telas largas, com busca, filtros e ordenação.
- Estado vazio com cadastro e coleção demonstrativa de livros.
- Detalhes, criação e edição com validação e feedback.
- Exclusão com confirmação e opção de desfazer.
- Status: Quero ler, Lendo, Lido e Abandonado.
- Formatos: Impresso, E-book, PDF, Bolso e Outro.
- Gênero literário, páginas lidas, nota e anotações.
- Painel com livros, páginas lidas, nota média, conclusão e gráficos.
- Sorteio da próxima leitura e conquistas baseadas na coleção.
- Persistência local, temas claro/escuro/sistema e versão web.

As páginas indicam a quantidade já lida, não o total de páginas da edição.
Os exemplos são demonstrativos. Não há autenticação, API nem sincronização.

## Executar e verificar

Os requisitos de SDK e dependências estão em `pubspec.yaml`, preservados da
base enviada. Com uma versão compatível do Flutter instalada:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

```bash
flutter build apk --release
flutter build web --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`.
Web: `build/web`. Esta versão não possui implantação pública própria.

## Estrutura

```text
lib/
  models/   Livro, StatusLivro, Formato e conquistas
  data/     repositórios e exemplos
  state/    acervo, filtros, ordenação e tema
  pages/    lista, detalhe, formulário, painel e navegação
  widgets/  capas, cartões, filtros, notas, gráficos e sorteio
  theme/    tema Material 3
test/       testes de modelo, estado, telas e acessibilidade
android/    projeto Android
web/        projeto web
```

## Adaptação e créditos

Esta versão adapta o domínio do projeto Zerado para livros, preservando a
organização e os fluxos da base fornecida.
Autores da base: Luiz Ragi, Israel Messias e Adalbert.

Foram adaptados os modelos, os rótulos, os formatos, os gêneros, o progresso
em páginas, os exemplos, os nomes de arquivos, os imports, os testes e os
identificadores de aplicativo e de armazenamento. Os dados antigos do
catálogo de jogos não são importados como livros.

## Validação da preparação

A integridade do ZIP, os caminhos dos imports, os enums e a consistência
dos identificadores foram conferidos. Os testes existentes foram adaptados
ao domínio de livros. Flutter e Dart não estão disponíveis no ambiente de
preparação: não houve execução dos testes, análise Flutter nem compilação.

## GitHub

Extraia o ZIP e envie o conteúdo de `minha_biblioteca` à raiz do repositório.
No GitHub Desktop, selecione a pasta, faça o commit e publique o repositório.
Envie os arquivos extraídos, não somente o ZIP.

## Recursos

Flutter, Dart, Material Icons, shared_preferences, flutter_localizations e
cupertino_icons. Fontes Barlow e Chakra Petch mantidas da base enviada.
