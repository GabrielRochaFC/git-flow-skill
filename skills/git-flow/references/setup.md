# Setting up Git Flow in a repository

Use this when `scripts/gitflow-status.sh` reports pending items (no repo, no commits, no `develop`, no base tag, no `.gitflow`). Go **in order**, stopping to ask where indicated. Anything that touches the remote (`push`, branch protection, changing the default branch) needs explicit confirmation.

Conversation to have with the user (one short question at a time, only what's missing):

1. Which branch is production? (detected: `main` or `master`)
2. Tag prefix: `1.2.0` or `v1.2.0`?
3. Where does the project version live? (detected: `package.json`, etc., or tag only)
4. Do features reach `develop` through a Pull Request or a local merge?
5. Keep a `CHANGELOG.md`, or keep the notes in the GitHub Release?

---

## 1. No repository

Only if the user confirms they want to version this folder:

```bash
git init -b main
git add <project-files>           # review what goes in; respect .gitignore
git commit -m "chore: initial commit"
```

If there's a remote to configure: `git remote add origin <url>` (and `git push -u origin main` only with permission).

## 2. Repository with no commits

`develop` can't branch off an empty history. Make an initial commit (with permission) as above before continuing.

## 3. Production branch

- `main` or `master` exists: use it and record it as `MAIN_BRANCH` in `.gitflow`.
- The current branch has another name (e.g. `trunk`, `dev`): ask which one will be production. **Don't rename** branches unless the user asks (`git branch -m <old> main`; if it's already on the remote, warn that the team must update their clones).

## 4. Create `develop`

Case A — it exists neither locally nor remotely:

```bash
git checkout <MAIN>
git pull origin <MAIN>          # if there is a remote
git checkout -b develop <MAIN>
# with permission:
git push -u origin develop
```

Case B — it exists only on the remote (a teammate created it):

```bash
git fetch origin
git checkout -b develop origin/develop      # or: git switch develop
```

Case C — it exists locally with no upstream: `git push -u origin develop` (with permission).

If `develop` exists but is **behind** `main` (e.g. a hotfix with no back-merge): show `git log --oneline develop..main`, explain it, and propose `git checkout develop && git merge --no-ff main` (confirm first; conflicts are possible).

## 5. Base tag and version

With no SemVer tag at all, the first release has nothing to start from. Ask and propose:

- Is there a version in a file (e.g. `package.json` with `0.3.0`)? Propose a base tag equal to it **on `main`**:
  ```bash
  git tag -a <prefix>0.3.0 -m "Release 0.3.0" <MAIN>
  ```
- No version anywhere: propose `0.1.0` (new project) or `1.0.0` (already in production) and, if there is a version file, align it with a `chore: bump version to X.Y.Z` commit.
- Push the tag only with permission: `git push origin <tag>`.

Repo already has tags? **Respect the existing pattern** (with or without `v`) and record it in `TAG_PREFIX`.

## 6. The `.gitflow` file

Offer to create it at the root with the user's answers (template and all keys in `conventions.md`). It should be **committed to `develop`** so the whole team uses the same conventions:

```bash
git checkout <DEV>
git add .gitflow
git commit -m "chore: add git flow conventions"
```

## 7. Document it for the team (optional)

Offer to add a short block to `README.md`/`CONTRIBUTING.md` (or `AGENTS.md`/`CLAUDE.md`):

```markdown
## Branching (Git Flow)
- `main` = production (every commit is a version, tagged X.Y.Z) · `develop` = integration
- Features: `feature/<name>` from `develop`, PR into `develop`
- Releases: `release/X.Y.Z` from `develop`; merge into `main` + tag + back into `develop`
- Hotfix: `hotfix/X.Y.Z` from `main`; merge into `main` + tag + `develop`
- SemVer versioning; conventions in `.gitflow`
```

## 8. Branch protection and PRs (recommended, only with permission)

Through the UI: *Settings → Branches → Branch protection rules* for `main` and `develop`: require a Pull Request, block force-push and branch deletion, require CI checks.

Through the GitHub CLI (needs an authenticated `gh` and admin permission; replace `OWNER/REPO`):

```bash
gh api -X PUT repos/OWNER/REPO/branches/main/protection \
  -H "Accept: application/vnd.github+json" --input - <<'EOF'
{"required_status_checks":null,"enforce_admins":false,
 "required_pull_request_reviews":{"required_approving_review_count":1},
 "restrictions":null,"allow_force_pushes":false,"allow_deletions":false}
EOF
```

Repeat for `develop`. **Heads up:** with `main` protected by PR, a local `release finish` can't push; use the PR flow in `release-and-hotfix.md` and record it in `.gitflow` (`PROTECTED_BRANCHES=true`).

Tip: if PRs should open against `develop` by default, an admin can switch the repository's default branch to `develop` (Settings → General → Default branch). Ask; don't do it on your own.

## 9. CI/CD

Suggest (without applying it yourself) that workflows run on `push` and `pull_request` for `main`, `develop`, `release/**` and `hotfix/**`, and that the production deploy follows `main` or the `X.Y.Z` tag.

## 10. Wrapping up

Run `bash scripts/gitflow-status.sh` again and confirm there are no structural pending items. Summarize for the user what was created and what is still pending (e.g. push, branch protection).
