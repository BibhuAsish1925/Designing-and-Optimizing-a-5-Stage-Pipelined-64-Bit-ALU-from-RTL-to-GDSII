# ============================================================
# ALU64_CP Vivado Synthesis + Reports
# ============================================================

set ROOT [file normalize [file join [pwd] ".."]]

set PROJECT \
    [file join \
        $ROOT \
        vivado \
        alu64_cp_vivado \
        alu64_cp_vivado.xpr]


open_project $PROJECT


reset_run synth_1


launch_runs synth_1 -jobs 4


wait_on_run synth_1


open_run synth_1


set REPORT_DIR \
    [file join $ROOT vivado reports]


file mkdir $REPORT_DIR


report_utilization \
    -file [file join \
        $REPORT_DIR utilization.rpt]


report_timing_summary \
    -file [file join \
        $REPORT_DIR timing_summary.rpt]


report_power \
    -file [file join \
        $REPORT_DIR power.rpt]


puts ""
puts "============================================"
puts "Vivado reports generated"
puts "Directory: $REPORT_DIR"
puts "============================================"
