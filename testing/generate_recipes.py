import re
import sys
import urllib.request
from pathlib import Path
from typing import Any, Dict, List

import yaml
from sympy.logic.boolalg import BooleanFalse, BooleanTrue
from sympy.parsing.sympy_parser import parse_expr

from common import RECIPES_PATHS

# TODO: we should generate jinja manually instead
#  (maybe we could generate jinja partially, a new template for a specific platform?)
IGNORE_PLATFORMS = ["win"]
REGEX_LINE_WITH_PLATFORM_COMMENT = re.compile(r"[^\n#]*#\s*\[([^\]]+)\]")
TARGET_PYTHON_VERSION = "37"
TARGET_PYTHON_REGEX = re.compile(r"(py *(>|>=|<|<=|==) *(\d+))")

PLACEHOLDER = "PLACEHOLDER"
PIP_MODULE_REGEX = re.compile(r"\s([a-z][^\s=]*)", re.IGNORECASE)
PIP_INSTALL_COMMANDS = {"$PIP_INSTALL"}
PIP_COMMAND_SEPARATORS = {"&&"}
META_YML_URL_PATTERN = "https://raw.githubusercontent.com/conda-forge/{pip}-feedstock/master/recipe/meta.yaml"
PIP_TO_RECIPE_MAP = {"torch": "pytorch-cpu", "tensorflow-gpu": "tensorflow"}


def _get_pip_packages(dockerfile_text: str) -> List[str]:
    lines = dockerfile_text.split("\n")
    pips: List[str] = []
    in_pip_section = False
    for line in lines:
        if any(cmd in line for cmd in PIP_INSTALL_COMMANDS):
            in_pip_section = True
        if not in_pip_section:
            continue
        packages = PIP_MODULE_REGEX.findall(line)
        for p in packages:
            if any(p in cmd for cmd in PIP_INSTALL_COMMANDS):
                continue
            pips.append(p)
        if any(sep in line for sep in PIP_COMMAND_SEPARATORS):
            in_pip_section = False
    return pips


def _download_meta_yml(pip: str) -> str:
    url = META_YML_URL_PATTERN.format(pip=pip)
    with urllib.request.urlopen(url) as resp:
        assert resp.status == 200, f"error {url}, status: {resp.status}"
        return resp.read().decode()


def _parse_yaml_jinja_text(text: str) -> Dict[str, Any]:
    # HACK: in order not to generate real yamls via jinja,
    #  just make jinja patterns yaml-parseable
    text = _jinja_remove_directives(text)
    text = _jinja_remove_platform_comments(text, IGNORE_PLATFORMS, PLACEHOLDER)

    text = re.sub(r"{.*}", PLACEHOLDER, text)
    return yaml.safe_load(text)


def _jinja_remove_directives(text: str) -> str:
    return text.replace("{%", "# {%")


def _jinja_remove_platform_comments(
    text: str,
    ignore_platforms: List[str],
    placeholder: str = PLACEHOLDER,
    target_python_version: str = TARGET_PYTHON_VERSION,
) -> str:
    """
    >>> _jinja_remove_platform_comments("test  # [not win]", ["win"], "replaced")
    'test  # [not win]'
    >>> _jinja_remove_platform_comments("test  # [win]", ["win"], "replaced")
    '# replaced'
    >>> _jinja_remove_platform_comments("test  # [linux]", ["win"], "replaced")
    'test  # [linux]'
    >>> _jinja_remove_platform_comments("test  # [linux and py<=35]", ["win"], "replaced", "37")
    '# replaced'
    """
    platform_line_iter = REGEX_LINE_WITH_PLATFORM_COMMENT.finditer(text)
    for match in platform_line_iter:
        platform_expr = match.group(1)
        platform_expr = _substitute_target_python(platform_expr, target_python_version)
        if not _match_target_platform(platform_expr, ignore_platforms):
            platform_line = match.group(0)
            text = text.replace(platform_line, f"# {placeholder}")
    return text


