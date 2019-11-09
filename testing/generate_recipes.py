import re
import sys
import urllib.request
from pathlib import Path
from typing import Any, Dict, List, Optional, Pattern, Sequence, Tuple

import yaml
from sympy.logic.boolalg import BooleanFalse, BooleanTrue
from sympy.parsing.sympy_parser import parse_expr

from _common import RECIPES_PATHS

# TODO: we should generate jinja manually instead
#  (maybe we could generate jinja partially, a new template for a specific platform?)
IGNORE_PLATFORMS: Tuple[str] = ("win",)
REGEX_LINE_WITH_PLATFORM_COMMENT = re.compile(r"[^\n#]*#\s*\[([^\]]+)\]")
TARGET_PYTHON_VERSION = "37"


def _get_version_assertion_regex(name: str) -> Pattern:
    return re.compile(fr"(({name}) *(>|>=|<|<=|==)* *(\d+))")


TARGET_PYTHON_REGEX = _get_version_assertion_regex("py")
TARGET_ANY_REGEX = _get_version_assertion_regex("[^><= ]+")

PLACEHOLDER = "PLACEHOLDER"
PIP_MODULE_REGEX = re.compile(r"\s([a-z][^\s=]*)", re.IGNORECASE)
PIP_INSTALL_COMMANDS = {"$PIP_INSTALL"}
PIP_COMMAND_SEPARATORS = {"&&"}
META_YML_URL_PATTERN = "https://raw.githubusercontent.com/conda-forge/{pip}-feedstock/master/recipe/meta.yaml"
PIP_TO_RECIPE_MAP = {"torch": "pytorch-cpu", "tensorflow-gpu": "tensorflow"}


def _get_deepo_pip_packages(dockerfile_text: str) -> List[str]:
    """ This method accepts target Dockerfile contents as a string and finds there
    all pip packages defined in standard syntax used in `deepo` Dockerfiles:
    ```
    $PIP_INSTALL \
       future \
       numpy \
       protobuf \
       enum \
       typing \
       && \
    ```
    :param dockerfile_text: Dockerfile contents as a string
    :return: List of pip packages (without versions)
    """
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
    """ This method downloads `meta.yaml` used by conda-forge project to store
    meta-information on pip- and system-packages (such as dependencies, testing
    commands, etc).
    :param pip: name of pip package
    :return: contents of `meta.yml` file
    """
    url = META_YML_URL_PATTERN.format(pip=pip)
    with urllib.request.urlopen(url) as resp:
        assert resp.status == 200, f"error downloading {url}, status: {resp.status}"
        return resp.read().decode()


def _parse_yaml_jinja_text(text: str) -> Dict[str, Any]:
    """ Since all `meta.yml` files are in fact jinja2 templates, we are unable to parse
    them directly via a yaml parser. However, most of the information specified by the
    template parameters (such as compiler version, python version) is unnecessary for us
    since it's used only in `build`, `source`, and other fields (so far, we use only
    `test` field). To solve this problem, we remove all jinja directives and parse
    platform-specifying comments (such as `# [win]`) removing those lines of yaml-file
    that are defined for undesired platforms (for example, windows is undesired).
    :param text: contents of the `meta.yml` file
    :return: parsed yaml
    """
    # HACK: in order not to generate real yamls via jinja,
    #  just make jinja patterns yaml-parseable
    text = __remove_jinja_directives(text)
    text = __conda_forge_analyze_platform(text)
    text = re.sub(r"{{.*}}", PLACEHOLDER, text)
    return yaml.safe_load(text)


def __remove_jinja_directives(text: str) -> str:
    """
    Replace all jinja directives with a placeholder.
    :param text: contents of the `meta.yml` file
    :return: contents of the `meta.yml` file without jinja directives
    """
    return text.replace("{%", "# {%")


