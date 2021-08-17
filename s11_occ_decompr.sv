// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180817

`default_nettype none

`include "./s00_defines.sv"

module OccDecompress
    import BwaMemDefines::*;
(
    input wire clk, rst,
    input wire [255:0] occ_block,
    input wire [4:0] i,             // MUST be stable during processing
    input wire start,
    output logic [39:0] val[0:3],
    output logic finish,
    output wire busy
);

    wire OccBlock ob = occ_block;
    logic [31:0][2:0] syms;

    logic [4:0] cnt;
    logic counting;

    always_ff @(posedge clk) begin : proc_syms
        if(rst) begin
            syms <= 96'b0;
        end
        else if(!counting & start) begin
            syms <= ob.BwtSlice;
        end
    end

    always_ff @(posedge clk) begin : proc_counting
        if(rst) begin
            counting <= 1'b0;
        end 
        else if(!counting & start) begin
            counting <= 1'b1;
        end
        else if(cnt == i) begin
            counting <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin : proc_cnt
        if(rst) begin
            cnt <= 5'b0;
        end 
        else if(counting) begin
            cnt <= cnt + 5'b1;
        end
        else if(!counting) begin
            cnt <= 5'b0;
        end
    end

    logic [39:0] occ[0:3];
    always_ff @(posedge clk) begin : proc_occ
        if(rst) begin
            occ <= '{4{40'd0}};
        end
        else if(!counting & start) begin
            occ[0] = ob.OccA;
            occ[1] = ob.OccC;
            occ[2] = ob.OccG;
            occ[3] = ob.OccT;
        end
        else if(counting) begin
            case(syms[cnt])
                sym_A: occ[0] <= occ[0] + 40'b1;
                sym_C: occ[1] <= occ[1] + 40'b1;
                sym_G: occ[2] <= occ[2] + 40'b1;
                sym_T: occ[3] <= occ[3] + 40'b1;
            endcase // ob.sym[cnt]
        end
    end

    always_ff @(posedge clk) begin : proc_val
        if(rst) begin
            val <= '{4{40'b0}};
        end
        else if(cnt == i) begin
            val[0] <= occ[0];
            val[1] <= occ[1];
            val[2] <= occ[2];
            val[3] <= occ[3];
        end
    end

    always_ff @(posedge clk) begin : proc_finish
        if(rst) begin
            finish <= 1'b0;
        end
        else if(counting & cnt == i) begin
            finish <= 1'b1;
        end
        else begin
            finish <= 1'b0;
        end
    end

    assign busy = counting;

endmodule // OccDecompress
