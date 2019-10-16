from pathlib import Path
from typing import Dict

CURRENT_DIR = Path(__file__).parent
RECIPES_DIR_PATH = CURRENT_DIR / "recipes"
RECIPES_IGNORE_DIR_PATH = CURRENT_DIR / "recipes-ignore"


def _get_paths(recipes_path: Path) -> Dict[str, Path]:
    paths = dict()
    for op in ["imports", "requires", "commands"]:
        path = recipes_path / op
        paths[op] = path
    return paths


RECIPES_PATHS = _get_paths(RECIPES_DIR_PATH)
IGNORE_RECIPES_PATHS = _get_paths(RECIPES_IGNORE_DIR_PATH)
