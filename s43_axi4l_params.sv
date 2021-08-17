// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180826

//  reg addr

//  0   0x00    bwt_len    [39: 0]
//  2   0x08    pri_pos    [39: 0]
//  4   0x10    acc_cnt_A  [39: 0]
//  6   0x18    acc_cnt_C  [39: 0]
//  8   0x20    acc_cnt_G  [39: 0]
//  10  0x28    acc_cnt_T  [39: 0]
//  12  0x30    min_mlen   [15: 0]
//  13  0x34    sf_mlen    [15: 0]
//  14  0x38    sf_max_intv[39: 0]
//  16  0x40    rs_min_mlen[15: 0]
//  18  0x48    rs_max_intv[39: 0]
//  20  0x50    params_update   (write event)
//  21  0x54    down_fifo_dc[31:0]
//  22  0x58    up_fifo_dc  [31:0]
//  23  0x5c    reg_rsv0
//  24  0x60    reg_rsv1
//  25  0x64    reg_rsv2
//  26  0x68    reg_rsv3
//  27  0x6c    reg_rsv4
//  28  0x70    reg_rsv5
//  29  0x74    reg_rsv6
//  30  0x78    reg_rsv7
//  31  0x7c    reg_rsv8

module Axi4LiteParams (
    input  wire  s_axi_aclk,
    input  wire  s_axi_aresetn,
    input  wire  [ 7 : 0]   s_axi_awaddr,
    input  wire  [ 2 : 0]   s_axi_awprot,
    input  wire             s_axi_awvalid,
    output logic            s_axi_awready,
    input  wire  [31 : 0]   s_axi_wdata,
    input  wire  [ 3 : 0]   s_axi_wstrb,
    input  wire             s_axi_wvalid,
    output logic            s_axi_wready,
    output logic [ 1 : 0]   s_axi_bresp,
    output logic            s_axi_bvalid,
    input  wire             s_axi_bready,
    input  wire  [ 7 : 0]   s_axi_araddr,
    input  wire  [ 2 : 0]   s_axi_arprot,
    input  wire             s_axi_arvalid,
    output logic            s_axi_arready,
    output logic [31 : 0]   s_axi_rdata,
    output logic [1 : 0]    s_axi_rresp,
    output logic            s_axi_rvalid,
    input  wire             s_axi_rready,

    output logic [39 : 0]   acc_cnt_A,
    output logic [39 : 0]   acc_cnt_C,
    output logic [39 : 0]   acc_cnt_G,
    output logic [39 : 0]   acc_cnt_T,
    output logic [39 : 0]   pri_pos,
    output logic [39 : 0]   bwt_len,
    output logic [15 : 0]   min_mlen,
    output logic [15 : 0]   sf_mlen,
    output logic [39 : 0]   sf_max_intv,
    output logic [15 : 0]   rs_min_mlen,
    output logic [39 : 0]   rs_max_intv,
    output logic            params_update,

    output logic [31:0]     reg_rsv0,
    output logic [31:0]     reg_rsv1,
    output logic [31:0]     reg_rsv2,
    output logic [31:0]     reg_rsv3,
    output logic [31:0]     reg_rsv4,
    output logic [31:0]     reg_rsv5,
    output logic [31:0]     reg_rsv6,
    output logic [31:0]     reg_rsv7,
    output logic [31:0]     reg_rsv8,
    output logic [30:0]     ud_rsv,   

    input  wire  [31:0]     down_fifo_dc,
    input  wire  [31:0]     up_fifo_dc,

    input  wire  [31:0]     in_rsv0,
    input  wire  [31:0]     in_rsv1,
    input  wire  [31:0]     in_rsv2,
    input  wire  [31:0]     in_rsv3,
    input  wire  [31:0]     in_rsv4,
    input  wire  [31:0]     in_rsv5,
    input  wire  [31:0]     in_rsv6,
    input  wire  [31:0]     in_rsv7,
    input  wire  [31:0]     in_rsv8
);
    localparam logic [5:0] reg_bwt_len0      =  0;
    localparam logic [5:0] reg_bwt_len1      =  1;
    localparam logic [5:0] reg_pri_pos0      =  2;
    localparam logic [5:0] reg_pri_pos1      =  3;
    localparam logic [5:0] reg_acc_cnt_A0    =  4;
    localparam logic [5:0] reg_acc_cnt_A1    =  5;
    localparam logic [5:0] reg_acc_cnt_C0    =  6;
    localparam logic [5:0] reg_acc_cnt_C1    =  7;
    localparam logic [5:0] reg_acc_cnt_G0    =  8;
    localparam logic [5:0] reg_acc_cnt_G1    =  9;
    localparam logic [5:0] reg_acc_cnt_T0    = 10;
    localparam logic [5:0] reg_acc_cnt_T1    = 11;
    localparam logic [5:0] reg_min_mlen      = 12;
    localparam logic [5:0] reg_sf_mlen       = 13;
    localparam logic [5:0] reg_sf_max_intv0  = 14;
    localparam logic [5:0] reg_sf_max_intv1  = 15;
    localparam logic [5:0] reg_rs_min_mlen   = 16;
    localparam logic [5:0] reg_rs_max_intv0  = 18;
    localparam logic [5:0] reg_rs_max_intv1  = 19;
    localparam logic [5:0] reg_params_update = 20;
    localparam logic [5:0] reg_down_fifo_d   = 21;
    localparam logic [5:0] reg_up_fifo_dc    = 22;
    localparam logic [5:0] reg_reserve0      = 23;
    localparam logic [5:0] reg_reserve1      = 24;
    localparam logic [5:0] reg_reserve2      = 25;
    localparam logic [5:0] reg_reserve3      = 26;
    localparam logic [5:0] reg_reserve4      = 27;
    localparam logic [5:0] reg_reserve5      = 28;
    localparam logic [5:0] reg_reserve6      = 29;
    localparam logic [5:0] reg_reserve7      = 30;
    localparam logic [5:0] reg_reserve8      = 31;

    wire clk = s_axi_aclk;
    wire rst = ~s_axi_aresetn;

    logic regs_wr, regs_rd;
    // ==== aw channel ====
    assign s_axi_awready = 1'b1;    // always ready
    logic [5 : 0] waddr_reg;   // byte addr --> reg addr
    always_ff@(posedge s_axi_aclk) begin
        if(rst) waddr_reg <= '0;
        else if(s_axi_awvalid) waddr_reg <= s_axi_awaddr[7 : 2];
    end
    // === w channel ===
    assign regs_wr = s_axi_wvalid & s_axi_wready;
    always_ff@(posedge clk) begin
        if(rst) s_axi_wready <= 1'b0;
        else if(s_axi_awvalid) s_axi_wready <= 1'b1;          //waddr got
        else if(s_axi_wvalid & s_axi_wready) s_axi_wready <= 1'b0; //handshake
    end
    // === b ch ===
    assign s_axi_bresp = 2'b00;     // always ok
    always_ff@(posedge clk) begin
        if(rst) s_axi_bvalid <= 1'b0;
        else if(s_axi_wvalid & s_axi_wready) s_axi_bvalid <= 1'b1;//wdata got
        else if(s_axi_bvalid & s_axi_bready) s_axi_bvalid <= 1'b0;//handshake
    end
    // === ar ch ===
    logic [5 : 0] raddr_reg;
    always_ff@(posedge clk) begin
        if(rst) raddr_reg <= 1'b0;
        else if(s_axi_arvalid) raddr_reg <= s_axi_araddr[7 : 2];
    end
    always_ff@(posedge clk) begin
        if(rst) s_axi_arready <= 1'b0;
        else if(s_axi_arvalid & ~s_axi_arready) s_axi_arready <= 1'b1;            //raddr got
        else if(s_axi_arvalid & s_axi_arready) s_axi_arready <= 1'b0;//handshake
    end
    assign regs_rd = s_axi_arvalid & s_axi_arready;
    // === r ch ===
    assign s_axi_rresp = 2'b00;     // always ok
    always_ff@(posedge clk) begin
        if(rst) s_axi_rvalid <= 1'b0;
        else if(regs_rd) s_axi_rvalid <= 1'b1;
        else if(s_axi_rvalid & s_axi_rready) s_axi_rvalid <= 1'b0;
    end
    always_ff@(posedge clk) begin
        if(rst) s_axi_rdata <= '0;
        else if(regs_rd) begin
            case(raddr_reg)
            reg_bwt_len0     : s_axi_rdata <= bwt_len    [31:0] ;
            reg_bwt_len1     : s_axi_rdata <= bwt_len    [39:32];
            reg_pri_pos0     : s_axi_rdata <= pri_pos    [31:0] ;
            reg_pri_pos1     : s_axi_rdata <= pri_pos    [39:32];
            reg_acc_cnt_A0   : s_axi_rdata <= acc_cnt_A  [31:0] ;
            reg_acc_cnt_A1   : s_axi_rdata <= acc_cnt_A  [39:32];
            reg_acc_cnt_C0   : s_axi_rdata <= acc_cnt_C  [31:0] ;
            reg_acc_cnt_C1   : s_axi_rdata <= acc_cnt_C  [39:32];
            reg_acc_cnt_G0   : s_axi_rdata <= acc_cnt_G  [31:0] ;
            reg_acc_cnt_G1   : s_axi_rdata <= acc_cnt_G  [39:32];
            reg_acc_cnt_T0   : s_axi_rdata <= acc_cnt_T  [31:0] ;
            reg_acc_cnt_T1   : s_axi_rdata <= acc_cnt_T  [39:32];
            reg_min_mlen     : s_axi_rdata <= min_mlen          ;
            reg_sf_mlen      : s_axi_rdata <= sf_mlen           ;
            reg_sf_max_intv0 : s_axi_rdata <= sf_max_intv[31:0] ;
            reg_sf_max_intv1 : s_axi_rdata <= sf_max_intv[39:32];
            reg_rs_min_mlen  : s_axi_rdata <= rs_min_mlen       ;
            reg_rs_max_intv0 : s_axi_rdata <= rs_max_intv[31:0] ;
            reg_rs_max_intv1 : s_axi_rdata <= rs_max_intv[39:32];
            reg_params_update: s_axi_rdata <= '0                ;
            reg_down_fifo_d  : s_axi_rdata <= down_fifo_dc      ;
            reg_up_fifo_dc   : s_axi_rdata <= up_fifo_dc        ;
            reg_reserve0     : s_axi_rdata <= in_rsv0           ;
            reg_reserve1     : s_axi_rdata <= in_rsv1           ;
            reg_reserve2     : s_axi_rdata <= in_rsv2           ;
            reg_reserve3     : s_axi_rdata <= in_rsv3           ;
            reg_reserve4     : s_axi_rdata <= in_rsv4           ;
            reg_reserve5     : s_axi_rdata <= in_rsv5           ;
            reg_reserve6     : s_axi_rdata <= in_rsv6           ;
            reg_reserve7     : s_axi_rdata <= in_rsv7           ;
            reg_reserve8     : s_axi_rdata <= in_rsv8           ;
            default          : s_axi_rdata <= '0                ;
            endcase // raddr_reg
        end
    end
    // === regs ===
    always_ff@(posedge clk) begin
        if(rst) begin
            bwt_len     <= '0;
            pri_pos     <= '0;
            acc_cnt_A   <= '0;
            acc_cnt_C   <= '0;
            acc_cnt_G   <= '0;
            acc_cnt_T   <= '0;
            min_mlen    <= '0;
            sf_mlen     <= '0;
            sf_max_intv <= '0;
            rs_min_mlen <= '0;
            rs_max_intv <= '0;
            reg_rsv0    <= '0;
            reg_rsv1    <= '0;
            reg_rsv2    <= '0;
            reg_rsv3    <= '0;
            reg_rsv4    <= '0;
            reg_rsv5    <= '0;
            reg_rsv6    <= '0;
            reg_rsv7    <= '0;
            reg_rsv8    <= '0;
        end
        else if(regs_wr) begin
            case(waddr_reg)
            reg_bwt_len0     : bwt_len    [31:0]  <= s_axi_wdata[31:0];
            reg_bwt_len1     : bwt_len    [39:32] <= s_axi_wdata[ 7:0];
            reg_pri_pos0     : pri_pos    [31:0]  <= s_axi_wdata[31:0];
            reg_pri_pos1     : pri_pos    [39:32] <= s_axi_wdata[ 7:0];
            reg_acc_cnt_A0   : acc_cnt_A  [31:0]  <= s_axi_wdata[31:0];
            reg_acc_cnt_A1   : acc_cnt_A  [39:32] <= s_axi_wdata[ 7:0];
            reg_acc_cnt_C0   : acc_cnt_C  [31:0]  <= s_axi_wdata[31:0];
            reg_acc_cnt_C1   : acc_cnt_C  [39:32] <= s_axi_wdata[ 7:0];
            reg_acc_cnt_G0   : acc_cnt_G  [31:0]  <= s_axi_wdata[31:0];
            reg_acc_cnt_G1   : acc_cnt_G  [39:32] <= s_axi_wdata[ 7:0];
            reg_acc_cnt_T0   : acc_cnt_T  [31:0]  <= s_axi_wdata[31:0];
            reg_acc_cnt_T1   : acc_cnt_T  [39:32] <= s_axi_wdata[ 7:0];
            reg_min_mlen     : min_mlen           <= s_axi_wdata[15:0];
            reg_sf_mlen      : sf_mlen            <= s_axi_wdata[15:0];
            reg_sf_max_intv0 : sf_max_intv[31:0]  <= s_axi_wdata[31:0];
            reg_sf_max_intv1 : sf_max_intv[39:32] <= s_axi_wdata[ 7:0];
            reg_rs_min_mlen  : rs_min_mlen        <= s_axi_wdata[15:0];
            reg_rs_max_intv0 : rs_max_intv[31:0]  <= s_axi_wdata[31:0];
            reg_rs_max_intv1 : rs_max_intv[39:32] <= s_axi_wdata[ 7:0];
            // reg_params_update: '0                 <= s_axi_wdata[31:0];
            // reg_down_fifo_d  : down_fifo_d        <= s_axi_wdata[31:0];
            // reg_up_fifo_dc   : up_fifo_dc         <= s_axi_wdata[31:0];
            reg_reserve0     : reg_rsv0           <= s_axi_wdata[31:0];
            reg_reserve1     : reg_rsv1           <= s_axi_wdata[31:0];
            reg_reserve2     : reg_rsv2           <= s_axi_wdata[31:0];
            reg_reserve3     : reg_rsv3           <= s_axi_wdata[31:0];
            reg_reserve4     : reg_rsv4           <= s_axi_wdata[31:0];
            reg_reserve5     : reg_rsv5           <= s_axi_wdata[31:0];
            reg_reserve6     : reg_rsv6           <= s_axi_wdata[31:0];
            reg_reserve7     : reg_rsv7           <= s_axi_wdata[31:0];
            reg_reserve8     : reg_rsv8           <= s_axi_wdata[31:0];
            endcase // raddr_reg
        end
    end
    
    always_ff @(posedge clk) begin : proc_ud
        if(rst) begin
            {ud_rsv, params_update} <= '0;
        end
        else if(regs_wr && waddr_reg == reg_params_update) begin
            {ud_rsv, params_update} <= s_axi_wdata;
        end
        else begin
            {ud_rsv, params_update} <= '0;
        end
    end

endmodule