def _match_target_platform(platform_expr: str, ignore_platforms: List[str]) -> bool:
    """ Simplified parser of `target_platform` directives.

    >>> _match_target_platform("win", ["win", "osx"])
    False
    >>> _match_target_platform("not win", ["win", "osx"])
    True
    >>> _match_target_platform("linux", ["win", "osx"])
    True
    >>> # The following example is a known non-working corner case:
    >>> #  the test should produce `True` because we assume
    >>> #  that except `linux` there are other valid platforms
    >>> _match_target_platform("not linux", ["win", "osx"])
    False
    >>> _match_target_platform("win or osx", ["win", "osx"])
    False
    >>> _match_target_platform("win or linux or osx", ["win", "osx"])
    True
    >>> _match_target_platform("not (win or osx)", ["win", "osx"])
    True
    >>> _match_target_platform("not (win or linux)", ["win", "osx"])
    False
    >>> # Python version expressions are evaluated to bools: True or False:
    >>> _match_target_platform("linux and True", ["win", "osx"])
    True
    """
    expr = platform_expr
    keywords = {"or", "and", "not"}

    local_dict = {
        token: True
        for token in expr.replace("(", "").replace(")", "").split()
        if token not in keywords
    }
    for ignore in ignore_platforms:
        local_dict[ignore] = False

    try:
        matched = parse_expr(expr, local_dict=local_dict)
        assert isinstance(matched, bool), f"Wrong type: {type(matched)}"
        return matched
    except Exception as e:
        print(f"Could not parse target platform expression `{platform_expr}`: {e}")
        return False


def _substitute_target_python(platform_expr: str, target_python_version: str) -> str:
    """
    >>> _substitute_target_python("py>=37", "37")
    'True'
    >>> _substitute_target_python("win and py>=37", "37")
    'win and True'
    >>> _substitute_target_python("win and py>=37", "35")
    'win and False'
    >>> _substitute_target_python("win and py == 37 or linux", "37")
    'win and True or linux'
    >>> _substitute_target_python("win and py< 37 or linux", "34")
    'win and True or linux'
    """
    result = platform_expr
    for full, op, ver in set(TARGET_PYTHON_REGEX.findall(platform_expr)):
        repl = parse_expr(f"{target_python_version} {op} {ver}")
        if isinstance(repl, (BooleanTrue, BooleanFalse)):
            repl = bool(repl)
        assert isinstance(repl, bool), f"Wrong type of {repl}: {type(repl)}"
        result = result.replace(full, str(repl))

    return result


def _get_tests_subdict(pip: str, meta_dict: Dict[str, Any]) -> Dict[str, Any]:
    normalized = meta_dict.copy()
    if pip == "tensorflow":
        outputs = [x for x in meta_dict["outputs"] if x["name"] == "tensorflow-base"]
        assert len(outputs) == 1, f"wrong dict: {meta_dict}"
        normalized = outputs[0]

    return normalized["test"]


def _get_tests_dict(pip: str, meta_dict: Dict[str, Any]) -> Dict[str, Any]:
    tests = _get_tests_subdict(pip, meta_dict)
    result = dict()
    for op in ["imports", "requires", "commands"]:
        commands = tests.get(op)
        if commands:
            assert isinstance(commands, list), f"expect: list, got: {type(commands)}"
            result[op] = commands
    return result


def _dump_tests(pip: str, tests_dict: Dict[str, Any]) -> None:
    for op in ["imports", "requires", "commands"]:
        tests = tests_dict.get(op)
        if not tests:
            continue
        assert isinstance(tests, list), type(tests)
        path = RECIPES_PATHS[op] / pip
        path.write_text("\n".join(tests))


def generate_recipes(dockerfile_path: str) -> None:
    dockerfile_text = Path(dockerfile_path).read_text()
    pips = _get_pip_packages(dockerfile_text)

    for pip in pips:
        recipe = PIP_TO_RECIPE_MAP.get(pip, pip)
        try:
            meta_text = _download_meta_yml(recipe)
            meta_dict = _parse_yaml_jinja_text(meta_text)
            test_dict = _get_tests_dict(recipe, meta_dict)
            _dump_tests(recipe, test_dict)

            dump_name = f"{recipe} (as {pip})" if pip != recipe else recipe
            print(f"dumped: {dump_name}")
        except Exception as e:
            print(f"ERROR: Could not load meta for {recipe}: {repr(e)} {e}")
            continue


if __name__ == "__main__":
    dockerfile_path = sys.argv[1]
    generate_recipes(dockerfile_path)
