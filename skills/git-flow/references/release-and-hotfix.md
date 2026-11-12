# Hotfix, release via PR and error recovery

Notation: `<MAIN>`, `<DEV>`, `<TAG>` = `<prefix>X.Y.Z` (as in `SKILL.md`). All safety rules from `SKILL.md` still apply (no push / remote tag / release without an explicit request).

## Hotfix (urgent production fix)

Hotfix version = PATCH+1 of the latest tag on `main`.

```bash
# start
git checkout <MAIN> && git pull origin <MAIN>
git checkout -b hotfix/X.Y.Z <MAIN>
# ...commits with the fix (only what's necessary)...
# bump the version file (see conventions.md)
git add <version-file> [lockfile]
git commit -m "chore: bump version to X.Y.Z"

# finish (equivalent to git flow hotfix finish)
git checkout <MAIN>
git merge --no-ff hotfix/X.Y.Z -m "Merge branch 'hotfix/X.Y.Z'"
git tag -a <TAG> -m "Hotfix X.Y.Z"

# back-merge: the bug exists on develop too
git checkout <DEV>
git merge --no-ff hotfix/X.Y.Z -m "Merge branch 'hotfix/X.Y.Z'"
git merge <TAG> -m "Merge tag '<TAG>' into <DEV>"

git branch -d hotfix/X.Y.Z
```

**If a `release/A.B.C` branch is open**, the hotfix back-merge goes into it (not into `develop`); `develop` receives the fix when that release is finished. Ask the user which path to follow.

Afterwards, with permission: `git push origin <MAIN> <DEV> <TAG>`.

## Release/hotfix with protected branches (PR flow)

When `PROTECTED_BRANCHES=true` (or a direct push to `main`/`develop` is rejected), nothing is merged locally into those branches. Flow:

1. `release/X.Y.Z` is created from `develop` and published (with permission): `git push -u origin release/X.Y.Z`
2. Open a **PR `release/X.Y.Z` → `<MAIN>`** (`gh pr create --base <MAIN> --head release/X.Y.Z --title "Release X.Y.Z"`). Use a **merge commit** (not squash/rebase) to preserve history.
3. Once the PR is merged, **the tag is created on the merge commit of `main`**:
   ```bash
   git fetch origin
   git checkout <MAIN> && git pull origin <MAIN>
   git tag -a <TAG> -m "Release X.Y.Z"
   git push origin <TAG>          # with permission
   ```
4. Open a **PR `<MAIN>` → `<DEV>`** (or `release/X.Y.Z` → `<DEV>`) so `develop` receives the release. Also with a merge commit.
5. Delete `release/X.Y.Z` (local with `-d`; remote only with permission).

A hotfix follows the same shape: `hotfix/X.Y.Z` → PR into `<MAIN>`, tag, PR back into `<DEV>`.

## Conflicts

- During any merge with conflicts: `git status` to list them; **show them to the user** and ask how to resolve.
- Once the files are resolved: `git add <files>` + `git commit` (keeps the default merge message).
- To give up: `git merge --abort` (safe, goes back to the state before the merge).
- Typical conflict in the back-merge into `develop`: the version file (`develop` still has the old version). Resolve by keeping the **new** version from the release/hotfix.

## Recovering from common mistakes (confirm before running)

| Situation | Fix |
|---|---|
| Tag created locally in the wrong place / lightweight, **not pushed yet** | `git tag -d <TAG>` and recreate with `git tag -a <TAG> -m "..." <commit-on-main>` |
| Tag already pushed with a mistake | Don't rewrite it without aligning with the team. Safe option: a new PATCH version. Rewriting needs `git push origin :refs/tags/<TAG>` and **explicit permission** |
| Merged into the wrong branch, **not pushed yet** | `git reset --hard ORIG_HEAD` right after the merge (discards the local merge; ask for confirmation) |
| Forgot the back-merge into `develop` | `git checkout <DEV> && git merge --no-ff <MAIN>` (or merge the tag) |
| `branch -d` refuses ("not fully merged") | Check whether it was squashed via PR; if the content is already in `develop`, use `-D` **with confirmation** |
| `main` and `develop` have different versions after a release | Check `gitflow-status.sh`; `develop`'s version file should match the latest release after the back-merge |

## GitHub Release (optional)

```bash
gh release create <TAG> --title "<TAG>" --notes "- item 1
- item 2"
# or from a file the user has reviewed:
gh release create <TAG> --title "<TAG>" --notes-file notes.md
```

Draft the notes with: `git log --no-merges --pretty='- %s' <previous-tag>..<TAG>`. Show them to the user and publish only after their OK. If `gh` isn't installed/authenticated, hand the notes text to the user to paste in the GitHub UI.
