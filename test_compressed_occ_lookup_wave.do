onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /TestCompressedOccLookup/clk
add wave -noupdate /TestCompressedOccLookup/rst
add wave -noupdate /TestCompressedOccLookup/k
add wave -noupdate /TestCompressedOccLookup/ks
add wave -noupdate /TestCompressedOccLookup/start
add wave -noupdate /TestCompressedOccLookup/valid
add wave -noupdate /TestCompressedOccLookup/val_k
add wave -noupdate /TestCompressedOccLookup/val_ks
add wave -noupdate /TestCompressedOccLookup/kandks
add wave -noupdate -divider axi4l
add wave -noupdate /TestCompressedOccLookup/axi/araddr
add wave -noupdate /TestCompressedOccLookup/axi/arprot
add wave -noupdate /TestCompressedOccLookup/axi/arvalid
add wave -noupdate /TestCompressedOccLookup/axi/arready
add wave -noupdate /TestCompressedOccLookup/axi/rdata
add wave -noupdate /TestCompressedOccLookup/axi/rresp
add wave -noupdate /TestCompressedOccLookup/axi/rvalid
add wave -noupdate /TestCompressedOccLookup/axi/rready
add wave -noupdate -group OccLookup /TestCompressedOccLookup/theDUT/start
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/status
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/nxt_sts
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/k_in
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/ks_in
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/cob_idx_k
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/cob_idx_ks
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/sym_off_k
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/sym_off_ks
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/val_k
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/val_ks
add wave -noupdate -group OccLookup /TestCompressedOccLookup/theDUT/val_valid
add wave -noupdate -group OccLookup /TestCompressedOccLookup/theDUT/dec_start
add wave -noupdate -group OccLookup /TestCompressedOccLookup/theDUT/dec_finish
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/dec_val
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/dec_i
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/dec_cob
add wave -noupdate -group OccLookup -radix unsigned /TestCompressedOccLookup/theDUT/sto_cob
add wave -noupdate -expand -group Decompr /TestCompressedOccLookup/theDUT/occDecompr/occ_block
add wave -noupdate -expand -group Decompr /TestCompressedOccLookup/theDUT/occDecompr/i
add wave -noupdate -expand -group Decompr /TestCompressedOccLookup/theDUT/occDecompr/start
add wave -noupdate -expand -group Decompr /TestCompressedOccLookup/theDUT/occDecompr/val
add wave -noupdate -expand -group Decompr /TestCompressedOccLookup/theDUT/occDecompr/finish
add wave -noupdate -expand -group Decompr /TestCompressedOccLookup/theDUT/occDecompr/busy
add wave -noupdate -expand -group Decompr -childformat {{/TestCompressedOccLookup/theDUT/occDecompr/ob.OccT -radix unsigned} {/TestCompressedOccLookup/theDUT/occDecompr/ob.OccG -radix unsigned} {/TestCompressedOccLookup/theDUT/occDecompr/ob.OccC -radix unsigned} {/TestCompressedOccLookup/theDUT/occDecompr/ob.OccA -radix unsigned}} -expand -subitemconfig {/TestCompressedOccLookup/theDUT/occDecompr/ob.OccT {-radix unsigned} /TestCompressedOccLookup/theDUT/occDecompr/ob.OccG {-radix unsigned} /TestCompressedOccLookup/theDUT/occDecompr/ob.OccC {-radix unsigned} /TestCompressedOccLookup/theDUT/occDecompr/ob.OccA {-radix unsigned}} /TestCompressedOccLookup/theDUT/occDecompr/ob
add wave -noupdate -expand -group Decompr /TestCompressedOccLookup/theDUT/occDecompr/syms
add wave -noupdate -expand -group Decompr /TestCompressedOccLookup/theDUT/occDecompr/cnt
add wave -noupdate -expand -group Decompr /TestCompressedOccLookup/theDUT/occDecompr/counting
add wave -noupdate -expand -group Decompr /TestCompressedOccLookup/theDUT/occDecompr/occ
add wave -noupdate -divider fileROM
add wave -noupdate /TestCompressedOccLookup/theROM/fd
add wave -noupdate /TestCompressedOccLookup/theROM/code
add wave -noupdate /TestCompressedOccLookup/theROM/clk
add wave -noupdate /TestCompressedOccLookup/theROM/rst
add wave -noupdate /TestCompressedOccLookup/theROM/rnd
add wave -noupdate /TestCompressedOccLookup/theROM/seed1
add wave -noupdate /TestCompressedOccLookup/theROM/seed2
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {173222 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ps} {543016 ps}
