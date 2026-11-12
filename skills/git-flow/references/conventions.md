# Project conventions (`.gitflow`) and version bumps

## The `.gitflow` file

Optional file at the repository root, `KEY=value` format, comments with `#`. **Commit it** so the whole team (and every agent) follows the same pattern. Missing keys fall back to the default/autodetection.

```ini
# .gitflow — Git Flow conventions for this repository
MAIN_BRANCH=main            # production branch (main | master)
DEVELOP_BRANCH=develop      # integration branch
TAG_PREFIX=                 # empty -> 1.2.0 | v -> v1.2.0
VERSION_FILE=package.json   # package.json | pyproject.toml | Cargo.toml | composer.json | VERSION | (empty = tag only)
FEATURE_MERGE=pr            # pr (Pull Request) | local (local merge --no-ff)
CHANGELOG=false             # true -> keep CHANGELOG.md updated in the release
GITHUB_RELEASE=true         # true -> offer gh release create
PROTECTED_BRANCHES=false    # true -> main/develop only accept PRs (use the PR flow)
```

`TAG_PREFIX=` (empty) is a valid value and **overrides** autodetection.

## How to bump the version

Always on `release/X.Y.Z` (or `hotfix/X.Y.Z`), in **a single commit**:

```
chore: bump version to X.Y.Z
```

| Project | How to change it | Files in the commit |
|---|---|---|
| Node (`package.json`) | `npm version X.Y.Z --no-git-tag-version` (updates the lockfile) or edit `"version"` | `package.json` + `package-lock.json` (if changed) |
| Python (`pyproject.toml`) | edit `version = "X.Y.Z"` under `[project]` or `[tool.poetry]` | `pyproject.toml` |
| Rust (`Cargo.toml`) | edit `version = "X.Y.Z"` under `[package]`; run `cargo check` to refresh `Cargo.lock` | `Cargo.toml` + `Cargo.lock` |
| PHP (`composer.json`) | edit `"version"` (many projects don't use it; then tag only) | `composer.json` |
| `VERSION` file | write `X.Y.Z` | `VERSION` |
| Others (Java/Gradle/.NET…) | edit the project's version field | the build file |
| No version file | **no bump commit**; the version lives only in the tag | — |

Rules:

- **Never** run `npm version` without `--no-git-tag-version`: it creates its own commit and lightweight tag and breaks the flow (the tag must be annotated and live on `main`).
- After the bump, check with `git diff --stat HEAD~1` that only version files changed.
- The source of truth for the version is the **annotated tag**; the file must match it on `main`.

## Commit messages

The flow only imposes the bump commit and the merge messages:

- `chore: bump version to X.Y.Z`
- `Merge branch 'release/X.Y.Z'` / `Merge branch 'hotfix/X.Y.Z'`
- `Merge tag '<TAG>' into develop`
- Tag: `Release X.Y.Z` (annotated)

For all other commits, follow the project's own pattern. If the team uses Conventional Commits (`feat:`, `fix:`, `feat!:`), the bump suggestion from `gitflow-status.sh` becomes more accurate.

## Branch names

- `feature/<description-in-kebab-case>` (e.g. `feature/question-forum`); if the team uses tickets: `feature/ABC-123-forum`
- `release/X.Y.Z` and `hotfix/X.Y.Z` — always **without** `v`
- No spaces, accents or uppercase letters