def __conda_forge_analyze_platform(
    text: str,
    ignore_platforms: Sequence[str] = IGNORE_PLATFORMS,
    target_python_version: str = TARGET_PYTHON_VERSION,
    placeholder: str = PLACEHOLDER,
) -> str:
    """
    This method analyzes platform-specifying comments and replace those lines defined
    for undesired platforms with a placeholder (python/bash comment). This step is
    needed since many tests are duplicated for different platforms, for example:
      https://github.com/conda-forge/numpy-feedstock/blob/master/recipe/meta.yaml#L54-L56
      ```
      - pytest --timeout=300 -v --pyargs numpy -k "not (test_loss_of_precision or test_einsum_sums_cfloat64)"  # [ppc64le]
      - pytest --timeout=300 -v --pyargs numpy -k "not (test_loss_of_precision or test_may_share_memory_easy_fuzz or test_xerbla_override or test_may_share_memory_harder_fuzz or test_large_zip or test_sdot_bug_8577 or test_unary_ufunc_call_fuzz)"  # [aarch64]
      - pytest --timeout=300 -v --pyargs numpy  # [not (aarch64 or ppc64le)]
      ```
    :param text: contents of the `meta.yml` file
    :param ignore_platforms: list of platform IDs to ignore (without brackets, ex.: "win")
    :param placeholder: text to replace lines with
    :param target_python_version: two-digit line of desired python version (ex.: "37")
    :return: contents of the `meta.yml` file without lines for undesired platforms

    >>> __conda_forge_analyze_platform("test  # [not win]", ["win"], "37", "replaced")
    'test  # [not win]'
    >>> __conda_forge_analyze_platform("test  # [win]", ["win"], "37", "replaced")
    '# replaced'
    >>> __conda_forge_analyze_platform("test  # [linux]", ["win"], "37", "replaced")
    'test  # [linux]'
    >>> __conda_forge_analyze_platform("test  # [linux and py<=35]", ["win"], "37", "replaced")
    '# replaced'
    >>> __conda_forge_analyze_platform("test  # [linux and py <= 35]", ["win"], "37", "replaced")
    '# replaced'
    >>> __conda_forge_analyze_platform("test  # [linux and py == 37]", ["win"], "37", "replaced")
    'test  # [linux and py == 37]'
    >>> __conda_forge_analyze_platform("test  # [linux and py ==37]", ["win"], "37", "replaced")
    'test  # [linux and py ==37]'
    >>> __conda_forge_analyze_platform("test  # [linux and py37]", ["win"], "37", "replaced")
    'test  # [linux and py37]'
    >>> __conda_forge_analyze_platform("test  # [linux and py38]", ["win"], "37", "replaced")
    '# replaced'
    """
    platform_line_iter = REGEX_LINE_WITH_PLATFORM_COMMENT.finditer(text)
    for match in platform_line_iter:
        platform_expr = match.group(1)
        platform_expr = __substitute_target_python(platform_expr, target_python_version)
        platform_expr = __normalize_expressions(platform_expr)
        matched = __match_target_platform(platform_expr, ignore_platforms)
        if not matched:
            platform_line = match.group(0)
            text = text.replace(platform_line, f"# {placeholder}")
    return text


