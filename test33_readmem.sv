// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180822

`timescale 1ns/1ps
`default_nettype none

`include "../common.sv"
`include "./s00_defines.sv"
module TestReadMemReseed3;
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
    // byte rstring [76] = "TAGTGGTGGTTCCATCTGTAGCCTCGACTGTGAGGTTGTAGTTTGACTTCTGTTCTGCATCAAGAGGTTTGGCAAC";     // 161-read001
    // byte rstring [76] = "TCCACGGCTAGTGGGCGCATGTAGGCGGTGGGCGTCCAGCATCTCCAGCAGCAGGTCATAGAGGGGCACCACGTTC";     // 161-read002
    // byte rstring [76] = "TCGCCATGTTGGCTAGGCTTGTCTCAAACTCCTGAGTTCAGGTAATCCGCCCGCCTTGGCCTCCCAAAGTGCGAGG";     // 161-read005
    // byte rstring [76] = "ATGGTATTCTTTCTCTTCCGCACCCAGCAGTTTGGCCCGCCCAAAATCTGTGATCTTGACATGCTGCGGTGTTTTC";     // 161-read006
    // byte rstring [76] = "GAGACGGAGTCTCGCTCTGTCGCCCAGGCTGGAGTGCAGTGGCGCGATCTCGGCTCACTGCAAGCTCCGCCTCCCG";     // 161-read017
    // byte rstring [76] = "CCCTCCCCTGACAGGCCCCAGTGTGTGTTGTTCCCCTCCCTGTGTTCATGTGTTCTCATTGTTCAGCTCCCACTTG";     // 161-read019
    // byte rstring [76] = "GATCCGCCTGCCACGGCCTCCCAAAGTGCTGGGATTACAAGCGTGAGCCACCACGCCCGACCCACCATTCTTGCAT";     // 161-read807
    // byte rstring [76] = "GCTGTCAGTCCAGCTACTGTGTCCCCGTGTGCTGCCAGTCTATCTTCTGATGGACATGCTGCTGTCAGTCCAGATT";     // 161-read820
    // byte rstring [76] = "GAAAGCATTTGTATTTGTTTTCTTTTTTAGGGGCAAAAAGGCCCCGAGTCACTTCAGGTGGTGTGTCAGAGTCTCC";     // 161-read996
    // byte rstring [76] = "GGCAGTAGGTGTGATAAATTATGTCACAATCATCACACAGCAGGAGTCTTCCTGGGTCAGTTGCCTTCCCACAGGC";     // 161-read880
    // byte rstring [76] = "GAGACCATGGGAACCCTCTCAGCCCCTCCCTGCACACAGCGCATCAAATGGAAGGGGCTCCTGCTCACAGGTGAGG";     // 161-read313

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
    logic [KLS_W-1:0] pri_pos;
    logic [KLS_W-1:0] bwt_len;
    logic bwt_params_valid;

    logic [POS_W-1:0] min_mlen = 19;
    logic min_mlen_valid;

    logic [POS_W-1:0] rs_min_mlen = 28;
    logic [KLS_W-1:0] rs_max_intv = 10;
    logic rs_params_valid;

    logic [POS_W-1:0] sf_mlen = 20;
    logic [KLS_W-1:0] sf_max_intv = 20;
    logic sf_params_valid;    

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
            rs_params_valid  <= 1'b1;
            sf_params_valid  <= 1'b1;
        end
        @(posedge clk) begin
            bwt_params_valid <= 1'b0;
            min_mlen_valid   <= 1'b0;
            rs_params_valid  <= 1'b0;
            sf_params_valid  <= 1'b0;
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

    integer f0, f1, f2, f3, f4;
    logic [POS_W-1:0] i, j;
    logic [KLS_W-1:0] s;
    initial begin
        f0 = $fopen("./simdata/0_bex_bi.txt", "w");
        f1 = $fopen("./simdata/1_bem_out.txt", "w");
        f2 = $fopen("./simdata/4_rsfil.txt", "w");
        f3 = $fopen("./simdata/2_fil1.txt", "w");
        f4 = $fopen("./simdata/3_fil2.txt", "w");
        $fdisplay(f0, "ex procedure");
        $fdisplay(f1, "bem output");
        $fdisplay(f2, "rs filter output");
        $fdisplay(f3, "filter1 output");
        $fdisplay(f4, "filter2 output");
    end
    always@(posedge clk) begin
        i = the_dut.the_bex.i0;
        j = the_dut.the_bex.j0;
        s = the_dut.the_bex.s0;
        if(the_dut.the_bex.ex_finish) begin
            if(!the_dut.the_bex.bi_dir) begin
                $fdisplay(f0, "SmpFwd  : %2d - %2d (%2d): %10d", i, j, j - i + 1, s);
            end
            else begin
                if(the_dut.state == the_dut.S_Reseeding) begin
                    $fwrite(f0, "RS ");
                end
                else begin
                    $fwrite(f0, "BI ");
                end
                if(the_dut.the_bex.dir == DirForward) begin
                    $fdisplay(f0, "Forw : %2d - %2d (%2d): %10d", i, j, j - i + 1, s);
                end
                else if(the_dut.the_bex.dir == DirBackward) begin
                    $fdisplay(f0, "Back : %2d - %2d (%2d): %10d", i, j, j - i + 1, s);
                end
            end
        end
        i = the_dut.the_bex.fifo_din.i;
        j = the_dut.the_bex.fifo_din.j;
        s = the_dut.the_bex.fifo_din.s;
        if(the_dut.the_bex.m_axis_emout.tvalid & the_dut.the_bex.m_axis_emout.tready) begin
            $fdisplay(f1, "%2d - %2d (%2d): %10d", i, j, j - i + 1, s);
        end

        i = the_dut.the_rsfil.m.i;
        j = the_dut.the_rsfil.m.j;
        s = the_dut.the_rsfil.m.s;
        if(the_dut.the_rsfil.m_axis_emout.tvalid & the_dut.the_rsfil.m_axis_emout.tready) begin
            $fwrite(f2, "%2d - %2d (%2d): %3d", i, j, j - i + 1, s);
            if(the_dut.the_rsfil.m_axis_rsout.tvalid & the_dut.the_rsfil.m_axis_rsout.tready) begin
                $fdisplay(f2, "  Reseed");
            end
            else begin
                $fdisplay(f2, "");
            end
        end
        i = the_dut.the_fil1.emout.i;
        j = the_dut.the_fil1.emout.j;
        s = the_dut.the_fil1.emout.s;
        if(the_dut.the_fil1.m_axis_emout.tvalid & the_dut.the_fil1.m_axis_emout.tready) begin
            $fdisplay(f3, "%2d - %2d (%2d): %3d", i, j, j - i + 1, s);
        end
        i = the_dut.the_fil2.emout.i;
        j = the_dut.the_fil2.emout.j;
        s = the_dut.the_fil2.emout.s;
        if(the_dut.the_fil2.m_axis_emout.tvalid & the_dut.the_fil2.m_axis_emout.tready) begin
            $fdisplay(f4, "%2d - %2d (%2d): %3d", i, j, j - i + 1, s);
        end
        if(finish) begin
            repeat(10) @(posedge clk);
            $fclose(f0);
            // $fclose(f1);
            $fclose(f2);
            $fclose(f3);
            $fclose(f4);
        end
    end


    // ReadMem #(76) the_dut (
    ReadMemReseed3 #(76) the_dut (
        .clk             (clk),
        .rst             (rst),
        .read            (read),
        .read_id         (32'h01234567),
        .start           (start),
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
        .rs_min_mlen_in  (rs_min_mlen),
        .rs_max_intv_in  (rs_max_intv),
        .rs_params_valid (rs_params_valid),
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
