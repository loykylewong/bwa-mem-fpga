// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180730

`default_nettype none

`include "./s00_defines.sv"
module Extension
    import BwaMemDefines::*;
(
    input wire clk, rst,
    // input
    input wire Symbol a_in,
    input wire dir_in,
    input wire [KLS_W-1:0] k_in, l_in, s_in,
    input wire start,
    // output
    output logic [KLS_W-1:0] k_out, l_out, s_out,
    output logic finish,
    output logic busy,
    // bwt params acc_cnt and pos of '$' input
    input wire [KLS_W-1:0] acc_cnt_in[0:3],
    input wire [KLS_W-1:0] pri_pos_in,
    input wire bwt_params_valid,
    // occ lookup interface
    output logic [KLS_W-1:0] occ_k, occ_ks,
    output logic occ_lookup,
    input wire [KLS_W-1:0] occ_val_k[0:3], occ_val_ks[0:3],
    input wire occ_val_valid
);

    localparam logic [3:0] S_Idle       = 4'd00;
    localparam logic [3:0] S_Prepare    = 4'd01;
    localparam logic [3:0] S_Lookup     = 4'd02;
    localparam logic [3:0] S_Calc$      = 4'd03;
    localparam logic [3:0] S_CalcT      = 4'd04;
    localparam logic [3:0] S_CalcG      = 4'd05;
    localparam logic [3:0] S_CalcC      = 4'd06;
    localparam logic [3:0] S_CalcA      = 4'd07;
    // localparam logic [3:0] S_CalcN       = 4'd13;
    
    Symbol a;
    logic dir;
    logic [KLS_W-1:0] k, l, s;
    logic [KLS_W-1:0] k$, l$, s$;
    logic [KLS_W-1:0] kT, lT, sT;
    logic [KLS_W-1:0] kG, lG, sG;
    logic [KLS_W-1:0] kC, lC, sC;
    logic [KLS_W-1:0] kA, lA, sA;
    // logic [KLS_W-1:0] kN, lN, sN;

    logic [3:0] state, nxt_state;
    // state drive
    always_ff@(posedge clk) begin
        if(rst) begin
            state <= S_Idle;
        end
        else begin
            state <= nxt_state;
        end
    end
    // state trans
    always_comb begin
        nxt_state = state;
        case(state)
        S_Idle: begin
            if(start && a_in != sym_N) begin
                nxt_state = S_Prepare;
            end
        end // S_Idle:
        S_Prepare: begin
            nxt_state = S_Lookup;
        end // S_Prepare:
        S_Lookup: begin
            nxt_state = S_Calc$;
        end // S_Lookup:
        S_Calc$: begin
            if(occ_val_valid) begin
                if(a == sym_$) begin
                    nxt_state = S_Idle;
                end
                else begin
                    nxt_state = S_CalcT;
                end
            end
        end // S_Calc$:
        S_CalcT: begin
            if(a == sym_T) begin
                nxt_state = S_Idle;
            end
            else begin
                nxt_state = S_CalcG;
            end
        end // S_CalcT:
        S_CalcG: begin
            if(a == sym_G) begin
                nxt_state = S_Idle;
            end
            else begin
                nxt_state = S_CalcC;
            end
        end // S_CalcG:
        S_CalcC: begin
            if(a == sym_C) begin
                nxt_state = S_Idle;
            end
            else begin
                nxt_state = S_CalcA;
            end
        end // S_CalcC:
        S_CalcA: begin
            // CalcA must be the last state if we never calc 'N'
            nxt_state = S_Idle;
        end // S_CalcA:
        default: begin
            nxt_state = state;
        end // default:
        endcase
    end

    // drive a, k, l, s, sumks, dir
    logic [KLS_W-1:0] sumks;
    always_ff @(posedge clk) begin : proc_a_k_l_s_sumks
        if(rst) begin
            a <= sym_$;
            k     <= 1'b0;
            l     <= 1'b0;
            s     <= 1'b0;
            sumks <= 1'b0;
            dir <= DirBackward;
        end 
        else if(state == S_Idle && nxt_state == S_Prepare) begin
            a <= dir_in == DirBackward ? a_in : Compl(a_in);
            k <= dir_in == DirBackward ? k_in : l_in;
            l <= dir_in == DirBackward ? l_in : k_in;
            s <= s_in;
            sumks <= (dir_in == DirBackward ? k_in : l_in) + s_in;
            dir <= dir_in;
        end
    end

    // drive occ lookup
    always_comb begin : proc_occ_lookup
        if(state == S_Prepare && nxt_state == S_Lookup) begin
            occ_lookup = 1'b1;
        end
        else begin
            occ_lookup = 1'b0;
        end
    end
    assign occ_k = k, occ_ks = sumks;
    
    // drive acc_cnt & pos$
    logic [KLS_W-1:0] acc_cnt[0:3];
    logic [KLS_W-1:0] pos$;
    always_ff @(posedge clk) begin : proc_acc_cnt
        if(rst) begin
            acc_cnt <= '{4{KLS_W'(0)}};
            pos$ <= 1'b0;
        end
        else if(bwt_params_valid) begin
            acc_cnt <= acc_cnt_in;
            pos$ <= pri_pos_in;
        end
    end

    // calculate
    always_ff @(posedge clk) begin : proc_calc$
        if(rst) begin
            k$ <= 1'b0; l$ <= 1'b0; s$ <= 1'b0;
        end
        else if(state == S_Lookup && nxt_state == S_Calc$) begin
            l$ <= l;
            k$ <= k > pos$ ? 1'b1 : 1'b0;
            s$ <= (sumks > pos$ && k <= pos$) ? 1'b1 : 1'b0;
        end
    end
    always_ff @(posedge clk) begin : proc_calcT
        if(rst) begin
            kT <= 1'd0; lT <= 1'd0; sT <= 1'd0;
        end
        else if(nxt_state == S_CalcT) begin
            lT <= l$ + s$;
            kT <= acc_cnt[3] + occ_val_k[3];
            sT <= occ_val_ks[3] - occ_val_k[3];
        end
    end
    always_ff @(posedge clk) begin : proc_calcG
        if(rst) begin
            kG <= 1'd0; lG <= 1'd0; sG <= 1'd0;
        end
        else if(nxt_state == S_CalcG) begin
            lG <= lT + sT;
            kG <= acc_cnt[2] + occ_val_k[2];
            sG <= occ_val_ks[2] - occ_val_k[2];
        end
    end
    always_ff @(posedge clk) begin : proc_calcC
        if(rst) begin
            kC <= 1'd0; lC <= 1'd0; sC <= 1'd0;
        end
        else if(nxt_state == S_CalcC) begin
            lC <= lG + sG;
            kC <= acc_cnt[1] + occ_val_k[1];
            sC <= occ_val_ks[1] - occ_val_k[1];
        end
    end
    always_ff @(posedge clk) begin : proc_calcA
        if(rst) begin
            kA <= 1'd0; lA <= 1'd0; sA <= 1'd0;
        end
        else if(nxt_state == S_CalcA) begin
            lA <= lC + sC;
            kA <= acc_cnt[0] + occ_val_k[0];
            sA <= occ_val_ks[0] - occ_val_k[0];
        end
    end

    // output
    always_ff @(posedge clk) begin : proc_output
        if(rst) begin
            k_out <= 1'b0;
            l_out <= 1'b0;
            s_out <= 1'b0;
        end
        else if(nxt_state == S_Idle) begin
            case(state)
            S_Idle: begin
                if(start && a_in == sym_N) begin
                    k_out <= 1'b0;
                    l_out <= 1'b0;
                    s_out <= 1'b0;
                end
            end
            S_CalcT: begin
                k_out <= dir == DirBackward ? kT : lT;
                l_out <= dir == DirBackward ? lT : kT;
                s_out <= sT;
            end // S_CalcT:
            S_CalcG: begin
                k_out <= dir == DirBackward ? kG : lG;
                l_out <= dir == DirBackward ? lG : kG;
                s_out <= sG;
            end // S_CalcG:
            S_CalcC: begin
                k_out <= dir == DirBackward ? kC : lC;
                l_out <= dir == DirBackward ? lC : kC;
                s_out <= sC;
            end // S_CalcC:
            S_CalcA: begin
                k_out <= dir == DirBackward ? kA : lA;
                l_out <= dir == DirBackward ? lA : kA;
                s_out <= sA;
            end
            endcase // state
        end
    end
    always_ff @(posedge clk) begin : proc_finish
        if(rst) begin
            finish <= 1'b0;
        end
        else begin
            finish <= (state != S_Idle && nxt_state == S_Idle
                || state == S_Idle && start && a_in == sym_N);
        end
    end
    assign busy = state != S_Idle;
endmodule
