---
name: git-flow
description: Applies Git Flow (main, develop, feature/*, release/*, hotfix/*) with SemVer versioning and annotated tags in any project, and sets up the branches when they don't exist yet. Use when the user asks to create a feature, release or hotfix, finish a release, bump a version, create a tag or GitHub Release, set up git flow, create the develop branch or organize branches. Also triggers on Portuguese requests such as fazer release, hotfix, bump de versão, criar tag, configurar git flow.
---

# Git Flow and Versioning

**Manual** flow (plain `git` commands, no `git-flow` CLI) based on Vincent Driessen's branching model. Works with any language and any agent: everything here is text plus terminal commands.

**Reply in the language the user writes in** (these instructions are in English, but a Portuguese-speaking user gets Portuguese answers).

## The model in 30 seconds

| Branch | Type | Created from | Merged back into |
|---|---|---|---|
| `main` | permanent (production, every commit = a version) | — | — |
| `develop` | permanent (integration for the next release) | `main` | — |
| `feature/<name>` | temporary | `develop` | `develop` (never straight into `main`) |
| `release/X.Y.Z` | temporary (staging + version bump) | `develop` | `main` **and** `develop` |
| `hotfix/X.Y.Z` | temporary (urgent production fix) | `main` | `main` **and** `develop` |

If the project does **continuous delivery** (several deploys a day), mention **once** that the model's own author recommends GitHub Flow or trunk-based development in that case, then follow whatever the user decides.

## Safety rules (always apply)

1. **Never** `push`, push a tag, run `gh release create` or delete a remote branch unless the user explicitly asks for it in this conversation. Show the command and ask for confirmation.
2. **Never** use `push --force` on `main`/`develop`, `reset --hard`, `clean -fd` or `--no-verify` without an explicit request.
3. The working tree must be **clean** before switching branches or merging. If it is dirty, stop and ask (commit, stash or abort).
4. On a **merge conflict**, stop, list the conflicting files and ask how to resolve them. Don't guess.
5. Delete branches only with `git branch -d`. If `-D` is needed, explain why and confirm.
6. Integration merges (feature, release, hotfix): always `--no-ff`.
7. Tags are **annotated** (`git tag -a`) and created on **main** (on the merge commit of the release/hotfix), never on the `release/` branch.
8. `git add` only the files of the task (for the bump: the version file and the lockfile if it changed). No blind `git add -A`.

## Step 0 — Diagnose (always first)

Run this skill's script (path relative to the skill folder):

```bash
bash scripts/gitflow-status.sh
```

It is **read-only** and reports: current branch, clean/dirty tree, detected conventions, whether `main`/`develop` exist (local and remote), open releases/hotfixes, last tag, version in the version file, tag × file mismatch, commits since the last tag with a **bump suggestion**, and whether `main` has commits that `develop` lacks.

If the script can't run, do the equivalent by hand: `git status -sb`, `git branch -a`, `git tag --sort=-v:refname | head`, `git remote -v`.

## Step 1 — Is the repository ready for Git Flow?

If the diagnosis shows a missing `develop`, a repo with no commits, no `main`, no base tag or no `.gitflow` file, **read `references/setup.md`** and guide the setup (ask before every action with a remote effect). Move on to the flows below only when the setup is complete or the user says to skip it.

## Conventions (defaults and how to override)

| Item | Default | Detection |
|---|---|---|
| Production branch | `main` (or `master` if that's what exists) | automatic |
| Integration branch | `develop` | — |
| Tag prefix | empty → `1.2.0` | uses `v` if existing tags already use `v` |
| Version file | `package.json`, `pyproject.toml`, `Cargo.toml`, `composer.json` or `VERSION` | first one found; otherwise tag only |
| Bump commit | `chore: bump version to X.Y.Z` | — |
| Changelog | does **not** maintain `CHANGELOG.md`; notes go in the GitHub Release | `CHANGELOG=true` changes this |
| Feature → develop | via Pull Request | `FEATURE_MERGE=local` merges locally |

If a **`.gitflow`** file exists at the repo root (`KEY=value` format, committed so the whole team shares it), it wins. Details and an example in `references/conventions.md`. If the team doesn't have one yet, offer to create it during setup.

Notation in commands: `<MAIN>`, `<DEV>`, `<TAG>` = `<prefix>X.Y.Z`. `release/` and `hotfix/` branches **never** carry the `v` prefix.

## Choosing the version (SemVer)

Ask for the target version if the user doesn't give one; suggest it from the commits (the script already prints a suggestion):

- **MAJOR** (`X+1.0.0`): breaking change (`!` after the type or `BREAKING CHANGE:` in the body)
- **MINOR** (`X.Y+1.0`): new feature (`feat`); PATCH resets to 0
- **PATCH** (`X.Y.Z+1`): fix (`fix`) or internal tweak

The suggestion is a heuristic; the user decides. In `0.y.z` SemVer allows breaking changes at any time, so confirm.

## Release checklist (copy and tick off)

```
Release X.Y.Z:
- [ ] Diagnosis ok (clean tree, develop up to date)
- [ ] release/X.Y.Z created from develop
- [ ] Version bump in the version file + commit
- [ ] (staging / fixes on the release, if any)
- [ ] --no-ff merge into main
- [ ] Annotated tag on main
- [ ] Release and tag merged into develop
- [ ] Local release branch deleted
- [ ] Push main/develop/tag (only if asked)
- [ ] GitHub Release (optional, only if asked)
```

## Flow: Feature → develop

Start:

```bash
git checkout <DEV> && git pull origin <DEV>
git checkout -b feature/<name-in-kebab-case>
```

Finish — usual path (`FEATURE_MERGE=pr`): publish the branch (with permission) and open a **PR into `<DEV>`**. Local equivalent (`FEATURE_MERGE=local`):

```bash
git checkout <DEV> && git pull origin <DEV>
git merge --no-ff feature/<name>
git branch -d feature/<name>        # if the PR was squashed: -D (confirm)
```

## Flow: Release start

```bash
git checkout <DEV> && git pull origin <DEV>
git checkout -b release/X.Y.Z <DEV>
# bump the version file to X.Y.Z (see references/conventions.md, "How to bump")
git add <version-file> [lockfile]
git commit -m "chore: bump version to X.Y.Z"
```

Staging fixes go in as commits on `release/X.Y.Z` itself (no new features). Publishing the `release/` branch is optional if you finish right away.

## Flow: Release finish

Equivalent to `git flow release finish`:

```bash
# 1. main receives the release
git checkout <MAIN> && git pull origin <MAIN>
git merge --no-ff release/X.Y.Z -m "Merge branch 'release/X.Y.Z'"

# 2. annotated tag on the merge commit of main
git tag -a <TAG> -m "Release X.Y.Z"

# 3. develop receives the release and the tag
git checkout <DEV>
git merge --no-ff release/X.Y.Z -m "Merge branch 'release/X.Y.Z'"
git merge <TAG> -m "Merge tag '<TAG>' into <DEV>"

# 4. clean up
git branch -d release/X.Y.Z
```

If `main`/`develop` are **protected** (direct push blocked), use the PR flow in `references/release-and-hotfix.md`.

## Push and GitHub Release

Only after explicit confirmation:

```bash
git push origin <MAIN> <DEV>
git push origin <TAG>
gh release create <TAG> --title "<TAG>" --notes "- …"   # optional
```

For the notes, draft them with `git log --no-merges --pretty='- %s' <previous-tag>..<TAG>`, show them to the user and publish only then. If `CHANGELOG=true`, update `CHANGELOG.md` **inside the `release/` branch**, before the bump commit.

## Hotfix

Summary: `hotfix/X.Y.Z` is created from `main` (PATCH+1), `--no-ff` merge into `main`, annotated tag, merge into `develop` (or into the open `release/` branch, if there is one). Full walkthrough in `references/release-and-hotfix.md`.

## After the release

Remind the user (don't do it yourself): deploy/CI that follows `main` or the tag, production environment variables, and database migrations if the schema changed.

## Don't

- Create lightweight tags (`git tag` without `-a`) or tag the `release/` branch
- Merge `feature/*` straight into `main`
- Change the tag prefix (`v` ↔ none) mid-history without the team deciding
- Install or depend on the `git flow` CLI
- Rewrite published history of `main`/`develop`

## References in this skill

- `references/setup.md` — setup from scratch: create `develop`, base tag, `.gitflow`, branch protection, CI
- `references/conventions.md` — the `.gitflow` file, bump per project type, commit messages
- `references/release-and-hotfix.md` — full hotfix, release via PR (protected branches), conflicts and error recovery
- `scripts/gitflow-status.sh` — read-only diagnosis
