"""Make the pymomentum-core wheel from the pymomentum-cpu wheel.

pymomentum-core is pymomentum-cpu without the files of the pymomentum_torch
CMake install component. Usage:

    make_core_wheel.py <pymomentum-cpu wheel> <torch component dir> <output dir>

<torch component dir> holds `cmake --install --component pymomentum_torch`
output from the build that made the pymomentum-cpu wheel.
"""

import base64
import hashlib
import sys
import zipfile
from pathlib import Path

cpu_wheel, torch_dir, out_dir = (Path(arg) for arg in sys.argv[1:])

torch_files = {
    path.relative_to(torch_dir).as_posix()
    for path in torch_dir.rglob("*")
    if path.is_file()
}
if not torch_files:
    raise RuntimeError(f"No pymomentum_torch files in {torch_dir}")

old_prefix, new_prefix = "pymomentum_cpu-", "pymomentum_core-"
if not cpu_wheel.name.startswith(old_prefix):
    raise RuntimeError(f"Unexpected wheel name: {cpu_wheel.name}")
out_dir.mkdir(parents=True, exist_ok=True)
core_wheel = out_dir / (new_prefix + cpu_wheel.name[len(old_prefix) :])

with zipfile.ZipFile(cpu_wheel) as cpu, zipfile.ZipFile(
    core_wheel, "w", zipfile.ZIP_DEFLATED
) as core:
    names = set(cpu.namelist())
    if not torch_files <= names:
        raise RuntimeError(f"Not in {cpu_wheel.name}: {sorted(torch_files - names)}")
    old_dist_info = next(n.split("/")[0] for n in names if ".dist-info/" in n)
    new_dist_info = new_prefix + old_dist_info[len(old_prefix) :]

    record = []
    for info in cpu.infolist():
        name = info.filename
        if info.is_dir() or name in torch_files or name == f"{old_dist_info}/RECORD":
            continue
        data = cpu.read(info)
        if name.startswith(f"{old_dist_info}/"):
            name = new_dist_info + name[len(old_dist_info) :]
            if name == f"{new_dist_info}/METADATA":
                old_name, new_name = b"Name: pymomentum-cpu\n", b"Name: pymomentum-core\n"
                if data.count(old_name) != 1:
                    raise RuntimeError(f"Expected exactly one {old_name!r} in METADATA")
                data = data.replace(old_name, new_name)
        new_info = zipfile.ZipInfo(name, date_time=info.date_time)
        new_info.external_attr = info.external_attr
        new_info.compress_type = zipfile.ZIP_DEFLATED
        core.writestr(new_info, data)
        digest = base64.urlsafe_b64encode(hashlib.sha256(data).digest()).rstrip(b"=")
        record.append(f"{name},sha256={digest.decode()},{len(data)}")
    record.append(f"{new_dist_info}/RECORD,,")
    core.writestr(f"{new_dist_info}/RECORD", "\n".join(record) + "\n")

print(f"Wrote {core_wheel}")
