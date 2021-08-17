// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180828

`default_nettype none
`include "./s00_defines.sv"

module ProcessBlockX16
    import BwaMemDefines::*;
#(
    parameter integer READ_LEN = 76,                   // must be a even number
    localparam integer RDW = READ_LEN * 4 + RID_W,  // 4-bit each symbol and a 32-bit id, 8*n bit for axi4-stream if 
    parameter integer OCCMEM_AW = 40,
    parameter logic [OCCMEM_AW - 1 : 0] OCC_BASE = 40'h00_0000_0000, // must be align to 2^(clog2(OccTableSize))
    parameter integer FILTER_GRP_SIZE = 2,
    parameter integer BIDIREX_QU_AW = 8,
    parameter integer RESEED_QU_AW = 6,
    parameter integer SEEDOUT_QU_AW = 8
)(
    input wire clk, rst_n,

    input  wire [RDW - 1 : 0] ri_data,   // {id[32], read[...]}
    input  wire               ri_valid,
    output wire               ri_ready,

    output wire [ASMMEM_W - 1 : 0] so_data,
    output wire                    so_last,
    output wire                    so_valid,
    input  wire                    so_ready,

    input wire [KLS_W-1:0] acc_cnt_A,
    input wire [KLS_W-1:0] acc_cnt_C,
    input wire [KLS_W-1:0] acc_cnt_G,
    input wire [KLS_W-1:0] acc_cnt_T,
    input wire [KLS_W-1:0] pri_pos,
    input wire [KLS_W-1:0] bwt_len,
    input wire [POS_W-1:0] min_mlen,
    input wire [POS_W-1:0] sf_mlen,
    input wire [KLS_W-1:0] sf_max_intv,
    input wire [POS_W-1:0] rs_min_mlen,
    input wire [KLS_W-1:0] rs_max_intv,
    input wire             param_update,

    output wire [OCCMEM_AW - 1 : 0] m_axi_araddr [16],
    output wire [2 : 0]             m_axi_arprot [16],
    output wire                     m_axi_arvalid[16],
    input  wire                     m_axi_arready[16],
    output wire [1 : 0]             m_axi_arburst[16],
    output wire [7 : 0]             m_axi_arlen  [16],
    output wire [2 : 0]             m_axi_arsize [16],
    output wire [3 : 0]             m_axi_arid   [16],
    output wire [3 : 0]             m_axi_arcache[16],
    output wire                     m_axi_arlock [16],
    output wire [3 : 0]             m_axi_arqos  [16],
    input  wire [255 : 0]           m_axi_rdata  [16],
    input  wire [1 : 0]             m_axi_rresp  [16],
    input  wire                     m_axi_rvalid [16],
    output wire                     m_axi_rready [16],
    input  wire [3 : 0]             m_axi_rid    [16],
    input  wire                     m_axi_rlast  [16] 
);
    wire rst = ~rst_n;
    
    wire [RDW - 1 : 0] read_data [16];
    wire               read_valid[16];
    wire               read_ready[16];

    wire [RDW - 1 : 0] read_regs_data [16];
    wire               read_regs_valid[16];
    wire               read_regs_ready[16];

    wire [ASMMEM_W - 1 : 0]  seed_data  [16];
    wire                     seed_last  [16];
    wire                     seed_valid [16];
    wire                     seed_ready [16];
    // wire [SEEDOUT_QU_AW : 0] seed_fifodc[16];

    wire  [ASMMEM_W - 1 : 0]  seed_regs_data  [16];
    wire                      seed_regs_last  [16];
    wire                      seed_regs_valid [16];
    wire                      seed_regs_ready [16];
    // logic [SEEDOUT_QU_AW : 0] seed_regs_fifodc[16];

    ReadDispatch #(.CH(16), .DW(RDW)) readDisp (
        .clk     (clk),
        .rst     (rst),
        .ri_data (ri_data),
        .ri_valid(ri_valid),
        .ri_ready(ri_ready),
        .ro_data (read_data),
        .ro_valid(read_valid),
        .ro_ready(read_ready)
    );

    genvar ch;
    generate
        for(ch = 0; ch < 16; ch++) begin : read_reg_slices
            StreamRSLite #(.DW(RDW)) read_regs(
                .clk          (clk),
                .rst          (rst),
                .s_axis_tdata (read_data [ch]),
                .s_axis_tvalid(read_valid[ch]),
                .s_axis_tready(read_ready[ch]),
                .m_axis_tdata (read_regs_data [ch]),
                .m_axis_tvalid(read_regs_valid[ch]),
                .m_axis_tready(read_regs_ready[ch]),
                .s_axis_tlast (1'b0),
                .m_axis_tlast ()
            );
        end
        for(ch = 0; ch < 16; ch++) begin : read2Seed_array
            Read2Seed #(
                .READ_LEN       (READ_LEN),
                .OCCMEM_AW      (OCCMEM_AW),
                .OCC_BASE       (OCC_BASE),
                .FILTER_GRP_SIZE(FILTER_GRP_SIZE),
                .BIDIREX_QU_AW  (BIDIREX_QU_AW),
                .RESEED_QU_AW   (RESEED_QU_AW),
                .SEEDOUT_QU_AW  (SEEDOUT_QU_AW),
                .M_AXI_OCC_ARID (4'(ch))
            ) read2Seed (
                .clk          (clk),
                .rst          (rst),
                .s_axis_tdata (read_regs_data [ch]),
                .s_axis_tvalid(read_regs_valid[ch]),
                .s_axis_tready(read_regs_ready[ch]),
                .m_axis_tdata (seed_data  [ch]),
                .m_axis_tlast (seed_last  [ch]),
                .m_axis_tvalid(seed_valid [ch]),
                .m_axis_tready(seed_ready [ch]),
                .m_axis_tuser (/*seed_fifodc[ch]*/),

                .m_axi_araddr (m_axi_araddr [ch]),
                .m_axi_arprot (m_axi_arprot [ch]),
                .m_axi_arvalid(m_axi_arvalid[ch]),
                .m_axi_arready(m_axi_arready[ch]),
                .m_axi_arburst(m_axi_arburst[ch]),
                .m_axi_arlen  (m_axi_arlen  [ch]),
                .m_axi_arsize (m_axi_arsize [ch]),
                .m_axi_arid   (m_axi_arid   [ch]),
                .m_axi_arcache(m_axi_arcache[ch]),
                .m_axi_arlock (m_axi_arlock [ch]),
                .m_axi_arqos  (m_axi_arqos  [ch]),
                .m_axi_rdata  (m_axi_rdata  [ch]),
                .m_axi_rresp  (m_axi_rresp  [ch]),
                .m_axi_rvalid (m_axi_rvalid [ch]),
                .m_axi_rready (m_axi_rready [ch]),
                .m_axi_rlast  (m_axi_rlast  [ch]),
                .m_axi_rid    (m_axi_rid    [ch]),

                .acc_cnt_A    (acc_cnt_A),
                .acc_cnt_C    (acc_cnt_C),
                .acc_cnt_G    (acc_cnt_G),
                .acc_cnt_T    (acc_cnt_T),
                .pri_pos      (pri_pos),
                .bwt_len      (bwt_len),
                .min_mlen     (min_mlen),
                .sf_mlen      (sf_mlen),
                .sf_max_intv  (sf_max_intv),
                .rs_min_mlen  (rs_min_mlen),
                .rs_max_intv  (rs_max_intv),
                .param_update (param_update)
            );
        end
        for(ch = 0; ch < 16; ch++) begin : seed_reg_slices
            StreamRSLite #(.DW(ASMMEM_W)) seed_regs(  
                .clk          (clk),
                .rst          (rst),
                .s_axis_tdata (seed_data [ch]),
                .s_axis_tlast (seed_last [ch]),
                .s_axis_tvalid(seed_valid[ch]),
                .s_axis_tready(seed_ready[ch]),
                .m_axis_tdata (seed_regs_data [ch]),
                .m_axis_tlast (seed_regs_last [ch]),
                .m_axis_tvalid(seed_regs_valid[ch]),
                .m_axis_tready(seed_regs_ready[ch])
            );
        end // seed_reg_slices
        // for(ch = 0; ch < 16; ch++) begin : seed_dc_reg_slice
        //     always_ff @(posedge clk) begin : proc_seed_regs_fifodc
        //         if(rst) begin
        //             seed_regs_fifodc[ch] <= '0;
        //         end
        //         else begin
        //             seed_regs_fifodc[ch] <= seed_fifodc[ch];
        //         end
        //     end
        // end // seed_reg_slices
    endgenerate

    // SeedCollectMDC #(.CH(16), .DW(ASMMEM_W), .DCW(SEEDOUT_QU_AW+1)) seedCollector(
    SeedCollectRR #(.CH(16), .DW(ASMMEM_W)) seedCollector(
        .clk        (clk),
        .rst        (rst),
        .si_data    (seed_regs_data),
        .si_last    (seed_regs_last),
        .si_valid   (seed_regs_valid),
        .si_ready   (seed_regs_ready),
        // .si_data_cnt(seed_regs_fifodc),
        .so_data    (so_data),
        .so_last    (so_last),
        .so_valid   (so_valid),
        .so_ready   (so_ready)
    );

