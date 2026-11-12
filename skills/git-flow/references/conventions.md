# Convenções do projeto (`.gitflow`) e bump de versão

## Arquivo `.gitflow`

Arquivo opcional na raiz do repositório, formato `CHAVE=valor`, comentários com `#`. **Commite-o** para o time todo (e todos os agentes) seguirem o mesmo padrão. Chaves ausentes usam o default/autodetecção.

```ini
# .gitflow — convenções de Git Flow deste repositório
MAIN_BRANCH=main            # branch de produção (main | master)
DEVELOP_BRANCH=develop      # branch de integração
TAG_PREFIX=                 # vazio -> 1.2.0 | v -> v1.2.0
VERSION_FILE=package.json   # package.json | pyproject.toml | Cargo.toml | composer.json | VERSION | (vazio = só tag)
FEATURE_MERGE=pr            # pr (Pull Request) | local (merge --no-ff local)
CHANGELOG=false             # true -> manter CHANGELOG.md na release
GITHUB_RELEASE=true         # true -> oferecer gh release create
PROTECTED_BRANCHES=false    # true -> main/develop só aceitam PR (usar fluxo por PR)
```

`TAG_PREFIX=` (vazio) é um valor válido e **sobrescreve** a autodetecção.

## Como fazer o bump da versão

Sempre na `release/X.Y.Z` (ou `hotfix/X.Y.Z`), em **um commit só**:

```
chore: bump version to X.Y.Z
```

| Projeto | Como alterar | Arquivos no commit |
|---|---|---|
| Node (`package.json`) | `npm version X.Y.Z --no-git-tag-version` (atualiza o lock) ou editar `"version"` | `package.json` + `package-lock.json` (se mudou) |
| Python (`pyproject.toml`) | editar `version = "X.Y.Z"` em `[project]` ou `[tool.poetry]` | `pyproject.toml` |
| Rust (`Cargo.toml`) | editar `version = "X.Y.Z"` em `[package]`; rodar `cargo check` para atualizar o `Cargo.lock` | `Cargo.toml` + `Cargo.lock` |
| PHP (`composer.json`) | editar `"version"` (muitos projetos nem usam; nesse caso só tag) | `composer.json` |
| Arquivo `VERSION` | escrever `X.Y.Z` | `VERSION` |
| Outros (Java/Gradle/.NET…) | editar o campo de versão do projeto | arquivo de build |
| Sem arquivo de versão | **sem commit de bump**; a versão vive só na tag | — |

Regras:

- **Nunca** use `npm version` sem `--no-git-tag-version`: ele cria commit e tag leve por conta própria e quebra o fluxo (tag deve ser anotada e ficar na `main`).
- Depois do bump, confira com `git diff --stat HEAD~1` que só os arquivos de versão mudaram.
- A fonte da verdade da versão é a **tag anotada**; o arquivo deve ficar igual a ela na `main`.

## Mensagens de commit

O fluxo só impõe o commit de bump e as mensagens de merge:

- `chore: bump version to X.Y.Z`
- `Merge branch 'release/X.Y.Z'` / `Merge branch 'hotfix/X.Y.Z'`
- `Merge tag '<TAG>' into develop`
- Tag: `Release X.Y.Z` (anotada)

Para os demais commits, siga o padrão do projeto. Se o time usa Conventional Commits (`feat:`, `fix:`, `feat!:`), a sugestão de bump do `gitflow-status.sh` fica mais precisa.

## Nomes de branches

- `feature/<descricao-em-kebab-case>` (ex.: `feature/forum-de-duvidas`); se o time usa tickets: `feature/ABC-123-forum`
- `release/X.Y.Z` e `hotfix/X.Y.Z` — sempre **sem** `v`
- Sem espaços, acentos ou maiúsculas
