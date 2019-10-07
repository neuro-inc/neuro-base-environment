import asyncio
import re
import sys
from pathlib import Path
from typing import Any, Dict, List

import aiohttp
import yaml

PIP_MODULE_REGEX = re.compile(r"\s([a-z][^\s=]*)", re.IGNORECASE)
PIP_INSTALL_COMMANDS = {"$PIP_INSTALL"}
PIP_COMMAND_SEPARATORS = {"&&"}
META_YML_URL_PATTERN = "https://raw.githubusercontent.com/conda-forge/{pip}-feedstock/master/recipe/meta.yaml"


def get_paths() -> Dict[str, Path]:
    recipes_dir = Path(__file__).parent / "recipes"
    paths = dict()
    for key in ["imports", "requires", "commands"]:
        path = recipes_dir / key
        paths[key] = path
    return paths


PATHS = get_paths()


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


async def _download_meta_yml(pip: str) -> str:
    url = META_YML_URL_PATTERN.format(pip=pip)
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as resp:
            assert resp.status == 200, f"error {url}, status: {resp.status}"
            return await resp.text()


def _parse_yml_jinja_text(text: str) -> Dict[str, Any]:
    text = text.replace("{%", "# {%")
    text = re.sub(r"{.*}", "PLACEHOLDER", text)
    return yaml.safe_load(text)


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
    for key in ["imports", "requires", "commands"]:
        value = tests.get(key)
        if value:
            result[key] = value
    return result


def _dump_tests(pip: str, tests_dict: Dict[str, Any]) -> None:
    for key in ["imports", "requires", "commands"]:
        tests = tests_dict.get(key)
        if not tests:
            continue
        assert isinstance(tests, list), type(tests)
        path = PATHS[key] / pip
        path.write_text("\n".join(tests))


async def generate_recipes(src: str) -> None:
    text = Path(src).read_text()
    pips = _get_pip_packages(text)

    for pip in pips:
        try:
            meta = await _download_meta_yml(pip)
            meta_dict = _parse_yml_jinja_text(meta)
            test_dict = _get_tests_dict(pip, meta_dict)
            _dump_tests(pip, test_dict)
            print(f"dumped: {pip}")
        except asyncio.CancelledError:
            raise
        except Exception as e:
            print(f"ERROR: Could not load meta for {pip}: {repr(e)}")
            continue


if __name__ == "__main__":
    dockerfile_path = sys.argv[1]
    asyncio.run(generate_recipes(dockerfile_path))
