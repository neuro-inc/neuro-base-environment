import sys

from .generate_recipes import get_paths

PATHS = get_paths()

COMMAND_TEPMLATES = {
    "imports": "python -c 'import {pip}'",
}


def run_tests(container: str) -> None:





if __name__ == "__main__":
    recipy = sys.argv[1]
    container = sys.argv[2]