def __match_target_platform(
    platform_expr: str, ignore_platforms: Sequence[str]
) -> bool:
    """ Helper: simplified parser of `target_platform` directives of `meta.yml` files.

    >>> __match_target_platform("win", ["win", "osx"])
    False
    >>> __match_target_platform("not win", ["win", "osx"])
    True
    >>> __match_target_platform("linux", ["win", "osx"])
    True
    >>> # The following example is a known non-working corner case:
    >>> #  the test should produce `True` because we assume
    >>> #  that except `linux` there are other valid platforms
    >>> __match_target_platform("not linux", ["win", "osx"])
    False
    >>> __match_target_platform("win or osx", ["win", "osx"])
    False
    >>> __match_target_platform("win or linux or osx", ["win", "osx"])
    True
    >>> __match_target_platform("not (win or osx)", ["win", "osx"])
    True
    >>> __match_target_platform("not (win or linux)", ["win", "osx"])
    False
    >>> # Python version expressions are evaluated to bools: True or False:
    >>> __match_target_platform("linux and True", ["win", "osx"])
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
        assert isinstance(matched, bool), f"should be bool: {type(matched)} | {expr}"
        return matched
    except Exception as e:
        print(f"Could not parse target platform expression `{platform_expr}`: {e}")
        return False


def __substitute_target_python(platform_expr: str, target_python_version: str) -> str:
    """ Helper: evaluates python-version conditions in order to make the whole line
    a valid string to be parsed by sympy.

    >>> __substitute_target_python("py>=37", "37")
    'True'
    >>> __substitute_target_python("win and py>=37", "37")
    'win and True'
    >>> __substitute_target_python("win and py>=37", "35")
    'win and False'
    >>> __substitute_target_python("win and py == 37 or linux", "37")
    'win and True or linux'
    >>> __substitute_target_python("win and py< 37 or linux", "34")
    'win and True or linux'
    >>> __substitute_target_python("win and py > 37 or linux", "34")
    'win and False or linux'
    >>> __substitute_target_python("win and py37 or linux", "37")
    'win and True or linux'
    """
    result = platform_expr
    for full, py, op, ver in set(TARGET_PYTHON_REGEX.findall(platform_expr)):
        if not op:
            op = "=="
        repl = parse_expr(f"{target_python_version} {op} {ver}")
        if isinstance(repl, (BooleanTrue, BooleanFalse)):
            repl = bool(repl)
        assert isinstance(repl, bool), f"Wrong type of {repl}: {type(repl)}"
        result = result.replace(full, str(repl))
    return result


def __normalize_expressions(platform_expr: str) -> str:
    """ Helper: Replaces expressions containing equality and non-equality signs
    with a "safe" string so that sympy evaluates them as a single token.

    >>> __normalize_expressions("vc<3")
    'vc_lt_3'
    >>> __normalize_expressions("vc >=3")
    'vc_gteq_3'
    >>> __normalize_expressions("vc  == 3")
    'vc_eq_3'
    >>> __normalize_expressions("vc3")
    'vc3'
    """
    result = platform_expr
    for full, nom, op, ver in set(TARGET_ANY_REGEX.findall(platform_expr)):
        if not op:
            continue
        if op == "==":
            op = "eq"
        elif op == ">":
            op = "gt"
        elif op == ">=":
            op = "gteq"
        elif op == "<":
            op = "lt"
        elif op == "<=":
            op = "lteq"
        elif op:
            op = "op"
        repl = f"{nom}_{op}_{ver}"
        result = result.replace(full, str(repl))
    return result


def _get_tests_subdict(
    meta_dict: Dict[str, Any], pip: Optional[str] = None
) -> Dict[str, Any]:
    """ Returns `test` section of the parsed `meta.yml` contents.
    """
    normalized = meta_dict.copy()

    # HACK(artem) tensorflow's meta.yml has multiple sections inside `test`
    if pip == "tensorflow":
        outputs = [x for x in meta_dict["outputs"] if x["name"] == "tensorflow-base"]
        assert len(outputs) == 1, f"wrong dict: {meta_dict}"
        normalized = outputs[0]

    return normalized["test"]


def _get_tests_dict(
    meta_dict: Dict[str, Any], pip: Optional[str] = None
) -> Dict[str, Any]:
    """ Returns necessary test sections: "imports", "requires", "commands"
    """
    tests = _get_tests_subdict(meta_dict, pip)
    result = dict()
    for op in ["imports", "requires", "commands"]:
        commands = tests.get(op)
        if not commands:
            continue
        assert isinstance(commands, list), f"expect: list, got: {type(commands)}"
        result[op] = [
            __conda_forge_analyze_platform(cmd, IGNORE_PLATFORMS, PLACEHOLDER)
            for cmd in commands
        ]
    return result


def _dump_tests(pip: str, tests_dict: Dict[str, Any]) -> None:
    """
    Dumps parsed contents of test operations into separate files.
    :param pip: name of pip package (no version)
    :param tests_dict: parsed contents of test operations
    """
    for op in ["imports", "requires", "commands"]:
        tests = tests_dict.get(op)
        if not tests:
            continue
        assert isinstance(tests, list), type(tests)
        path = RECIPES_PATHS[op] / pip
        path.write_text("\n".join(tests))


def generate_recipes(dockerfile_path: str) -> None:
    """
    Entry point of the whole script.
    Parses Dockerfile to collect all pip packages installed, downloads and analyzes
    `meta.yml` files of each pip package, dumps collected information to the files.
    """
    dockerfile_text = Path(dockerfile_path).read_text()
    pips = _get_deepo_pip_packages(dockerfile_text)

    for pip in pips:
        recipe = PIP_TO_RECIPE_MAP.get(pip, pip)
        try:
            meta_text = _download_meta_yml(recipe)
            meta_dict = _parse_yaml_jinja_text(meta_text)
            test_dict = _get_tests_dict(meta_dict, recipe)
            _dump_tests(recipe, test_dict)

            dump_name = f"{recipe} (as {pip})" if pip != recipe else recipe
            print(f"dumped: {dump_name}")
        except Exception as e:
            url = META_YML_URL_PATTERN.format(pip=pip)
            print(f"ERROR {recipe}: {type(e)} {e}. See file: {url}")
            continue


if __name__ == "__main__":
    dockerfile_path = sys.argv[1]
    generate_recipes(dockerfile_path)
