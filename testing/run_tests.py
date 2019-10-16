import shlex
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, Iterator, List, Set

from common import IGNORE_RECIPES_PATHS, RECIPES_PATHS

COMMAND_FACTORIES = {
    "imports": lambda arg: f"python -c 'import {arg}'",
    "requires": lambda arg: f"pip install -U {arg.replace(' ', '')}",
    "commands": lambda arg: 'bash -c "' + arg.replace('"', '\\"') + '"',
}
TIME_START = datetime.now()


def get_output_files():
    current_dir = Path(__file__).parent
    logs_dir = current_dir / "logs"
    logs_dir.mkdir(exist_ok=True)
    stdout = logs_dir / "stdout.txt"
    stderr = logs_dir / "stderr.txt"
    if stdout.exists():
        stdout.unlink()
    if stderr.exists():
        stderr.unlink()
    return stdout, stderr


STDOUT_DUMP_FILE, STDERR_DUMP_FILE = get_output_files()


def _get_recipe_commands(recipe: str, recipes_paths: Dict[str, Path]) -> Iterator[str]:
    # order matters: only "commands" depend on "requires"
    for op in ["imports", "requires", "commands"]:
        path = recipes_paths[op] / recipe
        if path.exists():
            lines = path.read_text().splitlines()
            for line in lines:
                command_factory = COMMAND_FACTORIES[op]
                yield command_factory(arg=line)


def _get_recipes(recipes_paths: Dict[str, Path]) -> List[str]:
    recipes = {
        recipe.stem
        for op in ["imports", "commands"]
        for recipe in recipes_paths[op].iterdir()
    }
    return sorted(list(recipes))


def get_commands(recipes_paths: Dict[str, Path]) -> List[str]:
    return [
        cmd.strip()
        for recipe in _get_recipes(recipes_paths)
        for cmd in _get_recipe_commands(recipe, recipes_paths)
        if cmd.strip()
    ]


def _timestamp() -> str:
    delta = datetime.now() - TIME_START
    total_sec = delta.total_seconds()
    m = int(total_sec // 60)
    s = total_sec % 60
    return f"{m}min {s:.3f}sec"


def run_tests(commands: List[str], ignore_commands: Set[str]) -> None:
    total_run, succeeded, failed, ignored = [], [], [], []
    try:
        for cmd in commands:
            if cmd in ignore_commands:
                ignored.append(cmd)
                print(f"[!] {_timestamp()} Ignore command: `{cmd}`")
                continue

            info = f"[.] {_timestamp()} Running command: `{cmd}`"
            print(info)
            try:
                import sys

                f_stdout = sys.stdout
                f_stderr = sys.stderr
                if True:
                    if True:
                        # with STDOUT_DUMP_FILE.open("a") as f_stdout:
                        #     with STDERR_DUMP_FILE.open("a") as f_stderr:
                        f_stdout.write("\n" + info + "\n")
                        f_stderr.write("\n" + info + "\n")
                        p = subprocess.run(
                            shlex.split(cmd), stdout=f_stdout, stderr=f_stderr
                        )
                total_run.append(cmd)
                assert p.returncode == 0, f"non-zero exit code: {p.returncode}"
                print(f"[+] {_timestamp()} Success.")
                succeeded.append(cmd)
            except KeyboardInterrupt:
                raise
            except Exception as e:
                print(f"[-] {_timestamp()} Error {type(e)}: {e}")
                failed.append(cmd)
    finally:
        print("-" * 50)
        print("Summary:")
        print(f"Total: {len(commands)} ({len(ignored)} ignored)")
        print(f"Total succeeded: {len(succeeded)}")
        print(f"Total failed: {len(failed)}")
        if failed:
            print(f"Failed tests:")
            for fail in failed:
                print(f"  {fail}")
            exit(1)


if __name__ == "__main__":
    commands = get_commands(RECIPES_PATHS)
    print(f"All commands: {commands}\n")
    ignore_commands = get_commands(IGNORE_RECIPES_PATHS)
    print(f"Ignore commands: {ignore_commands}\n")
    run_tests(commands, set(ignore_commands))
