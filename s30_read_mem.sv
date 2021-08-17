// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180809

`default_nettype none

// ReadMem without reseeding
module ReadMem
    import BwaMemDefines::*;
#(
    parameter READ_LEN  = 76,
    // POW_W moved into package BwaMemDefines
    // parameter POS_W       = 8,
    parameter integer OCC_AW = 40,
    parameter logic [OCC_AW - 1 : 0] OCC_BASE = 40'h00_0000_0000 // must be align to 64G
)(
    input wire clk, rst,
    input wire Symbol read[0 : READ_LEN - 1],
    input wire [RID_W - 1 : 0] read_id,
    input wire start,
    output logic finish,
    output logic busy,
    Axi4StreamIf.master m_axis_emout,
    Axi4LiteIf.master m_axi_occlu,
    input wire [KLS_W - 1 : 0] acc_cnt_in[0 : 3],
    input wire acc_cnt_valid,
    input wire [KLS_W - 1 : 0] pri_pos_in,
    input wire pri_pos_valid,
    input wire [POS_W - 1 : 0] min_mlen_in,
    input wire min_mlen_valid,
    input wire [KLS_W - 1 : 0] bwt_len_in,
    input wire bwt_len_valid
);
    localparam GD_READ_LEN = READ_LEN + 2;

    Symbol gd_read[0 : GD_READ_LEN - 1];
    logic [POS_W - 1 : 0] pos, nxt_pos; // pos=0 - idle, pos=1~GD_READ_LEN-1 - bex, pos=GD_READ_LEN, filter

    logic  bem_start;
    wire   bem_finish, bem_busy;
    logic  fil1_start, fil1_stop;
    wire   fil1_finish, fil1_busy;
    wire   fil2_start, fil2_stop, fil2_finish, fil2_busy;
    assign fil2_start = fil1_start;
    assign fil2_stop = fil1_finish;

    always_ff @(posedge clk) begin : proc_gd_read
        if(rst) begin
            gd_read <= '{GD_READ_LEN{sym_N}};
        end 
        else if(pos == '0 && start) begin
            gd_read[0] <= sym_N;
            gd_read[READ_LEN + 1] <= sym_N;
            gd_read[1 : READ_LEN] <= read;
        end
    end

    logic [RID_W - 1 : 0] id;
    always_ff @(posedge clk) begin : proc_id
        if(rst) begin
            id <= 1'b0;
        end
        else if(pos == '0 && start) begin
            id <= read_id;
        end
    end

    always_ff @(posedge clk) begin : proc_pos
        if(rst) begin
            pos <= '0;
        end 
        else if(pos == '0) begin
            if(start) begin
                pos <= 1'b1;
            end
        end
        else if(bem_finish) begin
            if(nxt_pos < GD_READ_LEN) begin
                pos <= nxt_pos;
            end
            else begin
                pos <= GD_READ_LEN;
            end
        end
        else if(pos == GD_READ_LEN) begin
            if(fil2_finish) begin
                pos <= '0;
            end
        end
    end

    always_ff @(posedge clk) begin : proc_bem_start
        if(rst) begin
            bem_start <= 1'b0;
        end 
        else if(pos == '0 && start) begin
            bem_start <= 1'b1;
        end
        else if(bem_finish && nxt_pos < GD_READ_LEN) begin
            bem_start <= 1'b1;
        end
        else begin
            bem_start <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin : proc_fil1_start
        if(rst) begin
            fil1_start <= 1'b0;
        end
        else if(pos == '0 && start) begin
            fil1_start <= 1'b1;
        end
        else begin
            fil1_start <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin : proc_fil1_stop
        if(rst) begin
            fil1_stop <= 0;
        end
        else if(bem_finish && nxt_pos >= GD_READ_LEN) begin
            fil1_stop <= 1'b1;
        end
        else begin
            fil1_stop <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin : proc_finish
        if(rst) begin
            finish <= 1'b0;
        end
        else if(pos == GD_READ_LEN && fil2_finish) begin
            finish <= 1'b1;
        end
        else begin
            finish <= 1'b0;
        end
    end

    assign busy = pos != '0;

    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_em_to_fil1  (.clk(clk), .reset_n(~rst));
    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_fil1_to_fil2(.clk(clk), .reset_n(~rst));
    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_fil2_to_asm (.clk(clk), .reset_n(~rst));

    BiDirEmSeek #(.GD_READ_LEN(GD_READ_LEN), .OCC_AW(OCC_AW), .OCC_BASE(OCC_BASE)) the_bem (
        .clk           (clk),
        .rst           (rst),
        .gd_read       (gd_read),
        .pos_in        (pos),
        .start         (bem_start),
        .pos_out       (nxt_pos),
        .finish        (bem_finish),
        .busy          (bem_busy),
        .m_axis_emout  (axis_em_to_fil1.master),
        .m_axi_occlu   (m_axi_occlu),
        .acc_cnt_in    (acc_cnt_in),
        .acc_cnt_valid (acc_cnt_valid),
        .pri_pos_in    (pri_pos_in),
        .pri_pos_valid (pri_pos_valid),
        .min_mlen_in   (min_mlen_in),
        .min_mlen_valid(min_mlen_valid),
        .bwt_len_in    (bwt_len_in),
        .bwt_len_valid (bwt_len_valid)
    );

    MemFilter1 the_fil1 (
        .clk         (clk),
        .rst         (rst),
        .start       (fil1_start),
        .stop        (fil1_stop),
        .finish      (fil1_finish),
        .busy        (fil1_busy),
        .s_axis_emin (axis_em_to_fil1.slave),
        .m_axis_emout(axis_fil1_to_fil2.master)
    );

    MemFilter2 the_fil2 (
        .clk         (clk),
        .rst         (rst),
        .start       (fil2_start),
        .stop        (fil2_stop),
        .finish      (fil2_finish),
        .busy        (fil2_busy),
        .s_axis_emin (axis_fil1_to_fil2.slave),
        .m_axis_emout(axis_fil2_to_asm.master)
    );

    MemAssem the_assem (
        .clk         (clk),
        .rst         (rst),
        .read_id     (id),
        .s_axis_emin (axis_fil2_to_asm.slave),
        .m_axis_emout(m_axis_emout)
    );

endmodule // ReadMem



