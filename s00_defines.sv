// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180730

`ifndef __DEFINES_SV__
`define __DEFINES_SV__

`define SIM_OCC_LOOKUP

package BwaMemDefines;

    typedef logic [2:0] Symbol;
    parameter Symbol sym_N      = 3'b000;
    parameter Symbol sym_$      = 3'b001;
    parameter Symbol sym_A 		= 3'b100;
    parameter Symbol sym_C 		= 3'b101;
    parameter Symbol sym_G 		= 3'b110;
    parameter Symbol sym_T 		= 3'b111;

    function automatic Symbol Compl(input Symbol s);
        Compl = {s[2], ~s[1:0]};
    endfunction

    // // 3-bit Symbol, used only in compressed Occ table and it's decompress
    // typedef logic [2:0] Sym3b;
    // parameter Sym3b sym3b_$       = 3'b000;
    // parameter Sym3b sym3b_A       = 3'b100;
    // parameter Sym3b sym3b_C       = 3'b101;
    // parameter Sym3b sym3b_G       = 3'b110;
    // parameter Sym3b sym3b_T       = 3'b111;
    // parameter Sym3b sym3b_N       = 3'b001;

    // function automatic Symbol Sym3to4(input Sym3b in);
    //     Sym3to4 = {1'b0, in};
    // endfunction

    // function automatic Sym3b Sym4to3(input Symbol in);
    //     Sym4to3 = in[2:0];
    // endfunction

    // extension direction
	parameter logic DirForward	= 1'b0;
	parameter logic DirBackward	= 1'b1;

    // working DW of k, l and s, 2^KLS_W = Max BWT Length
    // don't change this unless you are preparing to review all source code.
    parameter integer KLS_W = 40;

    // 2 * POS_W = n * 8, n = 1, 2, ...
    // POS_W >= Ceiling(Log2(READ_LEN + 3))
    parameter integer POS_W = 16;

    // width of read id
    parameter integer RID_W = 32;

    // 2^BIDIREX_QU_AW - 1 = Capacity of working queue in BiDirEmSeek
    // 2^RESEED_QU_AW = Capacity of reseed queue in ReadMemReseed
    // these 2 params:
    //  * too small may cause queue overflow (it's fatal error!)
    //  * too large ..., make sure you have enough block memory
    //  * Carefully choose their values
    parameter integer BIDIREX_QU_AW = 8; // at least $clog2(read_length), but may not be necessary
    parameter integer RESEED_QU_AW = 6;  // could be smaller than BEX_QU_AW

    // 2^SEEDOUT_QU_AW = Capacity of output queue of each processing block
    // too small will enlarge the probability of backpressure.
    parameter integer SEEDOUT_QU_AW = 8;

    // used in filters which filter mems to seeds
    // can be OVERRIDED in Read2Seeds instantiation.
    // when set to 2, seeds output will cover 95% of effective seeds in ref. result,
    // but generate average 12.4 seeds for each read (more redundant seeds).
    // when set to 1, seeds output will cover 80% of effective seeds in ref. result,
    // and generate average 6.1 seeds for each read (more efficient)
    parameter integer FILTER_GRP_SIZE = 2;

    // block of compressed Occ table
    typedef struct packed {
        logic [31:0][2:0] BwtSlice; //  32 * 3 = 96bit
        logic [39 : 0] OccT;        //  40 * 4 = 160bit
        logic [39 : 0] OccG;        // total: 256bit
        logic [39 : 0] OccC;
        logic [39 : 0] OccA;
    } OccBlock;

    typedef struct packed {
        logic [POS_W - 1 : 0]   j;  // tail position in guarded read
        logic [POS_W - 1 : 0]   i;  // head position in guarded read
        logic [KLS_W - 1 : 0]   s;  // interval
        logic [KLS_W - 1 : 0]   l;  // lower boundary of the reversed complementary
        logic [KLS_W - 1 : 0]   k;  // lower boundary of the original
    } WorkingMem;

    typedef struct packed {
        logic [POS_W - 1 : 0]   j;  // tail position in guarded read
        logic [POS_W - 1 : 0]   i;  // head position in guarded read
        logic [KLS_W - 1 : 0]   s;  // interval
    } ReseedMem;

    // size of AssemMem must be integer number of bytes
    typedef struct packed {
        logic [POS_W - 1 : 0]  j;  // tail position + 1 in read
        logic [POS_W - 1 : 0]  i;  // head position in read
        logic [KLS_W - 1 : 0]  s;  // interval will be saturate to [0,255]
        logic [KLS_W - 1 : 0]  l;  // lower boundary of the reversed complementary
        logic [KLS_W - 1 : 0]  k;  // lower boundary of the original
        logic [RID_W - 1 : 0]  id;
    } AssemMem;

    // parameter ASMMEM_W = $bits(AssemMem);
    // $bits is not supported by vivado ip packager -_-#
    parameter ASMMEM_W = 2*POS_W + 3*KLS_W + RID_W;
endpackage

interface Axi4StreamIf #(
    parameter DW_BYTES = 4
)(
    input wire clk, reset_n
);
    localparam DW = DW_BYTES * 8;
    logic [DW - 1 : 0] tdata;
    logic tvalid = '0, tready, tlast;
    logic [DW_BYTES - 1 : 0] tstrb, tkeep;

    modport master(
        input   clk, reset_n, tready,
        output  tdata, tvalid, tlast, tstrb, tkeep
    );
    modport slave(
        input   clk, reset_n, tdata, tvalid, tlast,
                tstrb, tkeep,
        output  tready
    );
    // task static Put(logic [31:0] data, logic last);
    // begin
    //     tdata <= data; tlast <= last;
    //     tvalid <= '1;
    //     do @(posedge clk);
    //     while(~tready);
    //     tvalid <= '0;
    // end
    // endtask
    // task static Get();
    // begin
    //     tready <= '1;
    //     do @(posedge clk);
    //     while(~tvalid);
    //     tready <= '0;
    // end
    // endtask
endinterface

interface Axi4LiteIf #( parameter AW = 32, DW = 32)(
    input wire clk, reset_n
);
    logic [AW-1:0] awaddr;
    logic [2:0] awprot;
    logic awvalid, awready;
    logic [DW-1:0] wdata;
    logic [DW/8-1:0] wstrb;
    logic wvalid, wready;
    logic [1:0] bresp;
    logic bvalid, bready;
    logic [AW-1:0] araddr;
    logic [2:0] arprot;
    logic arvalid, arready;
    logic [DW-1:0] rdata;
    logic [1:0] rresp;
    logic rvalid, rready;
    modport master(
        input clk, reset_n,
        output awaddr, awprot, awvalid, input awready,
        output wdata, wstrb, wvalid, input wready,
        input bresp, bvalid, output bready,
        output araddr, arprot, arvalid, input arready,
        input rdata, rresp, rvalid, output rready
    );
    modport slave(
        input clk, reset_n,
        input awaddr, awprot, awvalid, output awready,
        input wdata, wstrb, wvalid, output wready,
        output bresp, bvalid, input bready,
        input araddr, arprot, arvalid, output arready,
        output rdata, rresp, rvalid, input rready
    );
//    task Write(
//        input logic [AW-1:0] addr, logic [31:0] data,
//        logic [31:0] strb = '1, logic [2:0] prot = '0
//    );
//        @(posedge clk) begin
//            awaddr = addr; awprot = prot; awvalid = '1;
//            wdata = data; wstrb = strb; wvalid = '1;
//            bready = '1;
//        end
//        fork
//            wait(awready) @(posedge clk) awvalid = '0;
//            wait(wready) @(posedge clk) wvalid = '0;
//            wait(bvalid) @(posedge clk) bready = '0;
//        join
//    endtask
//    task Read(
//        input logic [AW-1:0] addr, output logic [31:0] data,
//        input logic [3:0] prot = '0
//    );
//        @(posedge clk) begin
//            araddr = addr; arprot = prot; arvalid = '1;
//            rready = '1;
//        end
//        wait(arready) @(posedge clk) arvalid = '0;
//        wait(rvalid) @(posedge clk) begin
//            rready = '0;
//            data = rdata;
//        end
//    endtask
endinterface

`endif
