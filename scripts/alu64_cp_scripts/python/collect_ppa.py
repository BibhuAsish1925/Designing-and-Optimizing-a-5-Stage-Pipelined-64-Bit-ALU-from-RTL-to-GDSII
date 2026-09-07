#!/usr/bin/env python3

from pathlib import Path
import argparse
import json
import csv


METRICS = [
    "design__instance__area",
    "design__instance__area__stdcell",
    "power__total",
    "timing__setup__wns",
    "timing__setup__tns",
    "timing__hold__wns",
    "route__wirelength",
    "route__vias",
    "route__drc_errors",
    "design__violations",
    "antenna__violating__nets",
    "antenna__violating__pins",
]


def main():

    parser = argparse.ArgumentParser()

    parser.add_argument(
        "run_dir",
        help="LibreLane run directory",
    )

    parser.add_argument(
        "--out",
        default=None,
    )

    args = parser.parse_args()

    run = Path(args.run_dir).resolve()

    states = list(run.rglob("state_in.json"))

    if not states:
        raise SystemExit(
            "ERROR: state_in.json not found"
        )

    preferred = [
        p for p in states
        if "72-checker-lvs" in str(p)
    ]

    state = preferred[0] if preferred else states[-1]

    data = json.loads(
        state.read_text()
    )

    output = (
        Path(args.out)
        if args.out
        else run / "ppa_summary.csv"
    )

    with output.open(
        "w",
        newline=""
    ) as fh:

        writer = csv.writer(fh)

        writer.writerow(
            ["metric", "value"]
        )

        for metric in METRICS:

            writer.writerow(
                [
                    metric,
                    data.get(
                        metric,
                        "N/A"
                    ),
                ]
            )

    print("\n========================================")
    print("ALU64_CP PPA SUMMARY")
    print("========================================")

    print(f"Run   : {run}")
    print(f"State : {state}")
    print(f"Output: {output}")

    print()

    for metric in METRICS:

        print(
            f"{metric:45s} "
            f"{data.get(metric, 'N/A')}"
        )


if __name__ == "__main__":
    main()
