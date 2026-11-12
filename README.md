# git-flow-skill

Skill de agente para aplicar o **Git Flow** com versionamento **SemVer** em qualquer projeto: cria features, releases e hotfixes, faz o bump de versão, cria tags anotadas e, se o repositório ainda não tem `develop`, tag base ou convenções, **ajuda a montar o setup**.

Funciona em **Claude Code**, **opencode**, **Codex**, **Cursor**, **Gemini CLI** e outros agentes que seguem o formato aberto *Agent Skills* (`SKILL.md` + `scripts/` + `references/`).

Baseada no modelo de Vincent Driessen, no [artigo da Alura sobre Git Flow](https://www.alura.com.br/artigos/git-flow-o-que-e-como-quando-utilizar) e na skill `git-flow-versionamento` do projeto Kineto, generalizada para qualquer stack.

> Fluxo **manual**, só com comandos `git` (sem a CLI `git-flow`). Requer `git` e `bash` (no Windows, o Git Bash que já vem com o Git). O `gh` (GitHub CLI) é opcional, para PRs, proteção de branches e GitHub Releases.

---

## Instalação

### Claude Code

#### Opção 1 — `npx skills` (recomendada)

```bash
npx skills add GabrielRochaFC/git-flow-skill            # no projeto atual (o time pode commitar)
npx skills add GabrielRochaFC/git-flow-skill --global   # para todos os seus projetos
```

#### Opção 2 — Plugin marketplace do Claude Code

Dentro do Claude Code:

```text
/plugin marketplace add GabrielRochaFC/git-flow-skill
/plugin install git-flow@git-flow-skill
```

Ou pelo terminal:

```bash
claude plugin marketplace add GabrielRochaFC/git-flow-skill
claude plugin install git-flow@git-flow-skill
```

Instalada como plugin, a skill também pode ser chamada como `/git-flow:git-flow`. Atualizações chegam pelo marketplace quando a `version` do plugin sobe (veja "Desenvolvimento").

### Outros agentes (opencode, Codex, Cursor, Gemini CLI…)

O `npx skills` instala nos diretórios de cada agente:

```bash
npx skills add GabrielRochaFC/git-flow-skill --list            # só lista o que há no repo
npx skills add GabrielRochaFC/git-flow-skill -a opencode       # escolhendo o agente
npx skills add GabrielRochaFC/git-flow-skill -a codex cursor
```

### Instalação manual (qualquer agente)

Copie a pasta **inteira** `skills/git-flow/` para o diretório de skills da ferramenta (o `SKILL.md` referencia o script e os arquivos de `references/`; o nome da pasta deve continuar `git-flow`):

| Agente | Projeto (commite para o time) | Pessoal (todos os projetos) |
|---|---|---|
| Claude Code | `.claude/skills/git-flow/` | `~/.claude/skills/git-flow/` |
| opencode | `.opencode/skills/git-flow/` (também lê `.claude/skills/` e `.agents/skills/`) | `~/.config/opencode/skills/git-flow/` |
| Codex | `.agents/skills/git-flow/` | `~/.agents/skills/git-flow/` |
| Cursor | `.cursor/skills/git-flow/` | `~/.cursor/skills/git-flow/` |
| Gemini CLI | `.gemini/skills/git-flow/` | `~/.gemini/skills/git-flow/` |

```bash
git clone https://github.com/GabrielRochaFC/git-flow-skill.git
mkdir -p .claude/skills && cp -r git-flow-skill/skills/git-flow .claude/skills/
```

> Caminhos conforme a documentação de cada ferramenta em nov/2026. Se algum agente mudar o diretório, vale a regra geral: uma pasta com `SKILL.md` dentro do diretório de skills da ferramenta.

### Pacote `.zip` (instalação por upload)

```bash
python3 scripts/package_skill.py     # gera dist/git-flow.zip e dist/git-flow.skill
```

O zip contém a pasta `git-flow/` na raiz, pronta para ser enviada por upload ou descompactada num diretório de skills. Ao publicar uma Release no GitHub, anexe esses arquivos.

### Agentes sem suporte a skills

Copie `AGENTS.snippet.md` para o `AGENTS.md` do projeto (ou `.github/copilot-instructions.md`, `GEMINI.md` etc.) e mantenha a pasta `git-flow/` no repositório, ajustando o caminho no snippet.

---

## Como usar

Basta pedir em linguagem natural; o agente carrega a skill sozinho:

- "configura o git flow neste projeto" → setup (cria `develop`, tag base e `.gitflow`)
- "cria a feature de login" → `feature/login` a partir da `develop`
- "vamos fazer a release 1.3.0" → `release/1.3.0`, bump, merge na `main`, tag e volta para a `develop`
- "preciso de um hotfix" → `hotfix/X.Y.Z` a partir da `main`
- "qual o estado do git flow?" → diagnóstico somente leitura

Também dá para rodar o diagnóstico sozinho em qualquer repositório:

```bash
bash .claude/skills/git-flow/scripts/gitflow-status.sh
```

## O que a skill faz

| Branch | Nasce de | Volta para |
|---|---|---|
| `main` (produção, cada commit = versão com tag) | — | — |
| `develop` (integração) | `main` | — |
| `feature/<nome>` | `develop` | `develop` |
| `release/X.Y.Z` | `develop` | `main` e `develop` |
| `hotfix/X.Y.Z` | `main` | `main` e `develop` |

- Tags **anotadas** `X.Y.Z` criadas na `main`; merges de integração sempre `--no-ff`; commit de bump `chore: bump version to X.Y.Z`.
- **Setup:** se não existir `develop`, tag base ou convenções, a skill conduz a criação (perguntando antes de qualquer ação com efeito remoto) e sugere proteção de branches e CI.
- **Genérica:** autodetecta `main`/`master`, o prefixo `v` nas tags e o arquivo de versão (`package.json`, `pyproject.toml`, `Cargo.toml`, `composer.json`, `VERSION`) ou usa só tag.
- **Branches protegidas:** com `main`/`develop` protegidas, usa o fluxo por Pull Request.

### Convenções do time (`.gitflow`)

Para todos usarem o mesmo padrão (prefixo de tag, arquivo de versão, PR × merge local, changelog), crie um `.gitflow` na raiz do projeto e commite na `develop`. A skill oferece criá-lo no setup. Modelo e chaves em [`skills/git-flow/references/conventions.md`](skills/git-flow/references/conventions.md).

### Segurança embutida

O agente **não** faz `push`, tag remota, GitHub Release nem apaga branch remota sem você pedir; não usa `--force` em `main`/`develop`; para em conflitos; só mergeia com árvore limpa. Regras completas no [`SKILL.md`](skills/git-flow/SKILL.md).

### Quando não usar Git Flow

Em entrega contínua (vários deploys por dia), o próprio autor do modelo recomenda GitHub Flow ou trunk-based. A skill avisa disso uma vez e respeita a sua decisão.

---

## Estrutura do repositório

```
.
├── .claude-plugin/
│   ├── marketplace.json          # catálogo para /plugin marketplace add
│   └── plugin.json               # manifesto do plugin (versão, autor)
├── skills/git-flow/
│   ├── SKILL.md                  # instruções principais
│   ├── scripts/gitflow-status.sh # diagnóstico somente leitura
│   └── references/               # setup, convenções, hotfix e release por PR
├── scripts/package_skill.py      # gera dist/git-flow.zip
├── AGENTS.snippet.md             # fallback para agentes sem skills
├── LICENSE
└── README.md
```

## Desenvolvimento

```bash
claude plugin validate .          # valida marketplace.json e plugin.json
bash skills/git-flow/scripts/gitflow-status.sh
python3 scripts/package_skill.py
```

Ao lançar uma versão nova, suba o campo `version` em `.claude-plugin/plugin.json` (quem instalou como plugin só recebe a atualização assim) e crie a tag e a Release correspondentes.

## Licença

MIT. Veja [LICENSE](LICENSE).
