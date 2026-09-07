#!/usr/bin/env python3

from pathlib import Path
import argparse
import subprocess
import sys


DEFAULT_LIB = (
    "/root/.ciel/ciel/sky130/"
    "versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/"
    "sky130B/libs.ref/sky130_fd_sc_hd/lib/"
    "sky130_fd_sc_hd__tt_025C_1v80.lib"
)


def main():

    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--root",
        default=".",
    )

    parser.add_argument(
        "--liberty",
        default=DEFAULT_LIB,
    )

    args = parser.parse_args()

    root = Path(args.root).resolve()

    build = root / "build" / "yosys"
    build.mkdir(parents=True, exist_ok=True)

    report = build / "yosys_synthesis_stat.rpt"
    netlist = build / "alu64_cp_top_synth.v"

    sources = [
        root / "src/alu64_cp_pkg.sv",
        root / "src/alu64_cp_core.sv",
        root / "src/alu64_cp_pipeline.sv",
        root / "src/alu64_cp_top.sv",
    ]

    yosys_script = f"""
read_verilog -sv {" ".join(map(str, sources))}

hierarchy -top alu64_cp_top

proc
opt
fsm
memory
opt
techmap
opt

abc -liberty {args.liberty}

clean

stat

write_verilog -noattr {netlist}
"""

    print("\nRunning Yosys synthesis...")

    with report.open("w") as fh:

        result = subprocess.run(
            [
                "yosys",
                "-p",
                yosys_script,
            ],
            cwd=root,
            stdout=fh,
            stderr=subprocess.STDOUT,
        )

    if result.returncode != 0:
        raise SystemExit(result.returncode)

    print("\n========================================")
    print("Yosys synthesis: PASS")
    print("========================================")
    print(f"Report : {report}")
    print(f"Netlist: {netlist}")


if __name__ == "__main__":
    main()
