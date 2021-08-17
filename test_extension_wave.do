onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /TestExtension/the_dut/clk
add wave -noupdate /TestExtension/the_dut/rst
add wave -noupdate /TestExtension/init
add wave -noupdate -radix binary /TestExtension/the_dut/a_in
add wave -noupdate -radix binary /TestExtension/the_dut/dir_in
add wave -noupdate -radix unsigned /TestExtension/the_dut/k_in
add wave -noupdate -radix unsigned -childformat {{{/TestExtension/the_dut/l_in[31]} -radix unsigned} {{/TestExtension/the_dut/l_in[30]} -radix unsigned} {{/TestExtension/the_dut/l_in[29]} -radix unsigned} {{/TestExtension/the_dut/l_in[28]} -radix unsigned} {{/TestExtension/the_dut/l_in[27]} -radix unsigned} {{/TestExtension/the_dut/l_in[26]} -radix unsigned} {{/TestExtension/the_dut/l_in[25]} -radix unsigned} {{/TestExtension/the_dut/l_in[24]} -radix unsigned} {{/TestExtension/the_dut/l_in[23]} -radix unsigned} {{/TestExtension/the_dut/l_in[22]} -radix unsigned} {{/TestExtension/the_dut/l_in[21]} -radix unsigned} {{/TestExtension/the_dut/l_in[20]} -radix unsigned} {{/TestExtension/the_dut/l_in[19]} -radix unsigned} {{/TestExtension/the_dut/l_in[18]} -radix unsigned} {{/TestExtension/the_dut/l_in[17]} -radix unsigned} {{/TestExtension/the_dut/l_in[16]} -radix unsigned} {{/TestExtension/the_dut/l_in[15]} -radix unsigned} {{/TestExtension/the_dut/l_in[14]} -radix unsigned} {{/TestExtension/the_dut/l_in[13]} -radix unsigned} {{/TestExtension/the_dut/l_in[12]} -radix unsigned} {{/TestExtension/the_dut/l_in[11]} -radix unsigned} {{/TestExtension/the_dut/l_in[10]} -radix unsigned} {{/TestExtension/the_dut/l_in[9]} -radix unsigned} {{/TestExtension/the_dut/l_in[8]} -radix unsigned} {{/TestExtension/the_dut/l_in[7]} -radix unsigned} {{/TestExtension/the_dut/l_in[6]} -radix unsigned} {{/TestExtension/the_dut/l_in[5]} -radix unsigned} {{/TestExtension/the_dut/l_in[4]} -radix unsigned} {{/TestExtension/the_dut/l_in[3]} -radix unsigned} {{/TestExtension/the_dut/l_in[2]} -radix unsigned} {{/TestExtension/the_dut/l_in[1]} -radix unsigned} {{/TestExtension/the_dut/l_in[0]} -radix unsigned}} -subitemconfig {{/TestExtension/the_dut/l_in[31]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[30]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[29]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[28]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[27]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[26]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[25]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[24]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[23]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[22]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[21]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[20]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[19]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[18]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[17]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[16]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[15]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[14]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[13]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[12]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[11]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[10]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[9]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[8]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[7]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[6]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[5]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[4]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[3]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[2]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[1]} {-height 27 -radix unsigned} {/TestExtension/the_dut/l_in[0]} {-height 27 -radix unsigned}} /TestExtension/the_dut/l_in
add wave -noupdate -radix unsigned /TestExtension/the_dut/s_in
add wave -noupdate /TestExtension/the_dut/start
add wave -noupdate -radix unsigned /TestExtension/the_dut/state
add wave -noupdate -radix unsigned /TestExtension/the_dut/nxt_state
add wave -noupdate -radix binary /TestExtension/the_dut/a
add wave -noupdate -radix binary /TestExtension/the_dut/dir
add wave -noupdate -radix unsigned /TestExtension/the_dut/k
add wave -noupdate -radix unsigned /TestExtension/the_dut/l
add wave -noupdate -radix unsigned /TestExtension/the_dut/s
add wave -noupdate -radix unsigned /TestExtension/the_dut/sumks
add wave -noupdate -expand -group kls -radix unsigned {/TestExtension/the_dut/k$}
add wave -noupdate -expand -group kls -radix unsigned {/TestExtension/the_dut/l$}
add wave -noupdate -expand -group kls -radix unsigned {/TestExtension/the_dut/s$}
add wave -noupdate -expand -group kls -radix unsigned /TestExtension/the_dut/kT
add wave -noupdate -expand -group kls -radix unsigned /TestExtension/the_dut/lT
add wave -noupdate -expand -group kls -radix unsigned /TestExtension/the_dut/sT
add wave -noupdate -expand -group kls -radix unsigned /TestExtension/the_dut/kG
add wave -noupdate -expand -group kls -radix unsigned /TestExtension/the_dut/lG
add wave -noupdate -expand -group kls -radix unsigned /TestExtension/the_dut/sG
add wave -noupdate -expand -group kls -radix unsigned /TestExtension/the_dut/kC
add wave -noupdate -expand -group kls -radix unsigned /TestExtension/the_dut/lC
add wave -noupdate -expand -group kls -radix unsigned /TestExtension/the_dut/sC
add wave -noupdate -expand -group kls -radix unsigned /TestExtension/the_dut/kA
add wave -noupdate -expand -group kls -radix unsigned /TestExtension/the_dut/lA
add wave -noupdate -expand -group kls -radix unsigned /TestExtension/the_dut/sA
add wave -noupdate -radix unsigned /TestExtension/the_dut/k_out
add wave -noupdate -radix unsigned /TestExtension/the_dut/l_out
add wave -noupdate -radix unsigned /TestExtension/the_dut/s_out
add wave -noupdate /TestExtension/the_dut/finish
add wave -noupdate -radix unsigned {/TestExtension/the_dut/pos$}
add wave -noupdate -radix unsigned /TestExtension/the_dut/acc_cnt
add wave -noupdate -expand -group occ -radix unsigned /TestExtension/the_dut/occ_k
add wave -noupdate -expand -group occ -radix unsigned /TestExtension/the_dut/occ_ks
add wave -noupdate -expand -group occ /TestExtension/the_dut/occ_lookup
add wave -noupdate -expand -group occ -radix unsigned -childformat {{{/TestExtension/the_dut/occ_val_k[0]} -radix unsigned} {{/TestExtension/the_dut/occ_val_k[1]} -radix unsigned} {{/TestExtension/the_dut/occ_val_k[2]} -radix unsigned} {{/TestExtension/the_dut/occ_val_k[3]} -radix unsigned}} -subitemconfig {{/TestExtension/the_dut/occ_val_k[0]} {-height 27 -radix unsigned} {/TestExtension/the_dut/occ_val_k[1]} {-height 27 -radix unsigned} {/TestExtension/the_dut/occ_val_k[2]} {-height 27 -radix unsigned} {/TestExtension/the_dut/occ_val_k[3]} {-height 27 -radix unsigned}} /TestExtension/the_dut/occ_val_k
add wave -noupdate -expand -group occ -radix unsigned -childformat {{{/TestExtension/the_dut/occ_val_ks[0]} -radix unsigned} {{/TestExtension/the_dut/occ_val_ks[1]} -radix unsigned} {{/TestExtension/the_dut/occ_val_ks[2]} -radix unsigned} {{/TestExtension/the_dut/occ_val_ks[3]} -radix unsigned}} -subitemconfig {{/TestExtension/the_dut/occ_val_ks[0]} {-height 27 -radix unsigned} {/TestExtension/the_dut/occ_val_ks[1]} {-height 27 -radix unsigned} {/TestExtension/the_dut/occ_val_ks[2]} {-height 27 -radix unsigned} {/TestExtension/the_dut/occ_val_ks[3]} {-height 27 -radix unsigned}} /TestExtension/the_dut/occ_val_ks
add wave -noupdate -expand -group occ /TestExtension/the_dut/occ_val_valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {225357 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 176
configure wave -valuecolwidth 120
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {1114754 ps}
