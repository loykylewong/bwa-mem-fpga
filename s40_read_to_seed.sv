// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180821

`default_nettype none
`include "./s00_defines.sv"

module Read2Seed    // a wrapper of ReadMem or ReadMemReseed? and output fifo can be packaged as ip in vivado,
                    // because system-verilog interface is not supported by vivado ip
                    // and use 4-bit symbol for easily suit data width requirement of axi4-stream if
    import BwaMemDefines::*;
#(
    parameter integer READ_LEN = 76,                   // must be a even number
    localparam integer READ_DW = READ_LEN * 4 + RID_W,  // 4-bit each symbol and a 32-bit id, 8*n bit for axi4-stream if 
    parameter integer OCCMEM_AW = 40,
    parameter logic [OCCMEM_AW - 1 : 0] OCC_BASE = 40'h00_0000_0000, // must be align to 2^(clog2(OccTableSize))
    parameter integer FILTER_GRP_SIZE = 2,
    parameter integer BIDIREX_QU_AW = 8,
    parameter integer RESEED_QU_AW = 6,
    parameter integer SEEDOUT_QU_AW = 8,
    parameter logic [3:0] M_AXI_OCC_ARID = 4'h0
)(
    // clock and reset
    input  wire clk, rst,
    
    // read input stream
    input  wire [READ_DW - 1 : 0]   s_axis_tdata,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    
    // seed output stream
    output wire [ASMMEM_W - 1 : 0]  m_axis_tdata,
    output wire                     m_axis_tlast,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire [SEEDOUT_QU_AW : 0] m_axis_tuser,    // fifo data cnt

    // occ lookup, must be a axi4-full to support 256-bit data
    // output wire [OCCMEM_AW - 1 : 0] m_axi_awaddr,
    // output wire [2 : 0]             m_axi_awprot,
    // output wire                     m_axi_awvalid,
    // input  wire                     m_axi_awready,
    // output wire [1 : 0]             m_axi_awburst,
    // output wire [7 : 0]             m_axi_awlen,
    // output wire [2 : 0]             m_axi_awsize,
    // output wire                     m_axi_awid,
    // output wire [3 : 0]             m_axi_awcache,
    // output wire                     m_axi_awlock,
    // output wire [3 : 0]             m_axi_awqos,
    
    // output wire [255 : 0]           m_axi_wdata,
    // output wire [31  : 0]           m_axi_wstrb,
    // output wire                     m_axi_wvalid,
    // input  wire                     m_axi_wready,
    // output wire                     m_axi_wid,
    // output wire                     m_axi_wlast,
    
    // input  wire [1 : 0]             m_axi_bresp,
    // input  wire                     m_axi_bvalid,
    // output wire                     m_axi_bready,
    // input  wire                     m_axi_bid,
    
    output wire [OCCMEM_AW - 1 : 0] m_axi_araddr,
    output wire [2 : 0]             m_axi_arprot,
    output wire                     m_axi_arvalid,
    input  wire                     m_axi_arready,
    output wire [1 : 0]             m_axi_arburst,
    output wire [7 : 0]             m_axi_arlen,
    output wire [2 : 0]             m_axi_arsize,
    output wire [3 : 0]             m_axi_arid,
    output wire [3 : 0]             m_axi_arcache,
    output wire                     m_axi_arlock,
    output wire [3 : 0]             m_axi_arqos,

    input  wire [255 : 0]           m_axi_rdata,
    input  wire [1 : 0]             m_axi_rresp,
    input  wire                     m_axi_rvalid,
    output wire                     m_axi_rready,
    input  wire [3 : 0]             m_axi_rid,
    input  wire                     m_axi_rlast,

    // bwt parameters
    input  wire [KLS_W - 1 : 0]     acc_cnt_A,
    input  wire [KLS_W - 1 : 0]     acc_cnt_C,
    input  wire [KLS_W - 1 : 0]     acc_cnt_G,
    input  wire [KLS_W - 1 : 0]     acc_cnt_T,
    input  wire [KLS_W - 1 : 0]     pri_pos,
    input  wire [KLS_W - 1 : 0]     bwt_len,
    // mem(seed) min len
    input  wire [POS_W - 1 : 0]     min_mlen,
    // simple forward phase params
    input  wire [POS_W - 1 : 0]     sf_mlen,
    input  wire [KLS_W - 1 : 0]     sf_max_intv,
    // reseed criterion params
    input  wire [POS_W - 1 : 0]     rs_min_mlen,
    input  wire [KLS_W - 1 : 0]     rs_max_intv,
    input  wire                     param_update
);
    Symbol read[0 : READ_LEN - 1];

    genvar i;
    generate
        for(i = 0; i < READ_LEN; i++) begin
            always_comb read[i] = s_axis_tdata[i * 4 +: 3];
        end
    endgenerate
    wire [RID_W - 1 : 0] rid = s_axis_tdata[READ_LEN * 4 +: RID_W];

    Axi4StreamIf #(.DW_BYTES($bits(AssemMem)/8)) pbout(.clk(clk), .reset_n(~rst));

    Axi4LiteIf #(.DW(256), .AW(OCCMEM_AW)) occlu(.clk(clk), .reset_n(~rst));

    wire start = s_axis_tready & s_axis_tvalid;
    wire busy;
    assign s_axis_tready = ~busy;

    ReadMemReseed3 #(
        .READ_LEN(READ_LEN),
        .OCC_AW(OCCMEM_AW),
        .OCC_BASE(OCC_BASE),
        .FILTER_GRP_SIZE(FILTER_GRP_SIZE), 
        .BIDIREX_QU_AW(BIDIREX_QU_AW),
        .RESEED_QU_AW (RESEED_QU_AW )
    ) theReadMem (
        .clk             (clk),
        .rst             (rst),
        .read            (read),
        .read_id         (rid),
        .start           (start),
        .finish          (),
        .busy            (busy),
        .m_axis_emout    (pbout.master),
        .m_axi_occlu     (occlu.master),
        .acc_cnt_in      ('{acc_cnt_A, acc_cnt_C, acc_cnt_G, acc_cnt_T}),
        .pri_pos_in      (pri_pos),
        .bwt_len_in      (bwt_len),
        .bwt_params_valid(param_update),
        .min_mlen_in     (min_mlen),
        .min_mlen_valid  (param_update),
        .rs_min_mlen_in  (rs_min_mlen),
        .rs_max_intv_in  (rs_max_intv),
        .rs_params_valid (param_update),
        .sf_mlen_in      (sf_mlen),
        .sf_max_intv_in  (sf_max_intv),
        .sf_params_valid (param_update)
    );

    StreamFifo #(.DW($bits(AssemMem) + 1), .AW(SEEDOUT_QU_AW)) seedoutFifo (
        .clk      (clk),
        .rst      (rst),
        .in_data  ({pbout.tlast, pbout.tdata}),
        .in_valid (pbout.tvalid),
        .in_ready (pbout.tready),
        .out_data ({m_axis_tlast, m_axis_tdata}),
        .out_valid(m_axis_tvalid),
        .out_ready(m_axis_tready),
        .data_cnt (m_axis_tuser)
    );

    // assign m_axis_tdata     = pbout.tdata;
    // assign m_axis_tlast     = pbout.tlast;
    // assign m_axis_tvalid    = pbout.tvalid;
    // always_comb pbout.tready = m_axis_tready;

    // // aw ch, never used
    // assign m_axi_awaddr  = '0;
    // assign m_axi_awprot  = 3'b0;
    // assign m_axi_awvalid = 1'b0;
    // assign m_axi_awburst = 2'b01;  // incr
    // assign m_axi_awsize  = 3'd5;   // 2^5 * 8=256 byte
    // assign m_axi_awlen   = 8'd0;   // len = 1
    // assign m_axi_awid    = '0;
    // assign m_axi_awlock  = 1'b0;
    // assign m_axi_awcache = 4'b0010;    // normal nc, nb
    // assign m_axi_awqos   = 4'b0000;
    // // w ch, never used
    // assign m_axi_wdata  = '0;
    // assign m_axi_wstrb  = '0;
    // assign m_axi_wvalid = 1'b0;
    // assign m_axi_wlast  = 1'b0;
    // assign m_axi_wid    = '0;
    // // b ch, never used
    // assign m_axi_bready = 1'b1;
    // ar ch
    assign      m_axi_araddr  = occlu.araddr;
    assign      m_axi_arprot  = occlu.arprot;
    assign      m_axi_arvalid = occlu.arvalid;
    always_comb occlu.arready = m_axi_arready;
    assign      m_axi_arburst = 2'b01;  // incr
    assign      m_axi_arsize  = 3'd5;   // 2^5 * 8=256 byte
    assign      m_axi_arlen   = 8'd0;   // len = 1
    assign      m_axi_arid    = M_AXI_OCC_ARID;
    assign      m_axi_arlock  = 1'b0;
    assign      m_axi_arcache = 4'b1111;    // write back, read allocate
    assign      m_axi_arqos   = 4'b0000;
    // r ch
    always_comb occlu.rdata   = m_axi_rdata;
    always_comb occlu.rvalid  = m_axi_rvalid;
    always_comb occlu.rresp   = m_axi_rresp;
    assign      m_axi_rready  = occlu.rready;

endmodule // Read2Seed
