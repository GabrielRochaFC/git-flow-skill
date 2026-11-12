## Git Flow and versioning

This project uses manual Git Flow (no `git-flow` CLI) with SemVer.
When asked for a feature, release, hotfix, version bump, tag or branch setup, **read and follow `.claude/skills/git-flow/SKILL.md`** (adjust the path to wherever the `git-flow/` folder lives in this repository) and the `references/` files it points to.

Rule summary:

- Branches: `main` (production), `develop` (integration), `feature/<name>`, `release/X.Y.Z`, `hotfix/X.Y.Z`
- Annotated tag `X.Y.Z` created on `main`; integration merges always `--no-ff`
- Before any step, run `bash .claude/skills/git-flow/scripts/gitflow-status.sh` (read-only)
- Never push, push a tag, create a GitHub Release, use `--force` or delete a remote branch without an explicit request from the user
- Team conventions (tag prefix, version file, etc.) live in `.gitflow`, if present
