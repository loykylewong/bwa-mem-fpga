// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180813

`default_nettype none

`include "./s00_defines.sv"

module MemAssem
    import BwaMemDefines::*;
(
    input wire clk, rst,
    input wire [RID_W - 1 : 0] read_id,

    Axi4StreamIf.slave s_axis_emin,
    Axi4StreamIf.master m_axis_emout
);
    logic stored;
    AssemMem asm;
    wire WorkingMem m_in = s_axis_emin.tdata;

    always_ff @(posedge clk) begin : proc_store
        if(rst) begin
            stored <= 1'b0;
        end
        else if(s_axis_emin.tvalid & s_axis_emin.tready) begin
            stored <= 1'b1;
        end
        else if(m_axis_emout.tvalid & m_axis_emout.tready) begin
            stored <= 1'b0;
        end
    end

    always_comb s_axis_emin.tready = ~stored;// | m_axis_emout.tready & m_axis_emout.tvalid;
    always_comb m_axis_emout.tvalid = stored;
    always_comb m_axis_emout.tdata = asm;
    always_comb m_axis_emout.tstrb = '1;
    always_comb m_axis_emout.tkeep = '1;
    always_ff @(posedge clk) begin : proc_asm
        if(rst) begin
            asm <= '0;
        end
        else if(s_axis_emin.tvalid & s_axis_emin.tready) begin
            asm.j <= m_in.j;            // right open interval without the guarded 'N
            asm.i <= m_in.i - 1'd1;     // minus 1 to get the position without the guarded 'N'
            asm.s <= m_in.s;            //> 32'd255 ? 8'd255 : m_in.s;
            asm.l <= m_in.l;
            asm.k <= m_in.k;
            asm.id <= read_id;
        end
    end

    always_ff @(posedge clk) begin : proc_tlast
        if(rst) begin
            m_axis_emout.tlast <= 1'b0;
        end
        else if(s_axis_emin.tvalid & s_axis_emin.tready) begin
            m_axis_emout.tlast <= s_axis_emin.tlast;
        end
    end

endmodule // MemAssem
