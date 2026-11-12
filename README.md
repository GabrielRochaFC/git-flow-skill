# git-flow-skill

🇺🇸 **English** · 🇧🇷 [Português (Brasil)](README.pt-BR.md)

An agent skill that applies **Git Flow** with **SemVer** versioning in any project: it creates features, releases and hotfixes, bumps the version, creates annotated tags and, if the repository doesn't yet have a `develop` branch, a base tag or team conventions, **helps you set them up**.

Works with **Claude Code**, **opencode**, **Codex**, **Cursor**, **Gemini CLI** and other agents that follow the open *Agent Skills* format (`SKILL.md` + `scripts/` + `references/`).

Based on Vincent Driessen's branching model, on [Alura's article about Git Flow](https://www.alura.com.br/artigos/git-flow-o-que-e-como-quando-utilizar) and on the `git-flow-versionamento` skill from the Kineto project, generalized for any stack.

> **Manual** flow using plain `git` commands (no `git-flow` CLI). Requires `git` and `bash` (on Windows, the Git Bash that ships with Git). The `gh` CLI (GitHub CLI) is optional, for PRs, branch protection and GitHub Releases. The skill replies in whatever language you write in.

---

## Installation

### Claude Code

#### Option 1 — `npx skills` (recommended)

```bash
npx skills add GabrielRochaFC/git-flow-skill            # current project (your team can commit it)
npx skills add GabrielRochaFC/git-flow-skill --global   # all your projects
```

#### Option 2 — Claude Code plugin marketplace

Inside Claude Code:

```text
/plugin marketplace add GabrielRochaFC/git-flow-skill
/plugin install git-flow@git-flow-skill
```

Or from the terminal:

```bash
claude plugin marketplace add GabrielRochaFC/git-flow-skill
claude plugin install git-flow@git-flow-skill
```

Installed as a plugin, the skill can also be invoked as `/git-flow:git-flow`. Updates arrive through the marketplace when the plugin `version` is bumped (see "Development").

### Other agents (opencode, Codex, Cursor, Gemini CLI…)

`npx skills` installs into each agent's own directories:

```bash
npx skills add GabrielRochaFC/git-flow-skill --list            # just list what's in the repo
npx skills add GabrielRochaFC/git-flow-skill -a opencode       # pick an agent
npx skills add GabrielRochaFC/git-flow-skill -a codex cursor
```

### Manual install (any agent)

Copy the **whole** `skills/git-flow/` folder into the tool's skills directory (`SKILL.md` references the script and the `references/` files; the folder name must stay `git-flow`):

| Agent | Project (commit it for the team) | Personal (all projects) |
|---|---|---|
| Claude Code | `.claude/skills/git-flow/` | `~/.claude/skills/git-flow/` |
| opencode | `.opencode/skills/git-flow/` (also reads `.claude/skills/` and `.agents/skills/`) | `~/.config/opencode/skills/git-flow/` |
| Codex | `.agents/skills/git-flow/` | `~/.agents/skills/git-flow/` |
| Cursor | `.cursor/skills/git-flow/` | `~/.cursor/skills/git-flow/` |
| Gemini CLI | `.gemini/skills/git-flow/` | `~/.gemini/skills/git-flow/` |

```bash
git clone https://github.com/GabrielRochaFC/git-flow-skill.git
mkdir -p .claude/skills && cp -r git-flow-skill/skills/git-flow .claude/skills/
```

> Paths follow each tool's documentation as of Nov 2026. If an agent changes its directory, the general rule still holds: a folder containing `SKILL.md` inside the tool's skills directory.

### `.zip` package (install by upload)

```bash
python3 scripts/package_skill.py     # builds dist/git-flow.zip and dist/git-flow.skill
```

The zip has the `git-flow/` folder at its root, ready to upload or unzip into a skills directory. When you publish a GitHub Release, attach these files.

### Agents without skills support

Copy `AGENTS.snippet.md` into the project's `AGENTS.md` (or `.github/copilot-instructions.md`, `GEMINI.md`, etc.) and keep the `git-flow/` folder in the repository, adjusting the path in the snippet.

---

## Usage

Just ask in natural language; the agent loads the skill on its own:

- "set up git flow in this project" → setup (creates `develop`, a base tag and `.gitflow`)
- "create the login feature" → `feature/login` from `develop`
- "let's do release 1.3.0" → `release/1.3.0`, bump, merge into `main`, tag, back-merge into `develop`
- "I need a hotfix" → `hotfix/X.Y.Z` from `main`
- "what's the git flow status?" → read-only diagnosis

You can also run the diagnosis on its own in any repository:

```bash
bash .claude/skills/git-flow/scripts/gitflow-status.sh
```

## What the skill does

| Branch | Created from | Merged back into |
|---|---|---|
| `main` (production, every commit = a tagged version) | — | — |
| `develop` (integration) | `main` | — |
| `feature/<name>` | `develop` | `develop` |
| `release/X.Y.Z` | `develop` | `main` and `develop` |
| `hotfix/X.Y.Z` | `main` | `main` and `develop` |

- **Annotated** `X.Y.Z` tags created on `main`; integration merges always `--no-ff`; bump commit `chore: bump version to X.Y.Z`.
- **Setup:** if `develop`, a base tag or conventions are missing, the skill walks you through creating them (asking before any action with a remote effect) and suggests branch protection and CI.
- **Generic:** autodetects `main`/`master`, the `v` tag prefix and the version file (`package.json`, `pyproject.toml`, `Cargo.toml`, `composer.json`, `VERSION`), or uses the tag alone.
- **Protected branches:** with protected `main`/`develop`, it uses the Pull Request flow.

### Team conventions (`.gitflow`)

So everyone follows the same pattern (tag prefix, version file, PR vs local merge, changelog), create a `.gitflow` at the project root and commit it to `develop`. The skill offers to create it during setup. Template and keys in [`skills/git-flow/references/conventions.md`](skills/git-flow/references/conventions.md).

### Built-in safety

The agent will **not** `push`, push tags, create a GitHub Release or delete a remote branch unless you ask; it won't use `--force` on `main`/`develop`; it stops on conflicts; and it only merges with a clean working tree. Full rules in [`SKILL.md`](skills/git-flow/SKILL.md).

### When not to use Git Flow

With continuous delivery (several deploys a day), the model's own author recommends GitHub Flow or trunk-based development. The skill mentions this once and respects your decision.

---

## Repository layout

```
.
├── .claude-plugin/
│   ├── marketplace.json          # catalog for /plugin marketplace add
│   └── plugin.json               # plugin manifest (version, author)
├── skills/git-flow/
│   ├── SKILL.md                  # main instructions
│   ├── scripts/gitflow-status.sh # read-only diagnosis
│   └── references/               # setup, conventions, hotfix and release via PR
├── scripts/package_skill.py      # builds dist/git-flow.zip
├── AGENTS.snippet.md             # fallback for agents without skills support
├── LICENSE
├── README.md                     # English
└── README.pt-BR.md               # Português (Brasil)
```

## Development

```bash
claude plugin validate .          # validates marketplace.json and plugin.json
bash skills/git-flow/scripts/gitflow-status.sh
python3 scripts/package_skill.py
```

When you ship a new version, bump `version` in `.claude-plugin/plugin.json` (plugin users only receive the update that way) and create the matching tag and Release.

## License

MIT. See [LICENSE](LICENSE).
