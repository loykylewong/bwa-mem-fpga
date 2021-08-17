// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180828

`timescale 1ns/1ps
`default_nettype none

`include "../common.sv"
`include "./s00_defines.sv"

module TestSynthPBx16;   // process block (16 x readmem unit)

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
        do @(posedge clk); while(the_dut.pbx16.seedCollector.siv != 0);
        repeat(100000) @(posedge clk);
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

    wire seed_ready = rnd[0];//rnd[1:0] == 2'b00;//1'b1;
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
                if(the_dut.pbx16.read2Seed_array[i].read2Seed.theReadMem.the_bex.fifo_data_cnt >= 2**(BIDIREX_QU_AW-1)) begin
                    $display("Bex qu exceed half: %d, in CH: %d.",
                        the_dut.pbx16.read2Seed_array[i].read2Seed.theReadMem.the_bex.fifo_data_cnt, i);
                end
                if(the_dut.pbx16.read2Seed_array[i].read2Seed.theReadMem.fifo_data_cnt >= 2**(RESEED_QU_AW-1)) begin
                    $display("Reseed qu exceed half: %d, in CH: %d.",
                        the_dut.pbx16.read2Seed_array[i].read2Seed.theReadMem.fifo_data_cnt, i);
                end
            end
        end
    endgenerate

    Axi4LiteIf #(.AW(40), .DW(256)) axi[16](.clk(clk), .reset_n(~rst));

    ProcessBlockX16Wrapper #(
        .READ_LEN       (RLEN),
        .OCCMEM_AW      (40),
        .OCC_BASE       (40'h00_0000_0000),
        .FILTER_GRP_SIZE(1),
        .BIDIREX_QU_AW  (8),
        .RESEED_QU_AW   (6),
        .SEEDOUT_QU_AW  (8)
    ) the_dut (
        .clk            (clk),
        .rst_n          (~rst),
        .s_axis_tdata   (read_data),
        .s_axis_tvalid  (read_valid),
        .s_axis_tready  (read_ready),
        .m_axis_tdata    (seed_data),
        .m_axis_tlast    (seed_last),
        .m_axis_tvalid   (seed_valid),
        .m_axis_tready   (seed_ready),
        .acc_cnt_A      (acc_cnt[0]),
        .acc_cnt_C      (acc_cnt[1]),
        .acc_cnt_G      (acc_cnt[2]),
        .acc_cnt_T      (acc_cnt[3]),
        .pri_pos        (pri_pos),
        .bwt_len        (bwt_len),
        .min_mlen       (min_mlen),
        .sf_mlen        (sf_mlen),
        .sf_max_intv    (sf_max_intv),
        .rs_min_mlen    (rs_min_mlen),
        .rs_max_intv    (rs_max_intv),
        .param_update   (param_update),

        .m00_axi_araddr (axi[00].araddr ),
        .m00_axi_arprot (axi[00].arprot ),
        .m00_axi_arvalid(axi[00].arvalid),
        .m00_axi_arready(axi[00].arready),
        .m00_axi_arburst(             ),
        .m00_axi_arlen  (             ),
        .m00_axi_arsize (             ),
        .m00_axi_arid   (             ),
        .m00_axi_arcache(             ),
        .m00_axi_arlock (             ),
        .m00_axi_arqos  (             ),
        .m00_axi_rdata  (axi[00].rdata  ),
        .m00_axi_rresp  (axi[00].rresp  ),
        .m00_axi_rvalid (axi[00].rvalid ),
        .m00_axi_rready (axi[00].rready ),
        .m00_axi_rid    (             ),
        .m00_axi_rlast  (             ),

        .m01_axi_araddr (axi[01].araddr ),
        .m01_axi_arprot (axi[01].arprot ),
        .m01_axi_arvalid(axi[01].arvalid),
        .m01_axi_arready(axi[01].arready),
        .m01_axi_arburst(             ),
        .m01_axi_arlen  (             ),
        .m01_axi_arsize (             ),
        .m01_axi_arid   (             ),
        .m01_axi_arcache(             ),
        .m01_axi_arlock (             ),
        .m01_axi_arqos  (             ),
        .m01_axi_rdata  (axi[01].rdata  ),
        .m01_axi_rresp  (axi[01].rresp  ),
        .m01_axi_rvalid (axi[01].rvalid ),
        .m01_axi_rready (axi[01].rready ),
        .m01_axi_rid    (             ),
        .m01_axi_rlast  (             ),

        .m02_axi_araddr (axi[02].araddr ),
        .m02_axi_arprot (axi[02].arprot ),
        .m02_axi_arvalid(axi[02].arvalid),
        .m02_axi_arready(axi[02].arready),
        .m02_axi_arburst(             ),
        .m02_axi_arlen  (             ),
        .m02_axi_arsize (             ),
        .m02_axi_arid   (             ),
        .m02_axi_arcache(             ),
        .m02_axi_arlock (             ),
        .m02_axi_arqos  (             ),
        .m02_axi_rdata  (axi[02].rdata  ),
        .m02_axi_rresp  (axi[02].rresp  ),
        .m02_axi_rvalid (axi[02].rvalid ),
        .m02_axi_rready (axi[02].rready ),
        .m02_axi_rid    (             ),
        .m02_axi_rlast  (             ),

        .m03_axi_araddr (axi[03].araddr ),
        .m03_axi_arprot (axi[03].arprot ),
        .m03_axi_arvalid(axi[03].arvalid),
        .m03_axi_arready(axi[03].arready),
        .m03_axi_arburst(             ),
        .m03_axi_arlen  (             ),
        .m03_axi_arsize (             ),
        .m03_axi_arid   (             ),
        .m03_axi_arcache(             ),
        .m03_axi_arlock (             ),
        .m03_axi_arqos  (             ),
        .m03_axi_rdata  (axi[03].rdata  ),
        .m03_axi_rresp  (axi[03].rresp  ),
        .m03_axi_rvalid (axi[03].rvalid ),
        .m03_axi_rready (axi[03].rready ),
        .m03_axi_rid    (             ),
        .m03_axi_rlast  (             ),

        .m04_axi_araddr (axi[04].araddr ),
        .m04_axi_arprot (axi[04].arprot ),
        .m04_axi_arvalid(axi[04].arvalid),
        .m04_axi_arready(axi[04].arready),
        .m04_axi_arburst(             ),
        .m04_axi_arlen  (             ),
        .m04_axi_arsize (             ),
        .m04_axi_arid   (             ),
        .m04_axi_arcache(             ),
        .m04_axi_arlock (             ),
        .m04_axi_arqos  (             ),
        .m04_axi_rdata  (axi[04].rdata  ),
        .m04_axi_rresp  (axi[04].rresp  ),
        .m04_axi_rvalid (axi[04].rvalid ),
        .m04_axi_rready (axi[04].rready ),
        .m04_axi_rid    (             ),
        .m04_axi_rlast  (             ),

        .m05_axi_araddr (axi[05].araddr ),
        .m05_axi_arprot (axi[05].arprot ),
        .m05_axi_arvalid(axi[05].arvalid),
        .m05_axi_arready(axi[05].arready),
        .m05_axi_arburst(             ),
        .m05_axi_arlen  (             ),
        .m05_axi_arsize (             ),
        .m05_axi_arid   (             ),
        .m05_axi_arcache(             ),
        .m05_axi_arlock (             ),
        .m05_axi_arqos  (             ),
        .m05_axi_rdata  (axi[05].rdata  ),
        .m05_axi_rresp  (axi[05].rresp  ),
        .m05_axi_rvalid (axi[05].rvalid ),
        .m05_axi_rready (axi[05].rready ),
        .m05_axi_rid    (             ),
        .m05_axi_rlast  (             ),

        .m06_axi_araddr (axi[06].araddr ),
        .m06_axi_arprot (axi[06].arprot ),
        .m06_axi_arvalid(axi[06].arvalid),
        .m06_axi_arready(axi[06].arready),
        .m06_axi_arburst(             ),
        .m06_axi_arlen  (             ),
        .m06_axi_arsize (             ),
        .m06_axi_arid   (             ),
        .m06_axi_arcache(             ),
        .m06_axi_arlock (             ),
        .m06_axi_arqos  (             ),
        .m06_axi_rdata  (axi[06].rdata  ),
        .m06_axi_rresp  (axi[06].rresp  ),
        .m06_axi_rvalid (axi[06].rvalid ),
        .m06_axi_rready (axi[06].rready ),
        .m06_axi_rid    (             ),
        .m06_axi_rlast  (             ),

        .m07_axi_araddr (axi[07].araddr ),
        .m07_axi_arprot (axi[07].arprot ),
        .m07_axi_arvalid(axi[07].arvalid),
        .m07_axi_arready(axi[07].arready),
        .m07_axi_arburst(             ),
        .m07_axi_arlen  (             ),
        .m07_axi_arsize (             ),
        .m07_axi_arid   (             ),
        .m07_axi_arcache(             ),
        .m07_axi_arlock (             ),
        .m07_axi_arqos  (             ),
        .m07_axi_rdata  (axi[07].rdata  ),
        .m07_axi_rresp  (axi[07].rresp  ),
        .m07_axi_rvalid (axi[07].rvalid ),
        .m07_axi_rready (axi[07].rready ),
        .m07_axi_rid    (             ),
        .m07_axi_rlast  (             ),

        .m08_axi_araddr (axi[08].araddr ),
        .m08_axi_arprot (axi[08].arprot ),
        .m08_axi_arvalid(axi[08].arvalid),
        .m08_axi_arready(axi[08].arready),
        .m08_axi_arburst(             ),
        .m08_axi_arlen  (             ),
        .m08_axi_arsize (             ),
        .m08_axi_arid   (             ),
        .m08_axi_arcache(             ),
        .m08_axi_arlock (             ),
        .m08_axi_arqos  (             ),
        .m08_axi_rdata  (axi[08].rdata  ),
        .m08_axi_rresp  (axi[08].rresp  ),
        .m08_axi_rvalid (axi[08].rvalid ),
        .m08_axi_rready (axi[08].rready ),
        .m08_axi_rid    (             ),
        .m08_axi_rlast  (             ),

        .m09_axi_araddr (axi[09].araddr ),
        .m09_axi_arprot (axi[09].arprot ),
        .m09_axi_arvalid(axi[09].arvalid),
        .m09_axi_arready(axi[09].arready),
        .m09_axi_arburst(             ),
        .m09_axi_arlen  (             ),
        .m09_axi_arsize (             ),
        .m09_axi_arid   (             ),
        .m09_axi_arcache(             ),
        .m09_axi_arlock (             ),
        .m09_axi_arqos  (             ),
        .m09_axi_rdata  (axi[09].rdata  ),
        .m09_axi_rresp  (axi[09].rresp  ),
        .m09_axi_rvalid (axi[09].rvalid ),
        .m09_axi_rready (axi[09].rready ),
        .m09_axi_rid    (             ),
        .m09_axi_rlast  (             ),

        .m10_axi_araddr (axi[10].araddr ),
        .m10_axi_arprot (axi[10].arprot ),
        .m10_axi_arvalid(axi[10].arvalid),
        .m10_axi_arready(axi[10].arready),
        .m10_axi_arburst(             ),
        .m10_axi_arlen  (             ),
        .m10_axi_arsize (             ),
        .m10_axi_arid   (             ),
        .m10_axi_arcache(             ),
        .m10_axi_arlock (             ),
        .m10_axi_arqos  (             ),
        .m10_axi_rdata  (axi[10].rdata  ),
        .m10_axi_rresp  (axi[10].rresp  ),
        .m10_axi_rvalid (axi[10].rvalid ),
        .m10_axi_rready (axi[10].rready ),
        .m10_axi_rid    (             ),
        .m10_axi_rlast  (             ),

        .m11_axi_araddr (axi[11].araddr ),
        .m11_axi_arprot (axi[11].arprot ),
        .m11_axi_arvalid(axi[11].arvalid),
        .m11_axi_arready(axi[11].arready),
        .m11_axi_arburst(             ),
        .m11_axi_arlen  (             ),
        .m11_axi_arsize (             ),
        .m11_axi_arid   (             ),
        .m11_axi_arcache(             ),
        .m11_axi_arlock (             ),
        .m11_axi_arqos  (             ),
        .m11_axi_rdata  (axi[11].rdata  ),
        .m11_axi_rresp  (axi[11].rresp  ),
        .m11_axi_rvalid (axi[11].rvalid ),
        .m11_axi_rready (axi[11].rready ),
        .m11_axi_rid    (             ),
        .m11_axi_rlast  (             ),

        .m12_axi_araddr (axi[12].araddr ),
        .m12_axi_arprot (axi[12].arprot ),
        .m12_axi_arvalid(axi[12].arvalid),
        .m12_axi_arready(axi[12].arready),
        .m12_axi_arburst(             ),
        .m12_axi_arlen  (             ),
        .m12_axi_arsize (             ),
        .m12_axi_arid   (             ),
        .m12_axi_arcache(             ),
        .m12_axi_arlock (             ),
        .m12_axi_arqos  (             ),
        .m12_axi_rdata  (axi[12].rdata  ),
        .m12_axi_rresp  (axi[12].rresp  ),
        .m12_axi_rvalid (axi[12].rvalid ),
        .m12_axi_rready (axi[12].rready ),
        .m12_axi_rid    (             ),
        .m12_axi_rlast  (             ),

        .m13_axi_araddr (axi[13].araddr ),
        .m13_axi_arprot (axi[13].arprot ),
        .m13_axi_arvalid(axi[13].arvalid),
        .m13_axi_arready(axi[13].arready),
        .m13_axi_arburst(             ),
        .m13_axi_arlen  (             ),
        .m13_axi_arsize (             ),
        .m13_axi_arid   (             ),
        .m13_axi_arcache(             ),
        .m13_axi_arlock (             ),
        .m13_axi_arqos  (             ),
        .m13_axi_rdata  (axi[13].rdata  ),
        .m13_axi_rresp  (axi[13].rresp  ),
        .m13_axi_rvalid (axi[13].rvalid ),
        .m13_axi_rready (axi[13].rready ),
        .m13_axi_rid    (             ),
        .m13_axi_rlast  (             ),

        .m14_axi_araddr (axi[14].araddr ),
        .m14_axi_arprot (axi[14].arprot ),
        .m14_axi_arvalid(axi[14].arvalid),
        .m14_axi_arready(axi[14].arready),
        .m14_axi_arburst(             ),
        .m14_axi_arlen  (             ),
        .m14_axi_arsize (             ),
        .m14_axi_arid   (             ),
        .m14_axi_arcache(             ),
        .m14_axi_arlock (             ),
        .m14_axi_arqos  (             ),
        .m14_axi_rdata  (axi[14].rdata  ),
        .m14_axi_rresp  (axi[14].rresp  ),
        .m14_axi_rvalid (axi[14].rvalid ),
        .m14_axi_rready (axi[14].rready ),
        .m14_axi_rid    (             ),
        .m14_axi_rlast  (             ),

        .m15_axi_araddr (axi[15].araddr ),
        .m15_axi_arprot (axi[15].arprot ),
        .m15_axi_arvalid(axi[15].arvalid),
        .m15_axi_arready(axi[15].arready),
        .m15_axi_arburst(             ),
        .m15_axi_arlen  (             ),
        .m15_axi_arsize (             ),
        .m15_axi_arid   (             ),
        .m15_axi_arcache(             ),
        .m15_axi_arlock (             ),
        .m15_axi_arqos  (             ),
        .m15_axi_rdata  (axi[15].rdata  ),
        .m15_axi_rresp  (axi[15].rresp  ),
        .m15_axi_rvalid (axi[15].rvalid ),
        .m15_axi_rready (axi[15].rready ),
        .m15_axi_rid    (               ),
        .m15_axi_rlast  (               )
    );

    genvar ch;
    generate
        for(ch = 0; ch < 16; ch++) begin : memories
            FileROM #(.BASE_ADDR(64'd0), .MEAN_LATENCY(96))
            theROM
            (
                .s_axi4l(axi[ch].slave)
            );
        end // memories
    endgenerate

endmodule // TestPBx16
