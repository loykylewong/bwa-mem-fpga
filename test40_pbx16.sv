// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180814

`timescale 1ns/1ps
`default_nettype none

`include "../common.sv"
`include "./s00_defines.sv"

module PBx16 // just for simulation, this kind of "Process block" is intended be implemented in vivado ipi
    import BwaMemDefines::*;
#(
    parameter RLEN = 76,    // read length in symbols
    localparam RDW = RLEN * 4 + RID_W
)(
    input wire clk, rst,

    input  wire [RDW - 1 : 0] ri_data,   // {id[32], read[...]}
    input  wire               ri_valid,
    output wire               ri_ready,

    output wire [$bits(AssemMem) - 1 : 0] so_data,
    output wire                           so_last,
    output wire                           so_valid,
    input  wire                           so_ready,

    input wire [KLS_W-1:0] acc_cnt[4],
    input wire [KLS_W-1:0] pri_pos,
    input wire [KLS_W-1:0] bwt_len,
    input wire [POS_W-1:0] min_mlen,
    input wire [POS_W-1:0] sf_mlen,
    input wire [KLS_W-1:0] sf_max_intv,
    input wire [POS_W-1:0] rs_min_mlen,
    input wire [KLS_W-1:0] rs_max_intv,
    input wire             param_update

);
    
    wire [RDW - 1 : 0] read_data [16];
    wire               read_valid[16];
    wire               read_ready[16];

    wire [$bits(AssemMem) - 1 : 0] seed_data [16];
    wire                           seed_last [16];
    wire                           seed_valid[16];
    wire                           seed_ready[16];
    wire [SEEDOUT_QU_AW : 0]       seed_fifodc[16];

    // wire [$bits(AssemMem) - 1 : 0] sbuf_data [16];
    // wire                           sbuf_last [16];
    // wire                           sbuf_valid[16];
    // wire                           sbuf_ready[16];
    // wire [PBOUT_QU_AW : 0]         sbuf_data_cnt[16];

    wire [39 : 0] axi_araddr [16];
    wire [2  : 0] axi_arprot [16];
    wire          axi_arvalid[16];
    wire          axi_arready[16];
    wire [255 : 0] axi_rdata [16];
    wire [  1 : 0] axi_rresp [16];
    wire           axi_rvalid[16];
    wire           axi_rready[16];

    Axi4LiteIf #(.AW(40), .DW(256)) axi[16](.clk(clk), .reset_n(~rst));

    ReadDispatch #(.CH(16), .DW(RDW)) readDisp (
        .clk     (clk),
        .rst     (rst),
        .ri_data (ri_data),
        .ri_valid(ri_valid),
        .ri_ready(ri_ready),
        .ro_data (read_data),
        .ro_valid(read_valid),
        .ro_ready(read_ready)
    );

    genvar ch;
    generate
        for(ch = 0; ch < 16; ch++) begin : read2Seed_array
            Read2Seed #(
                .READ_LEN       (RLEN),
                .OCCMEM_AW      (40),
                .FILTER_GRP_SIZE(FILTER_GRP_SIZE),
                .OCC_BASE       (40'h00_0000_0000),
                .BIDIREX_QU_AW  (BIDIREX_QU_AW),
                .RESEED_QU_AW   (RESEED_QU_AW),
                .SEEDOUT_QU_AW  (SEEDOUT_QU_AW)
            ) read2Seed (
                .clk          (clk),
                .rst          (rst),
                .s_axis_tdata (read_data [ch]),
                .s_axis_tvalid(read_valid[ch]),
                .s_axis_tready(read_ready[ch]),
                .m_axis_tdata (seed_data [ch]),
                .m_axis_tlast (seed_last [ch]),
                .m_axis_tvalid(seed_valid[ch]),
                .m_axis_tready(seed_ready[ch]),
                .m_axis_tuser (seed_fifodc[ch]),
                // .m_axi_awaddr (),
                // .m_axi_awprot (),
                // .m_axi_awvalid(),
                // .m_axi_awready(1'b1),
                // .m_axi_wdata  (),
                // .m_axi_wstrb  (),
                // .m_axi_wvalid (),
                // .m_axi_wready (1'b1),
                // .m_axi_bresp  (2'b00),
                // .m_axi_bvalid (1'b0),
                // .m_axi_bready (),
                .m_axi_araddr (axi[ch].araddr ),
                .m_axi_arprot (axi[ch].arprot ),
                .m_axi_arvalid(axi[ch].arvalid),
                .m_axi_arready(axi[ch].arready),
                .m_axi_arburst(),
                .m_axi_arlen  (),
                .m_axi_arsize (),
                .m_axi_arid   (),
                .m_axi_arcache(),
                .m_axi_arlock (),
                .m_axi_arqos  (),
                .m_axi_rdata  (axi[ch].rdata ),
                .m_axi_rresp  (axi[ch].rresp ),
                .m_axi_rvalid (axi[ch].rvalid),
                .m_axi_rready (axi[ch].rready),
                .m_axi_rid    (),
                .m_axi_rlast  (),
                .acc_cnt_A    (acc_cnt[0]),
                .acc_cnt_C    (acc_cnt[1]),
                .acc_cnt_G    (acc_cnt[2]),
                .acc_cnt_T    (acc_cnt[3]),
                .pri_pos      (pri_pos),
                .bwt_len      (bwt_len),
                .min_mlen     (min_mlen),
                .sf_mlen      (sf_mlen),
                .sf_max_intv  (sf_max_intv),
                .rs_min_mlen  (rs_min_mlen),
                .rs_max_intv  (rs_max_intv),
                .param_update (param_update)
            );
        end
        // for(ch = 0; ch < 16; ch++) begin : streamFifo_array
        //     StreamFifo #(.DW($bits(AssemMem) + 1), .AW(PBOUT_QU_AW)) seedoutFifo (
        //         .clk      (clk),
        //         .rst      (rst),
        //         .in_data  ({seed_last[ch], seed_data[ch]}),
        //         .in_valid (seed_valid[ch]),
        //         .in_ready (seed_ready[ch]),
        //         .out_data ({sbuf_last[ch], sbuf_data[ch]}),
        //         .out_valid(sbuf_valid[ch]),
        //         .out_ready(sbuf_ready[ch]),
        //         .data_cnt (sbuf_data_cnt[ch])
        //     );
        // end
        for(ch = 0; ch < 16; ch++) begin : memories
            FileROM #(.BASE_ADDR(64'd0), .MEAN_LATENCY(96))
            theROM
            (
                .s_axi4l(axi[ch].slave)
            );
        end // memories
    endgenerate

    SeedCollectRR #(.CH(16), .DW($bits(AssemMem))/*, .DCW(SEEDOUT_QU_AW+1)*/) seedCollector(
        .clk        (clk),
        .rst        (rst),
        // .si_data    (sbuf_data),
        // .si_last    (sbuf_last),
        // .si_valid   (sbuf_valid),
        // .si_ready   (sbuf_ready),
        // .si_data_cnt(sbuf_data_cnt),
        .si_data    (seed_data),
        .si_last    (seed_last),
        .si_valid   (seed_valid),
        .si_ready   (seed_ready),
        // .si_data_cnt(seed_fifodc),
        .so_data    (so_data),
        .so_last    (so_last),
        .so_valid   (so_valid),
        .so_ready   (so_ready)
    );

