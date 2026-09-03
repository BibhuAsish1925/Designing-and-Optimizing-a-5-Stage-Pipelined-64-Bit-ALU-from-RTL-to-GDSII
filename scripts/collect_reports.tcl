#!/usr/bin/env tclsh

# ============================================================
# 64-bit ALU - LibreLane Report Collection
# ============================================================
# Automatically finds the latest RUN_* directory and copies
# important LibreLane reports into a clean project directory.
# ============================================================

set project_dir [file normalize [file join [file dirname [info script]] ".."]]
set runs_dir    [file join $project_dir "runs"]
set output_dir  [file join $project_dir "PPA_TIMING_REPORTS"]

# ------------------------------------------------------------
# Find latest LibreLane run
# ------------------------------------------------------------
set run_dirs [glob -nocomplain -type d [file join $runs_dir "RUN_*"]]

if {[llength $run_dirs] == 0} {
    puts "ERROR: No RUN_* directory found."
    exit 1
}

set latest_run [lindex [lsort -dictionary $run_dirs] end]

puts ""
puts "============================================================"
puts "64-bit ALU - LibreLane Report Collection"
puts "============================================================"
puts ""
puts "Source:"
puts $latest_run
puts ""
puts "Destination:"
puts $output_dir
puts ""

# ------------------------------------------------------------
# Create output directories
# ------------------------------------------------------------
foreach dir {
    metrics
    timing
    power
    area
    routing
    ir_drop
    drc_lvs
    final_layout
} {
    file mkdir [file join $output_dir $dir]
}

# ------------------------------------------------------------
# Copy one file if it exists
# ------------------------------------------------------------
proc copy_if_exists {src dst} {
    if {[file exists $src]} {
        file copy -force $src $dst
        puts "  copied: $src"
    }
}

# ------------------------------------------------------------
# Recursively find files matching a pattern
# ------------------------------------------------------------
proc recursive_files {directory} {

    set results {}

    foreach item [glob -nocomplain -directory $directory *] {

        if {[file isdirectory $item]} {

            foreach child [recursive_files $item] {
                lappend results $child
            }

        } elseif {[file isfile $item]} {

            lappend results $item
        }
    }

    return $results
}

# ------------------------------------------------------------
# Find and copy matching files
# ------------------------------------------------------------
proc find_and_copy {root pattern destination} {

    foreach current_file [recursive_files $root] {

        if {[string match $pattern [file tail $current_file]]} {

            file copy -force \
                $current_file \
                [file join $destination [file tail $current_file]]

            puts "  copied: $current_file"
        }
    }
}

# ============================================================
# 1/8 Metrics
# ============================================================
puts {[1/8] Collecting metrics...}

copy_if_exists \
    [file join $latest_run final metrics.csv] \
    [file join $output_dir metrics metrics.csv]

copy_if_exists \
    [file join $latest_run final metrics.json] \
    [file join $output_dir metrics metrics.json]

copy_if_exists \
    [file join $latest_run resolved.json] \
    [file join $output_dir metrics resolved.json]

# ============================================================
# 2/8 Timing
# ============================================================
puts {[2/8] Collecting timing reports...}

find_and_copy \
    [file join $latest_run 55-openroad-stapostpnr] \
    "summary.rpt" \
    [file join $output_dir timing]

find_and_copy \
    [file join $latest_run 55-openroad-stapostpnr] \
    "wns.*.rpt" \
    [file join $output_dir timing]

find_and_copy \
    [file join $latest_run 55-openroad-stapostpnr] \
    "ws.*.rpt" \
    [file join $output_dir timing]

find_and_copy \
    [file join $latest_run 55-openroad-stapostpnr] \
    "min.rpt" \
    [file join $output_dir timing]

find_and_copy \
    [file join $latest_run 55-openroad-stapostpnr] \
    "max.rpt" \
    [file join $output_dir timing]

# ============================================================
# 3/8 Power
# ============================================================
puts {[3/8] Collecting power reports...}

find_and_copy \
    $latest_run \
    "power.rpt" \
    [file join $output_dir power]

# ============================================================
# 4/8 Area
# ============================================================
puts {[4/8] Collecting area reports...}

find_and_copy \
    $latest_run \
    "*area*.rpt" \
    [file join $output_dir area]

find_and_copy \
    $latest_run \
    "*summary*.rpt" \
    [file join $output_dir area]

# ============================================================
# 5/8 Routing
# ============================================================
puts {[5/8] Collecting routing reports...}

find_and_copy \
    $latest_run \
    "*route*.rpt" \
    [file join $output_dir routing]

find_and_copy \
    $latest_run \
    "*routing*.rpt" \
    [file join $output_dir routing]

# ============================================================
# 6/8 IR Drop / Power Grid
# ============================================================
puts {[6/8] Collecting IR-drop reports...}

find_and_copy \
    $latest_run \
    "*irdrop*.rpt" \
    [file join $output_dir ir_drop]

find_and_copy \
    $latest_run \
    "*ir_drop*.rpt" \
    [file join $output_dir ir_drop]

find_and_copy \
    $latest_run \
    "*power_grid*.rpt" \
    [file join $output_dir ir_drop]

# ============================================================
# 7/8 DRC / LVS / Antenna / XOR
# ============================================================
puts {[7/8] Collecting signoff reports...}

find_and_copy \
    $latest_run \
    "*drc*" \
    [file join $output_dir drc_lvs]

find_and_copy \
    $latest_run \
    "*lvs*" \
    [file join $output_dir drc_lvs]

find_and_copy \
    $latest_run \
    "*antenna*" \
    [file join $output_dir drc_lvs]

find_and_copy \
    $latest_run \
    "*xor*" \
    [file join $output_dir drc_lvs]

# ============================================================
# 8/8 Final Layout
# ============================================================
puts {[8/8] Collecting final layout files...}

set final_dir [file join $latest_run final]

foreach pattern {
    "*.gds"
    "*.def"
    "*.lef"
    "*.nl.v"
    "*.spice"
} {

    foreach current_file [glob -nocomplain -type f \
        -directory $final_dir $pattern] {

        file copy -force \
            $current_file \
            [file join $output_dir final_layout [file tail $current_file]]

        puts "  copied: [file tail $current_file]"
    }
}

# ============================================================
# Finished
# ============================================================
puts ""
puts "============================================================"
puts "DONE"
puts "============================================================"
puts ""
puts "Reports collected in:"
puts $output_dir
puts ""
puts "Latest run:"
puts $latest_run
puts ""