# Hotfix, release por PR e recuperação de erros

Notação: `<MAIN>`, `<DEV>`, `<TAG>` = `<prefixo>X.Y.Z` (como em `SKILL.md`). Todas as regras de segurança do `SKILL.md` continuam valendo (nada de push/tag remota/release sem pedido explícito).

## Hotfix (correção urgente em produção)

Versão do hotfix = PATCH+1 da última tag na `main`.

```bash
# start
git checkout <MAIN> && git pull origin <MAIN>
git checkout -b hotfix/X.Y.Z <MAIN>
# ...commits da correção (só o necessário)...
# bump do arquivo de versão (ver conventions.md)
git add <arquivo-de-versao> [lockfile]
git commit -m "chore: bump version to X.Y.Z"

# finish (equivale a git flow hotfix finish)
git checkout <MAIN>
git merge --no-ff hotfix/X.Y.Z -m "Merge branch 'hotfix/X.Y.Z'"
git tag -a <TAG> -m "Hotfix X.Y.Z"

# back-merge: o bug também existe na develop
git checkout <DEV>
git merge --no-ff hotfix/X.Y.Z -m "Merge branch 'hotfix/X.Y.Z'"
git merge <TAG> -m "Merge tag '<TAG>' into <DEV>"

git branch -d hotfix/X.Y.Z
```

**Se há uma `release/A.B.C` aberta**, o back-merge do hotfix vai para ela (e não para a `develop`); a `develop` receberá a correção quando a release for finalizada. Pergunte ao usuário qual caminho seguir.

Depois, com autorização: `git push origin <MAIN> <DEV> <TAG>`.

## Release/hotfix com branches protegidas (fluxo por PR)

Quando `PROTECTED_BRANCHES=true` (ou o push direto em `main`/`develop` for recusado), nada é mergeado localmente nessas branches. Fluxo:

1. `release/X.Y.Z` criada a partir da `develop` e publicada (com autorização): `git push -u origin release/X.Y.Z`
2. Abrir **PR `release/X.Y.Z` → `<MAIN>`** (`gh pr create --base <MAIN> --head release/X.Y.Z --title "Release X.Y.Z"`). Usar **merge commit** (não squash/rebase), para preservar o histórico.
3. Depois que o PR for mergeado, **a tag nasce no merge commit da `main`**:
   ```bash
   git fetch origin
   git checkout <MAIN> && git pull origin <MAIN>
   git tag -a <TAG> -m "Release X.Y.Z"
   git push origin <TAG>          # com autorização
   ```
4. Abrir **PR `<MAIN>` → `<DEV>`** (ou `release/X.Y.Z` → `<DEV>`) para a `develop` receber a release. Também com merge commit.
5. Apagar a `release/X.Y.Z` (local com `-d`; remota só com autorização).

Hotfix segue o mesmo desenho: `hotfix/X.Y.Z` → PR para `<MAIN>`, tag, PR de volta para `<DEV>`.

## Conflitos

- Durante qualquer merge com conflito: `git status` para listar; **mostrar ao usuário** e perguntar como resolver.
- Resolvidos os arquivos: `git add <arquivos>` + `git commit` (mantém a mensagem de merge padrão).
- Desistir: `git merge --abort` (seguro, volta ao estado anterior ao merge).
- Conflito típico no back-merge para `develop`: o arquivo de versão (a `develop` ainda tem a versão antiga). Resolver mantendo a versão **nova** da release/hotfix.

## Recuperação de erros comuns (confirmar antes de executar)

| Situação | Solução |
|---|---|
| Tag criada local no lugar errado/leve, **ainda não enviada** | `git tag -d <TAG>` e recriar com `git tag -a <TAG> -m "..." <commit-da-main>` |
| Tag já enviada ao remoto com erro | Não reescreva sem alinhar com o time. Opção segura: nova versão PATCH. Reescrever exige `git push origin :refs/tags/<TAG>` e **autorização explícita** |
| Merge na branch errada, **ainda não enviado** | `git reset --hard ORIG_HEAD` logo após o merge (descarta o merge local; pedir confirmação) |
| Esqueceu o back-merge na `develop` | `git checkout <DEV> && git merge --no-ff <MAIN>` (ou o merge da tag) |
| `branch -d` recusa ("not fully merged") | Verificar se foi squash/PR; se o conteúdo já está na `develop`, usar `-D` **com confirmação** |
| `main` e `develop` com versões diferentes após release | Conferir `gitflow-status.sh`; o arquivo de versão da `develop` deve igualar a última release após o back-merge |

## GitHub Release (opcional)

```bash
gh release create <TAG> --title "<TAG>" --notes "- item 1
- item 2"
# ou a partir de um arquivo revisado pelo usuário:
gh release create <TAG> --title "<TAG>" --notes-file notes.md
```

Rascunho das notas: `git log --no-merges --pretty='- %s' <tag-anterior>..<TAG>`. Mostre ao usuário e publique só depois do OK. Se `gh` não estiver instalado/autenticado, passe o texto das notas para o usuário colar na interface do GitHub.
