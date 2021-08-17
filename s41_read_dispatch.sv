// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180813

`default_nettype none

module ReadDispatch
#(
    parameter CH = 16,
    parameter DW = 512
)(
    input wire clk, rst,
    input  wire [DW - 1 : 0] ri_data,
    input  wire              ri_valid,
    output logic             ri_ready,
    output logic [DW - 1 : 0] ro_data [CH],
    output logic              ro_valid[CH],
    input  wire               ro_ready[CH]
);
    logic stored;
    logic [CH - 1 : 0] rov, ror;
    always_comb begin
        for(integer i = 0; i < CH; i++) begin
            ror[i] = ro_ready[i];
            ro_valid[i] = rov[i];
        end
    end

    always_ff @(posedge clk) begin : proc_stored
        if(rst) begin
            stored <= 1'b0;
        end 
        else if(ri_valid & ri_ready) begin
            stored <= 1'b1;
        end
        else if(|(rov & ror)) begin
            stored <= 1'b0;
        end
    end
    assign ri_ready = ~stored;

    logic [DW - 1 : 0] data;
    always_ff @(posedge clk) begin : proc_data
        if(rst) begin
            data <= '0;
        end 
        else if(ri_valid & ri_ready) begin
            data <= ri_data;
        end
    end

    genvar i;
    generate
        for(i = 0; i < CH; i++) begin
            always_comb begin
                ro_data[i] = data;
            end 
        end
    endgenerate

    function automatic logic [CH - 1 : 0] prio(
        input logic [CH - 1 : 0] in
    );
        prio = '0;
        for(integer i = CH - 1; i >= 0; i--) begin
            if(in[i]) begin
                prio = CH'(1) << i;
            end
        end
    endfunction

    // always_ff @(posedge clk) begin : proc_ro_valid
    //     if(rst) begin
    //         ro_valid <= '0;
    //     end
    //     else if(ri_valid & ri_read) begin
    //         ro_valid <= prio(ro_ready);
    //     end
    //     else if(ro_valid = '0 & stored) begin
    //         ro_valid <= prio(ro_ready);
    //     end
    //     else if(|(ro_valid & ro_ready)) begin
    //         ro_valid <= '0;
    //     end
    // end
    
    // funcion ok, timing ok
    always_ff @(posedge clk) begin : proc_rov
        if(rst) begin
            rov <= '0;
        end
        else if(ri_valid & ri_ready) begin
            rov <= prio(ror);
        end
        else if(rov == '0 & stored) begin
            rov <= prio(ror);
        end
        else if(|(rov & ror)) begin
            rov <= '0;
        end
    end

    // function ok, timing stress
    // always_comb begin
    //     if(stored) begin
    //         rov = prio(ror);
    //     end // if(stored)
    //     else begin
    //         rov = '{CH{1'b0}};
    //     end
    // end

endmodule // ReadDispatch

// for vivado ipi & ip packager
module ReadDispatchWrapper
#(
    parameter DW = 256
)
(
    input wire clk, rst_n,
     
    input  wire [DW-1:0] s_axis_tdata ,
    input  wire          s_axis_tvalid,
    output wire          s_axis_tready,
    
    output wire [DW-1:0] m00_axis_tdata ,
    output wire          m00_axis_tvalid,
    input  wire          m00_axis_tready,
    
    output wire [DW-1:0] m01_axis_tdata ,
    output wire          m01_axis_tvalid,
    input  wire          m01_axis_tready,
    
    output wire [DW-1:0] m02_axis_tdata ,
    output wire          m02_axis_tvalid,
    input  wire          m02_axis_tready,
    
    output wire [DW-1:0] m03_axis_tdata ,
    output wire          m03_axis_tvalid,
    input  wire          m03_axis_tready,
    
    output wire [DW-1:0] m04_axis_tdata ,
    output wire          m04_axis_tvalid,
    input  wire          m04_axis_tready,
    
    output wire [DW-1:0] m05_axis_tdata ,
    output wire          m05_axis_tvalid,
    input  wire          m05_axis_tready,
    
    output wire [DW-1:0] m06_axis_tdata ,
    output wire          m06_axis_tvalid,
    input  wire          m06_axis_tready,
    
    output wire [DW-1:0] m07_axis_tdata ,
    output wire          m07_axis_tvalid,
    input  wire          m07_axis_tready,
    
    output wire [DW-1:0] m08_axis_tdata ,
    output wire          m08_axis_tvalid,
    input  wire          m08_axis_tready,
    
    output wire [DW-1:0] m09_axis_tdata ,
    output wire          m09_axis_tvalid,
    input  wire          m09_axis_tready,
    
    output wire [DW-1:0] m10_axis_tdata ,
    output wire          m10_axis_tvalid,
    input  wire          m10_axis_tready,
    
    output wire [DW-1:0] m11_axis_tdata ,
    output wire          m11_axis_tvalid,
    input  wire          m11_axis_tready,
    
    output wire [DW-1:0] m12_axis_tdata ,
    output wire          m12_axis_tvalid,
    input  wire          m12_axis_tready,
    
    output wire [DW-1:0] m13_axis_tdata ,
    output wire          m13_axis_tvalid,
    input  wire          m13_axis_tready,
    
    output wire [DW-1:0] m14_axis_tdata ,
    output wire          m14_axis_tvalid,
    input  wire          m14_axis_tready,
    
    output wire [DW-1:0] m15_axis_tdata ,
    output wire          m15_axis_tvalid,
    input  wire          m15_axis_tready
);
    wire [DW - 1 : 0] ro_data [16];
    wire              ro_valid[16];
    wire              ro_ready[16];
    
    assign         m00_axis_tdata  = ro_data [00];
    assign         m00_axis_tvalid = ro_valid[00];
    assign ro_ready[00]            =         m00_axis_tready;

    assign         m01_axis_tdata  = ro_data [01];
    assign         m01_axis_tvalid = ro_valid[01];
    assign ro_ready[01]            =         m01_axis_tready;

    assign         m02_axis_tdata  = ro_data [02];
    assign         m02_axis_tvalid = ro_valid[02];
    assign ro_ready[02]            =         m02_axis_tready;

    assign         m03_axis_tdata  = ro_data [03];
    assign         m03_axis_tvalid = ro_valid[03];
    assign ro_ready[03]            =         m03_axis_tready;

    assign         m04_axis_tdata  = ro_data [04];
    assign         m04_axis_tvalid = ro_valid[04];
    assign ro_ready[04]            =         m04_axis_tready;

    assign         m05_axis_tdata  = ro_data [05];
    assign         m05_axis_tvalid = ro_valid[05];
    assign ro_ready[05]            =         m05_axis_tready;

    assign         m06_axis_tdata  = ro_data [06];
    assign         m06_axis_tvalid = ro_valid[06];
    assign ro_ready[06]            =         m06_axis_tready;

    assign         m07_axis_tdata  = ro_data [07];
    assign         m07_axis_tvalid = ro_valid[07];
    assign ro_ready[07]            =         m07_axis_tready;

    assign         m08_axis_tdata  = ro_data [08];
    assign         m08_axis_tvalid = ro_valid[08];
    assign ro_ready[08]            =         m08_axis_tready;

    assign         m09_axis_tdata  = ro_data [09];
    assign         m09_axis_tvalid = ro_valid[09];
    assign ro_ready[09]            =         m09_axis_tready;

    assign         m10_axis_tdata  = ro_data [10];
    assign         m10_axis_tvalid = ro_valid[10];
    assign ro_ready[10]            =         m10_axis_tready;

    assign         m11_axis_tdata  = ro_data [11];
    assign         m11_axis_tvalid = ro_valid[11];
    assign ro_ready[11]            =         m11_axis_tready;

    assign         m12_axis_tdata  = ro_data [12];
    assign         m12_axis_tvalid = ro_valid[12];
    assign ro_ready[12]            =         m12_axis_tready;

    assign         m13_axis_tdata  = ro_data [13];
    assign         m13_axis_tvalid = ro_valid[13];
    assign ro_ready[13]            =         m13_axis_tready;

    assign         m14_axis_tdata  = ro_data [14];
    assign         m14_axis_tvalid = ro_valid[14];
    assign ro_ready[14]            =         m14_axis_tready;

    assign         m15_axis_tdata  = ro_data [15];
    assign         m15_axis_tvalid = ro_valid[15];
    assign ro_ready[15]            =         m15_axis_tready;

    ReadDispatch #(.CH(16), .DW(DW)) readDispatch (
        .clk(clk), .rst(~rst_n),
        .ri_data (s_axis_tdata ),
        .ri_valid(s_axis_tvalid),
        .ri_ready(s_axis_tready),
        .ro_data (ro_data),
        .ro_valid(ro_valid),
        .ro_ready(ro_ready)
    );

endmodule
