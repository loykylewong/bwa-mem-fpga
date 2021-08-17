// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180820

`default_nettype none
`include "./s00_defines.sv"

// read to mem(seed) with reseeding
module ReadMemReseed    // Obsolete
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
    input wire bwt_len_valid,
    input wire [POS_W - 1 : 0] min_rslen_in,
    input wire [KLS_W - 1 : 0] max_rsintv_in,
    input wire rs_params_valid
);
    localparam GD_READ_LEN = READ_LEN + 2;

    Symbol gd_read[0 : GD_READ_LEN - 1];
    logic [POS_W - 1 : 0] pos;
    wire  [POS_W - 1 : 0] nxt_pos;

    logic  bex_start;
    wire   bex_finish, bex_busy;
    // logic  [POS_W - 1 : 0] default_min_mlen;
    // logic  [POW_W - 1 : 0] bex_min_mlen_in;
    // wire   bex_min_mlen_valid;
    logic  [KLS_W - 1 : 0] min_intv;
    logic  min_intv_valid;
    logic  fil1_start, fil1_stop;
    wire   fil1_finish, fil1_busy;
    wire   fil2_start, fil2_stop, fil2_finish, fil2_busy;
    assign fil2_start = fil1_start;
    assign fil2_stop = fil1_finish;

    wire WorkingMem fifo_tdata;
    wire fifo_tvalid;
    wire fifo_ready;

    logic [1:0] wait_cnt;

    localparam logic [2:0] S_Idle       = 3'd0;
    localparam logic [2:0] S_Seeding    = 3'd1;
    localparam logic [2:0] S_WaitFifo   = 3'd2;
    localparam logic [2:0] S_ChkFifo    = 3'd3;
    localparam logic [2:0] S_Reseeding  = 3'd4;
    localparam logic [2:0] S_WaitFilter = 3'd5;
    logic [2:0] status, nxt_sts;

    always_ff @(posedge clk) begin : proc_status
        if(rst) begin
            status <= S_Idle;
        end
        else begin
            status <= nxt_sts;
        end
    end

    always_comb begin : proc_nxt_sts
        nxt_sts = status;
        case(status)
        S_Idle : begin
            if(start) begin
                nxt_sts = S_Seeding;
            end
        end // S_Idle :
        S_Seeding : begin
            if(bex_finish && nxt_pos >= GD_READ_LEN) begin
                // nxt_sts = S_ChkFifo;
                nxt_sts = S_WaitFifo;
            end
        end // S_Seeding :
        S_WaitFifo : begin
            if(wait_cnt == 2'd1) begin
                nxt_sts = S_ChkFifo;
            end
        end
        S_ChkFifo : begin
            if(fifo_tvalid) begin
                nxt_sts = S_Reseeding;
            end
            else begin
                nxt_sts = S_WaitFilter;
            end
        end // S_ChkFifo :
        S_Reseeding : begin
            if(bex_finish) begin
                nxt_sts = S_ChkFifo;
            end
        end // S_Reseeding :
        S_WaitFilter: begin
            if(fil2_finish) begin
                nxt_sts = S_Idle;
            end
        end
        endcase
    end

    always_ff @(posedge clk) begin : proc_wait_cnt
        if(rst) begin
            wait_cnt <= 1'b0;
        end 
        else if (status == S_Seeding && nxt_sts == S_WaitFifo) begin
            wait_cnt <= 1'b0;
        end
        else if (status == S_WaitFifo) begin
            wait_cnt <= wait_cnt + 1'b1;
        end
    end

    always_ff @(posedge clk) begin : proc_gd_read
        if(rst) begin
            gd_read <= '{GD_READ_LEN{sym_N}};
        end 
        else if(status == S_Idle && nxt_sts == S_Seeding) begin
            gd_read[0] <= sym_N;
            gd_read[1 : READ_LEN] <= read;
            gd_read[READ_LEN + 1] <= sym_N;
        end
    end

    logic [RID_W - 1 : 0] id;
    always_ff @(posedge clk) begin : proc_id
        if(rst) begin
            id <= 1'b0;
        end
        else if(status == S_Idle && nxt_sts == S_Seeding) begin
            id <= read_id;
        end
    end

    always_ff @(posedge clk) begin : proc_pos
        if(rst) begin
            pos <= '0;
        end
        else if(status == S_Idle && nxt_sts == S_Seeding) begin
            pos <= 1'b1;
        end
        else if(status == S_Seeding && bex_finish && nxt_pos < GD_READ_LEN) begin
            pos <= nxt_pos;
        end
        else if(status == S_ChkFifo) begin
            if(nxt_sts == S_Reseeding) begin
                pos <= POS_W'(((POS_W+1)'(fifo_tdata.i) + fifo_tdata.j + 1'b1) >> 1);
            end
            // else if(nxt_sts == S_WaitFilter) begin
            //     pos <= '0;
            // end
        end
    end

    always_ff @(posedge clk) begin : proc_bex_start
        if(rst) begin
            bex_start <= 1'b0;
        end 
        else if(status == S_Idle && nxt_sts == S_Seeding) begin
            bex_start <= 1'b1;
        end
        else if(status == S_Seeding && bex_finish && nxt_pos < GD_READ_LEN) begin
            bex_start <= 1'b1;
        end
        else if(status == S_ChkFifo && nxt_sts == S_Reseeding) begin
            bex_start <= 1'b1;
        end
        else begin
            bex_start <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin : proc_min_intv;
        if(rst) begin
            min_intv <= '0;
        end
        else if(status == S_Idle && nxt_sts == S_Seeding) begin
            min_intv <= '0;
        end
        else if(status == S_ChkFifo && nxt_sts == S_Reseeding) begin
            min_intv <= fifo_tdata.s;
        end
    end

    always_ff @(posedge clk) begin : proc_min_intv_valid
        if(rst) begin
            min_intv_valid <= 1'b0;
        end
        else if(status == S_Idle && nxt_sts == S_Seeding) begin
            min_intv_valid <= 1'b1;
        end
        else if(status == S_ChkFifo && nxt_sts == S_Reseeding) begin
            min_intv_valid <= 1'b1;
        end
        else begin
            min_intv_valid <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin : proc_fil1_start
        if(rst) begin
            fil1_start <= 1'b0;
        end
        else if(status == S_Idle && nxt_sts == S_Seeding) begin
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
        else if(status == S_ChkFifo && nxt_sts == S_WaitFilter) begin
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
        else if(status == S_WaitFilter && nxt_sts == S_Idle) begin
            finish <= 1'b1;
        end
        else begin
            finish <= 1'b0;
        end
    end

    assign busy = status != S_Idle;

    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_em_to_rs    (.clk(clk), .reset_n(~rst));
    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_rs_to_fil1  (.clk(clk), .reset_n(~rst));
    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_rs_to_fifo  (.clk(clk), .reset_n(~rst));
    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_fil1_to_fil2(.clk(clk), .reset_n(~rst));
    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_fil2_to_asm (.clk(clk), .reset_n(~rst));

    BiDirSeek #(.GD_READ_LEN(GD_READ_LEN), .OCC_AW(OCC_AW), .OCC_BASE(OCC_BASE)) the_bex (
        .clk           (clk),
        .rst           (rst),
        .gd_read       (gd_read),
        .pos_in        (pos),
        .start         (bex_start),
        .pos_out       (nxt_pos),
        .finish        (bex_finish),
        .busy          (bex_busy),
        .m_axis_emout  (axis_em_to_rs.master),
        .m_axi_occlu   (m_axi_occlu),
        .acc_cnt_in    (acc_cnt_in),
        .acc_cnt_valid (acc_cnt_valid),
        .pri_pos_in    (pri_pos_in),
        .pri_pos_valid (pri_pos_valid),
        .min_mlen_in   (min_mlen_in),
        .min_mlen_valid(min_mlen_valid),
        .bwt_len_in    (bwt_len_in),
        .bwt_len_valid (bwt_len_valid),
        .min_intv_in   (min_intv),
        .min_intv_valid(min_intv_valid)
    );

    wire rs_bypass = status != S_Seeding;
    ReseedFilter the_rsfil (
        .clk            (clk),
        .rst            (rst),
        .rs_min_len     (min_rslen_in),
        .rs_max_intv    (max_rsintv_in),
        .rs_params_valid(rs_params_valid),
        .bypass         (rs_bypass),
        .s_axis_emin    (axis_em_to_rs.slave),
        .m_axis_rsout   (axis_rs_to_fifo.master),
        .m_axis_emout   (axis_rs_to_fil1.master)
    );

    assign fifo_ready = status == S_ChkFifo;
    StreamFifo #(.DW($bits(WorkingMem)), .AW(RESEED_QU_AW)) reseedFifo (
        .clk      (clk),
        .rst      (rst),
        .in_data  (axis_rs_to_fifo.tdata),
        .in_valid (axis_rs_to_fifo.tvalid),
        .in_ready (axis_rs_to_fifo.tready),
        .out_data (fifo_tdata),
        .out_valid(fifo_tvalid),
        .out_ready(fifo_ready)
    );

    MemFilter1 the_fil1 (
        .clk         (clk),
        .rst         (rst),
        .start       (fil1_start),
        .stop        (fil1_stop),
        .finish      (fil1_finish),
        .busy        (fil1_busy),
        .s_axis_emin (axis_rs_to_fil1.slave),
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

endmodule