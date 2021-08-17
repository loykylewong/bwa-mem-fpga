// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180809

`timescale 1ns/1ps
`default_nettype none

`include "../common.sv"
`include "./s00_defines.sv"
module TestReadMemReseed;
    import SimSrcGen::*;
    import BwaMemDefines::*;

    logic clk, rst;
    initial GenClk(clk, 8, 10);
    initial GenRst(clk, rst, 2, 2);

    // byte rstring[76] = "CTTTATGGTTTGTAGTTTAAAACAAAGACAATAACAACCCTTTCCTAAAGCAGACATCCTTCTTGCCTGGGGACTN";    // read 1 
    // byte rstring[76] = "CCTACAAAGTGAATCTAGTCCCCAGGCAAGAAGGAGGTCTGCTTTAGGAAAGGGTTGTTATTGTCTTTGTTTTAAN";  // read 2
    // byte rstring[76] = "CGGGAGGCTGAGGTAGGAGAATCACTTGAACCTGGGAAGCAGAGGTTGCAGTGAGCCGAGATCGTGCCACTGCACT";    // read 5
    // byte rstring[76] = "CCCAGTAGCTCGGACTACAGGCACATACCACCACGCCTGGCTAATTTTTTATNTTNANNNGTGTAGATNNNGGTTN";    // read 16

    byte rstring [76] = "TGTCAGGGTCGTCTTCGTCCTCATCGCCACTCTCCTCAGGGATGGCGTCCTCAGGAATCGCCTGCATTTGGACCCC";     // 161-read000
    // byte rstring [76] = "TCCACGGCTAGTGGGCGCATGTAGGCGGTGGGCGTCCAGCATCTCCAGCAGCAGGTCATAGAGGGGCACCACGTTC";     // 161-read002
    // byte rstring [76] = "ATGGTATTCTTTCTCTTCCGCACCCAGCAGTTTGGCCCGCCCAAAATCTGTGATCTTGACATGCTGCGGTGTTTTC";     // 161-read006
    // byte rstring [76] = "GAGACGGAGTCTCGCTCTGTCGCCCAGGCTGGAGTGCAGTGGCGCGATCTCGGCTCACTGCAAGCTCCGCCTCCCG";     // 161-read017
    // byte rstring [76] = "CCCTCCCCTGACAGGCCCCAGTGTGTGTTGTTCCCCTCCCTGTGTTCATGTGTTCTCATTGTTCAGCTCCCACTTG";     // 161-read019

    Symbol read[76];

    initial begin
        for(int i = 0; i < 76; i++) begin
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
    logic acc_cnt_valid;
    logic [KLS_W-1:0] pri_pos;
    logic pri_pos_valid;
    logic [KLS_W-1:0] bwt_len;
    logic bwt_len_valid;
    logic [POS_W-1:0] min_mlen = 19;
    logic min_mlen_valid;
    logic [POS_W-1:0] min_rslen = 28;
    logic [KLS_W-1:0] max_rsintv = 10;
    logic rs_params_valid;
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

    Axi4StreamIf #(.DW_BYTES($bits(AssemMem)/8)) axis_emout(.clk(clk), .reset_n(~rst));
    wire AssemMem emout = axis_emout.tdata;
    always_comb axis_emout.tready = rnd[0] == 1'b0;//1'b1;
    wire emout_handsk = axis_emout.tready & axis_emout.tvalid;
    Axi4LiteIf #(.AW(40), .DW(256)) axi_occlu(clk, ~rst);

    integer c_file, code;
    initial begin
        c_file = $fopen("./hs37d5_cocc.bin.txt", "r");
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
            bwt_len_valid   <= 1'b1;
            acc_cnt_valid   <= 1'b1;
            pri_pos_valid   <= 1'b1;
            min_mlen_valid  <= 1'b1;
            rs_params_valid <= 1'b1;
        end
        @(posedge clk) begin
            bwt_len_valid   <= 1'b0;
            acc_cnt_valid   <= 1'b0;
            pri_pos_valid   <= 1'b0;
            min_mlen_valid  <= 1'b0;
            rs_params_valid <= 1'b0;
        end

        @(posedge clk) begin
            start <= 1'b1;
        end
        @(posedge clk) begin
            start <= 1'b0;
        end
        do begin
            @(posedge clk);
        end while(!finish);
        repeat(100) @(posedge clk);
        @(posedge clk) begin
            $stop();
        end

    end // initial

    // ReadMem #(76) the_dut (
    ReadMemReseed #(76) the_dut (
        .clk            (clk),
        .rst            (rst),
        .read           (read),
        .read_id        (32'h01234567),
        .start          (start),
        .finish         (finish),
        .busy           (busy),
        .m_axis_emout   (axis_emout.master),
        .m_axi_occlu    (axi_occlu.master),
        .acc_cnt_in     (acc_cnt),
        .acc_cnt_valid  (acc_cnt_valid),
        .pri_pos_in     (pri_pos),
        .pri_pos_valid  (pri_pos_valid),
        .min_mlen_in    (min_mlen),
        .min_mlen_valid (min_mlen_valid),
        .bwt_len_in     (bwt_len),
        .bwt_len_valid  (bwt_len_valid),
        .min_rslen_in   (min_rslen),
        .max_rsintv_in  (max_rsintv),
        .rs_params_valid(rs_params_valid)
    );

    FileROM #(.BASE_ADDR(64'd0), .MEAN_LATENCY(32))
    theROM
    (
        .s_axi4l(axi_occlu.slave)
    );

endmodule // TestExtension
