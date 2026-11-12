---
name: git-flow
description: Aplica o Git Flow (main, develop, feature/*, release/*, hotfix/*) com versionamento SemVer e tags anotadas em qualquer projeto, e faz o setup inicial das branches quando elas ainda não existem. Use quando o usuário pedir para criar feature, release ou hotfix, finalizar release, bump de versão, criar tag, GitHub Release, configurar git flow, criar a branch develop ou organizar branches. Use when asked about git flow, release, hotfix, version bump, tagging or branch setup.
---

# Git Flow e Versionamento

Fluxo **manual** (comandos `git` puros, sem a CLI `git-flow`) baseado no modelo de Vincent Driessen. Funciona em qualquer linguagem e em qualquer agente: tudo aqui é texto + comandos de terminal.

## Modelo em 30 segundos

| Branch | Tipo | Nasce de | Volta para |
|---|---|---|---|
| `main` | permanente (produção, cada commit = versão) | — | — |
| `develop` | permanente (integração do próximo release) | `main` | — |
| `feature/<nome>` | temporária | `develop` | `develop` (nunca direto na `main`) |
| `release/X.Y.Z` | temporária (homologação + bump) | `develop` | `main` **e** `develop` |
| `hotfix/X.Y.Z` | temporária (correção urgente em produção) | `main` | `main` **e** `develop` |

Se o projeto faz **entrega contínua** (vários deploys por dia), avise **uma vez** que o próprio autor do modelo recomenda GitHub Flow ou trunk-based nesse cenário, e siga o que o usuário decidir.

## Regras de segurança (valem sempre)

1. **Nunca** faça `push`, crie tag remota, `gh release create` ou apague branch remota sem o usuário pedir **explicitamente** nesta conversa. Mostre o comando e peça confirmação.
2. **Nunca** use `push --force` em `main`/`develop`, `reset --hard`, `clean -fd` ou `--no-verify` sem pedido explícito.
3. Working tree precisa estar **limpa** antes de trocar de branch/mergear. Se estiver suja, pare e pergunte (commit, stash ou abortar).
4. Em **conflito de merge**, pare, mostre os arquivos em conflito e pergunte como resolver. Não resolva "no chute".
5. Apague branches só com `git branch -d`. Se pedir `-D`, explique por quê e confirme.
6. Merges de integração (feature, release, hotfix): sempre `--no-ff`.
7. Tags são **anotadas** (`git tag -a`), nascem na **main** (no merge commit da release/hotfix), nunca na `release/`.
8. Faça `git add` só dos arquivos da tarefa (para o bump: o arquivo de versão e o lockfile, se mudou). Nada de `git add -A` às cegas.

## Passo 0 — Diagnóstico (sempre primeiro)

Rode o script desta skill (caminho relativo à pasta da skill):

```bash
bash scripts/gitflow-status.sh
```

Ele é **somente leitura** e mostra: branch atual, árvore limpa/suja, convenções detectadas, se `main`/`develop` existem (local e remoto), releases/hotfixes abertos, última tag, versão no arquivo, divergência tag × versão, commits desde a última tag com **sugestão de bump** e se a `main` tem commits que a `develop` não tem.

Se não for possível rodar o script, faça o equivalente: `git status -sb`, `git branch -a`, `git tag --sort=-v:refname | head`, `git remote -v`.

## Passo 1 — O repositório está pronto para Git Flow?

Se o diagnóstico mostrar `develop` ausente, repositório sem commits, sem `main`, sem tag base ou sem `.gitflow`, **leia `references/setup.md`** e conduza o setup (pergunte antes de cada ação com efeito remoto). Só siga para os fluxos abaixo quando o setup estiver completo ou o usuário disser para ignorar.

## Convenções (defaults e como sobrescrever)

| Item | Default | Detecção |
|---|---|---|
| Branch de produção | `main` (ou `master` se for a existente) | automática |
| Branch de integração | `develop` | — |
| Prefixo da tag | vazio → `1.2.0` | usa `v` se as tags existentes já usam `v` |
| Arquivo de versão | `package.json`, `pyproject.toml`, `Cargo.toml`, `composer.json` ou `VERSION` | primeiro que existir; senão só tag |
| Commit de bump | `chore: bump version to X.Y.Z` | — |
| Changelog | **não** mantém `CHANGELOG.md`; notas vão na GitHub Release | `CHANGELOG=true` muda isso |
| Feature → develop | via Pull Request | `FEATURE_MERGE=local` faz merge local |

Se existir um arquivo **`.gitflow`** na raiz (formato `CHAVE=valor`, commitado para o time todo), ele manda. Detalhes e exemplo em `references/conventions.md`. Se o time ainda não tem, ofereça criá-lo no setup.

Notação nos comandos: `<MAIN>`, `<DEV>`, `<TAG>` = `<prefixo>X.Y.Z`. Branches `release/` e `hotfix/` **nunca** levam o prefixo `v`.

## Escolher a versão (SemVer)

Pergunte a versão alvo se o usuário não disser; sugira com base nos commits (o script já dá uma sugestão):

- **MAIOR** (`X+1.0.0`): breaking change (`!` no tipo ou `BREAKING CHANGE:` no corpo)
- **MENOR** (`X.Y+1.0`): funcionalidade nova (`feat`), PATCH zera
- **PATCH** (`X.Y.Z+1`): correção (`fix`) ou ajuste interno

A sugestão é heurística; o usuário decide. Em `0.y.z` o SemVer permite quebras a qualquer momento, então confirme.

## Checklist de release (copie e marque)

```
Release X.Y.Z:
- [ ] Diagnóstico ok (árvore limpa, develop atualizada)
- [ ] release/X.Y.Z criada a partir da develop
- [ ] Bump no arquivo de versão + commit
- [ ] (homologação / correções na release, se houver)
- [ ] Merge --no-ff em main
- [ ] Tag anotada na main
- [ ] Merge da release e da tag em develop
- [ ] Branch release local apagada
- [ ] Push main/develop/tag (só se pedido)
- [ ] GitHub Release (opcional, só se pedido)
```

## Fluxo: Feature → develop

Criar:

```bash
git checkout <DEV> && git pull origin <DEV>
git checkout -b feature/<nome-em-kebab-case>
```

Finalizar — caminho usual (`FEATURE_MERGE=pr`): publicar a branch (com autorização) e abrir **PR para `<DEV>`**. Equivalente local (`FEATURE_MERGE=local`):

```bash
git checkout <DEV> && git pull origin <DEV>
git merge --no-ff feature/<nome>
git branch -d feature/<nome>        # se o PR foi squash: -D (confirmar)
```

## Fluxo: Release start

```bash
git checkout <DEV> && git pull origin <DEV>
git checkout -b release/X.Y.Z <DEV>
# bump do arquivo de versão para X.Y.Z (ver references/conventions.md, "Como fazer o bump")
git add <arquivo-de-versao> [lockfile]
git commit -m "chore: bump version to X.Y.Z"
```

Correções de homologação entram como commits na própria `release/X.Y.Z` (nada de features novas). Não é obrigatório publicar a `release/` se o finish vier na sequência.

## Fluxo: Release finish

Equivale ao `git flow release finish`:

```bash
# 1. main recebe a release
git checkout <MAIN> && git pull origin <MAIN>
git merge --no-ff release/X.Y.Z -m "Merge branch 'release/X.Y.Z'"

# 2. tag anotada no merge commit da main
git tag -a <TAG> -m "Release X.Y.Z"

# 3. develop recebe a release e a tag
git checkout <DEV>
git merge --no-ff release/X.Y.Z -m "Merge branch 'release/X.Y.Z'"
git merge <TAG> -m "Merge tag '<TAG>' into <DEV>"

# 4. limpar
git branch -d release/X.Y.Z
```

Se `main`/`develop` são **protegidas** (push direto bloqueado), use o fluxo por PR em `references/release-and-hotfix.md`.

## Push e GitHub Release

Só após confirmação explícita:

```bash
git push origin <MAIN> <DEV>
git push origin <TAG>
gh release create <TAG> --title "<TAG>" --notes "- …"   # opcional
```

Para as notas, gere um rascunho com `git log --no-merges --pretty='- %s' <tag-anterior>..<TAG>`, mostre ao usuário e só então publique. Se `CHANGELOG=true`, atualize o `CHANGELOG.md` **dentro da `release/`**, antes do commit de bump.

## Hotfix

Resumo: `hotfix/X.Y.Z` nasce da `main` (PATCH+1), merge `--no-ff` na `main`, tag anotada, merge na `develop` (ou na `release/` aberta, se houver). Passo a passo completo em `references/release-and-hotfix.md`.

## Depois da release

Lembre o usuário (não execute sozinho): deploy/CI que segue `main` ou a tag, variáveis de ambiente de produção, e migrações de banco, se houve mudança de schema.

## Não fazer

- Criar tag leve (`git tag` sem `-a`) ou tag na `release/`
- Mergear `feature/*` direto na `main`
- Mudar o prefixo de tag (`v` ↔ sem `v`) no meio do histórico sem o time decidir
- Instalar/depender da CLI `git flow`
- Reescrever histórico publicado de `main`/`develop`

## Referências desta skill

- `references/setup.md` — setup do zero: criar `develop`, tag base, `.gitflow`, proteção de branches, CI
- `references/conventions.md` — arquivo `.gitflow`, bump por tipo de projeto, mensagens de commit
- `references/release-and-hotfix.md` — hotfix completo, release por PR (branches protegidas), conflitos e recuperação de erros
- `scripts/gitflow-status.sh` — diagnóstico somente leitura
