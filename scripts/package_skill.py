#!/usr/bin/env python3
"""Builds dist/git-flow.zip (and dist/git-flow.skill, same contents) from skills/git-flow.

The zip has the `git-flow/` folder at its root with SKILL.md inside, which is the
format expected for manual installs (upload or copying a folder).
Standard library only. Usage: python3 scripts/package_skill.py
"""
import os
import shutil
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILL_NAME = "git-flow"
SRC = os.path.join(ROOT, "skills", SKILL_NAME)
DIST = os.path.join(ROOT, "dist")
IGNORE_DIRS = {"__pycache__", ".git"}
IGNORE_FILES = {".DS_Store"}


def main() -> int:
    if not os.path.isfile(os.path.join(SRC, "SKILL.md")):
        print(f"ERROR: {SRC}/SKILL.md not found", file=sys.stderr)
        return 1
    os.makedirs(DIST, exist_ok=True)
    out = os.path.join(DIST, f"{SKILL_NAME}.zip")
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for folder, dirs, files in os.walk(SRC):
            dirs[:] = sorted(d for d in dirs if d not in IGNORE_DIRS)
            for name in sorted(files):
                if name in IGNORE_FILES:
                    continue
                path = os.path.join(folder, name)
                arc = os.path.join(SKILL_NAME, os.path.relpath(path, SRC))
                info = zipfile.ZipInfo.from_file(path, arc)
                info.compress_type = zipfile.ZIP_DEFLATED
                with open(path, "rb") as fh:
                    z.writestr(info, fh.read())
    shutil.copyfile(out, os.path.join(DIST, f"{SKILL_NAME}.skill"))
    print(f"built: {out}")
    print(f"built: {os.path.join(DIST, SKILL_NAME + '.skill')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
