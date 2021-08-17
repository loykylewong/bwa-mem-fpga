// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180828

`default_nettype none

`include "./s00_defines.sv"
module BiDirEmSeek3
    import BwaMemDefines::*;
#(
    parameter integer GD_READ_LEN = 78,
    // POW_W moved into package BwaMemDefines
    // parameter POS_W       = 8
    parameter integer OCC_AW = 40,
    parameter logic [OCC_AW - 1 : 0] OCC_BASE = 40'h00_0000_0000, // must be align to 2^(clog2(OccTableSize))
    parameter integer BEX_QU_AW = 8
)(
    input wire clk, rst,
    input wire Symbol gd_read[0 : GD_READ_LEN - 1],
    input wire [POS_W - 1 : 0] pos_in,
    input wire bi_dir_in,
    input wire start,
    output logic [POS_W - 1 : 0] pos_out,
    output logic finish,
    output logic busy,
    Axi4StreamIf.master m_axis_emout,
    Axi4LiteIf.master m_axi_occlu,
    input wire [KLS_W-1:0] acc_cnt_in[0:3],
    input wire [KLS_W-1:0] pri_pos_in,
    input wire [KLS_W-1:0] bwt_len_in,
    input wire bwt_params_valid,
    input wire [POS_W-1:0] min_mlen_in,
    input wire min_mlen_valid,
    input wire [KLS_W-1:0] min_intv_in,
    input wire min_intv_valid,
    input wire [POS_W-1:0] sf_mlen_in,
    input wire [KLS_W-1:0] sf_max_intv_in,
    input wire sf_params_valid
);

    localparam logic [4:0] S_Idle       = 5'd00;
    localparam logic [4:0] S_FwdPrep0   = 5'd01;
    localparam logic [4:0] S_FwdReadSym = 5'd02;
    localparam logic [4:0] S_FwdStart   = 5'd03;
    localparam logic [4:0] S_FwdWait    = 5'd04;
    localparam logic [4:0] S_SmpFwdChk  = 5'd05;
    localparam logic [4:0] S_SmpFwdOut  = 5'd18;
    localparam logic [4:0] S_WrFifo     = 5'd06;
    localparam logic [4:0] S_NoWrFifo   = 5'd07;
    localparam logic [4:0] S_FwdPrep1   = 5'd08;
    localparam logic [4:0] S_RdFifo     = 5'd09;
    localparam logic [4:0] S_FifoRS     = 5'd10;
    localparam logic [4:0] S_BwdPrep0   = 5'd11;
    localparam logic [4:0] S_BwdReadSym = 5'd12;    
    localparam logic [4:0] S_BwdStart   = 5'd13;
    localparam logic [4:0] S_BwdWait    = 5'd14;
    localparam logic [4:0] S_Output     = 5'd15;
    localparam logic [4:0] S_NoOutput   = 5'd16;
    localparam logic [4:0] S_BwdPrep1   = 5'd17;
    logic [4:0] state, nxt_state;

    // i (lower working boundary) & j (upper working boundary)
    logic [POS_W - 1 : 0] i0, j0;   // register last time j1, k1
    logic [POS_W - 1 : 0] i1, j1;   // idx for ex input

    // connections for module extension
    logic [KLS_W - 1 : 0] k0, l0, s0;    // extension k, l, s input
    wire  [KLS_W - 1 : 0] k1, l1, s1;    // extension k, l, s output

    logic dir;    
    Symbol read[0 : GD_READ_LEN - 1];

    // wire ex_start = state == S_FwdStart || state == S_BwdStart;
    logic ex_start;
    always_ff @(posedge clk) begin : proc_ex_start
        if(rst) begin
            ex_start <= 1'b0;
        end
        // else if(state == S_FwdPrep0 || state == S_FwdPrep1 ||
        //         state == S_BwdPrep0 || state == S_BwdPrep1) begin
        else if(state == S_FwdReadSym || state == S_BwdReadSym) begin
            ex_start <= 1'b1;
        end
        else begin
            ex_start <= 1'b0;
        end
    end
    wire ex_finish;             // extension finish
    // wire Symbol ex_a;
    // assign ex_a = read[dir == DirForward ? j1 : i1];
    Symbol ex_a;
    always_ff @(posedge clk) begin : proc_ex_a
        if(rst) begin
            ex_a <= 1'b0;
        end
        // else if(state == S_FwdPrep0 || state == S_FwdPrep1) begin
        else if(state == S_FwdReadSym) begin
            ex_a <= read[j1];
        end
        // else if(state == S_BwdPrep0 || state == S_BwdPrep1) begin
        else if(state == S_BwdReadSym) begin
            ex_a <= read[i1];
        end
    end

    // connections for working fifo
    wire fifo_wr = state == S_WrFifo;
    wire fifo_rd = state == S_RdFifo;
    wire fifo_empty;
    wire WorkingMem fifo_din, fifo_qout;
    assign fifo_din = {j0, i0, s0, l0, k0};

    logic [KLS_W - 1 : 0] fifo_k;// = fifo_qout.k;
    logic [KLS_W - 1 : 0] fifo_l;// = fifo_qout.l;
    logic [KLS_W - 1 : 0] fifo_s;// = fifo_qout.s;
    logic [POS_W - 1 : 0] fifo_i;// = fifo_qout.i;
    logic [POS_W - 1 : 0] fifo_j;// = fifo_qout.j;
    always_ff @(posedge clk) begin : proc_fifo_out_regslice
        if(rst) begin
            fifo_k <= '0;
            fifo_l <= '0;
            fifo_s <= '0;
            fifo_i <= '0;
            fifo_j <= '0;            
        end else begin
            fifo_k <= fifo_qout.k;
            fifo_l <= fifo_qout.l;
            fifo_s <= fifo_qout.s;
            fifo_i <= fifo_qout.i;
            fifo_j <= fifo_qout.j;            
        end
    end

    // pos & bi_dir
    logic [POS_W - 1 : 0] pos;
    logic bi_dir;
    always_ff @(posedge clk) begin : proc_pos
        if(rst) begin
            pos <= 1'b0;
            bi_dir <= 1'b0;
        end
        else if(state == S_Idle /*&& nxt_state == S_FwdPrep0*/) begin
            pos <= pos_in;
            bi_dir <= bi_dir_in;
        end
    end
    // read
    always_ff @(posedge clk) begin : proc_read
        if(rst) begin
            read <= '{GD_READ_LEN{sym_N}};
        end
        else if(state == S_Idle /*&& nxt_state == S_FwdPrep0*/) begin
            read <= gd_read;
        end
    end
    // min_mlen
    logic [POS_W - 1 : 0] min_mlen; // actually equal to min_len - 1
    always_ff @(posedge clk) begin : proc_min_mlen
        if(rst) begin
            min_mlen <= 1'b0;
        end
        else if(min_mlen_valid) begin
            min_mlen <= min_mlen_in - 1'b1;
        end
    end
    // bwt_len
    logic [KLS_W - 1 : 0] bwt_len;
    always_ff @(posedge clk) begin : proc_bwt_len
        if(rst) begin
            bwt_len <= 1'd0;
        end
        else if(bwt_params_valid) begin
            bwt_len <= bwt_len_in;
        end
    end
    // min_intv
    logic [KLS_W - 1 : 0] min_intv;
    always_ff @(posedge clk) begin : proc_min_intv
        if(rst) begin
            min_intv <= 1'd0;
        end 
        else if(min_intv_valid) begin
            min_intv <= min_intv_in;
        end
    end
    // sf_params
    logic [POS_W - 1 : 0] sf_mlen;
    logic [KLS_W - 1 : 0] sf_max_intv;
    always_ff @(posedge clk) begin : proc_sf_params
        if(rst) begin
            sf_mlen <= 1'b0;
            sf_max_intv <= 1'b0;
        end 
        else if(sf_params_valid) begin
            sf_mlen <= sf_mlen_in - 1'b1;
            sf_max_intv <= sf_max_intv_in;
        end
    end
    // i0, j0, i1, j1
    always_ff @(posedge clk) begin : proc_ij
        if(rst) begin
            i1 <= '0;
            j1 <= '0;
            i0 <= '0;
            j0 <= '0;
        end
        else begin
            // if(nxt_state == S_FwdPrep0) begin
            if(state == S_FwdPrep0) begin
                i1 <= pos_in;
                j1 <= pos_in;
                i0 <= pos_in;
                j0 <= pos_in - 1'b1;
            end
            // else if(nxt_state == S_FwdPrep1) begin
            else if(state == S_FwdPrep1) begin
                // i1 not change
                j1 <= j1 + 1'b1;
                i0 <= i1;
                j0 <= j1;
            end
            // else if(nxt_state == S_BwdPrep0) begin
            else if(state == S_BwdPrep0) begin
                i1 <= fifo_i - 1'b1;
                j1 <= fifo_j;
                i0 <= fifo_i;
                j0 <= fifo_j;
            end
            // else if(nxt_state == S_BwdPrep1) begin
            else if(state == S_BwdPrep1) begin
                i1 <= i1 - 1'b1;
                // j0 not change
                i0 <= i1;
                j0 <= j1;
            end
        end
    end

    // dir
    always_ff @(posedge clk) begin : proc_dir
        if(rst) begin
            dir <= DirForward;
        end
        else if(state == S_FwdPrep0) begin
            dir <= DirForward;
        end
        else if(state == S_BwdPrep0) begin
            dir <= DirBackward;
        end
    end
    // k0, l0, s0;
    always_ff @(posedge clk) begin : proc_kls0
        if(rst) begin
            k0 <= '0;
            l0 <= '0;
            s0 <= '0;
        end 
        else begin
            if(state == S_FwdPrep0) begin
                k0 <= 1'd0;
                l0 <= 1'd0;
                s0 <= bwt_len;
            end
            else if(state == S_FwdPrep1) begin
                k0 <= k1;
                l0 <= l1;
                s0 <= s1;
            end
            else if(state == S_BwdPrep0) begin
                k0 <= fifo_k;
                l0 <= fifo_l;
                s0 <= fifo_s;
            end
            else if(state == S_BwdPrep1) begin
                k0 <= k1;
                l0 <= l1;
                s0 <= s1;
            end
        end
    end

    // need output
    wire need_out = s1 != s0 && fifo_j - i0 >= min_mlen;
    // simple forward finish
    wire sf_finish = s1 == 1'b0 || j0 - i0 == sf_mlen;

    always_ff @(posedge clk) begin : proc_state
        if(rst) begin
            state <= S_Idle;
        end 
        else begin
            state <= nxt_state;
        end
    end
    always_comb begin
        nxt_state = state;
        case(state)
        S_Idle: begin
            if(start) begin
                nxt_state = S_FwdPrep0;
            end
        end // S_Idle:
        S_FwdPrep0: begin
            nxt_state = S_FwdReadSym;
        end // S_FwdPrep0:
        S_FwdReadSym: begin
            nxt_state = S_FwdStart;
        end // S_FwdPrep0:
        S_FwdStart: begin
            nxt_state = S_FwdWait;
        end // S_FwdStart:
        S_FwdWait: begin
            if(ex_finish) begin
                if(bi_dir) begin
                    if(s1 != s0 && s0 != bwt_len) begin
                        nxt_state = S_WrFifo;
                    end
                    else begin
                        nxt_state = S_NoWrFifo;
                    end
                end
                else begin
                    if(sf_finish) begin
                        nxt_state = S_SmpFwdChk;
                    end
                    else begin
                        nxt_state = S_FwdPrep1;
                    end
                end
            end
        end // S_FwdWait:
        S_SmpFwdChk: begin
            if(s0 <= sf_max_intv && j0 - i0 == sf_mlen) begin
                nxt_state = S_SmpFwdOut;
            end
            else begin
                nxt_state = S_Idle;
            end
        end // S_SmpFwdChk:
        S_SmpFwdOut: begin
            nxt_state = S_Idle;
        end // S_SmpFwdOut:
        S_WrFifo: begin
            // if(s1 != 0) begin
            if(s1 > min_intv) begin
                nxt_state = S_FwdPrep1;
            end
            else begin
                nxt_state = S_RdFifo;
            end
        end // S_WrFifo:
        S_NoWrFifo: begin
            // if(s1 != 0) begin
            if(s1 > min_intv) begin
                nxt_state = S_FwdPrep1;
            end
            else begin
                if(!fifo_empty) begin
                    nxt_state = S_RdFifo;
                end
                else begin
                    nxt_state = S_Idle;
                end
            end
        end // S_NoWrFifo:
        S_FwdPrep1: begin
            nxt_state = S_FwdReadSym;
        end // S_FwdPrep1:
        S_RdFifo: begin
            nxt_state = S_FifoRS;
        end // S_RdFifo:
        S_FifoRS: begin
            nxt_state = S_BwdPrep0;
        end // S_BwdRdFifo:
        S_BwdPrep0: begin
            nxt_state = S_BwdReadSym;
        end // S_BwdPrep0:
        S_BwdReadSym: begin
            nxt_state = S_BwdStart;
        end // S_BwdPrep0:
        S_BwdStart: begin
            nxt_state = S_BwdWait;
        end // S_BwdStart:
        S_BwdWait: begin
            if(ex_finish) begin
                if(need_out) begin
                    nxt_state = S_Output;
                end
                else begin
                    nxt_state = S_NoOutput;
                end
            end
        end // S_BwdWait:
        S_Output: begin
            if(m_axis_emout.tready) begin
                if(s1 > min_intv) begin
                    nxt_state = S_BwdPrep1;
                end
                else begin
                    if(!fifo_empty) begin
                        nxt_state = S_RdFifo;
                    end
                    else begin
                        nxt_state = S_Idle;
                    end
                end
            end
        end // S_Output:
        S_NoOutput: begin
            if(s1 > min_intv) begin
                nxt_state = S_BwdPrep1;
            end
            else begin
                if(!fifo_empty) begin
                    nxt_state = S_RdFifo;
                end
                else begin
                    nxt_state = S_Idle;
                end
            end
        end // S_NoOutput:
        S_BwdPrep1: begin
            nxt_state = S_BwdReadSym;
        end // S_BwdPrep1:
        default: begin
            nxt_state = state;
        end // default:
        endcase // state
    end

    wire [BEX_QU_AW - 1 : 0] fifo_data_cnt;
    ScFifo2 #(.DW($bits(WorkingMem)), .AW(BEX_QU_AW)) the_queue (
        .clk     (clk),
        .din     (fifo_din),
        .write   (fifo_wr),
        .read    (fifo_rd),
        .dout    (fifo_qout),
        .wr_cnt  (),
        .rd_cnt  (),
        .data_cnt(fifo_data_cnt),
        .full    (),
        .empty   (fifo_empty)
    );

    wire [KLS_W - 1 : 0] occ_k, occ_ks, occ_val_k[0 : 3], occ_val_ks[0 : 3];
    wire occ_lookup, occ_val_valid;

    Extension the_ex (
        .clk             (clk),
        .rst             (rst),
        .k_in            (k0),
        .l_in            (l0),
        .s_in            (s0),
        .a_in            (ex_a),
        .dir_in          (dir),
        .start           (ex_start),
        .k_out           (k1),
        .l_out           (l1),
        .s_out           (s1),
        .finish          (ex_finish),
        .busy            (),
        .acc_cnt_in      (acc_cnt_in),
        // .acc_cnt_valid(acc_cnt_valid),
        .pri_pos_in      (pri_pos_in),
        .bwt_params_valid(bwt_params_valid),
        .occ_k           (occ_k),
        .occ_ks          (occ_ks),
        .occ_lookup      (occ_lookup),
        .occ_val_k       (occ_val_k),
        .occ_val_ks      (occ_val_ks),
        .occ_val_valid   (occ_val_valid)
    );

    OccLookup #(.AW(OCC_AW), .OCC_BASE(OCC_BASE)) the_occlu (
        .clk        (clk),
        .rst        (rst),
        .k_in       (occ_k),
        .ks_in      (occ_ks),
        .start      (occ_lookup),
        .val_k      (occ_val_k),
        .val_ks     (occ_val_ks),
        .val_valid  (occ_val_valid),
        .m_axi_occlu(m_axi_occlu)
    );

    // emout
    always_comb m_axis_emout.tdata = fifo_din;//{j0, i0, s0, l0, k0};
    always_comb m_axis_emout.tvalid = state == S_Output
                                      || (state == S_SmpFwdOut);// S_SmpFwdChk && j0 - i0 == sf_mlen && s0 <= sf_max_intv);
    always_comb m_axis_emout.tstrb = '1;
    always_comb m_axis_emout.tkeep = '1;
    always_comb m_axis_emout.tlast = 1'b0;
    // pos_out
    always_ff @(posedge clk) begin : proc_pos_out
        if(rst) begin
            pos_out <= '0;
        end
        else if(bi_dir) begin
            if(s1 <= min_intv && (state == S_WrFifo || state == S_NoWrFifo)) begin
                // pos_out <= read[j1] == sym_N ? j1 + 1'b1 : j1;
                pos_out <= ex_a == sym_N ? j1 + 1'b1 : j1;
            end
        end
        else begin
            if(sf_finish && state == S_SmpFwdChk) begin
                // pos_out <= read[j1] == sym_N ? j1 + 1'b1 : j1;
                pos_out <= ex_a == sym_N ? j1 + 1'b1 : j1;
            end
        end
    end
    // finish
    always_ff @(posedge clk) begin : proc_finish
        if(rst) begin
            finish <= 1'b0;
        end 
        else if(state != S_Idle && nxt_state == S_Idle) begin
            finish <= 1'b1;
        end
        else begin
            finish <= 1'b0;
        end
    end
    assign busy = state != S_Idle;
endmodule // BiDirEmSeek

