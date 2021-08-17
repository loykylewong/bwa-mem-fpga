// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180803

`timescale 1ns/1ps
`default_nettype none

`include "../common.sv"
`include "./s00_defines.sv"
module TestExtension;
    import SimSrcGen::*;
    import BwaMemDefines::*;

    logic clk, rst;
    initial GenClk(clk, 8, 10);
    initial GenRst(clk, rst, 2, 2);

    Symbol a = sym_$;
    logic dir = DirBackward;
    logic [KLS_W-1:0] k0 = 0, l0 = 0, s0;
    wire  [KLS_W-1:0] k1, l1, s1;
    logic [KLS_W-1:0] acc_cnt[0:3];
    logic [KLS_W-1:0] pri_pos;
    logic bwt_params_valid;
    logic [KLS_W-1:0] bwt_len;
    logic init = 1'b0;
    logic start = 1'b0;
    wire  finish;

    integer seq_len = 3;
    Symbol seq[3] = '{sym_A, sym_C, sym_T};
    integer idx;
    integer c_file, code;
    initial begin
        // check the order of those values in file!
        c_file = $fopen("./data/hs37d5_cocc.bin.txt","r");
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
            s0 <= bwt_len;
            bwt_params_valid <= 1'b1;
        end
        @(posedge clk) begin
            bwt_params_valid <= 1'b0;
        end

        // === forward === 
        for(idx = 0; idx < seq_len; idx++) begin
            @(posedge clk) begin
                a <= seq[idx];
                if(idx == 0) init <= 1'b1;
                start <= 1'b1;
                dir <= DirForward;
            end
            @(posedge clk) begin
                init <= 1'b0;
                start <= 1'b0;
            end
            while(~finish) begin
                @(posedge clk);
            end
        end
        // === backward ===
        for(idx = seq_len - 1; idx >= 0; idx--) begin
            @(posedge clk) begin
                a <= seq[idx];
                if(idx == seq_len - 1) init <= 1'b1;
                start <= 1'b1;
                dir <= DirBackward;
            end
            @(posedge clk) begin
                init <= 1'b0;
                start <= 1'b0;
            end
            while(~finish) begin
                @(posedge clk);
            end
        end

        @(posedge clk) $stop();

    end

    wire [KLS_W-1:0] occ_k, occ_ks, occ_val_k[0:3], occ_val_ks[0:3];
    wire occ_lookup, occ_val_valid;

    wire busy;
    Extension the_dut(
        .clk             (clk), .rst(rst),
        .a_in            (a),  .dir_in(dir),
        .k_in            (init ? k0 : k1),
        .l_in            (init ? l0 : l1),
        .s_in            (init ? s0 : s1),
        .start           (start),
        .k_out           (k1), 
        .l_out           (l1),
        .s_out           (s1),
        .finish          (finish),
        .busy            (busy),
        .acc_cnt_in      (acc_cnt),
        .pri_pos_in      (pri_pos),
        .bwt_params_valid(bwt_params_valid),
        .occ_k           (occ_k),
        .occ_ks          (occ_ks),
        .occ_lookup      (occ_lookup),
        .occ_val_k       (occ_val_k),
        .occ_val_ks      (occ_val_ks),
        .occ_val_valid   (occ_val_valid)
    );

    Axi4LiteIf #(.AW(40), .DW(256)) axi_occlu(clk, ~rst);

    OccLookup the_olu(
        .clk(clk), .rst(rst),
        .k_in(occ_k), .ks_in(occ_ks),
        .start(occ_lookup),
        .val_k(occ_val_k), .val_ks(occ_val_ks),
        .val_valid(occ_val_valid),
        .m_axi_occlu(axi_occlu.master)
    );

    FileROM #(.BASE_ADDR(64'd0), .MEAN_LATENCY(32))
    theROM
    (
        .s_axi4l(axi_occlu.slave)
    );

endmodule // TestExtension
