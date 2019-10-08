import os
import shlex
import subprocess
from typing import Iterator, List

from generate_recipes import get_paths

PATHS = get_paths()

DEFAULT_DELIMITER = "\n"
COMMAND_TEPMLATES = {
    "imports": "python -c 'import {arg}'",
    "requires": "pip install {arg}",
    "commands": "{arg}",  # shell command
}


def _get_recipe_commands(recipe: str) -> Iterator[str]:
    # order matters: only "commands" depend on "requires"
    for key in ["imports", "requires", "commands"]:
        path = PATHS[key] / recipe
        if path.exists():
            lines = path.read_text().splitlines()
            for line in lines:
                yield COMMAND_TEPMLATES[key].format(arg=line)


def get_recipes() -> List[str]:
    recipes = {
        recipe.stem
        for key in ["imports", "commands"]
        for recipe in PATHS[key].iterdir()
    }
    return sorted(list(recipes))


def get_commands() -> List[str]:
    return [cmd for recipe in get_recipes() for cmd in _get_recipe_commands(recipe)]


def run_tests(commands: List[str]) -> None:
    total_run, succeeded, failed = [], [], []
    try:
        for cmd in commands:
            print(f"[.] Running command: `{cmd}`")
            try:
                with open(os.devnull, "wb") as devnull:
                    p = subprocess.run(shlex.split(cmd), stdout=devnull)
                    total_run.append(cmd)
                assert p.returncode == 0, f"non-zero exit code: {p.returncode}"
                print(f"[+] Success.")
                succeeded.append(cmd)
            except KeyboardInterrupt:
                raise
            except Exception as e:
                print(f"[-] Error {type(e)}: {e}")
                failed.append(cmd)
    finally:
        print("-" * 50)
        print("Summary:")
        print(f"Total commands: {len(commands)}")
        print(f"Total run: {len(total_run)}")
        print(f"Total succeeded: {len(succeeded)}")
        print(f"Total failed: {len(failed)}")
        if failed:
            print(f"Failed tests:")
            for fail in failed:
                print(f"  {fail}")
            exit(1)


if __name__ == "__main__":
    commands = get_commands()
    print(f"All commands: {commands}\n")
    run_tests(commands)
