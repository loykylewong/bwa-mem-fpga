// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180806

`default_nettype none

`include "./s00_defines.sv"
module BiDirEmSeek  // Obsolete
    import BwaMemDefines::*;
#(
    parameter GD_READ_LEN = 78,
    // POW_W moved into package BwaMemDefines
    // parameter POS_W       = 8
    parameter integer OCC_AW = 40,
    parameter logic [OCC_AW - 1 : 0] OCC_BASE = 40'h00_0000_0000 // must be align to 64G
)(
    input wire clk, rst,
    input wire Symbol gd_read[0 : GD_READ_LEN - 1],
    input wire [POS_W - 1 : 0] pos_in,
    input wire start,
    output logic [POS_W - 1 : 0] pos_out,
    output logic finish,
    output logic busy,
    Axi4StreamIf.master m_axis_emout,
    Axi4LiteIf.master m_axi_occlu,
    input wire [KLS_W-1:0] acc_cnt_in[0:3],
    input wire acc_cnt_valid,
    input wire [KLS_W-1:0] pri_pos_in,
    input wire pri_pos_valid,
    input wire [KLS_W-1:0] bwt_len_in,
    input wire bwt_len_valid,
    input wire [POS_W-1:0] min_mlen_in,
    input wire min_mlen_valid
);

    localparam logic [3:0] S_Idle       = 4'd00;
    localparam logic [3:0] S_FwdStart   = 4'd01;
    localparam logic [3:0] S_FwdWait    = 4'd02;
    localparam logic [3:0] S_WrFifo     = 4'd03;
    localparam logic [3:0] S_NoWrFifo   = 4'd04;
    localparam logic [3:0] S_RdFifo     = 4'd05;
    localparam logic [3:0] S_BwdPrepare = 4'd06;
    localparam logic [3:0] S_BwdStart   = 4'd07;
    localparam logic [3:0] S_BwdWait    = 4'd08;
    localparam logic [3:0] S_Output     = 4'd09;
    localparam logic [3:0] S_NoOutput   = 4'd10;
    logic [3:0] state, nxt_state;

    // i (lower working boundary) & j (upper working boundary)
    logic [POS_W - 1 : 0] i0, j0;   // register last time j1, k1
    logic [POS_W - 1 : 0] i1, j1;   // idx for ex input

    // connections for module extension
    logic [KLS_W - 1 : 0] k0, l0, s0;    // extension k, l, s input
    wire  [KLS_W - 1 : 0] k1, l1, s1;    // extension k, l, s output

    wire ex_start = state == S_FwdStart || state == S_BwdStart;
    wire ex_finish;             // extension finish
    wire Symbol ex_a;
    logic dir;    
    Symbol read[0 : GD_READ_LEN - 1];
    assign ex_a = read[dir == DirForward ? j1 : i1];

    // connections for working fifo
    wire fifo_wr = state == S_WrFifo;
    wire fifo_rd = state == S_RdFifo;
    wire fifo_empty;
    wire WorkingMem fifo_din, fifo_qout;
    assign fifo_din = {j0, i0, s0, l0, k0};

    wire [KLS_W - 1 : 0] fifo_k = fifo_qout.k;
    wire [KLS_W - 1 : 0] fifo_l = fifo_qout.l;
    wire [KLS_W - 1 : 0] fifo_s = fifo_qout.s;
    wire [POS_W - 1 : 0] fifo_i = fifo_qout.i;
    wire [POS_W - 1 : 0] fifo_j = fifo_qout.j;

    // pos
    logic [POS_W - 1 : 0] pos;
    always_ff @(posedge clk) begin : proc_pos
        if(rst) begin
            pos <= 0;
        end
        else if(state == S_Idle && nxt_state == S_FwdStart) begin
            pos <= pos_in;
        end
    end
    // read
    always_ff @(posedge clk) begin : proc_read
        if(rst) begin
            read <= '{GD_READ_LEN{sym_N}};
        end
        else if(state == S_Idle && nxt_state == S_FwdStart) begin
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
        else if(bwt_len_valid) begin
            bwt_len <= bwt_len_in;
        end
    end
    // i0, j0, i1, j1
    // always_ff @(posedge clk) begin : proc_ij0
    //     if(rst) begin
    //         i0 <= '0;
    //         j0 <= '0;
    //     end
    //     else if(state == S_Idle && nxt_state == S_FwdStart) begin
    //         i0 <= pos_in;
    //         j0 <= pos_in - 1'b1;
    //     end
    //     else if(state == S_BwdPrepare && nxt_state == S_BwdStart) begin
    //         i0 <= fifo_i;
    //         j0 <= fifo_j;
    //     end
    // end
    always_ff @(posedge clk) begin : proc_ij
        if(rst) begin
            i1 <= '0;
            j1 <= '0;
            i0 <= '0;
            j0 <= '0;
        end
        else if(nxt_state == S_FwdStart) begin
            if(state == S_Idle) begin
                i1 <= pos_in;
                j1 <= pos_in;
                i0 <= pos_in;
                j0 <= pos_in - 1'b1;
            end
            else begin
                // i1 not change
                j1 <= j1 + 1'b1;
                i0 <= i1;
                j0 <= j1;
            end
        end
        else if(nxt_state == S_BwdStart) begin
            if(state == S_BwdPrepare) begin
                i1 <= fifo_i - 1'b1;
                j1 <= fifo_j;
                i0 <= fifo_i;
                j0 <= fifo_j;
            end
            else begin
                i1 <= i1 - 1'b1;
                // j0 not change
                i0 <= i1;
                j0 <= j1;
            end
        end
    end
    // always_ff @(posedge clk) begin : proc_j1
    //     if(rst) begin
    //         j1 <= '0;
    //     end
    //     else if(nxt_state == S_FwdStart) begin
    //         if(state == S_Idle) begin
    //             j1 <= pos_in;
    //         end
    //         else begin
    //             j1 <= j1 + 1'b1;
    //         end
    //     end
    //     else if(nxt_state == S_BwdStart) begin
    //         if(state == S_BwdPrepare) begin
    //             j1 <= fifo_j;
    //         end
    //     end
    // end

    // dir
    always_ff @(posedge clk) begin : proc_dir
        if(rst) begin
            dir <= DirForward;
        end
        else if(nxt_state == S_FwdStart) begin
            dir <= DirForward;
        end
        else if(nxt_state == S_BwdStart) begin
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
        else if(nxt_state == S_FwdStart) begin
            if(state == S_Idle) begin
                k0 <= 1'd0;
                l0 <= 1'd0;
                s0 <= bwt_len;
            end
            else begin
                k0 <= k1;
                l0 <= l1;
                s0 <= s1;
            end
        end
        else if(nxt_state == S_BwdStart) begin
            if(state == S_BwdPrepare) begin
                k0 <= fifo_k;
                l0 <= fifo_l;
                s0 <= fifo_s;
            end
            else begin
                k0 <= k1;
                l0 <= l1;
                s0 <= s1;
            end
        end
    end

    // need output
    wire need_out = s1 != s0 && fifo_j - i0 >= min_mlen;

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
                nxt_state = S_FwdStart;
            end
        end // S_Idle:
        S_FwdStart: begin
            nxt_state = S_FwdWait;
        end // S_FwdStart:
        S_FwdWait: begin
            if(ex_finish) begin
                if(s1 != s0 && s0 != bwt_len) begin
                    nxt_state = S_WrFifo;
                end
                else begin
                    nxt_state = S_NoWrFifo;
                end
            end
        end // S_FwdWait:
        S_WrFifo: begin
            if(s1 != 0) begin
                nxt_state = S_FwdStart;
            end
            else begin
                nxt_state = S_RdFifo;
            end
        end // S_WrFifo:
        S_NoWrFifo: begin
            if(s1 != 0) begin
                nxt_state = S_FwdStart;
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
        S_RdFifo: begin
            nxt_state = S_BwdPrepare;
        end // S_BwdRdFifo:
        S_BwdPrepare: begin
            nxt_state = S_BwdStart;
        end // S_BwdPrepare:
        S_BwdStart: begin
            nxt_state = S_BwdWait;
        end // S_FwdStart:
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
                if(s1 != 1'b0) begin
                    nxt_state = S_BwdStart;
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
            if(s1 != 1'd0) begin
                nxt_state = S_BwdStart;
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
        default: begin
            nxt_state = state;
        end // default:
        endcase // state
    end

    ScFifo2 #(.DW($bits(WorkingMem)), .AW(BEX_QU_AW)) the_queue (
        .clk     (clk),
        .din     (fifo_din),
        .write   (fifo_wr),
        .read    (fifo_rd),
        .dout    (fifo_qout),
        .wr_cnt  (),
        .rd_cnt  (),
        .data_cnt(),
        .full    (),
        .empty   (fifo_empty)
    );

    wire [KLS_W - 1 : 0] occ_k, occ_ks, occ_val_k[0 : 3], occ_val_ks[0 : 3];
    wire occ_lookup, occ_val_valid;

    Extension the_ex (
        .clk          (clk),
        .rst          (rst),
        .k_in         (k0),
        .l_in         (l0),
        .s_in         (s0),
        .a_in         (ex_a),
        .dir_in       (dir),
        .start        (ex_start),
        .k_out        (k1),
        .l_out        (l1),
        .s_out        (s1),
        .finish       (ex_finish),
        .busy         (),
        .acc_cnt_in   (acc_cnt_in),
        .acc_cnt_valid(acc_cnt_valid),
        .pri_pos_in   (pri_pos_in),
        .pri_pos_valid(pri_pos_valid),
        .occ_k        (occ_k),
        .occ_ks       (occ_ks),
        .occ_lookup   (occ_lookup),
        .occ_val_k    (occ_val_k),
        .occ_val_ks   (occ_val_ks),
        .occ_val_valid(occ_val_valid)
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
    always_comb m_axis_emout.tvalid = state == S_Output;
    always_comb m_axis_emout.tstrb = '1;
    always_comb m_axis_emout.tkeep = '1;
    always_comb m_axis_emout.tlast = 1'b0;
    // pos_out
    always_ff @(posedge clk) begin : proc_pos_out
        if(rst) begin
            pos_out <= '0;
        end 
        else if(s1 == 1'b0) begin
            if(state == S_WrFifo || state == S_NoWrFifo) begin
                pos_out <= read[j1] == sym_N ? j1 + 1'b1 : j1;
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

