#!/usr/bin/env python3

"""
64-bit ALU - LibreLane Report Collector

Collects important reports and final physical-design files from
a completed LibreLane run into a clean directory suitable for
project documentation and GitHub.

This script does not rerun LibreLane.
"""

from pathlib import Path
import shutil
import sys


# ------------------------------------------------------------
# Project locations
# ------------------------------------------------------------

RUN = Path.home() / (
    "asic_projects1/alu64/runs/"
    "RUN_2026-09-02_10-53-20"
)

OUT = Path.home() / "asic_projects1/alu64/PPA_TIMING_REPORTS"

# ------------------------------------------------------------
# Report categories
# ------------------------------------------------------------

CATEGORIES = [
    "metrics",
    "timing",
    "power",
    "area",
    "routing",
    "ir_drop",
    "drc_lvs",
    "final_layout",
]


# ------------------------------------------------------------
# Utility functions
# ------------------------------------------------------------

def copy_file(source: Path, destination: Path) -> None:
    """Copy one file while creating the destination directory."""
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)


def collect_matching_files(
    source_root: Path,
    destination_root: Path,
    patterns: list[str],
) -> int:
    """Collect files matching the supplied filename patterns."""

    count = 0

    for file_path in source_root.rglob("*"):

        if not file_path.is_file():
            continue

        name = file_path.name.lower()

        matched = any(
            pattern.lower() in name
            for pattern in patterns
        )

        if not matched:
            continue

        relative_path = file_path.relative_to(source_root)
        destination = destination_root / relative_path

        copy_file(file_path, destination)
        count += 1

    return count

# ------------------------------------------------------------
# Validate source
# ------------------------------------------------------------

if not RUN.exists():

    print("ERROR: LibreLane run directory was not found.")
    print(f"Expected location: {RUN}")
    sys.exit(1)


# ------------------------------------------------------------
# Create output directories
# ------------------------------------------------------------

for category in CATEGORIES:
    (OUT / category).mkdir(parents=True, exist_ok=True)


print()
print("=" * 60)
print("64-bit ALU - LibreLane Report Collection")
print("=" * 60)
print()
print(f"Source      : {RUN}")
print(f"Destination : {OUT}")
print()

# ------------------------------------------------------------
# 1. Metrics
# ------------------------------------------------------------

print("[1/8] Collecting metrics...")

for filename in [
    "metrics.csv",
    "metrics.json",
    "resolved.json",
]:

    source = (
        RUN / "final" / filename
        if filename != "resolved.json"
        else RUN / filename
    )

    if source.exists():
        copy_file(
            source,
            OUT / "metrics" / filename
        )


# ------------------------------------------------------------
# 2. Timing
# ------------------------------------------------------------

print("[2/8] Collecting timing reports...")

timing_root = OUT / "timing"

for file_path in RUN.rglob("*"):

    if not file_path.is_file():
        continue

    if "openroad-stapostpnr" not in str(file_path):
        continue

    if file_path.suffix.lower() not in [".rpt", ".log"]:
        continue

    relative = file_path.relative_to(RUN)
    copy_file(file_path, timing_root / relative)


# ------------------------------------------------------------
# 3. Power
# ------------------------------------------------------------

print("[3/8] Collecting power reports...")

collect_matching_files(
    RUN,
    OUT / "power",
    ["power.rpt"],
)


# ------------------------------------------------------------
# 4. Area / synthesis
# ------------------------------------------------------------

print("[4/8] Collecting area/synthesis reports...")

collect_matching_files(
    RUN,
    OUT / "area",
    [
        "area.rpt",
        "area.log",
        "synthesis.rpt",
    ],
)


# ------------------------------------------------------------
# 5. Routing
# ------------------------------------------------------------

print("[5/8] Collecting routing reports...")

collect_matching_files(
    RUN,
    OUT / "routing",
    [
        "route.rpt",
        "routing.rpt",
        "detailedroute.rpt",
    ],
)


# ------------------------------------------------------------
# 6. IR-drop / power grid
# ------------------------------------------------------------

print("[6/8] Collecting IR-drop / power-grid reports...")

collect_matching_files(
    RUN,
    OUT / "ir_drop",
    [
        "irdrop.rpt",
        "ir_drop.rpt",
        "power_grid.rpt",
    ],
)


# ------------------------------------------------------------
# 7. DRC / LVS / antenna / XOR
# ------------------------------------------------------------

print("[7/8] Collecting physical-verification reports...")

collect_matching_files(
    RUN,
    OUT / "drc_lvs",
    [
        "drc",
        "lvs",
        "antenna",
        "xor",
    ],
)


# ------------------------------------------------------------
# 8. Final physical-design files
# ------------------------------------------------------------

print("[8/8] Collecting final layout files...")

final_dir = RUN / "final"

if final_dir.exists():

    allowed_extensions = {
        ".gds",
        ".def",
        ".lef",
        ".v",
        ".spice",
        ".json",
        ".csv",
    }

    for file_path in final_dir.iterdir():

        if not file_path.is_file():
            continue

        if file_path.suffix.lower() not in allowed_extensions:
            continue

        copy_file(
            file_path,
            OUT / "final_layout" / file_path.name
        )


# ------------------------------------------------------------
# Final summary
# ------------------------------------------------------------

files = [
    path
    for path in OUT.rglob("*")
    if path.is_file()
]

print()
print("=" * 60)
print("REPORT COLLECTION COMPLETE")
print("=" * 60)
print()
print(f"Output directory : {OUT}")
print(f"Files collected  : {len(files)}")
print()

for file_path in sorted(files):
    print(file_path.relative_to(OUT))

print()
print("=" * 60)
print("DONE")
print("=" * 60)
