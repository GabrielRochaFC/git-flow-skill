# Setup do Git Flow em um repositório

Use quando `scripts/gitflow-status.sh` apontar pendências (sem repo, sem commits, sem `develop`, sem tag base, sem `.gitflow`). Conduza **em ordem**, parando para perguntar onde indicado. Tudo que mexe no remoto (`push`, proteção de branch, mudar branch padrão) exige confirmação explícita.

Resumo da conversa a ter com o usuário (uma pergunta curta por vez, só o que faltar):

1. Qual é a branch de produção? (detectada: `main` ou `master`)
2. Prefixo de tag: `1.2.0` ou `v1.2.0`?
3. Onde fica a versão do projeto? (detectado: `package.json`, etc., ou só tag)
4. Features entram na `develop` por Pull Request ou merge local?
5. Mantém `CHANGELOG.md` ou as notas ficam na GitHub Release?

---

## 1. Sem repositório

Só se o usuário confirmar que quer versionar esta pasta:

```bash
git init -b main
git add <arquivos-do-projeto>     # revisar o que entra; respeitar .gitignore
git commit -m "chore: initial commit"
```

Se tiver remote para configurar: `git remote add origin <url>` (e `git push -u origin main` só com autorização).

## 2. Repositório sem commits

`develop` não pode nascer de uma branch vazia. Faça (com autorização) um commit inicial como acima antes de continuar.

## 3. Branch de produção

- Existe `main` ou `master`: use a que existe; registre em `MAIN_BRANCH` no `.gitflow`.
- A branch atual tem outro nome (ex.: `trunk`, `dev`): pergunte qual será a de produção. **Não renomeie** branches sem o usuário pedir (`git branch -m <antigo> main` e, se já estiver no remoto, avisar que o time precisa atualizar clones).

## 4. Criar a `develop`

Caso A — não existe local nem remota:

```bash
git checkout <MAIN>
git pull origin <MAIN>          # se houver remote
git checkout -b develop <MAIN>
# com autorização:
git push -u origin develop
```

Caso B — existe só no remoto (colega já criou):

```bash
git fetch origin
git checkout -b develop origin/develop      # ou: git switch develop
```

Caso C — existe local mas sem upstream: `git push -u origin develop` (com autorização).

Se `develop` já existir mas estiver **atrás** da `main` (ex.: hotfix sem back-merge): mostre `git log --oneline develop..main`, explique e proponha `git checkout develop && git merge --no-ff main` (confirmar antes; pode haver conflito).

## 5. Tag base e versão

Sem nenhuma tag SemVer, o primeiro release não tem de onde partir. Pergunte e proponha:

- Há versão no arquivo (ex.: `package.json` com `0.3.0`)? Proponha tag base igual a ela **na `main`**:
  ```bash
  git tag -a <prefixo>0.3.0 -m "Release 0.3.0" <MAIN>
  ```
- Não há versão em lugar nenhum: proponha `0.1.0` (projeto novo) ou `1.0.0` (já em produção) e, se existir arquivo de versão, alinhe com um commit `chore: bump version to X.Y.Z`.
- Empurrar a tag só com autorização: `git push origin <tag>`.

Já tem tags no repo? **Respeite o padrão existente** (com ou sem `v`) e registre em `TAG_PREFIX`.

## 6. Arquivo `.gitflow`

Ofereça criar na raiz com as respostas do usuário (modelo e todas as chaves em `conventions.md`). Ele deve ser **commitado na `develop`** para o time todo usar as mesmas convenções:

```bash
git checkout <DEV>
git add .gitflow
git commit -m "chore: add git flow conventions"
```

## 7. Documentar para o time (opcional)

Ofereça adicionar ao `README.md`/`CONTRIBUTING.md` (ou `AGENTS.md`/`CLAUDE.md`) um bloco curto:

```markdown
## Fluxo de branches (Git Flow)
- `main` = produção (cada commit é uma versão, com tag X.Y.Z) · `develop` = integração
- Features: `feature/<nome>` a partir da `develop`, PR para `develop`
- Releases: `release/X.Y.Z` a partir da `develop`; merge na `main` + tag + volta para `develop`
- Hotfix: `hotfix/X.Y.Z` a partir da `main`; merge na `main` + tag + `develop`
- Versionamento SemVer; convenções em `.gitflow`
```

## 8. Proteção de branches e PRs (recomendado, só com autorização)

Via interface: *Settings → Branches → Branch protection rules* para `main` e `develop`: exigir Pull Request, bloquear force-push e exclusão de branch, exigir checks de CI.

Via GitHub CLI (precisa de `gh` autenticado e permissão de admin; troque `OWNER/REPO`):

```bash
gh api -X PUT repos/OWNER/REPO/branches/main/protection \
  -H "Accept: application/vnd.github+json" --input - <<'EOF'
{"required_status_checks":null,"enforce_admins":false,
 "required_pull_request_reviews":{"required_approving_review_count":1},
 "restrictions":null,"allow_force_pushes":false,"allow_deletions":false}
EOF
```

Repita para `develop`. **Atenção:** com a `main` protegida por PR, o `release finish` local não consegue dar push; use o fluxo por PR de `release-and-hotfix.md` e registre isso em `.gitflow` (`PROTECTED_BRANCHES=true`).

Dica: se quiser que PRs abram contra a `develop` por padrão, o admin pode trocar a branch padrão do repositório para `develop` (Settings → General → Default branch). Pergunte; não faça por conta própria.

## 9. CI/CD

Sugira (sem aplicar sozinho) que os workflows rodem em `push` e `pull_request` para `main`, `develop`, `release/**` e `hotfix/**`, e que o deploy de produção siga a `main` ou a tag `X.Y.Z`.

## 10. Conclusão do setup

Rode `bash scripts/gitflow-status.sh` de novo e confirme que não há pendências estruturais. Resuma ao usuário o que foi criado e o que ficou pendente (ex.: push, proteção de branch).
