// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180818

// Simulation ONLY
`default_nettype none

module FileROM
#(
    // parameter string FILE = "",
    parameter [39:0] BASE_ADDR = 40'h00_0000_0000,
    parameter MEAN_LATENCY = 10
)(
    Axi4LiteIf.slave s_axi4l
);
    // logic [s_axi4l.DW - 1 : 0] data;

    integer fd[3], code;
    initial begin
        fd[0] = $fopen("./data/hs37d5_cocc0.bin", "rb");
        fd[1] = $fopen("./data/hs37d5_cocc1.bin", "rb");
        fd[2] = $fopen("./data/hs37d5_cocc2.bin", "rb");
    end

    final begin
        $fclose(fd[0]);
        $fclose(fd[1]);
        $fclose(fd[2]);
    end

    wire clk = s_axi4l.clk;
    wire rst = ~s_axi4l.reset_n;
    // aw
    // s_axi4l.awaddr
    // s_axi4l.awvalid
    // s_axi4l.awprot
    always_comb s_axi4l.awready = 1'b0;
    // w
    // s_axi4l.wdata
    // s_axi4l.wstrb
    // s_axi4l.wvalid
    always_comb s_axi4l.wready = 1'b0;
    // b
    always_comb s_axi4l.bresp = 2'b00;
    always_comb s_axi4l.bvalid = 1'b0;
    // s_axi4l.bready
    // ar
    integer seed1 = 123327842;
    integer rnd;
    always_comb s_axi4l.arready = rnd[0];   // gen random ready
    always_ff @(posedge clk) begin
        rnd <= $random(seed1);
    end
    logic [s_axi4l.DW - 1 : 0] fileBuf;
    logic [39 : 0] addr, seekstep;
    always_comb s_axi4l.rdata = {<<8{fileBuf}};
    always_ff @(posedge clk) begin : proc_rdata
        if(rst) begin
            fileBuf <= '0;
        end
        else if(s_axi4l.arvalid & s_axi4l.arready) begin
            addr = s_axi4l.araddr - BASE_ADDR;
            code = $fseek(fd[addr[39:31]], addr[30:0], 0);
            code = $fread(fileBuf, fd[addr[39:31]]);
        end
    end

    integer seed2 = 68235289;
    always @(posedge clk) begin : proc_rvalid
        if(rst) begin
            s_axi4l.rvalid <= 1'b0;
        end
        else if(s_axi4l.arvalid & s_axi4l.arready) begin
            repeat(1 + $dist_poisson(seed2, MEAN_LATENCY)) @(posedge clk);
            s_axi4l.rvalid <= 1'b1;
        end
        else if(s_axi4l.rvalid & s_axi4l.rready) begin
            s_axi4l.rvalid <= 1'b0;
        end
    end

endmodule // MemoryFromFile
