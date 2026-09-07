# ============================================================
# ALU64_CP Vivado 2025.1 Project Creation
# ============================================================

set ROOT [file normalize [file join [pwd] ".."]]

set VIVADO_DIR [file join $ROOT vivado]

set PROJECT_NAME alu64_cp_vivado

set PART xc7a200tfbg676-2


file mkdir $VIVADO_DIR


create_project \
    $PROJECT_NAME \
    [file join $VIVADO_DIR $PROJECT_NAME] \
    -part $PART \
    -force


add_files [list \
    [file join $ROOT src alu64_cp_pkg.sv] \
    [file join $ROOT src alu64_cp_core.sv] \
    [file join $ROOT src alu64_cp_pipeline.sv] \
    [file join $ROOT src alu64_cp_top.sv] \
]


set_property top alu64_cp_top [current_fileset]


update_compile_order \
    -fileset sources_1


puts ""
puts "============================================"
puts "ALU64_CP Vivado project created"
puts "Top  : alu64_cp_top"
puts "Part : $PART"
puts "============================================"
