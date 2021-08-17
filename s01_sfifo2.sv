`default_nettype none

module SdpRamRf #(
    parameter DW = 8, WORDS = 256
)(
    input wire clk,
    input wire [$clog2(WORDS) - 1 : 0] addr_a,
    input wire wr_a,
    input wire [DW - 1 : 0] din_a,
    input wire [$clog2(WORDS) - 1 : 0] addr_b,
    output logic [DW - 1 : 0] qout_b
);
    (* ram_style = "block" *) logic [DW - 1 : 0] ram[WORDS];
    always_ff@(posedge clk) begin
        if(wr_a) begin
            ram[addr_a] <= din_a;
        end
    end
    always_ff@(posedge clk) begin
        qout_b <= ram[addr_b];
    end
endmodule

module ScFifo2 #(
    parameter DW = 8,
    parameter AW = 10
)(
    input wire clk,
    input wire [DW - 1 : 0] din,
    input wire write,
    output logic [DW - 1 : 0] dout,
    input wire read,
    output logic [AW - 1 : 0] wr_cnt = '0, rd_cnt = '0,
    output logic [AW - 1 : 0] data_cnt,
    output logic full, empty
);
    localparam CAPACITY = 2**AW - 1;
    always_ff@(posedge clk) begin
        if(write) wr_cnt <= wr_cnt + 1'b1;
    end
    always_ff@(posedge clk) begin
        if(read) rd_cnt <= rd_cnt + 1'b1;
    end
    assign data_cnt = wr_cnt - rd_cnt;
    assign full = data_cnt == CAPACITY;
    assign empty = data_cnt == 0;
    logic rd_dly;
    always_ff@(posedge clk) begin
        rd_dly <= read;
    end
    logic [DW - 1 : 0] qout_b, qout_b_reg = '0;
    always_ff@(posedge clk) begin
        if(rd_dly) qout_b_reg <= qout_b;
    end
    SdpRamRf #(.DW(DW), .WORDS(2**AW)) theRam(
        .clk(clk), .addr_a(wr_cnt), .wr_a(write),
        .din_a(din), .addr_b(rd_cnt), .qout_b(qout_b)
    );
    assign dout = (rd_dly)? qout_b : qout_b_reg;
endmodule

module StreamFifo 
#(
    parameter DW = 32,
    parameter AW = 8
)(
    input wire clk, rst,
    input wire [DW - 1 : 0] in_data,
    input wire in_valid,
    output wire in_ready,
    output wire [DW - 1 : 0] out_data,
    output logic out_valid,
    input wire out_ready,
    output wire [AW : 0] data_cnt
);
    wire [AW - 1 : 0] dc;
    logic full, empty;
    assign in_ready = ~full;
    wire wr = in_ready & in_valid;
    wire rd = ~empty & (~out_valid | out_valid & out_ready);
    ScFifo2 #(DW, AW) theFifo(
        clk, in_data, wr, out_data, rd,
        , , dc, full, empty);
    always_ff@(posedge clk) begin
        if(rst) out_valid <= '0;
        else if(rd) out_valid <= '1;
        else if(out_ready) out_valid <= 0;
    end
    assign data_cnt = dc + out_valid;
endmodule
