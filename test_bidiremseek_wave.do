onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /TestBiDirEmSeek3/clk
add wave -noupdate /TestBiDirEmSeek3/rst
add wave -noupdate -radix unsigned -childformat {{{/TestBiDirEmSeek3/acc_cnt[0]} -radix unsigned -childformat {{{/TestBiDirEmSeek3/acc_cnt[0][39]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][38]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][37]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][36]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][35]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][34]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][33]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][32]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][31]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][30]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][29]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][28]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][27]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][26]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][25]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][24]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][23]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][22]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][21]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][20]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][19]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][18]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][17]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][16]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][15]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][14]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][13]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][12]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][11]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][10]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][9]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][8]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][7]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][6]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][5]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][4]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][3]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][2]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][1]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][0]} -radix unsigned}}} {{/TestBiDirEmSeek3/acc_cnt[1]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[2]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[3]} -radix unsigned}} -subitemconfig {{/TestBiDirEmSeek3/acc_cnt[0]} {-height 27 -radix unsigned -childformat {{{/TestBiDirEmSeek3/acc_cnt[0][39]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][38]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][37]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][36]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][35]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][34]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][33]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][32]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][31]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][30]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][29]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][28]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][27]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][26]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][25]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][24]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][23]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][22]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][21]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][20]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][19]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][18]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][17]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][16]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][15]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][14]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][13]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][12]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][11]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][10]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][9]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][8]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][7]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][6]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][5]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][4]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][3]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][2]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][1]} -radix unsigned} {{/TestBiDirEmSeek3/acc_cnt[0][0]} -radix unsigned}}} {/TestBiDirEmSeek3/acc_cnt[0][39]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][38]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][37]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][36]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][35]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][34]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][33]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][32]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][31]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][30]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][29]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][28]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][27]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][26]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][25]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][24]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][23]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][22]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][21]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][20]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][19]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][18]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][17]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][16]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][15]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][14]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][13]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][12]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][11]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][10]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][9]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][8]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][7]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][6]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][5]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][4]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][3]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][2]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][1]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[0][0]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[1]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[2]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/acc_cnt[3]} {-height 27 -radix unsigned}} /TestBiDirEmSeek3/acc_cnt
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/bwt_len
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/pNxt
add wave -noupdate /TestBiDirEmSeek3/emout_handsk
add wave -noupdate -childformat {{/TestBiDirEmSeek3/emout.j -radix unsigned} {/TestBiDirEmSeek3/emout.i -radix unsigned} {/TestBiDirEmSeek3/emout.s -radix unsigned} {/TestBiDirEmSeek3/emout.l -radix unsigned} {/TestBiDirEmSeek3/emout.k -radix unsigned}} -expand -subitemconfig {/TestBiDirEmSeek3/emout.j {-height 27 -radix unsigned} /TestBiDirEmSeek3/emout.i {-height 27 -radix unsigned} /TestBiDirEmSeek3/emout.s {-height 27 -radix unsigned} /TestBiDirEmSeek3/emout.l {-height 27 -radix unsigned} /TestBiDirEmSeek3/emout.k {-height 27 -radix unsigned}} /TestBiDirEmSeek3/emout
add wave -noupdate -divider DUT
add wave -noupdate -radix binary /TestBiDirEmSeek3/the_dut/gd_read
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/pos_in
add wave -noupdate /TestBiDirEmSeek3/the_dut/start
add wave -noupdate /TestBiDirEmSeek3/the_dut/busy
add wave -noupdate /TestBiDirEmSeek3/the_dut/finish
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/pos_out
add wave -noupdate -radix unsigned -childformat {{{/TestBiDirEmSeek3/the_dut/state[4]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/state[3]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/state[2]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/state[1]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/state[0]} -radix unsigned}} -subitemconfig {{/TestBiDirEmSeek3/the_dut/state[4]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/state[3]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/state[2]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/state[1]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/state[0]} {-height 27 -radix unsigned}} /TestBiDirEmSeek3/the_dut/state
add wave -noupdate -radix unsigned -childformat {{{/TestBiDirEmSeek3/the_dut/nxt_state[4]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/nxt_state[3]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/nxt_state[2]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/nxt_state[1]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/nxt_state[0]} -radix unsigned}} -subitemconfig {{/TestBiDirEmSeek3/the_dut/nxt_state[4]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/nxt_state[3]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/nxt_state[2]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/nxt_state[1]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/nxt_state[0]} {-height 27 -radix unsigned}} /TestBiDirEmSeek3/the_dut/nxt_state
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/i1
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/j1
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/i0
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/j0
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/k0
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/l0
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/s0
add wave -noupdate -radix binary /TestBiDirEmSeek3/the_dut/ex_a
add wave -noupdate /TestBiDirEmSeek3/the_dut/dir
add wave -noupdate /TestBiDirEmSeek3/the_dut/ex_start
add wave -noupdate /TestBiDirEmSeek3/the_dut/ex_finish
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/k1
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/l1
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/s1
add wave -noupdate /TestBiDirEmSeek3/the_dut/fifo_din
add wave -noupdate /TestBiDirEmSeek3/the_dut/fifo_wr
add wave -noupdate /TestBiDirEmSeek3/the_dut/fifo_empty
add wave -noupdate /TestBiDirEmSeek3/the_dut/fifo_rd
add wave -noupdate -expand -group fifo_qout -radix unsigned /TestBiDirEmSeek3/the_dut/fifo_k
add wave -noupdate -expand -group fifo_qout -radix unsigned /TestBiDirEmSeek3/the_dut/fifo_l
add wave -noupdate -expand -group fifo_qout -radix unsigned /TestBiDirEmSeek3/the_dut/fifo_s
add wave -noupdate -expand -group fifo_qout -radix unsigned /TestBiDirEmSeek3/the_dut/fifo_i
add wave -noupdate -expand -group fifo_qout -radix unsigned /TestBiDirEmSeek3/the_dut/fifo_j
add wave -noupdate /TestBiDirEmSeek3/the_dut/need_out
add wave -noupdate -divider EX
add wave -noupdate -group ex_in -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/k_in
add wave -noupdate -group ex_in -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/l_in
add wave -noupdate -group ex_in -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/s_in
add wave -noupdate -group ex_in /TestBiDirEmSeek3/the_dut/the_ex/a_in
add wave -noupdate -group ex_in /TestBiDirEmSeek3/the_dut/the_ex/dir_in
add wave -noupdate /TestBiDirEmSeek3/the_dut/the_ex/start
add wave -noupdate /TestBiDirEmSeek3/the_dut/the_ex/busy
add wave -noupdate /TestBiDirEmSeek3/the_dut/the_ex/finish
add wave -noupdate -group ex_out -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/k_out
add wave -noupdate -group ex_out -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/l_out
add wave -noupdate -group ex_out -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/s_out
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/state
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/nxt_state
add wave -noupdate /TestBiDirEmSeek3/the_dut/the_ex/dir
add wave -noupdate /TestBiDirEmSeek3/the_dut/the_ex/a
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/k
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/l
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/s
add wave -noupdate -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/sumks
add wave -noupdate -group occ -radix decimal /TestBiDirEmSeek3/the_dut/the_ex/occ_k
add wave -noupdate -group occ -radix decimal /TestBiDirEmSeek3/the_dut/the_ex/occ_ks
add wave -noupdate -group occ /TestBiDirEmSeek3/the_dut/the_ex/occ_lookup
add wave -noupdate -group occ -radix hexadecimal -childformat {{{/TestBiDirEmSeek3/the_dut/the_ex/occ_val_k[0]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/the_ex/occ_val_k[1]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/the_ex/occ_val_k[2]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/the_ex/occ_val_k[3]} -radix unsigned}} -subitemconfig {{/TestBiDirEmSeek3/the_dut/the_ex/occ_val_k[0]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/the_ex/occ_val_k[1]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/the_ex/occ_val_k[2]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/the_ex/occ_val_k[3]} {-height 27 -radix unsigned}} /TestBiDirEmSeek3/the_dut/the_ex/occ_val_k
add wave -noupdate -group occ -radix hexadecimal -childformat {{{/TestBiDirEmSeek3/the_dut/the_ex/occ_val_ks[0]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/the_ex/occ_val_ks[1]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/the_ex/occ_val_ks[2]} -radix unsigned} {{/TestBiDirEmSeek3/the_dut/the_ex/occ_val_ks[3]} -radix unsigned}} -subitemconfig {{/TestBiDirEmSeek3/the_dut/the_ex/occ_val_ks[0]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/the_ex/occ_val_ks[1]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/the_ex/occ_val_ks[2]} {-height 27 -radix unsigned} {/TestBiDirEmSeek3/the_dut/the_ex/occ_val_ks[3]} {-height 27 -radix unsigned}} /TestBiDirEmSeek3/the_dut/the_ex/occ_val_ks
add wave -noupdate -group occ /TestBiDirEmSeek3/the_dut/the_ex/occ_val_valid
add wave -noupdate -group {acgt$_calc} -radix unsigned {/TestBiDirEmSeek3/the_dut/the_ex/k$}
add wave -noupdate -group {acgt$_calc} -radix unsigned {/TestBiDirEmSeek3/the_dut/the_ex/l$}
add wave -noupdate -group {acgt$_calc} -radix unsigned {/TestBiDirEmSeek3/the_dut/the_ex/s$}
add wave -noupdate -group {acgt$_calc} -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/kT
add wave -noupdate -group {acgt$_calc} -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/lT
add wave -noupdate -group {acgt$_calc} -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/sT
add wave -noupdate -group {acgt$_calc} -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/kG
add wave -noupdate -group {acgt$_calc} -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/lG
add wave -noupdate -group {acgt$_calc} -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/sG
add wave -noupdate -group {acgt$_calc} -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/kC
add wave -noupdate -group {acgt$_calc} -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/lC
add wave -noupdate -group {acgt$_calc} -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/sC
add wave -noupdate -group {acgt$_calc} -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/kA
add wave -noupdate -group {acgt$_calc} -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/lA
add wave -noupdate -group {acgt$_calc} -radix unsigned /TestBiDirEmSeek3/the_dut/the_ex/sA
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {9999886719 ps} 0} {{Cursor 2} {448913000 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 221
configure wave -valuecolwidth 169
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
WaveRestoreZoom {0 ps} {471400650 ps}