endmodule


module ProcessBlockX16Wrapper   // wrapper for vivado ip packager
        import BwaMemDefines::*;
#(
    parameter integer READ_LEN = 76,                   // must be a even number
    parameter integer RDW = READ_LEN * 4 + RID_W,  // 4-bit each symbol and a 32-bit id, 8*n bit for axi4-stream if 
    parameter integer OCCMEM_AW = 40,
    parameter logic [OCCMEM_AW - 1 : 0] OCC_BASE = 40'h00_0000_0000, // must be align to 2^(clog2(OccTableSize))
    parameter integer FILTER_GRP_SIZE = 2,
    parameter integer BIDIREX_QU_AW = 8,
    parameter integer RESEED_QU_AW = 6,
    parameter integer SEEDOUT_QU_AW = 8
)(
    input wire clk, rst_n,

    input  wire [RDW - 1 : 0] s_axis_tdata,   // {id[32], read[...]}
    input  wire               s_axis_tvalid,
    output wire               s_axis_tready,

    output wire [ASMMEM_W - 1 : 0] m_axis_tdata,
    output wire                    m_axis_tlast,
    output wire                    m_axis_tvalid,
    input  wire                    m_axis_tready,

    input wire [KLS_W-1:0] acc_cnt_A,
    input wire [KLS_W-1:0] acc_cnt_C,
    input wire [KLS_W-1:0] acc_cnt_G,
    input wire [KLS_W-1:0] acc_cnt_T,
    input wire [KLS_W-1:0] pri_pos,
    input wire [KLS_W-1:0] bwt_len,
    input wire [POS_W-1:0] min_mlen,
    input wire [POS_W-1:0] sf_mlen,
    input wire [KLS_W-1:0] sf_max_intv,
    input wire [POS_W-1:0] rs_min_mlen,
    input wire [KLS_W-1:0] rs_max_intv,
    input wire             param_update,

    output wire [OCCMEM_AW - 1 : 0] m00_axi_araddr,
    output wire [2 : 0]             m00_axi_arprot,
    output wire                     m00_axi_arvalid,
    input  wire                     m00_axi_arready,
    output wire [1 : 0]             m00_axi_arburst,
    output wire [7 : 0]             m00_axi_arlen,
    output wire [2 : 0]             m00_axi_arsize,
    output wire [3 : 0]             m00_axi_arid,
    output wire [3 : 0]             m00_axi_arcache,
    output wire                     m00_axi_arlock,
    output wire [3 : 0]             m00_axi_arqos,
    input  wire [255 : 0]           m00_axi_rdata,
    input  wire [1 : 0]             m00_axi_rresp,
    input  wire                     m00_axi_rvalid,
    output wire                     m00_axi_rready,
    input  wire [3 : 0]             m00_axi_rid,
    input  wire                     m00_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m01_axi_araddr,
    output wire [2 : 0]             m01_axi_arprot,
    output wire                     m01_axi_arvalid,
    input  wire                     m01_axi_arready,
    output wire [1 : 0]             m01_axi_arburst,
    output wire [7 : 0]             m01_axi_arlen,
    output wire [2 : 0]             m01_axi_arsize,
    output wire [3 : 0]             m01_axi_arid,
    output wire [3 : 0]             m01_axi_arcache,
    output wire                     m01_axi_arlock,
    output wire [3 : 0]             m01_axi_arqos,
    input  wire [255 : 0]           m01_axi_rdata,
    input  wire [1 : 0]             m01_axi_rresp,
    input  wire                     m01_axi_rvalid,
    output wire                     m01_axi_rready,
    input  wire [3 : 0]             m01_axi_rid,
    input  wire                     m01_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m02_axi_araddr,
    output wire [2 : 0]             m02_axi_arprot,
    output wire                     m02_axi_arvalid,
    input  wire                     m02_axi_arready,
    output wire [1 : 0]             m02_axi_arburst,
    output wire [7 : 0]             m02_axi_arlen,
    output wire [2 : 0]             m02_axi_arsize,
    output wire [3 : 0]             m02_axi_arid,
    output wire [3 : 0]             m02_axi_arcache,
    output wire                     m02_axi_arlock,
    output wire [3 : 0]             m02_axi_arqos,
    input  wire [255 : 0]           m02_axi_rdata,
    input  wire [1 : 0]             m02_axi_rresp,
    input  wire                     m02_axi_rvalid,
    output wire                     m02_axi_rready,
    input  wire [3 : 0]             m02_axi_rid,
    input  wire                     m02_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m03_axi_araddr,
    output wire [2 : 0]             m03_axi_arprot,
    output wire                     m03_axi_arvalid,
    input  wire                     m03_axi_arready,
    output wire [1 : 0]             m03_axi_arburst,
    output wire [7 : 0]             m03_axi_arlen,
    output wire [2 : 0]             m03_axi_arsize,
    output wire [3 : 0]             m03_axi_arid,
    output wire [3 : 0]             m03_axi_arcache,
    output wire                     m03_axi_arlock,
    output wire [3 : 0]             m03_axi_arqos,
    input  wire [255 : 0]           m03_axi_rdata,
    input  wire [1 : 0]             m03_axi_rresp,
    input  wire                     m03_axi_rvalid,
    output wire                     m03_axi_rready,
    input  wire [3 : 0]             m03_axi_rid,
    input  wire                     m03_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m04_axi_araddr,
    output wire [2 : 0]             m04_axi_arprot,
    output wire                     m04_axi_arvalid,
    input  wire                     m04_axi_arready,
    output wire [1 : 0]             m04_axi_arburst,
    output wire [7 : 0]             m04_axi_arlen,
    output wire [2 : 0]             m04_axi_arsize,
    output wire [3 : 0]             m04_axi_arid,
    output wire [3 : 0]             m04_axi_arcache,
    output wire                     m04_axi_arlock,
    output wire [3 : 0]             m04_axi_arqos,
    input  wire [255 : 0]           m04_axi_rdata,
    input  wire [1 : 0]             m04_axi_rresp,
    input  wire                     m04_axi_rvalid,
    output wire                     m04_axi_rready,
    input  wire [3 : 0]             m04_axi_rid,
    input  wire                     m04_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m05_axi_araddr,
    output wire [2 : 0]             m05_axi_arprot,
    output wire                     m05_axi_arvalid,
    input  wire                     m05_axi_arready,
    output wire [1 : 0]             m05_axi_arburst,
    output wire [7 : 0]             m05_axi_arlen,
    output wire [2 : 0]             m05_axi_arsize,
    output wire [3 : 0]             m05_axi_arid,
    output wire [3 : 0]             m05_axi_arcache,
    output wire                     m05_axi_arlock,
    output wire [3 : 0]             m05_axi_arqos,
    input  wire [255 : 0]           m05_axi_rdata,
    input  wire [1 : 0]             m05_axi_rresp,
    input  wire                     m05_axi_rvalid,
    output wire                     m05_axi_rready,
    input  wire [3 : 0]             m05_axi_rid,
    input  wire                     m05_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m06_axi_araddr,
    output wire [2 : 0]             m06_axi_arprot,
    output wire                     m06_axi_arvalid,
    input  wire                     m06_axi_arready,
    output wire [1 : 0]             m06_axi_arburst,
    output wire [7 : 0]             m06_axi_arlen,
    output wire [2 : 0]             m06_axi_arsize,
    output wire [3 : 0]             m06_axi_arid,
    output wire [3 : 0]             m06_axi_arcache,
    output wire                     m06_axi_arlock,
    output wire [3 : 0]             m06_axi_arqos,
    input  wire [255 : 0]           m06_axi_rdata,
    input  wire [1 : 0]             m06_axi_rresp,
    input  wire                     m06_axi_rvalid,
    output wire                     m06_axi_rready,
    input  wire [3 : 0]             m06_axi_rid,
    input  wire                     m06_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m07_axi_araddr,
    output wire [2 : 0]             m07_axi_arprot,
    output wire                     m07_axi_arvalid,
    input  wire                     m07_axi_arready,
    output wire [1 : 0]             m07_axi_arburst,
    output wire [7 : 0]             m07_axi_arlen,
    output wire [2 : 0]             m07_axi_arsize,
    output wire [3 : 0]             m07_axi_arid,
    output wire [3 : 0]             m07_axi_arcache,
    output wire                     m07_axi_arlock,
    output wire [3 : 0]             m07_axi_arqos,
    input  wire [255 : 0]           m07_axi_rdata,
    input  wire [1 : 0]             m07_axi_rresp,
    input  wire                     m07_axi_rvalid,
    output wire                     m07_axi_rready,
    input  wire [3 : 0]             m07_axi_rid,
    input  wire                     m07_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m08_axi_araddr,
    output wire [2 : 0]             m08_axi_arprot,
    output wire                     m08_axi_arvalid,
    input  wire                     m08_axi_arready,
    output wire [1 : 0]             m08_axi_arburst,
    output wire [7 : 0]             m08_axi_arlen,
    output wire [2 : 0]             m08_axi_arsize,
    output wire [3 : 0]             m08_axi_arid,
    output wire [3 : 0]             m08_axi_arcache,
    output wire                     m08_axi_arlock,
    output wire [3 : 0]             m08_axi_arqos,
    input  wire [255 : 0]           m08_axi_rdata,
    input  wire [1 : 0]             m08_axi_rresp,
    input  wire                     m08_axi_rvalid,
    output wire                     m08_axi_rready,
    input  wire [3 : 0]             m08_axi_rid,
    input  wire                     m08_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m09_axi_araddr,
    output wire [2 : 0]             m09_axi_arprot,
    output wire                     m09_axi_arvalid,
    input  wire                     m09_axi_arready,
    output wire [1 : 0]             m09_axi_arburst,
    output wire [7 : 0]             m09_axi_arlen,
    output wire [2 : 0]             m09_axi_arsize,
    output wire [3 : 0]             m09_axi_arid,
    output wire [3 : 0]             m09_axi_arcache,
    output wire                     m09_axi_arlock,
    output wire [3 : 0]             m09_axi_arqos,
    input  wire [255 : 0]           m09_axi_rdata,
    input  wire [1 : 0]             m09_axi_rresp,
    input  wire                     m09_axi_rvalid,
    output wire                     m09_axi_rready,
    input  wire [3 : 0]             m09_axi_rid,
    input  wire                     m09_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m10_axi_araddr,
    output wire [2 : 0]             m10_axi_arprot,
    output wire                     m10_axi_arvalid,
    input  wire                     m10_axi_arready,
    output wire [1 : 0]             m10_axi_arburst,
    output wire [7 : 0]             m10_axi_arlen,
    output wire [2 : 0]             m10_axi_arsize,
    output wire [3 : 0]             m10_axi_arid,
    output wire [3 : 0]             m10_axi_arcache,
    output wire                     m10_axi_arlock,
    output wire [3 : 0]             m10_axi_arqos,
    input  wire [255 : 0]           m10_axi_rdata,
    input  wire [1 : 0]             m10_axi_rresp,
    input  wire                     m10_axi_rvalid,
    output wire                     m10_axi_rready,
    input  wire [3 : 0]             m10_axi_rid,
    input  wire                     m10_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m11_axi_araddr,
    output wire [2 : 0]             m11_axi_arprot,
    output wire                     m11_axi_arvalid,
    input  wire                     m11_axi_arready,
    output wire [1 : 0]             m11_axi_arburst,
    output wire [7 : 0]             m11_axi_arlen,
    output wire [2 : 0]             m11_axi_arsize,
    output wire [3 : 0]             m11_axi_arid,
    output wire [3 : 0]             m11_axi_arcache,
    output wire                     m11_axi_arlock,
    output wire [3 : 0]             m11_axi_arqos,
    input  wire [255 : 0]           m11_axi_rdata,
    input  wire [1 : 0]             m11_axi_rresp,
    input  wire                     m11_axi_rvalid,
    output wire                     m11_axi_rready,
    input  wire [3 : 0]             m11_axi_rid,
    input  wire                     m11_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m12_axi_araddr,
    output wire [2 : 0]             m12_axi_arprot,
    output wire                     m12_axi_arvalid,
    input  wire                     m12_axi_arready,
    output wire [1 : 0]             m12_axi_arburst,
    output wire [7 : 0]             m12_axi_arlen,
    output wire [2 : 0]             m12_axi_arsize,
    output wire [3 : 0]             m12_axi_arid,
    output wire [3 : 0]             m12_axi_arcache,
    output wire                     m12_axi_arlock,
    output wire [3 : 0]             m12_axi_arqos,
    input  wire [255 : 0]           m12_axi_rdata,
    input  wire [1 : 0]             m12_axi_rresp,
    input  wire                     m12_axi_rvalid,
    output wire                     m12_axi_rready,
    input  wire [3 : 0]             m12_axi_rid,
    input  wire                     m12_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m13_axi_araddr,
    output wire [2 : 0]             m13_axi_arprot,
    output wire                     m13_axi_arvalid,
    input  wire                     m13_axi_arready,
    output wire [1 : 0]             m13_axi_arburst,
    output wire [7 : 0]             m13_axi_arlen,
    output wire [2 : 0]             m13_axi_arsize,
    output wire [3 : 0]             m13_axi_arid,
    output wire [3 : 0]             m13_axi_arcache,
    output wire                     m13_axi_arlock,
    output wire [3 : 0]             m13_axi_arqos,
    input  wire [255 : 0]           m13_axi_rdata,
    input  wire [1 : 0]             m13_axi_rresp,
    input  wire                     m13_axi_rvalid,
    output wire                     m13_axi_rready,
    input  wire [3 : 0]             m13_axi_rid,
    input  wire                     m13_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m14_axi_araddr,
    output wire [2 : 0]             m14_axi_arprot,
    output wire                     m14_axi_arvalid,
    input  wire                     m14_axi_arready,
    output wire [1 : 0]             m14_axi_arburst,
    output wire [7 : 0]             m14_axi_arlen,
    output wire [2 : 0]             m14_axi_arsize,
    output wire [3 : 0]             m14_axi_arid,
    output wire [3 : 0]             m14_axi_arcache,
    output wire                     m14_axi_arlock,
    output wire [3 : 0]             m14_axi_arqos,
    input  wire [255 : 0]           m14_axi_rdata,
    input  wire [1 : 0]             m14_axi_rresp,
    input  wire                     m14_axi_rvalid,
    output wire                     m14_axi_rready,
    input  wire [3 : 0]             m14_axi_rid,
    input  wire                     m14_axi_rlast,

    output wire [OCCMEM_AW - 1 : 0] m15_axi_araddr,
    output wire [2 : 0]             m15_axi_arprot,
    output wire                     m15_axi_arvalid,
    input  wire                     m15_axi_arready,
    output wire [1 : 0]             m15_axi_arburst,
    output wire [7 : 0]             m15_axi_arlen,
    output wire [2 : 0]             m15_axi_arsize,
    output wire [3 : 0]             m15_axi_arid,
    output wire [3 : 0]             m15_axi_arcache,
    output wire                     m15_axi_arlock,
    output wire [3 : 0]             m15_axi_arqos,
    input  wire [255 : 0]           m15_axi_rdata,
    input  wire [1 : 0]             m15_axi_rresp,
    input  wire                     m15_axi_rvalid,
    output wire                     m15_axi_rready,
    input  wire [3 : 0]             m15_axi_rid,
    input  wire                     m15_axi_rlast
);

    wire [OCCMEM_AW - 1 : 0] m_axi_araddr [16];
    wire [2 : 0]             m_axi_arprot [16];
    wire                     m_axi_arvalid[16];
    wire                     m_axi_arready[16];
    wire [1 : 0]             m_axi_arburst[16];
    wire [7 : 0]             m_axi_arlen  [16];
    wire [2 : 0]             m_axi_arsize [16];
    wire [3 : 0]             m_axi_arid   [16];
    wire [3 : 0]             m_axi_arcache[16];
    wire                     m_axi_arlock [16];
    wire [3 : 0]             m_axi_arqos  [16];
    wire [255 : 0]           m_axi_rdata  [16];
    wire [1 : 0]             m_axi_rresp  [16];
    wire                     m_axi_rvalid [16];
    wire                     m_axi_rready [16];
    wire [3 : 0]             m_axi_rid    [16];
    wire                     m_axi_rlast  [16];

    assign              m00_axi_araddr  = m_axi_araddr [00];
    assign              m00_axi_arprot  = m_axi_arprot [00];
    assign              m00_axi_arvalid = m_axi_arvalid[00];
    assign m_axi_arready[00]            =              m00_axi_arready;
    assign              m00_axi_arburst = m_axi_arburst[00];
    assign              m00_axi_arlen   = m_axi_arlen  [00];
    assign              m00_axi_arsize  = m_axi_arsize [00];
    assign              m00_axi_arid    = m_axi_arid   [00];
    assign              m00_axi_arcache = m_axi_arcache[00];
    assign              m00_axi_arlock  = m_axi_arlock [00];
    assign              m00_axi_arqos   = m_axi_arqos  [00];
    assign m_axi_rdata  [00]            =              m00_axi_rdata  ;
    assign m_axi_rresp  [00]            =              m00_axi_rresp  ;
    assign m_axi_rvalid [00]            =              m00_axi_rvalid ;
    assign              m00_axi_rready  = m_axi_rready [00];
    assign m_axi_rid    [00]            =              m00_axi_rid    ;
    assign m_axi_rlast  [00]            =              m00_axi_rlast  ;

    assign              m01_axi_araddr  = m_axi_araddr [01];
    assign              m01_axi_arprot  = m_axi_arprot [01];
    assign              m01_axi_arvalid = m_axi_arvalid[01];
    assign m_axi_arready[01]            =              m01_axi_arready;
    assign              m01_axi_arburst = m_axi_arburst[01];
    assign              m01_axi_arlen   = m_axi_arlen  [01];
    assign              m01_axi_arsize  = m_axi_arsize [01];
    assign              m01_axi_arid    = m_axi_arid   [01];
    assign              m01_axi_arcache = m_axi_arcache[01];
    assign              m01_axi_arlock  = m_axi_arlock [01];
    assign              m01_axi_arqos   = m_axi_arqos  [01];
    assign m_axi_rdata  [01]            =              m01_axi_rdata  ;
    assign m_axi_rresp  [01]            =              m01_axi_rresp  ;
    assign m_axi_rvalid [01]            =              m01_axi_rvalid ;
    assign              m01_axi_rready  = m_axi_rready [01];
    assign m_axi_rid    [01]            =              m01_axi_rid    ;
    assign m_axi_rlast  [01]            =              m01_axi_rlast  ;

    assign              m02_axi_araddr  = m_axi_araddr [02];
    assign              m02_axi_arprot  = m_axi_arprot [02];
    assign              m02_axi_arvalid = m_axi_arvalid[02];
    assign m_axi_arready[02]            =              m02_axi_arready;
    assign              m02_axi_arburst = m_axi_arburst[02];
    assign              m02_axi_arlen   = m_axi_arlen  [02];
    assign              m02_axi_arsize  = m_axi_arsize [02];
    assign              m02_axi_arid    = m_axi_arid   [02];
    assign              m02_axi_arcache = m_axi_arcache[02];
    assign              m02_axi_arlock  = m_axi_arlock [02];
    assign              m02_axi_arqos   = m_axi_arqos  [02];
    assign m_axi_rdata  [02]            =              m02_axi_rdata  ;
    assign m_axi_rresp  [02]            =              m02_axi_rresp  ;
    assign m_axi_rvalid [02]            =              m02_axi_rvalid ;
    assign              m02_axi_rready  = m_axi_rready [02];
    assign m_axi_rid    [02]            =              m02_axi_rid    ;
    assign m_axi_rlast  [02]            =              m02_axi_rlast  ;

    assign              m03_axi_araddr  = m_axi_araddr [03];
    assign              m03_axi_arprot  = m_axi_arprot [03];
    assign              m03_axi_arvalid = m_axi_arvalid[03];
    assign m_axi_arready[03]            =              m03_axi_arready;
    assign              m03_axi_arburst = m_axi_arburst[03];
    assign              m03_axi_arlen   = m_axi_arlen  [03];
    assign              m03_axi_arsize  = m_axi_arsize [03];
    assign              m03_axi_arid    = m_axi_arid   [03];
    assign              m03_axi_arcache = m_axi_arcache[03];
    assign              m03_axi_arlock  = m_axi_arlock [03];
    assign              m03_axi_arqos   = m_axi_arqos  [03];
    assign m_axi_rdata  [03]            =              m03_axi_rdata  ;
    assign m_axi_rresp  [03]            =              m03_axi_rresp  ;
    assign m_axi_rvalid [03]            =              m03_axi_rvalid ;
    assign              m03_axi_rready  = m_axi_rready [03];
    assign m_axi_rid    [03]            =              m03_axi_rid    ;
    assign m_axi_rlast  [03]            =              m03_axi_rlast  ;

    assign              m04_axi_araddr  = m_axi_araddr [04];
    assign              m04_axi_arprot  = m_axi_arprot [04];
    assign              m04_axi_arvalid = m_axi_arvalid[04];
    assign m_axi_arready[04]            =              m04_axi_arready;
    assign              m04_axi_arburst = m_axi_arburst[04];
    assign              m04_axi_arlen   = m_axi_arlen  [04];
    assign              m04_axi_arsize  = m_axi_arsize [04];
    assign              m04_axi_arid    = m_axi_arid   [04];
    assign              m04_axi_arcache = m_axi_arcache[04];
    assign              m04_axi_arlock  = m_axi_arlock [04];
    assign              m04_axi_arqos   = m_axi_arqos  [04];
    assign m_axi_rdata  [04]            =              m04_axi_rdata  ;
    assign m_axi_rresp  [04]            =              m04_axi_rresp  ;
    assign m_axi_rvalid [04]            =              m04_axi_rvalid ;
    assign              m04_axi_rready  = m_axi_rready [04];
    assign m_axi_rid    [04]            =              m04_axi_rid    ;
    assign m_axi_rlast  [04]            =              m04_axi_rlast  ;

    assign              m05_axi_araddr  = m_axi_araddr [05];
    assign              m05_axi_arprot  = m_axi_arprot [05];
    assign              m05_axi_arvalid = m_axi_arvalid[05];
    assign m_axi_arready[05]            =              m05_axi_arready;
    assign              m05_axi_arburst = m_axi_arburst[05];
    assign              m05_axi_arlen   = m_axi_arlen  [05];
    assign              m05_axi_arsize  = m_axi_arsize [05];
    assign              m05_axi_arid    = m_axi_arid   [05];
    assign              m05_axi_arcache = m_axi_arcache[05];
    assign              m05_axi_arlock  = m_axi_arlock [05];
    assign              m05_axi_arqos   = m_axi_arqos  [05];
    assign m_axi_rdata  [05]            =              m05_axi_rdata  ;
    assign m_axi_rresp  [05]            =              m05_axi_rresp  ;
    assign m_axi_rvalid [05]            =              m05_axi_rvalid ;
    assign              m05_axi_rready  = m_axi_rready [05];
    assign m_axi_rid    [05]            =              m05_axi_rid    ;
    assign m_axi_rlast  [05]            =              m05_axi_rlast  ;

    assign              m06_axi_araddr  = m_axi_araddr [06];
    assign              m06_axi_arprot  = m_axi_arprot [06];
    assign              m06_axi_arvalid = m_axi_arvalid[06];
    assign m_axi_arready[06]            =              m06_axi_arready;
    assign              m06_axi_arburst = m_axi_arburst[06];
    assign              m06_axi_arlen   = m_axi_arlen  [06];
    assign              m06_axi_arsize  = m_axi_arsize [06];
    assign              m06_axi_arid    = m_axi_arid   [06];
    assign              m06_axi_arcache = m_axi_arcache[06];
    assign              m06_axi_arlock  = m_axi_arlock [06];
    assign              m06_axi_arqos   = m_axi_arqos  [06];
    assign m_axi_rdata  [06]            =              m06_axi_rdata  ;
    assign m_axi_rresp  [06]            =              m06_axi_rresp  ;
    assign m_axi_rvalid [06]            =              m06_axi_rvalid ;
    assign              m06_axi_rready  = m_axi_rready [06];
    assign m_axi_rid    [06]            =              m06_axi_rid    ;
    assign m_axi_rlast  [06]            =              m06_axi_rlast  ;

    assign              m07_axi_araddr  = m_axi_araddr [07];
    assign              m07_axi_arprot  = m_axi_arprot [07];
    assign              m07_axi_arvalid = m_axi_arvalid[07];
    assign m_axi_arready[07]            =              m07_axi_arready;
    assign              m07_axi_arburst = m_axi_arburst[07];
    assign              m07_axi_arlen   = m_axi_arlen  [07];
    assign              m07_axi_arsize  = m_axi_arsize [07];
    assign              m07_axi_arid    = m_axi_arid   [07];
    assign              m07_axi_arcache = m_axi_arcache[07];
    assign              m07_axi_arlock  = m_axi_arlock [07];
    assign              m07_axi_arqos   = m_axi_arqos  [07];
    assign m_axi_rdata  [07]            =              m07_axi_rdata  ;
    assign m_axi_rresp  [07]            =              m07_axi_rresp  ;
    assign m_axi_rvalid [07]            =              m07_axi_rvalid ;
    assign              m07_axi_rready  = m_axi_rready [07];
    assign m_axi_rid    [07]            =              m07_axi_rid    ;
    assign m_axi_rlast  [07]            =              m07_axi_rlast  ;

    assign              m08_axi_araddr  = m_axi_araddr [08];
    assign              m08_axi_arprot  = m_axi_arprot [08];
    assign              m08_axi_arvalid = m_axi_arvalid[08];
    assign m_axi_arready[08]            =              m08_axi_arready;
    assign              m08_axi_arburst = m_axi_arburst[08];
    assign              m08_axi_arlen   = m_axi_arlen  [08];
    assign              m08_axi_arsize  = m_axi_arsize [08];
    assign              m08_axi_arid    = m_axi_arid   [08];
    assign              m08_axi_arcache = m_axi_arcache[08];
    assign              m08_axi_arlock  = m_axi_arlock [08];
    assign              m08_axi_arqos   = m_axi_arqos  [08];
    assign m_axi_rdata  [08]            =              m08_axi_rdata  ;
    assign m_axi_rresp  [08]            =              m08_axi_rresp  ;
    assign m_axi_rvalid [08]            =              m08_axi_rvalid ;
    assign              m08_axi_rready  = m_axi_rready [08];
    assign m_axi_rid    [08]            =              m08_axi_rid    ;
    assign m_axi_rlast  [08]            =              m08_axi_rlast  ;

    assign              m09_axi_araddr  = m_axi_araddr [09];
    assign              m09_axi_arprot  = m_axi_arprot [09];
    assign              m09_axi_arvalid = m_axi_arvalid[09];
    assign m_axi_arready[09]            =              m09_axi_arready;
    assign              m09_axi_arburst = m_axi_arburst[09];
    assign              m09_axi_arlen   = m_axi_arlen  [09];
    assign              m09_axi_arsize  = m_axi_arsize [09];
    assign              m09_axi_arid    = m_axi_arid   [09];
    assign              m09_axi_arcache = m_axi_arcache[09];
    assign              m09_axi_arlock  = m_axi_arlock [09];
    assign              m09_axi_arqos   = m_axi_arqos  [09];
    assign m_axi_rdata  [09]            =              m09_axi_rdata  ;
    assign m_axi_rresp  [09]            =              m09_axi_rresp  ;
    assign m_axi_rvalid [09]            =              m09_axi_rvalid ;
    assign              m09_axi_rready  = m_axi_rready [09];
    assign m_axi_rid    [09]            =              m09_axi_rid    ;
    assign m_axi_rlast  [09]            =              m09_axi_rlast  ;

    assign              m10_axi_araddr  = m_axi_araddr [10];
    assign              m10_axi_arprot  = m_axi_arprot [10];
    assign              m10_axi_arvalid = m_axi_arvalid[10];
    assign m_axi_arready[10]            =              m10_axi_arready;
    assign              m10_axi_arburst = m_axi_arburst[10];
    assign              m10_axi_arlen   = m_axi_arlen  [10];
    assign              m10_axi_arsize  = m_axi_arsize [10];
    assign              m10_axi_arid    = m_axi_arid   [10];
    assign              m10_axi_arcache = m_axi_arcache[10];
    assign              m10_axi_arlock  = m_axi_arlock [10];
    assign              m10_axi_arqos   = m_axi_arqos  [10];
    assign m_axi_rdata  [10]            =              m10_axi_rdata  ;
    assign m_axi_rresp  [10]            =              m10_axi_rresp  ;
    assign m_axi_rvalid [10]            =              m10_axi_rvalid ;
    assign              m10_axi_rready  = m_axi_rready [10];
    assign m_axi_rid    [10]            =              m10_axi_rid    ;
    assign m_axi_rlast  [10]            =              m10_axi_rlast  ;

    assign              m11_axi_araddr  = m_axi_araddr [11];
    assign              m11_axi_arprot  = m_axi_arprot [11];
    assign              m11_axi_arvalid = m_axi_arvalid[11];
    assign m_axi_arready[11]            =              m11_axi_arready;
    assign              m11_axi_arburst = m_axi_arburst[11];
    assign              m11_axi_arlen   = m_axi_arlen  [11];
    assign              m11_axi_arsize  = m_axi_arsize [11];
    assign              m11_axi_arid    = m_axi_arid   [11];
    assign              m11_axi_arcache = m_axi_arcache[11];
    assign              m11_axi_arlock  = m_axi_arlock [11];
    assign              m11_axi_arqos   = m_axi_arqos  [11];
    assign m_axi_rdata  [11]            =              m11_axi_rdata  ;
    assign m_axi_rresp  [11]            =              m11_axi_rresp  ;
    assign m_axi_rvalid [11]            =              m11_axi_rvalid ;
    assign              m11_axi_rready  = m_axi_rready [11];
    assign m_axi_rid    [11]            =              m11_axi_rid    ;
    assign m_axi_rlast  [11]            =              m11_axi_rlast  ;

    assign              m12_axi_araddr  = m_axi_araddr [12];
    assign              m12_axi_arprot  = m_axi_arprot [12];
    assign              m12_axi_arvalid = m_axi_arvalid[12];
    assign m_axi_arready[12]            =              m12_axi_arready;
    assign              m12_axi_arburst = m_axi_arburst[12];
    assign              m12_axi_arlen   = m_axi_arlen  [12];
    assign              m12_axi_arsize  = m_axi_arsize [12];
    assign              m12_axi_arid    = m_axi_arid   [12];
    assign              m12_axi_arcache = m_axi_arcache[12];
    assign              m12_axi_arlock  = m_axi_arlock [12];
    assign              m12_axi_arqos   = m_axi_arqos  [12];
    assign m_axi_rdata  [12]            =              m12_axi_rdata  ;
    assign m_axi_rresp  [12]            =              m12_axi_rresp  ;
    assign m_axi_rvalid [12]            =              m12_axi_rvalid ;
    assign              m12_axi_rready  = m_axi_rready [12];
    assign m_axi_rid    [12]            =              m12_axi_rid    ;
    assign m_axi_rlast  [12]            =              m12_axi_rlast  ;

    assign              m13_axi_araddr  = m_axi_araddr [13];
    assign              m13_axi_arprot  = m_axi_arprot [13];
    assign              m13_axi_arvalid = m_axi_arvalid[13];
    assign m_axi_arready[13]            =              m13_axi_arready;
    assign              m13_axi_arburst = m_axi_arburst[13];
    assign              m13_axi_arlen   = m_axi_arlen  [13];
    assign              m13_axi_arsize  = m_axi_arsize [13];
    assign              m13_axi_arid    = m_axi_arid   [13];
    assign              m13_axi_arcache = m_axi_arcache[13];
    assign              m13_axi_arlock  = m_axi_arlock [13];
    assign              m13_axi_arqos   = m_axi_arqos  [13];
    assign m_axi_rdata  [13]            =              m13_axi_rdata  ;
    assign m_axi_rresp  [13]            =              m13_axi_rresp  ;
    assign m_axi_rvalid [13]            =              m13_axi_rvalid ;
    assign              m13_axi_rready  = m_axi_rready [13];
    assign m_axi_rid    [13]            =              m13_axi_rid    ;
    assign m_axi_rlast  [13]            =              m13_axi_rlast  ;

    assign              m14_axi_araddr  = m_axi_araddr [14];
    assign              m14_axi_arprot  = m_axi_arprot [14];
    assign              m14_axi_arvalid = m_axi_arvalid[14];
    assign m_axi_arready[14]            =              m14_axi_arready;
    assign              m14_axi_arburst = m_axi_arburst[14];
    assign              m14_axi_arlen   = m_axi_arlen  [14];
    assign              m14_axi_arsize  = m_axi_arsize [14];
    assign              m14_axi_arid    = m_axi_arid   [14];
    assign              m14_axi_arcache = m_axi_arcache[14];
    assign              m14_axi_arlock  = m_axi_arlock [14];
    assign              m14_axi_arqos   = m_axi_arqos  [14];
    assign m_axi_rdata  [14]            =              m14_axi_rdata  ;
    assign m_axi_rresp  [14]            =              m14_axi_rresp  ;
    assign m_axi_rvalid [14]            =              m14_axi_rvalid ;
    assign              m14_axi_rready  = m_axi_rready [14];
    assign m_axi_rid    [14]            =              m14_axi_rid    ;
    assign m_axi_rlast  [14]            =              m14_axi_rlast  ;

    assign              m15_axi_araddr  = m_axi_araddr [15];
    assign              m15_axi_arprot  = m_axi_arprot [15];
    assign              m15_axi_arvalid = m_axi_arvalid[15];
    assign m_axi_arready[15]            =              m15_axi_arready;
    assign              m15_axi_arburst = m_axi_arburst[15];
    assign              m15_axi_arlen   = m_axi_arlen  [15];
    assign              m15_axi_arsize  = m_axi_arsize [15];
    assign              m15_axi_arid    = m_axi_arid   [15];
    assign              m15_axi_arcache = m_axi_arcache[15];
    assign              m15_axi_arlock  = m_axi_arlock [15];
    assign              m15_axi_arqos   = m_axi_arqos  [15];
    assign m_axi_rdata  [15]            =              m15_axi_rdata  ;
    assign m_axi_rresp  [15]            =              m15_axi_rresp  ;
    assign m_axi_rvalid [15]            =              m15_axi_rvalid ;
    assign              m15_axi_rready  = m_axi_rready [15];
    assign m_axi_rid    [15]            =              m15_axi_rid    ;
    assign m_axi_rlast  [15]            =              m15_axi_rlast  ;

    ProcessBlockX16 #(
        .READ_LEN       (READ_LEN),
        .OCCMEM_AW      (OCCMEM_AW),
        .OCC_BASE       (OCC_BASE),
        .FILTER_GRP_SIZE(FILTER_GRP_SIZE),
        .BIDIREX_QU_AW  (BIDIREX_QU_AW),
        .RESEED_QU_AW   (RESEED_QU_AW),
        .SEEDOUT_QU_AW  (SEEDOUT_QU_AW)
    ) pbx16(
        .clk          (clk),
        .rst_n        (rst_n),
        .ri_data      (s_axis_tdata),
        .ri_valid     (s_axis_tvalid),
        .ri_ready     (s_axis_tready),
        .so_data      (m_axis_tdata),
        .so_last      (m_axis_tlast),
        .so_valid     (m_axis_tvalid),
        .so_ready     (m_axis_tready),
        .acc_cnt_A    (acc_cnt_A),
        .acc_cnt_C    (acc_cnt_C),
        .acc_cnt_G    (acc_cnt_G),
        .acc_cnt_T    (acc_cnt_T),
        .pri_pos      (pri_pos),
        .bwt_len      (bwt_len),
        .min_mlen     (min_mlen),
        .sf_mlen      (sf_mlen),
        .sf_max_intv  (sf_max_intv),
        .rs_min_mlen  (rs_min_mlen),
        .rs_max_intv  (rs_max_intv),
        .param_update (param_update),
        .m_axi_araddr (m_axi_araddr),
        .m_axi_arprot (m_axi_arprot),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arlen  (m_axi_arlen),
        .m_axi_arsize (m_axi_arsize),
        .m_axi_arid   (m_axi_arid),
        .m_axi_arcache(m_axi_arcache),
        .m_axi_arlock (m_axi_arlock),
        .m_axi_arqos  (m_axi_arqos),
        .m_axi_rdata  (m_axi_rdata),
        .m_axi_rresp  (m_axi_rresp),
        .m_axi_rvalid (m_axi_rvalid),
        .m_axi_rready (m_axi_rready),
        .m_axi_rid    (m_axi_rid),
        .m_axi_rlast  (m_axi_rlast)
    );

endmodule // ProcessBlockX16Wrapper
