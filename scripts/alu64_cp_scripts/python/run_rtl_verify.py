#!/usr/bin/env python3

from pathlib import Path
import argparse
import subprocess
import sys


def run(cmd, cwd):
    print("\n$ " + " ".join(cmd))
    result = subprocess.run(cmd, cwd=cwd)

    if result.returncode != 0:
        raise SystemExit(result.returncode)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    args = parser.parse_args()

    root = Path(args.root).resolve()

    src = root / "src"
    tb = root / "tb"
    build = root / "build" / "iverilog"

    build.mkdir(parents=True, exist_ok=True)

    common = [
        str(src / "alu64_cp_pkg.sv"),
        str(src / "alu64_cp_core.sv"),
    ]

    tests = [
        (
            "core",
            common,
            tb / "alu64_cp_core_tb.sv",
        ),
        (
            "pipeline",
            common + [
                str(src / "alu64_cp_pipeline.sv"),
            ],
            tb / "alu64_cp_pipeline_tb.sv",
        ),
        (
            "top",
            common + [
                str(src / "alu64_cp_pipeline.sv"),
                str(src / "alu64_cp_top.sv"),
            ],
            tb / "alu64_cp_top_tb.sv",
        ),
    ]

    for name, sources, testbench in tests:

        executable = build / f"alu64_cp_{name}_tb"

        run(
            [
                "iverilog",
                "-g2012",
                "-o",
                str(executable),
            ]
            + sources
            + [str(testbench)],
            root,
        )

        run(
            [
                "vvp",
                str(executable),
            ],
            root,
        )

    print("\n========================================")
    print("ALU64_CP RTL verification: PASS")
    print("========================================")


if __name__ == "__main__":
    main()
