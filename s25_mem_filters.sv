// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180809

`default_nettype none
`include "./s00_defines.sv"

// module MemFilter1
//     import BwaMemDefines::*;
// (
//     input wire clk, rst,
//     input wire start,
//     input wire stop,
//     output logic finish,
//     output logic busy,

//     Axi4StreamIf.slave s_axis_emin,
//     Axi4StreamIf.master m_axis_emout
// );
    
//     logic [2:0] state, nxt_state;
//     localparam logic [2:0] S_Idle   = 3'd0;
//     localparam logic [2:0] S_Wait   = 3'd1;
//     localparam logic [2:0] S_Judge  = 3'd2;
//     localparam logic [2:0] S_Output = 3'd3;
//     localparam logic [2:0] S_Flush  = 3'd4;

//     WorkingMem m[4];

//     wire in_handsk = s_axis_emin.tready & s_axis_emin.tvalid;
//     wire out_handsk = m_axis_emout.tready & m_axis_emout.tvalid;

//     always_ff @(posedge clk) begin : proc_m
//         if(rst) begin
//             m[0] <= '0;
//             m[1] <= '0;
//             m[2] <= '0;
//             m[3] <= '0;
//         end 
//         else if(in_handsk) begin
//             m[0] <= s_axis_emin.tdata;
//             m[1] <= m[0];
//             m[2] <= m[1];
//             m[3] <= m[2];
//         end
//         else if(state == S_Output && nxt_state == S_Wait) begin
//             m[1] <= '0;
//             m[2] <= '0;
//             m[3] <= '0;
//         end
//     end

//     wire ij_diff = m[0].i != m[1].i && m[0].j != m[1].j;

//     logic stop_r;
//     always_ff @(posedge clk) begin : proc_stop_r
//         if(rst) begin
//             stop_r <= '0;
//         end
//         else if(stop) begin
//             stop_r <= 1'b1;
//         end
//         else if(state == S_Flush) begin
//             stop_r <= 1'b0;
//         end
//     end

//     logic [1:0] cnt; 
//     always_ff @(posedge clk) begin : proc_cnt
//         if(rst) begin
//             cnt <= '0;
//         end 
//         else if(state == S_Judge && nxt_state == S_Output) begin
//             cnt <= 1'b0;
//         end
//         else if(state == S_Wait && nxt_state == S_Flush) begin
//             cnt <= 1'b1;
//         end
//         else if(state == S_Output || state == S_Flush) begin
//             if(out_handsk) begin
//                 cnt <= cnt + 1'b1;
//             end
//         end
//     end

//     always_ff @(posedge clk) begin : proc_state
//         if(rst) begin
//             state <= S_Idle;
//         end else begin
//             state <= nxt_state;
//         end
//     end
//     always_comb begin
//         nxt_state = state;
//         case (state)
//         S_Idle: begin
//             if(start) begin
//                 nxt_state = S_Wait;
//             end
//         end // S_Idle:
//         S_Wait: begin
//             if(in_handsk) begin
//                 nxt_state = S_Judge;
//             end
//             else if(stop_r) begin
//                 nxt_state = S_Flush;
//             end
//         end // S_Wait:
//         S_Judge: begin
//             if(ij_diff) begin
//                 nxt_state = S_Output;
//             end // if(ij_diff)
//             else begin
//                 nxt_state = S_Wait;
//             end
//         end // S_Judge:
//         S_Output: begin
//             if(cnt == 2'd2 & out_handsk) begin
//                 nxt_state = S_Wait;
//             end
//         end
//         S_Flush: begin
//             if(cnt == 2'd3 & out_handsk) begin
//                 nxt_state = S_Idle;
//             end
//         end
//         default: begin
//             nxt_state = state;
//         end
//         endcase
//     end

//     always_ff @(posedge clk) begin : proc_finish
//         if(rst) begin
//             finish <= 1'b0;
//         end 
//         else if(state == S_Flush && nxt_state == S_Idle) begin
//             finish <= 1'b1;
//         end
//         else begin
//             finish <= 1'b0;
//         end
//     end
//     assign busy = state != S_Idle;

//     wire WorkingMem emout = m[2'd3 - cnt];

//     always_comb s_axis_emin.tready = state == S_Wait;
//     always_comb m_axis_emout.tdata = emout;
//     always_comb m_axis_emout.tvalid = state == S_Output || state == S_Flush;

// endmodule // MemFilter1

module MemFilter1
    import BwaMemDefines::*;
