import shlex
import subprocess
from typing import Iterator, List
from pathlib import Path
from generate_recipes import get_paths


DEFAULT_DELIMITER = "\n"
COMMAND_FACTORIES = {
    "imports": lambda arg: f"python -c 'import {arg}'",
    "requires": lambda arg: f"pip install -U {arg.replace(' ', '')}",
    "commands": lambda arg: 'bash -c "' + arg.replace('"', '\\"') + '"',
}


def get_output_files():
    current_dir = Path(__file__).parent
    logs_dir = current_dir / "logs"
    stdout = logs_dir / "stdout.txt"
    stderr = logs_dir / "stderr.txt"
    stdout.parent.mkdir(exist_ok=True)
    if stdout.exists():
        stdout.unlink()
    if stderr.exists():
        stderr.unlink()
    return stdout.open("a"), stderr.open("a")


STDOUT_DUMP_FILE, STDERR_DUMP_FILE = get_output_files()
STDOUT_DUMP_FILE.write("STARTING WRITE")

PATHS = get_paths()


def _get_recipe_commands(recipe: str) -> Iterator[str]:
    # order matters: only "commands" depend on "requires"
    for key in ["imports", "requires", "commands"]:
        path = PATHS[key] / recipe
        if path.exists():
            lines = path.read_text().splitlines()
            for line in lines:
                command_factory = COMMAND_FACTORIES[key]
                yield command_factory(arg=line)


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
            info = f"[.] Running command: `{cmd}`"
            print(info)
            try:
                STDOUT_DUMP_FILE.write(">>> " + info + "\n")
                STDERR_DUMP_FILE.write(">>> " + info + "\n")
                p = subprocess.run(
                    shlex.split(cmd), stdout=STDOUT_DUMP_FILE, stderr=STDERR_DUMP_FILE
                )
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
