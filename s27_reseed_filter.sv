// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180820

`default_nettype none
`include "./s00_defines.sv"

module ReseedFilter
    import BwaMemDefines::*;
(
    input wire clk, rst,
    input wire bypass,
    input wire [POS_W-1 : 0] rs_min_len,
    input wire [KLS_W-1 : 0] rs_max_intv,
    input wire rs_params_valid,
    Axi4StreamIf.slave s_axis_emin,
    Axi4StreamIf.master m_axis_emout,
    Axi4StreamIf.master m_axis_rsout
);
    logic [POS_W-1 : 0] min_len;
    logic [KLS_W-1 : 0] max_intv;
    always_ff @(posedge clk) begin : proc_rs_params
        if(rst) begin
            min_len <= 1'b0;
            max_intv <= 1'b0;
        end
        else if(rs_params_valid) begin
            min_len <= rs_min_len - 1'b1;
            max_intv <= rs_max_intv;
        end
    end

    logic stored;
    WorkingMem m_in = s_axis_emin.tdata;
    logic last_in;
    always_ff @(posedge clk) begin : proc_m_in
        if(rst) begin
            m_in <= '0;
            last_in <= 1'b0;
            stored <= 1'b0;
        end
        else if(s_axis_emin.tvalid & s_axis_emin.tready) begin
            m_in <= s_axis_emin.tdata;
            last_in <= s_axis_emin.tlast;
            stored <= 1'b1;
        end
        else begin
            stored <= 1'b0;
        end
    end

    WorkingMem m;
    logic last;
    
    assign m_axis_emout.tdata = m;
    assign m_axis_emout.tlast = last;
    assign m_axis_emout.tstrb = '1;
    assign m_axis_emout.tkeep = '1;

    assign m_axis_rsout.tdata = m;
    assign m_axis_rsout.tlast = '0;
    assign m_axis_rsout.tstrb = '1;
    assign m_axis_rsout.tkeep = '1;
    
    always_ff @(posedge clk) begin : proc_m
        if(rst) begin
            m <= '0;
            last <= 1'b0;
        end
        // else if(s_axis_emin.tvalid & s_axis_emin.tready) begin
        //     m <= m_in;
        //     last <= s_axis_emin.tlast;
        // end
        else if(stored) begin
            m <= m_in;
            last <= last_in;
        end
    end

    always_comb s_axis_emin.tready = ~stored & ~m_axis_rsout.tvalid & ~m_axis_emout.tvalid;

    wire need_reseed = ~bypass && (m_in.j - m_in.i >= min_len && m_in.s <= max_intv);

    always_ff @(posedge clk) begin : proc_emout_tvalid
        if(rst) begin
            m_axis_emout.tvalid <= 1'b0;
        end
        // else if(s_axis_emin.tvalid & s_axis_emin.tready) begin
        //     m_axis_emout.tvalid <= 1'b1;
        // end
        else if(stored) begin
            m_axis_emout.tvalid <= 1'b1;
        end
        else if(m_axis_emout.tvalid & m_axis_emout.tready) begin
            m_axis_emout.tvalid <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin : proc_rsout_tvalid
        if(rst) begin
            m_axis_rsout.tvalid <= 1'b0;
        end
        // else if(s_axis_emin.tvalid & s_axis_emin.tready & need_reseed) begin
        //     m_axis_rsout.tvalid <= 1'b1;
        // end
        else if(stored & need_reseed) begin
            m_axis_rsout.tvalid <= 1'b1;
        end
        else if(m_axis_rsout.tvalid & m_axis_rsout.tready) begin
            m_axis_rsout.tvalid <= 1'b0;
        end
    end

endmodule // ReseedFilter

// module ReseedFilter
//     import BwaMemDefines::*;
// (
//     input wire clk, rst,
//     input wire bypass,
//     input wire [POS_W-1 : 0] rs_min_len,
//     input wire [KLS_W-1 : 0] rs_max_intv,
//     input wire rs_params_valid,
//     Axi4StreamIf.slave s_axis_emin,
//     Axi4StreamIf.master m_axis_emout,
//     Axi4StreamIf.master m_axis_rsout
// );
//     logic [POS_W-1 : 0] min_len;
//     logic [KLS_W-1 : 0] max_intv;
//     always_ff @(posedge clk) begin : proc_rs_params
//         if(rst) begin
//             min_len <= 1'b0;
//             max_intv <= 1'b0;
//         end
//         else if(rs_params_valid) begin
//             min_len <= rs_min_len - 1'b1;
//             max_intv <= rs_max_intv;
//         end
//     end

//     logic stored;
//     wire WorkingMem m_in = s_axis_emin.tdata;
//     WorkingMem m;
//     assign m_axis_emout.tdata = m;
//     assign m_axis_rsout.tdata = m;
    
//     always_ff @(posedge clk) begin : proc_m
//         if(rst) begin
//             m <= '0;
//         end
//         else if(s_axis_emin.tvalid & s_axis_emin.tready) begin
//             m <= m_in;
//         end
//     end

//     always_ff @(posedge clk) begin : proc_stored
//         if(rst) begin
//             stored <= 1'b0;
//         end
//         else if(s_axis_emin.tvalid & s_axis_emin.tready) begin
//             stored <= 1'b1;
//         end
//         else if(m_axis_emout.tvalid & m_axis_emout.tready
//              || m_axis_rsout.tvalid & m_axis_rsout.tready) begin
//             stored <= 1'b0;
//         end
//     end

//     always_comb s_axis_emin.tready = ~stored;

//     wire need_reseed = ~bypass && (m_in.j - m_in.i >= min_len && m_in.s <= max_intv);

//     always_ff @(posedge clk) begin : proc_emout_tvalid
//         if(rst) begin
//             m_axis_emout.tvalid <= 1'b0;
//         end
//         else if(s_axis_emin.tvalid & s_axis_emin.tready & ~need_reseed) begin
//             m_axis_emout.tvalid <= 1'b1;
//         end
//         else if(m_axis_emout.tvalid & m_axis_emout.tready) begin
//             m_axis_emout.tvalid <= 1'b0;
//         end
//     end

//     always_ff @(posedge clk) begin : proc_rsout_tvalid
//         if(rst) begin
//             m_axis_rsout.tvalid <= 1'b0;
//         end
//         else if(s_axis_emin.tvalid & s_axis_emin.tready & need_reseed) begin
//             m_axis_rsout.tvalid <= 1'b1;
//         end
//         else if(m_axis_rsout.tvalid & m_axis_rsout.tready) begin
//             m_axis_rsout.tvalid <= 1'b0;
//         end
//     end

// endmodule // ReseedFilter
