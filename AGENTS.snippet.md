## Git Flow e versionamento

Este projeto usa Git Flow manual (sem a CLI `git-flow`) com SemVer.
Ao pedirem feature, release, hotfix, bump de versão, tag ou setup de branches, **leia e siga `.claude/skills/git-flow/SKILL.md`** (ajuste o caminho para onde a pasta `git-flow/` está neste repositório) e os arquivos de `references/` que ele indicar.

Resumo das regras:

- Branches: `main` (produção), `develop` (integração), `feature/<nome>`, `release/X.Y.Z`, `hotfix/X.Y.Z`
- Tag anotada `X.Y.Z` criada na `main`; merges de integração sempre `--no-ff`
- Antes de qualquer passo, rode `bash .claude/skills/git-flow/scripts/gitflow-status.sh` (somente leitura)
- Nunca fazer push, tag remota, GitHub Release, `--force` ou apagar branch remota sem pedido explícito do usuário
- Convenções do time (prefixo de tag, arquivo de versão etc.) ficam em `.gitflow`, se existir