endmodule

module TestPBx16;   // process block (16 x readmem unit)

    import SimSrcGen::*;
    import BwaMemDefines::*;

    parameter RLEN = 76;
    parameter RDW = RLEN * 4 + RID_W;

    logic clk, rst;
    initial GenClk(clk, 2, 4);
    initial GenRst(clk, rst, 2, 2);

    function automatic logic [RDW - 1 : 0] read2bits(/*byte str[RLEN]*/string str, logic [31:0] id);
        for(integer i = 0; i < RLEN; i++) begin
            case(str[i])
            8'h41:      read2bits[i * 4 +: 4] = {1'b0, sym_A};
            8'h43:      read2bits[i * 4 +: 4] = {1'b0, sym_C};
            8'h47:      read2bits[i * 4 +: 4] = {1'b0, sym_G};
            8'h54:      read2bits[i * 4 +: 4] = {1'b0, sym_T};
            default:    read2bits[i * 4 +: 4] = {1'b0, sym_N};
            endcase
        end
        read2bits[RLEN * 4 +: RID_W] = id;
    endfunction

    logic [KLS_W-1:0] acc_cnt[0:3];
    logic [KLS_W-1:0] pri_pos;
    logic [KLS_W-1:0] bwt_len;
    logic [POS_W-1:0] min_mlen = 19;
    logic [POS_W-1:0] sf_mlen = 20;
    logic [KLS_W-1:0] sf_max_intv = 20;
    logic [POS_W-1:0] rs_min_mlen = 28;
    logic [KLS_W-1:0] rs_max_intv = 10;
    logic param_update;

    logic [RDW - 1 : 0] read_data; 
    logic               read_valid;
    wire                read_ready;

    integer c_file, fd, code;
    string str;//[RLEN];
    initial begin
        c_file = $fopen("./data/hs37d5_cocc.bin.txt", "r");
        code = $fscanf(c_file, "%d\n", acc_cnt[0]);
        code = $fscanf(c_file, "%d\n", acc_cnt[1]);
        code = $fscanf(c_file, "%d\n", acc_cnt[2]);
        code = $fscanf(c_file, "%d\n", acc_cnt[3]);
        code = $fscanf(c_file, "%d\n", bwt_len);
        code = $fscanf(c_file, "%d\n", pri_pos);
        $fclose(c_file);

        do @(posedge clk);
        while(~rst);
        do @(posedge clk);
        while(rst);

        @(posedge clk) param_update <= 1'b1;
        @(posedge clk) param_update <= 1'b0;

        fd = $fopen("./data/161_read.fastq", "r");
        for(integer i = 0; i < 1000; i++) begin
            code = $fgets(str, fd);
            @(posedge clk) begin
                read_data <= read2bits(str, i);
                read_valid <= 1'b1;
            end
            do @(posedge clk);
            while(!(read_valid & read_ready));
            read_valid = 1'b0;
        end
        do @(posedge clk); while(pbx16.seedCollector.siv != 0);
        repeat(1000) @(posedge clk);
        $stop();
    end

    integer seed = 123321;
    integer rnd;
    always_ff @(posedge clk) begin : proc_rnd
        if(rst) begin
            rnd <= 0;
        end else begin
            rnd <= $random(seed);
        end
    end

    wire seed_ready = rnd[1:0] == 2'b00;//1'b1;
    wire [$bits(AssemMem)-1:0] seed_data;
    wire AssemMem seed_out = seed_data;
    wire seed_last, seed_valid;

    integer fout;
    initial begin
        $timeformat(-6, 6, "us", 12);
        fout = $fopen("./simdata/pbx16_out.txt", "w");
        $fdisplay(fout, "   ID   Start   End      64-bit S-E      k          l      intv     @time");
    end
    string outstr;
    always_ff @(posedge clk) begin : proc_wf
        if(seed_valid & seed_ready) begin
            outstr = $sformatf("id-%04d %5d %5d %15d %10d %10d %5d @%t",
                seed_out.id, seed_out.i, seed_out.j,
                (64'(seed_out.i) << 32) | seed_out.j,
                seed_out.k, seed_out.l, seed_out.s, $realtime());
            $fdisplay(fout, outstr);
            $display(outstr);
        end
    end

    genvar i;
    generate
        for(i = 0; i < 16; i++) begin : qumon_array
            always_ff @(posedge clk) begin : proc_qumon
                if(pbx16.read2Seed_array[i].read2Seed.theReadMem.the_bex.fifo_data_cnt >= 2**(BIDIREX_QU_AW-1)) begin
                    $display("Bex qu exceed half: %d, in CH: %d.",
                        pbx16.read2Seed_array[i].read2Seed.theReadMem.the_bex.fifo_data_cnt, i);
                end
                if(pbx16.read2Seed_array[i].read2Seed.theReadMem.fifo_data_cnt >= 2**(RESEED_QU_AW-1)) begin
                    $display("Reseed qu exceed half: %d, in CH: %d.",
                        pbx16.read2Seed_array[i].read2Seed.theReadMem.fifo_data_cnt, i);
                end
            end
        end
    endgenerate

    PBx16 #(.RLEN(76)) pbx16 (
        .clk         (clk),
        .rst         (rst),
        .ri_data     (read_data),
        .ri_valid    (read_valid),
        .ri_ready    (read_ready),
        .so_data     (seed_data),
        .so_last     (seed_last),
        .so_valid    (seed_valid),
        .so_ready    (seed_ready),
        .acc_cnt     (acc_cnt),
        .pri_pos     (pri_pos),
        .bwt_len     (bwt_len),
        .min_mlen    (min_mlen),
        .sf_mlen     (sf_mlen),
        .sf_max_intv (sf_max_intv),
        .rs_min_mlen (rs_min_mlen),
        .rs_max_intv (rs_max_intv),
        .param_update(param_update)
    );

endmodule // TestPBx16
