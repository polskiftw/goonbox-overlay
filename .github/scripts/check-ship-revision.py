"""Verify that Portage saved Shipwright's own git-r3 revision, not a dependency's."""

import bz2
from pathlib import Path
import re
import sys


def verify(build_log: Path, vdb: Path) -> str:
    if (vdb / "repository").read_text(encoding="ascii").strip() != "goonbox-overlay":
        raise ValueError("expected the installed Ship package from goonbox-overlay")
    if not (vdb / "CONTENTS").stat().st_size:
        raise ValueError("installed Ship package has an empty CONTENTS file")

    # git-r3 prints the actual checkout, including on a non-fresh cache.
    repo = rb"https://github\.com/HarbourMasters/Shipwright\.git"
    pattern = (
        rb"^[ \t]+repository:[ \t]+" + repo + rb"[ \t]*\n"
        rb"(?:[ \t]+updating from commit:[ \t]+[0-9a-f]{40}[ \t]*\n)?"
        rb"[ \t]+(?:at the commit|to commit):[ \t]+([0-9a-f]{40})[ \t]*$"
    )
    commits = re.findall(pattern, build_log.read_bytes(), re.MULTILINE)
    if len(commits) != 1:
        raise ValueError("expected one Shipwright checkout revision in the build log")

    # The Portage environment is data; do not source it.
    with bz2.open(vdb / "environment.bz2", "rb") as env:
        assignments = re.findall(
            rb"^(?:declare (?:-[a-zA-Z]+|--) )?EGIT_VERSION=(.*)$",
            env.read(),
            re.MULTILINE,
        )
    if len(assignments) != 1:
        raise ValueError("expected one EGIT_VERSION assignment in the installed package")
    match = re.fullmatch(rb"""([\x22\x27]?)([0-9a-f]{40})\1""", assignments[0])
    if match is None:
        raise ValueError("installed EGIT_VERSION is not a full commit SHA")
    checkout, saved = commits[0].decode("ascii"), match[2].decode("ascii")
    if saved != checkout:
        raise ValueError(f"installed EGIT_VERSION {saved} does not match Shipwright checkout {checkout}")
    return saved


if __name__ == "__main__":
    try:
        commit = verify(Path(sys.argv[1]), Path(sys.argv[2]))
    except (OSError, ValueError) as exc:
        sys.exit(str(exc))
    print(f"Verified installed Shipwright revision: {commit}")
