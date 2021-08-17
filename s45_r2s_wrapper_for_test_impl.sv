// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180830

`default_nettype none
`include "./s00_defines.sv"


module VirtualIn
#(
    parameter integer W = 100
)(
    input  wire clk, rst,
    input  wire din, update,
    output logic [W-1:0] vout
);
    logic [W-1:0] shift;
    always_ff @(posedge clk) begin : proc_shift
        if(rst) begin
            shift <= '0;
        end
        else begin
            shift <= {shift[0+:W-1], din};
        end
    end
    always_ff @(posedge clk) begin : proc_dout
        if(rst) begin
            vout <= '0;
        end
        else if(update) begin
            vout <= shift;
        end
    end
endmodule // VirtualIn

module VirtualOut
#(
    parameter integer W = 100
)(
    input wire clk, rst,
    input wire [W-1:0] vin,
    input wire load,
    output logic dout
);
    logic [W-1:0] shift;
    always_ff @(posedge clk) begin : proc_shift
        if(rst) begin
            shift <= '0;
        end
        else if(load) begin
            shift <= vin;
        end
        else begin
            shift <= {1'b0, shift[1+:W-1]};
        end
    end
    assign dout = shift[0];

endmodule // VirtualOut


module r2s_wrapper_for_test_impl
    import BwaMemDefines::*;
(
    input wire clk, rst,
    input wire din, update, load,
    output wire dout
);

    typedef struct packed
    {
        logic [READ_DW - 1 : 0]   s_axis_tdata;
        logic                     s_axis_tvalid;
        logic                     m_axis_tready;
        logic                     m_axi_arready;
        logic [255 : 0]           m_axi_rdata;
        logic [1 : 0]             m_axi_rresp;
        logic                     m_axi_rvalid;
        logic                     m_axi_rid;
        logic                     m_axi_rlast;
        logic [KLS_W - 1 : 0]     acc_cnt_A;
        logic [KLS_W - 1 : 0]     acc_cnt_C;
        logic [KLS_W - 1 : 0]     acc_cnt_G;
        logic [KLS_W - 1 : 0]     acc_cnt_T;
        logic [KLS_W - 1 : 0]     pri_pos;
        logic [KLS_W - 1 : 0]     bwt_len;
        logic [POS_W - 1 : 0]     min_mlen;
        logic [POS_W - 1 : 0]     sf_mlen;
        logic [KLS_W - 1 : 0]     sf_max_intv;
        logic [POS_W - 1 : 0]     rs_min_mlen;
        logic [KLS_W - 1 : 0]     rs_max_intv;
        logic                     param_update;
    } virt_in;
    typedef struct packed
    {
        logic                     s_axis_tready;
        logic [ASMMEM_W - 1 : 0]  m_axis_tdata;
        logic                     m_axis_tlast;
        logic                     m_axis_tvalid;
        logic [SEEDOUT_QU_AW : 0] m_axis_tuser;
        logic [OCCMEM_AW - 1 : 0] m_axi_araddr;
        logic [2 : 0]             m_axi_arprot;
        logic                     m_axi_arvalid;
        logic [1 : 0]             m_axi_arburst;
        logic [7 : 0]             m_axi_arlen;
        logic [2 : 0]             m_axi_arsize;
        logic                     m_axi_arid;
        logic [3 : 0]             m_axi_arcache;
        logic                     m_axi_arlock;
        logic [3 : 0]             m_axi_arqos;
        logic                     m_axi_rready;
    } virt_out;

    wire virt_in vi;
    wire virt_out vo;

    VirtualIn #(.W($bits(virt_in))) the_vi(
        .clk   (clk), .rst   (rst),
        .din   (din), .update(update), .vout(vi)
        );
    VirtualOut #(.W($bits(virt_out))) the_vo(
        .clk (clk), .rst (rst),
        .vin (vo),  .load(load), .dout(dout)
    );

    Read2Seed #(
        .READ_LEN       (76),
        .READ_DW        (76*4+32),
        .OCCMEM_AW      (40),
        .OCC_BASE       (40'h01_0000_0000),
        .FILTER_GRP_SIZE(2),
        .BIDIREX_QU_AW  (8),
        .RESEED_QU_AW   (6),
        .SEEDOUT_QU_AW  (8)
    ) the_r2s (
        .clk          (clk),
        .rst          (rst),
        .s_axis_tdata (vi.s_axis_tdata),
        .s_axis_tvalid(vi.s_axis_tvalid),
        .s_axis_tready(vo.s_axis_tready),
        .m_axis_tdata (vo.m_axis_tdata),
        .m_axis_tlast (vo.m_axis_tlast),
        .m_axis_tvalid(vo.m_axis_tvalid),
        .m_axis_tready(vi.m_axis_tready),
        .m_axis_tuser (vo.m_axis_tuser),
        .m_axi_araddr (vo.m_axi_araddr),
        .m_axi_arprot (vo.m_axi_arprot),
        .m_axi_arvalid(vo.m_axi_arvalid),
        .m_axi_arready(vi.m_axi_arready),
        .m_axi_arburst(vo.m_axi_arburst),
        .m_axi_arlen  (vo.m_axi_arlen),
        .m_axi_arsize (vo.m_axi_arsize),
        .m_axi_arid   (vo.m_axi_arid),
        .m_axi_arcache(vo.m_axi_arcache),
        .m_axi_arlock (vo.m_axi_arlock),
        .m_axi_arqos  (vo.m_axi_arqos),
        .m_axi_rdata  (vi.m_axi_rdata),
        .m_axi_rresp  (vi.m_axi_rresp),
        .m_axi_rvalid (vi.m_axi_rvalid),
        .m_axi_rready (vo.m_axi_rready),
        .m_axi_rid    (vi.m_axi_rid),
        .m_axi_rlast  (vi.m_axi_rlast),
        .acc_cnt_A    (vi.acc_cnt_A),
        .acc_cnt_C    (vi.acc_cnt_C),
        .acc_cnt_G    (vi.acc_cnt_G),
        .acc_cnt_T    (vi.acc_cnt_T),
        .pri_pos      (vi.pri_pos),
        .bwt_len      (vi.bwt_len),
        .min_mlen     (vi.min_mlen),
        .sf_mlen      (vi.sf_mlen),
        .sf_max_intv  (vi.sf_max_intv),
        .rs_min_mlen  (vi.rs_min_mlen),
        .rs_max_intv  (vi.rs_max_intv),
        .param_update (vi.param_update)
    );

endmodule
