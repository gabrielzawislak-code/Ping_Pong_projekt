# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Project detiles required for generate_bitstream.tcl
# Make sure that project_name, top_module and target are correct.
# Provide paths to all the files required for synthesis and implementation.
# Depending on the file type, it should be added in the corresponding section.
# If the project does not use files of some type, leave the corresponding section commented out.

#-----------------------------------------------------#
#                   Project details                   #
#-----------------------------------------------------#
# Project name                                  -- EDIT
set project_name vga_project

# Top module name                               -- EDIT
set top_module top_vga_basys3

# FPGA device
set target xc7a35tcpg236-1

#-----------------------------------------------------#
#                    Design sources                   #
#-----------------------------------------------------#
# Specify .xdc files location                   -- EDIT
set xdc_files {
    constraints/top_vga_basys3.xdc
    constraints/clk_wiz_0.xdc
    constraints/clk_wiz_0_late.xdc
}

# Specify SystemVerilog design files location   -- EDIT
set sv_files {
    ../rtl/video/vga_pkg.sv
    ../rtl/video/vga_if.sv
    ../rtl/video/vga_timing.sv
    ../rtl/video/draw_bg.sv
    ../rtl/top_vga.sv
    ../rtl/video/char_rom.sv
    ../rtl/game/counter_refresh_time.sv
    ../rtl/common/delay.sv
    ../rtl/common/reset_ctrl.sv
    ../rtl/video/draw_char.sv
    ../rtl/video/draw_paddle_ball.sv
    ../rtl/video/draw_score.sv
    ../rtl/video/font_rom.sv
    ../rtl/game/game_fsm.sv
    ../rtl/game/paddle_pos.sv
    ../rtl/uart/receive_bytes.sv
    ../rtl/uart/send_bytes.sv
    ../rtl/uart/uart_sync.sv
    rtl/top_vga_basys3.sv

}

#Specify Verilog design files location         -- EDIT
 set verilog_files {
    rtl/clk_wiz_0_clk_wiz.v
    rtl/clk_wiz_0.v
    ../rtl/common/debounce.v
    ../rtl/uart/fifo.v
    ../rtl/common/mod_m_counter.v
    ../rtl/uart/uart_rx.v
    ../rtl/uart/uart_tx.v
    ../rtl/uart/uart.v
}

# Specify VHDL design files location            -- EDIT
# set vhdl_files {
#    path/to/file.vhd
# }

# Specify files for a memory initialization     -- EDIT
# set mem_files {
#    path/to/file.data
# }
