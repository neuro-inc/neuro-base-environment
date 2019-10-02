#!/bin/env python

import re
import sys
import typing as t

REPLACEMENTS = {"scikit-learn": "sklearn",}

def _parse_pip_packages(dockerfile_lines: t.Iterable[str]) -> t.List[str]:
    pattern = re.compile(r"[a-z][^\s=]*")
    pips: t.List[str] = []
    in_pip_section = False
    for line in dockerfile_lines:
        if "$PIP_INSTALL" in line:
            in_pip_section = True
        if in_pip_section:
            packages = pattern.findall(line)
            for p in packages:
                pips.append(REPLACEMENTS.get(p, p))
            if "&&" in line:
                in_pip_section = False
    return pips


if __name__ == "__main__":
    path = sys.argv[1]
    with open(path, "r") as f:
        packages = _parse_pip_packages(f.readlines())
        print("\n".join(f"import {p}" for p in packages))
