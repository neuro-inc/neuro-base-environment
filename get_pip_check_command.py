#!/bin/env python

import re
import sys
import typing as t

PIP_MODULE_NAMES = {
    "scikit-learn": "sklearn",
    "protobuf": "google",
    "enum34": "enum",
    "pyyaml": "yaml",
}
BASH_COMMANDS = {
    "jupyterlab": "jupyter-lab --version",
}


def _get_pip_check_commands(dockerfile_lines: t.Iterable[str]) -> t.List[str]:
    pattern = re.compile(r"\s([a-z][^\s=]*)", re.IGNORECASE)
    result: t.List[str] = []
    in_pip_section = False
    verb = "PIP_INSTALL"
    for line in dockerfile_lines:
        if f"${verb}" in line:
            in_pip_section = True
        if not in_pip_section:
            continue
        packages = pattern.findall(line)
        for p in packages:
            if p == verb:
                continue
            module = PIP_MODULE_NAMES.get(p, p)
            cmd = BASH_COMMANDS.get(module, f"python -c 'import {module}'")
            result.append(cmd)
        if "&&" in line:
            in_pip_section = False
    return result


if __name__ == "__main__":
    path = sys.argv[1]
    with open(path, "r") as f:
        commands = _get_pip_check_commands(f.readlines())
        print(' && '.join(commands))
