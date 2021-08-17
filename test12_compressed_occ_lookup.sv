// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180818

`default_nettype none

module TestCompressedOccLookup;
    import SimSrcGen::*;
    import BwaMemDefines::*;

    logic clk, rst;
    initial GenClk(clk, 8, 10);
    initial GenRst(clk, rst, 2, 2);

    logic [KLS_W-1 : 0] k, ks;
    logic start;
    wire valid;
    wire [KLS_W-1 : 0] val_k[0:3], val_ks[0:3];

    Axi4LiteIf #(.AW(40), .DW(256)) axi(.clk(clk), .reset_n(~rst));

    OccLookup #( .AW(40), .OCC_BASE(40'h00_0000_0000))
    theDUT
    (
        .clk(clk), .rst(rst),
        .k_in(k), .ks_in(ks),
        .val_k(val_k), .val_ks(val_ks),
        .start(start), .val_valid(valid),
        .m_axi_occlu(axi.master)
    );

    FileROM #(.BASE_ADDR(64'd0), .MEAN_LATENCY(32))
    theROM
    (
        .s_axi4l(axi.slave)
    );

    logic [79:0] kandks[10] = '{
        {40'd0000000000, 40'd0000000001},
        {40'd0000000002, 40'd0000000003},
        {40'd1000000000, 40'd1000000001},
        {40'd1000000002, 40'd1000000003},
        {40'd2000000000, 40'd2000000001},
        {40'd2147483647, 40'd2147483648},
        {40'd2668688547, 40'd2668688548},
        {40'd2668688549, 40'd2668688550},
        {40'd6274909009, 40'd6274909010},
        {40'd6274909011, 40'd6274909012}
    };

    initial begin

        do @(posedge clk); while(~rst);
        do @(posedge clk); while(rst);

        for(int i = 0; i < 10; i++) begin
            @(posedge clk) begin
                {k, ks} <= kandks[i];
                start <= 1'b1;
            end
            @(posedge clk) start <= 1'b0;
            do @(posedge clk); while(~valid);
        end

        @(posedge clk) $stop();

    end

endmodule // TestCompressedOccLookup