#(
    parameter GRP_SIZE = 3
)(
    input wire clk, rst,
    input wire start,
    input wire stop,
    output logic finish,
    output logic busy,

    Axi4StreamIf.slave s_axis_emin,
    Axi4StreamIf.master m_axis_emout
);
    localparam ROW = GRP_SIZE + 1;
    
    logic [2:0] state, nxt_state;
    localparam logic [2:0] S_Idle   = 3'd0;
    localparam logic [2:0] S_Wait   = 3'd1;
    localparam logic [2:0] S_Judge  = 3'd2;
    localparam logic [2:0] S_Output = 3'd3;
    localparam logic [2:0] S_Clear  = 3'd4;
    localparam logic [2:0] S_Flush  = 3'd5;

    (* ram_style = "registers" *) WorkingMem m[ROW];

    wire in_handsk = s_axis_emin.tready & s_axis_emin.tvalid;
    wire out_handsk = m_axis_emout.tready & m_axis_emout.tvalid;

    genvar r;
    always_ff @(posedge clk) begin : proc_m
        if(rst) begin
            m[0] <= '0;
        end 
        else if(state == S_Idle && start) begin
            m[0] <= '0;
        end
        else if(in_handsk) begin
            m[0] <= s_axis_emin.tdata;
        end
    end
    generate
        for(r = 1; r < ROW; r++ ) begin
            always_ff @(posedge clk) begin : proc_m
                if(rst) begin
                    m[r] <= '0;
                end
                else if(state == S_Idle && start) begin
                    m[r] <= '0;
                end
                else if(in_handsk) begin
                    m[r] <= m[r - 1];
                end
                else if(state == S_Clear) begin
                    m[r] <= '0;
                end
            end
        end
    endgenerate

    wire ij_diff = m[0].i != m[1].i && m[0].j != m[1].j;

    logic stop_r;
    always_ff @(posedge clk) begin : proc_stop_r
        if(rst) begin
            stop_r <= '0;
        end
        else if(stop) begin
            stop_r <= 1'b1;
        end
        else if(state == S_Flush) begin
            stop_r <= 1'b0;
        end
    end

    localparam CW = $clog2(ROW);
    logic [CW - 1 : 0] cnt; 
    always_ff @(posedge clk) begin : proc_cnt
        if(rst) begin
            cnt <= '0;
        end 
        else if(state == S_Judge && ij_diff) begin
            cnt <= CW'(ROW - 1);
        end
        else if(state == S_Wait && stop_r) begin
            cnt <= CW'(ROW - 2);
        end
        else if(state == S_Output || state == S_Flush) begin
            if(out_handsk) begin
                if(cnt > 1'b0) begin
                    cnt <= cnt - 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk) begin : proc_state
        if(rst) begin
            state <= S_Idle;
        end else begin
            state <= nxt_state;
        end
    end
    always_comb begin
        nxt_state = state;
        case (state)
        S_Idle: begin
            if(start) begin
                nxt_state = S_Wait;
            end
        end // S_Idle:
        S_Wait: begin
            if(in_handsk) begin
                nxt_state = S_Judge;
            end
            else if(stop_r) begin
                nxt_state = S_Flush;
            end
        end // S_Wait:
        S_Judge: begin
            if(ij_diff) begin
                nxt_state = S_Output;
            end // if(ij_diff)
            else begin
                nxt_state = S_Wait;
            end
        end // S_Judge:
        S_Output: begin
            if(cnt == 1'd1 & out_handsk) begin
                nxt_state = S_Clear;
            end
        end
        S_Clear: begin
            nxt_state = S_Wait;
        end
        S_Flush: begin
            if(cnt == 1'd0 & out_handsk) begin
                nxt_state = S_Idle;
            end
        end
        default: begin
            nxt_state = state;
        end
        endcase
    end

    always_ff @(posedge clk) begin : proc_finish
        if(rst) begin
            finish <= 1'b0;
        end 
        else if(state == S_Flush && (cnt == 1'd0 & out_handsk)) begin
            finish <= 1'b1;
        end
        else begin
            finish <= 1'b0;
        end
    end
    assign busy = state != S_Idle;

    wire WorkingMem emout = m[cnt];

    always_comb s_axis_emin.tready = state == S_Wait;
    always_comb m_axis_emout.tdata = emout;
    always_comb m_axis_emout.tvalid = state == S_Output || state == S_Flush;
    always_comb m_axis_emout.tstrb = '1;
    always_comb m_axis_emout.tkeep = '1;
    always_comb m_axis_emout.tlast = '0;

endmodule // MemFilter1

module MemFilter2
    import BwaMemDefines::*;
#(
    parameter GRP_SIZE = 3
)(
    input wire clk, rst,
    input wire gen_last,
    input wire start,
    input wire stop,
    output logic finish,
    output logic busy,

    Axi4StreamIf.slave s_axis_emin,
    Axi4StreamIf.master m_axis_emout
);
    
    logic [2:0] state, nxt_state;
    localparam logic [2:0] S_Idle   = 3'd0;
    localparam logic [2:0] S_Wait   = 3'd1;
    localparam logic [2:0] S_Judge  = 3'd2;
    localparam logic [2:0] S_Output = 3'd3;
    localparam logic [2:0] S_Clear  = 3'd4;
    localparam logic [2:0] S_Flush  = 3'd5;

    localparam ROW = GRP_SIZE + 1;
    localparam COL = GRP_SIZE;
    // let idx(r, c) = r * COL + c;
    function automatic integer idx (input integer r, input integer c);  // "let" is not supported by vivado
        idx = r * COL + c;
    endfunction

    (* ram_style = "registers" *) WorkingMem m[ROW * COL];
    WorkingMem m_in[ROW * COL];

    wire in_handsk = s_axis_emin.tready & s_axis_emin.tvalid;
    wire out_handsk = m_axis_emout.tready & m_axis_emout.tvalid;
    wire out_cont = m_axis_emout.tready | ~m_axis_emout.tvalid;

    logic glast;
    always_ff @(posedge clk) begin : proc_glast
        if(rst) begin
            glast <= 1'b0;
        end
        else if(state == S_Idle & start) begin
            glast <= gen_last;
        end
    end

    always_comb begin
        m_in[0] = s_axis_emin.tdata;
    end
    genvar r, c;
    generate
        for(c = 1; c < COL; c++) begin : m_in_row0
            always_comb begin
                m_in[idx(0, c)] = m[idx(0, c) - 1];
            end
        end
    endgenerate
    generate
        for(r = 1; r < ROW; r++) begin : m_in_row
            for(c = 0; c < COL; c++) begin : m_in_col
                always_comb begin
                    m_in[idx(r, c)] = m[idx(r, c) - 1];
                end
            end
        end
    endgenerate

    generate
        for(c = 0; c < COL; c++) begin : m_row0
            always_ff @(posedge clk) begin : proc_m
                if(rst) begin
                    m[idx(0, c)] <= '0;
                end
                else if(state == S_Idle && start) begin
                    m[idx(0, c)] <= '0;
                end
                else if(in_handsk) begin
                    m[idx(0, c)] <= m_in[idx(0, c)];
                end
            end
        end
    endgenerate
    generate
        for(r = 1; r < ROW; r++) begin : m_row
            for(c = 0; c < COL; c++) begin : m_col
                always_ff @(posedge clk) begin : proc_m
                    if(rst) begin
                        m[idx(r, c)] <= '0;
                    end
                    else if(state == S_Idle && start) begin
                        m[idx(r, c)] <= '0;
                    end
                    else if(in_handsk) begin
                        m[idx(r, c)] <= m_in[idx(r, c)];
                    end
                    // else if(state == S_Output && nxt_state == S_Wait) begin
                    else if(state == S_Clear) begin
                        m[idx(r, c)] <= '0;
                    end
                end
            end
        end
    endgenerate

    logic [COL - 1 : 0] ij_diff;
    generate
        for(c = 0; c < COL; c++) begin
            always_comb begin
                ij_diff[c] = m[idx(0, c)].i != m[idx(1, c)].i && m[idx(0, c)].j != m[idx(1, c)].j;
            end
        end
    endgenerate

    logic [ROW * COL - 1 : COL] s_diff;
    generate
        for(r = 1; r < ROW; r++) begin
            for(c = 0; c < COL; c++) begin
                always_comb begin
                    s_diff[idx(r, c)] = m[idx(r, c)].s != m[idx(r - 1, c)].s;
                end
            end
        end
    endgenerate

    logic [ROW * COL - 1 : COL] keep;  // only used in output, not flush
    generate
        for(c = 0; c < COL; c++) begin
            always_comb begin
                keep[idx(1, c)] = ij_diff[c];
            end
        end
    endgenerate 
    generate
        for(r = 2; r < ROW; r++) begin
            for(c = 0; c < COL; c++) begin
                always_comb begin
                    keep[idx(r, c)] = ij_diff[c] & s_diff[idx(r, c)];
                end
            end
        end
    endgenerate

    // logic [(ROW - 1) * COL - 1 : 0] keep;
    // generate
    //     for(c = 0; c < COL; c++) begin
    //         always_comb begin
    //             keep[idx(0, c)] = ij_diff[c];
    //         end
    //     end
    // endgenerate
    // generate
    //     for(r = 1; r < ROW - 1; r++) begin
    //         for(c = 0; c < COL; c++) begin
    //             always_comb begin
    //                 keep[idx(r, c)] = keep[idx(r - 1, c)] && (m[idx(r + 1, c)].s != m[idx(r, c)].s);
    //             end
    //         end
    //     end
    // endgenerate

    logic stop_r;
    always_ff @(posedge clk) begin : proc_stop_r
        if(rst) begin
            stop_r <= '0;
        end
        else if(stop) begin
            stop_r <= 1'b1;
        end
        else if(state == S_Flush) begin
            stop_r <= 1'b0;
        end
    end

    localparam CW = $clog2(ROW * COL);
    logic [CW - 1:0] cnt; 
    always_ff @(posedge clk) begin : proc_cnt
        if(rst) begin
            cnt <= '0;
        end
        
        // else if(state != S_Wait && nxt_state == S_Wait) begin
        //     cnt <= CW'(COL - 1); //4'd2;
        // end
        // else if(state != S_Output && nxt_state == S_Output) begin
        //     cnt <= CW'(ROW * COL - 1); //4'd11;
        // end
        // else if(state != S_Flush && nxt_state == S_Flush) begin
        //     cnt <= CW'((ROW - 1) * COL - 1); //4'd8;
        // end
        else if(state == S_Idle || state == S_Clear) begin
            cnt <= CW'(COL - 1);
        end
        else if(state == S_Judge) begin
            if(|ij_diff) begin
                cnt <= CW'(ROW * COL - 1);
            end
            else begin
                cnt <= CW'(COL - 1);
            end
        end
        else if(state == S_Wait && stop_r) begin
            cnt <= CW'((ROW - 1) * COL - 1);
        end

        else if(state == S_Wait) begin
            if(in_handsk) begin
                if(cnt > 4'd0) begin
                    cnt <= cnt - 1'b1;
                end
            end
        end
        else if(state == S_Output || state == S_Flush) begin
            if(out_cont) begin
                if(cnt > 4'd0) begin
                    cnt <= cnt - 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk) begin : proc_state
        if(rst) begin
            state <= S_Idle;
        end else begin
            state <= nxt_state;
        end
    end
    always_comb begin
        nxt_state = state;
        case (state)
        S_Idle: begin
            if(start) begin
                nxt_state = S_Wait;
            end
        end // S_Idle:
        S_Wait: begin
            if(cnt == 4'b0 & in_handsk) begin
                nxt_state = S_Judge;
            end
            else if(stop_r) begin
                nxt_state = S_Flush;
            end
        end // S_Wait:
        S_Judge: begin
            if(|ij_diff) begin
                nxt_state = S_Output;
            end // if(ij_diff)
            else begin
                nxt_state = S_Wait;
            end
        end // S_Judge:
        S_Output: begin
            if(cnt == CW'(COL) & out_cont) begin
                nxt_state = S_Clear;
            end
        end
        S_Clear: begin
            nxt_state = S_Wait;
        end
        S_Flush: begin
            if(cnt == 4'd0 & out_cont) begin
                nxt_state = S_Idle;
            end
        end
        default: begin
            nxt_state = state;
        end
        endcase
    end

    always_ff @(posedge clk) begin : proc_finish
        if(rst) begin
            finish <= 1'b0;
        end 
        else if(state == S_Flush && (cnt == 4'd0 & out_cont)) begin
            finish <= 1'b1;
        end
        else begin
            finish <= 1'b0;
        end
    end
    assign busy = state != S_Idle;

    always_comb begin
        s_axis_emin.tready = state == S_Wait;
    end

    wire WorkingMem emout = m[cnt];
    always_comb begin
        m_axis_emout.tdata = emout;
    end
    always_comb begin
        if(state == S_Output) begin
            m_axis_emout.tvalid = m[cnt].s != 32'd0 & keep[cnt];
        end
        else if(state == S_Flush) begin
            if(cnt == 4'd0) begin
                m_axis_emout.tvalid = glast || m[cnt].s != 32'd0; //glast ? 1'b1 : m[cnt].s != 32'd0;
            end
            else if(cnt < CW'(COL)/*4'd3*/) begin
                m_axis_emout.tvalid = m[cnt].s != 32'd0;
            end
            else begin
                m_axis_emout.tvalid = m[cnt].s != 32'd0 && s_diff[cnt];
            end
        end
        else begin
            m_axis_emout.tvalid = 1'b0;
        end
    end
    always_comb begin
        m_axis_emout.tlast = glast && (state == S_Flush && cnt == 4'd0);
    end

    always_comb m_axis_emout.tstrb = '1;
    always_comb m_axis_emout.tkeep = '1;


endmodule // MemFilter2
