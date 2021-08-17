// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180821

`default_nettype none
`include "./s00_defines.sv"

// read to mem(seed) with 'all' 3 phase : SmpFwd, BiDir & Reseed
module ReadMemReseed3
    import BwaMemDefines::*;
#(
    parameter integer READ_LEN  = 76,
    // POW_W moved into package BwaMemDefines
    // parameter POS_W       = 8,
    parameter integer OCC_AW = 40,
    parameter logic [OCC_AW - 1 : 0] OCC_BASE = 40'h00_0000_0000, // must be align to 64G
    parameter integer FILTER_GRP_SIZE = 2,
    parameter integer BIDIREX_QU_AW = 8,
    parameter integer RESEED_QU_AW = 6
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
    input wire [KLS_W - 1 : 0] pri_pos_in,
    input wire [KLS_W - 1 : 0] bwt_len_in,
    input wire bwt_params_valid,
    input wire [POS_W - 1 : 0] min_mlen_in,
    input wire min_mlen_valid,
    input wire [POS_W - 1 : 0] rs_min_mlen_in,
    input wire [KLS_W - 1 : 0] rs_max_intv_in,
    input wire rs_params_valid,
    input wire [POS_W - 1 : 0] sf_mlen_in,
    input wire [KLS_W - 1 : 0] sf_max_intv_in,
    input wire sf_params_valid
);
    localparam GD_READ_LEN = READ_LEN + 2;

    Symbol gd_read[0 : GD_READ_LEN - 1];
    logic [POS_W - 1 : 0] pos;
    wire  [POS_W - 1 : 0] nxt_pos;

    logic  bex_start, bi_dir;
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
    wire   asm_last;

    wire ReseedMem fifo_tdata;
    wire fifo_tvalid;
    wire fifo_ready;

    logic [1:0] wait_cnt;

    localparam logic [3:0] S_Idle          = 4'd0;
    localparam logic [3:0] S_SmpFwdSeeding = 4'd1;
    localparam logic [3:0] S_SFWaitFilter  = 4'd2;
    localparam logic [3:0] S_BiDirSeeding  = 4'd3;
    localparam logic [3:0] S_BDWaitFilter  = 4'd4;
    localparam logic [3:0] S_WaitRsFifo    = 4'd5;
    localparam logic [3:0] S_CheckRsFifo   = 4'd6;
    localparam logic [3:0] S_Reseeding     = 4'd7;
    localparam logic [3:0] S_RSWaitFilter  = 4'd8;
    logic [3:0] state, nxt_sts;

    always_ff @(posedge clk) begin : proc_state
        if(rst) begin
            state <= S_Idle;
        end
        else begin
            state <= nxt_sts;
        end
    end

    always_comb begin : proc_nxt_sts
        nxt_sts = state;
        case(state)
        S_Idle : begin
            if(start) begin
                nxt_sts = S_SmpFwdSeeding;
            end
        end // S_Idle :
        S_SmpFwdSeeding : begin
            if(bex_finish && nxt_pos >= GD_READ_LEN) begin
                nxt_sts = S_SFWaitFilter;
            end
        end // S_SmpFwdSeeding :
        S_SFWaitFilter : begin
            if(fil2_finish) begin
                nxt_sts = S_BiDirSeeding;
            end
        end
        S_BiDirSeeding : begin
            if(bex_finish && nxt_pos >= GD_READ_LEN) begin
                nxt_sts = S_BDWaitFilter;
            end
        end // S_BiDirSeeding :
        S_BDWaitFilter : begin
            if(fil2_finish) begin
                nxt_sts = S_WaitRsFifo;
            end
        end
        S_WaitRsFifo : begin
            if(wait_cnt == 2'd2) begin
                nxt_sts = S_CheckRsFifo;
            end
        end
        S_CheckRsFifo : begin
            if(fifo_tvalid) begin
                nxt_sts = S_Reseeding;
            end
            else begin
                nxt_sts = S_RSWaitFilter;
            end
        end // S_CheckRsFifo :
        S_Reseeding : begin
            if(bex_finish) begin
                nxt_sts = S_CheckRsFifo;
            end
        end // S_Reseeding :
        S_RSWaitFilter: begin
            if(asm_last) begin
                nxt_sts = S_Idle;
            end
        end
        endcase
    end

    always_ff @(posedge clk) begin : proc_wait_cnt
        if(rst) begin
            wait_cnt <= 1'b0;
        end 
        else if (state == S_BDWaitFilter && fil2_finish) begin
            wait_cnt <= 1'b0;
        end
        else if (state == S_WaitRsFifo) begin
            wait_cnt <= wait_cnt + 1'b1;
        end
    end

    always_ff @(posedge clk) begin : proc_gd_read
        if(rst) begin
            gd_read <= '{GD_READ_LEN{sym_N}};
        end 
        else if(state == S_Idle /*&& start*/) begin
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
        else if(state == S_Idle /*&& start*/) begin
            id <= read_id;
        end
    end

    always_ff @(posedge clk) begin : proc_pos
        if(rst) begin
            pos <= '0;
        end
        else if(state == S_Idle /*&& start*/) begin
            pos <= 1'b1;
        end
        else if(state == S_SmpFwdSeeding && bex_finish /*&& nxt_pos < GD_READ_LEN*/) begin
            pos <= nxt_pos; // nxt_pos?? or next multple of 20 pos??
        end
        else if(state == S_SFWaitFilter /*&& fil2_finish*/) begin
            pos <= 1'b1;
        end
        else if(state == S_BiDirSeeding && bex_finish /*&& nxt_pos < GD_READ_LEN*/) begin
            pos <= nxt_pos;
        end
        else if(state == S_CheckRsFifo) begin
            // if(fifo_tvalid /*nxt_sts == S_Reseeding*/) begin
                pos <= POS_W'(((POS_W+1)'(fifo_tdata.i) + fifo_tdata.j + 1'b1) >> 1);
            // end
            //// else if(nxt_sts == S_WaitFilter) begin
            ////     pos <= '0;
            //// end
        end
    end

    always_ff @(posedge clk) begin : proc_bi_dir
        if(rst) begin
            bi_dir <= 1'b0;
        end
        else if(state == S_Idle /*&& start*/) begin
            bi_dir <= 1'b0;
        end
        else if(state == S_SFWaitFilter /*&& fil2_finish*/) begin
            bi_dir <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin : proc_bex_start
        if(rst) begin
            bex_start <= 1'b0;
        end 
        else if(state == S_Idle && start) begin
            bex_start <= 1'b1;
        end
        else if(state == S_SmpFwdSeeding && bex_finish && nxt_pos < GD_READ_LEN) begin
            bex_start <= 1'b1;
        end
        else if(state == S_SFWaitFilter && fil2_finish) begin
            bex_start <= 1'b1;
        end
        else if(state == S_BiDirSeeding && bex_finish && nxt_pos < GD_READ_LEN) begin
            bex_start <= 1'b1;
        end
        else if(state == S_CheckRsFifo && fifo_tvalid) begin
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
        else if(state == S_Idle /*&& start*/) begin
            min_intv <= '0;
        end
        else if(state == S_CheckRsFifo /*&& fifo_tvalid*/) begin
            min_intv <= fifo_tdata.s;
        end
    end

    always_ff @(posedge clk) begin : proc_min_intv_valid
        if(rst) begin
            min_intv_valid <= 1'b0;
        end
        else if(state == S_Idle && start) begin
            min_intv_valid <= 1'b1;
        end
        else if(state == S_CheckRsFifo && fifo_tvalid) begin
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
        else if(state == S_Idle && start) begin
            fil1_start <= 1'b1;
        end
        else if(state == S_SFWaitFilter && fil2_finish) begin
            fil1_start <= 1'b1;
        end
        else if(state == S_BDWaitFilter && fil2_finish) begin
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
        else if(state == S_SmpFwdSeeding && bex_finish && nxt_pos >= GD_READ_LEN) begin
            fil1_stop <= 1'b1;
        end
        else if(state == S_BiDirSeeding && bex_finish && nxt_pos >= GD_READ_LEN) begin
            fil1_stop <= 1'b1;
        end
        else if(state == S_CheckRsFifo && !fifo_tvalid) begin
            fil1_stop <= 1'b1;
        end
        else begin
            fil1_stop <= 1'b0;
        end
    end

    logic gen_last;
    always_ff @(posedge clk) begin : proc_gen_last
        if(rst) begin
            gen_last <= 1'b0;
        end
        else if(state == S_Idle /*&& start*/) begin
            gen_last <= 1'b0;
        end
        //else if(state == S_SFWaitFilter /*&& fil2_finish*/) begin
        //    gen_last <= 1'b0;
        //end
        else if(state == S_BDWaitFilter && fil2_finish) begin
            gen_last <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin : proc_finish
        if(rst) begin
            finish <= 1'b0;
        end
        else if(state == S_RSWaitFilter && asm_last) begin
            finish <= 1'b1;
        end
        else begin
            finish <= 1'b0;
        end
    end

    assign busy = state != S_Idle;

    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_em_to_fil1  (.clk(clk), .reset_n(~rst));
    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_fil1_to_fil2(.clk(clk), .reset_n(~rst));
    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_fil2_to_rs  (.clk(clk), .reset_n(~rst));
    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_rs_to_fifo  (.clk(clk), .reset_n(~rst));
    Axi4StreamIf #(.DW_BYTES($bits(WorkingMem)/8)) axis_rs_to_asm   (.clk(clk), .reset_n(~rst));

    BiDirEmSeek3 #(
        .GD_READ_LEN(GD_READ_LEN),
        .OCC_AW(OCC_AW),
        .OCC_BASE(OCC_BASE),
        .BEX_QU_AW(BIDIREX_QU_AW)
    ) the_bex (
        .clk             (clk),
        .rst             (rst),
        .gd_read         (gd_read),
        .pos_in          (pos),
        .bi_dir_in       (bi_dir),
        .start           (bex_start),
        .pos_out         (nxt_pos), 
        .finish          (bex_finish),
        .busy            (bex_busy),
        .m_axis_emout    (axis_em_to_fil1.master),
        .m_axi_occlu     (m_axi_occlu),
        .acc_cnt_in      (acc_cnt_in),
        .pri_pos_in      (pri_pos_in),
        .bwt_len_in      (bwt_len_in),
        .bwt_params_valid(bwt_params_valid),
        .min_mlen_in     (min_mlen_in),
        .min_mlen_valid  (min_mlen_valid),
        .min_intv_in     (min_intv),
        .min_intv_valid  (min_intv_valid),
        .sf_mlen_in      (sf_mlen_in),
        .sf_max_intv_in  (sf_max_intv_in),
        .sf_params_valid (sf_params_valid)
    );

    MemFilter1 #(.GRP_SIZE(FILTER_GRP_SIZE)) the_fil1 (
        .clk         (clk),
        .rst         (rst),
        .start       (fil1_start),
        .stop        (fil1_stop),
        .finish      (fil1_finish),
        .busy        (fil1_busy),
        .s_axis_emin (axis_em_to_fil1.slave),
        .m_axis_emout(axis_fil1_to_fil2.master)
    );

    MemFilter2 #(.GRP_SIZE(FILTER_GRP_SIZE)) the_fil2 (
        .clk         (clk),
        .rst         (rst),
        .gen_last    (gen_last),
        .start       (fil2_start),
        .stop        (fil2_stop),
        .finish      (fil2_finish),
        .busy        (fil2_busy),
        .s_axis_emin (axis_fil1_to_fil2.slave),
        .m_axis_emout(axis_fil2_to_rs.master)
    );

    wire rs_bypass = !(state == S_BiDirSeeding || state == S_BDWaitFilter);
    ReseedFilter the_rsfil (
        .clk            (clk),
        .rst            (rst),
        .rs_min_len     (rs_min_mlen_in),
        .rs_max_intv    (rs_max_intv_in),
        .rs_params_valid(rs_params_valid),
        .bypass         (rs_bypass),
        .s_axis_emin    (axis_fil2_to_rs.slave),
        .m_axis_rsout   (axis_rs_to_fifo.master),
        .m_axis_emout   (axis_rs_to_asm.master)
    );

    assign fifo_ready = state == S_CheckRsFifo;
    wire [RESEED_QU_AW : 0] fifo_data_cnt;
    wire WorkingMem rsfil_out = axis_rs_to_fifo.tdata;
    wire ReseedMem rsfifo_in;
    assign rsfifo_in.j = rsfil_out.j;
    assign rsfifo_in.i = rsfil_out.i;
    assign rsfifo_in.s = rsfil_out.s;
    StreamFifo #(.DW($bits(ReseedMem)), .AW(RESEED_QU_AW)) reseedFifo (
        .clk      (clk),
        .rst      (rst),
        .in_data  (rsfifo_in),
        .in_valid (axis_rs_to_fifo.tvalid),
        .in_ready (axis_rs_to_fifo.tready),
        .out_data (fifo_tdata),
        .out_valid(fifo_tvalid),
        .out_ready(fifo_ready),
        .data_cnt (fifo_data_cnt)
    );

    assign asm_last = axis_rs_to_asm.tlast & axis_rs_to_asm.tready & axis_rs_to_asm.tvalid;
    MemAssem the_assem (
        .clk         (clk),
        .rst         (rst),
        .read_id     (id),
        .s_axis_emin (axis_rs_to_asm.slave),
        .m_axis_emout(m_axis_emout)
    );

endmodule