import os
from pathlib import Path


path = Path("pyproject.toml")
text = path.read_text()
package_name = os.environ["PKG_NAME"]
if package_name not in {"pymomentum-core", "pymomentum-cpu", "pymomentum-gpu"}:
    raise RuntimeError(f"Unexpected PyMomentum package name: {package_name!r}")

replacements = {
    'name = "pymomentum"': f'name = "{package_name}"',
    'version = "0.1.0"': f'version = "{os.environ["PKG_VERSION"]}"',
    "dependencies = []": 'dependencies = ["numpy", "scipy>=1.7", "torch>=1.13"]',
}

for old, new in replacements.items():
    if text.count(old) != 1:
        raise RuntimeError(f"Expected exactly one {old!r} in {path}")
    text = text.replace(old, new)

path.write_text(text)
