// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180822

`timescale 1ns/1ps
`default_nettype none

`include "../common.sv"
`include "./s00_defines.sv"
module TestBiDirEmSeek3;
    import SimSrcGen::*;
    import BwaMemDefines::*;

    logic clk, rst;
    initial GenClk(clk, 8, 10);
    initial GenRst(clk, rst, 2, 2);

    // byte rstring[78] = "NCTTTATGGTTTGTAGTTTAAAACAAAGACAATAACAACCCTTTCCTAAAGCAGACATCCTTCTTGCCTGGGGACTNN";    // read 1 
    // byte rstring[78] = "NCGGGAGGCTGAGGTAGGAGAATCACTTGAACCTGGGAAGCAGAGGTTGCAGTGAGCCGAGATCGTGCCACTGCACTN";    // read 5
    // byte rstring[78] = "NCCCAGTAGCTCGGACTACAGGCACATACCACCACGCCTGGCTAATTTTTTATNTTNANNNGTGTAGATNNNGGTTNN";    // read 16
    byte rstring [78] = "NATGGTATTCTTTCTCTTCCGCACCCAGCAGTTTGGCCCGCCCAAAATCTGTGATCTTGACATGCTGCGGTGTTTTCN";     // 161-read006

    Symbol read[78];

    initial begin
        for(int i = 0; i < 78; i++) begin
            case(rstring[i])
            8'h41: read[i] = sym_A;
            8'h43: read[i] = sym_C;
            8'h47: read[i] = sym_G;
            8'h54: read[i] = sym_T;
            default: read[i] = sym_N;
            endcase
        end
    end

    logic [KLS_W-1:0] acc_cnt[0:3];
    logic [KLS_W-1:0] pri_pos;
    logic [KLS_W-1:0] bwt_len;
    logic bwt_params_valid;

    logic [POS_W-1:0] min_mlen = 19;
    logic min_mlen_valid;

    logic [KLS_W-1:0] min_intv = 0;
    logic min_intv_valid;
    
    logic [POS_W-1:0] sf_mlen = 20;
    logic [KLS_W-1:0] sf_max_intv = 10;
    logic sf_params_valid;
    
    logic bi_dir = 1'b1;
    logic start = 1'b0;
    wire  finish;
    wire  busy;

    integer seed = 123321;
    integer rnd;
    always_ff @(posedge clk) begin : proc_rnd
        if(rst) begin
            rnd <= 0;
        end else begin
            rnd <= $random(seed);
        end
    end

    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_emout(.clk(clk), .reset_n(~rst));
    wire WorkingMem emout = axis_emout.tdata;
    always_comb axis_emout.tready = rnd[1:0] == 3'b00;//1'b1;
    wire emout_handsk = axis_emout.tready & axis_emout.tvalid;
    Axi4LiteIf #(.AW(40), .DW(256)) axi_occlu(clk, ~rst);

    logic [POS_W-1:0] p, pNxt;
    integer c_file, code;
    initial begin
        // check the order of those values in file!
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
        @(posedge clk) begin
            bwt_params_valid <= 1'b1;
            min_mlen_valid   <= 1'b1;
            min_intv_valid   <= 1'b1;
            sf_params_valid  <= 1'b1;
        end
        @(posedge clk) begin
            bwt_params_valid <= 1'b0;
            min_mlen_valid   <= 1'b0;
            min_intv_valid   <= 1'b0;
            sf_params_valid  <= 1'b0;
        end

        p = 1;
        while(p < 78) begin
        // for(p = 1; p < 78;) begin // this cause warning
            @(posedge clk) begin
                start <= 1'b1;
            end
            @(posedge clk) begin
                start <= 1'b0;
            end
            while(1) begin
                @(posedge clk) begin
                    if(finish) begin
                        p = pNxt;
                        start <= 1'b1;
                        break;
                    end
                end
            end
            @(posedge clk) begin
                start <= 1'b0;
            end
        end
        @(posedge clk) begin
            $stop();
        end

    end // initial

    BiDirEmSeek3 #(78) the_dut (
        .clk             (clk),
        .rst             (rst),
        .gd_read         (read),
        .pos_in          (p),
        .bi_dir_in       (bi_dir),
        .start           (start),
        .pos_out         (pNxt),
        .finish          (finish),
        .busy            (busy),
        .m_axis_emout    (axis_emout.master),
        .m_axi_occlu     (axi_occlu.master),
        .acc_cnt_in      (acc_cnt),
        .pri_pos_in      (pri_pos),
        .bwt_len_in      (bwt_len),
        .bwt_params_valid(bwt_params_valid),
        .min_mlen_in     (min_mlen),
        .min_mlen_valid  (min_mlen_valid),
        .min_intv_in     (min_intv),
        .min_intv_valid  (min_intv_valid),
        .sf_mlen_in      (sf_mlen),
        .sf_max_intv_in  (sf_max_intv),
        .sf_params_valid (sf_params_valid)
    );

    FileROM #(.BASE_ADDR(64'd0), .MEAN_LATENCY(32))
    theROM
    (
        .s_axi4l(axi_occlu.slave)
    );

endmodule // TestExtension
