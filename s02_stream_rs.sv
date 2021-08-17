// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180821

`default_nettype none

module StreamRSLite
#(
    parameter DW = 32
)(
    input  wire  clk, rst,

    input  wire  [DW-1:0] s_axis_tdata,
    input  wire           s_axis_tlast,
    input  wire           s_axis_tvalid,
    output logic          s_axis_tready,

    output logic [DW-1:0] m_axis_tdata,
    output logic          m_axis_tlast,
    output logic          m_axis_tvalid,
    input  wire           m_axis_tready
);
    wire in_hs = s_axis_tvalid & s_axis_tready;
    wire out_hs = m_axis_tvalid & m_axis_tready;

    always_ff @(posedge clk) begin : proc_store
        if(rst) begin
            s_axis_tready <= 1'b1;
            m_axis_tvalid <= 1'b0;
        end
        else if(in_hs) begin
            s_axis_tready <= 1'b0;
            m_axis_tvalid <= 1'b1;
        end
        else if(out_hs) begin
            s_axis_tready <= 1'b1;
            m_axis_tvalid <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin : proc_asm
        if(rst) begin
            m_axis_tlast <= '0;
            m_axis_tdata <= '0;
        end
        else if(in_hs) begin
            m_axis_tlast <= s_axis_tlast;
            m_axis_tdata <= s_axis_tdata;            
        end
    end

endmodule // MemAssem

module StreamIfRSLite
(
    Axi4StreamIf.slave s,
    Axi4StreamIf.master m
);
    wire in_hs = s.tvalid & s.tready;
    wire out_hs = m.tvalid & m.tready;
    wire clk = s.clk;
    wire rst = ~s.reset_n;
    always_ff @(posedge clk) begin : proc_store
        if(rst) begin
            s.tready <= 1'b1;
            m.tvalid <= 1'b0;
        end
        else if(in_hs) begin
            s.tready <= 1'b0;
            m.tvalid <= 1'b1;
        end
        else if(out_hs) begin
            s.tready <= 1'b1;
            m.tvalid <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin : proc_asm
        if(rst) begin
            m.tlast <= '0;
            m.tdata <= '0;
        end
        else if(in_hs) begin
            m.tlast <= s.tlast;
            m.tdata <= s.tdata;            
        end
    end

endmodule // MemAssem