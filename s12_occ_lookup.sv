// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180803

`default_nettype none

`include "./s00_defines.sv"
module OccLookup
    import BwaMemDefines::*;
#(
    parameter integer AW = 40,
    parameter logic [AW - 1 : 0] OCC_BASE = 40'h00_0000_0000 // must be align to 2^(clog2(OccTableSize))
)(
    input wire clk, rst,
    input wire [KLS_W-1:0] k_in, ks_in,
    input wire start,
    output logic [KLS_W-1:0] val_k[0:3], val_ks[0:3],
    output logic val_valid,
    Axi4LiteIf.master m_axi_occlu
);

`ifdef SIM_UCOCC_LOOKUP_WITHOUT_AXIMEM
    // this code in `ifdef is obsolete
    integer occ_file, code;
    initial begin
        occ_file = $fopen("./chr21_OTable.bin", "rb");
    end

    int seed = 123;
    int unsigned kA, kC, kG, kT, ksA, ksC, ksG, ksT;
    string errmsg;
    always@(posedge clk) begin : proc_out
        if(rst) begin
            val_k       <= '{4{KLS_W'(0)}};
            val_ks      <= '{4{KLS_W'(0)}};
            val_valid   <= 1'b0;
        end
        else if(start) begin
            code = $fseek(occ_file, int'(16 * k_in) +  0, 0);        // seek to Occ(A, k)
            code = $fread(kA, occ_file);
            code = $fread(kC, occ_file);
            code = $fread(kG, occ_file);
            code = $fread(kT, occ_file);
            
            code = $fseek(occ_file, int'(16 * ks_in) +  0, 0);    // seek to Occ(A, ks)
            code = $fread(ksA, occ_file);
            code = $fread(ksC, occ_file);
            code = $fread(ksG, occ_file);
            code = $fread(ksT, occ_file);

            repeat(1 + $dist_poisson(seed, 90)) @(posedge clk);

            @(posedge clk) begin
                val_k[0]  <= { 8'b0, {<<8{ kA}} };
                val_k[1]  <= { 8'b0, {<<8{ kC}} };
                val_k[2]  <= { 8'b0, {<<8{ kG}} };
                val_k[3]  <= { 8'b0, {<<8{ kT}} };
                val_ks[0] <= { 8'b0, {<<8{ksA}} };
                val_ks[1] <= { 8'b0, {<<8{ksC}} };
                val_ks[2] <= { 8'b0, {<<8{ksG}} };
                val_ks[3] <= { 8'b0, {<<8{ksT}} };
                val_valid <= 1'b1;
            end
            @(posedge clk) begin
                val_valid <= 1'b0;
            end
        end
    end
`else 

    // TODO: Occ decompressing (>﹏<)
    localparam logic [2:0] S_Idle       = 3'd0;
    localparam logic [2:0] S_Prepare    = 3'd1;
    localparam logic [2:0] S_ReadMem1   = 3'd2;
    localparam logic [2:0] S_Dec1Read2  = 3'd3;
    localparam logic [2:0] S_WaitRead2   = 3'd4;
    localparam logic [2:0] S_WaitDec1    = 3'd5;
    localparam logic [2:0] S_Decompr2   = 3'd6;

    wire dec_start, dec_finish;
    wire [39:0] dec_val[0:3];
    wire [4:0] dec_i;
    wire OccBlock dec_cob;

    OccBlock sto_cob;

    logic [KLS_W-5 - 1 : 0] cob_idx_k, cob_idx_ks;
    logic [5 - 1 : 0]       sym_off_k, sym_off_ks;

    logic [2:0] status, nxt_sts;
    always_ff @(posedge clk) begin : proc_status
        if(rst) begin
            status <= S_Idle;
        end
        else begin
            status <= nxt_sts;
        end
    end

    always_comb begin
        nxt_sts = status;
        case(status)
        S_Idle: begin
            if(start) begin
                nxt_sts = S_Prepare;
            end
        end // S_Idle:
        S_Prepare: begin
            nxt_sts = S_ReadMem1;
        end // S_Prepare:
        S_ReadMem1: begin
            if(m_axi_occlu.rvalid & m_axi_occlu.rready) begin
                nxt_sts = S_Dec1Read2;
            end
        end // S_ReadMem1:
        S_Dec1Read2: begin
            if(dec_finish & m_axi_occlu.rvalid & m_axi_occlu.rready) begin
                nxt_sts = S_Decompr2;
            end
            else if(dec_finish) begin
                nxt_sts = S_WaitRead2;
            end
            else if(m_axi_occlu.rvalid & m_axi_occlu.rready) begin
                nxt_sts = S_WaitDec1;
            end
        end // S_Dec1Read2:
        S_WaitRead2: begin
            if(m_axi_occlu.rvalid & m_axi_occlu.rready) begin
                nxt_sts = S_Decompr2;
            end
        end // S_WaitRead2
        S_WaitDec1: begin
            if(dec_finish) begin
                nxt_sts = S_Decompr2;
            end
        end
        S_Decompr2: begin
            if(dec_finish) begin
                nxt_sts = S_Idle;
            end
        end // S_Decompr2:
        endcase
    end

    always_ff @(posedge clk) begin : proc_ks
        if(rst) begin
            cob_idx_k  <= 1'b0;
            cob_idx_ks <= 1'b0;
            sym_off_k  <= 5'b0;
            sym_off_ks <= 5'b0;
        end 
        else if(status == S_Idle & nxt_sts == S_Prepare) begin
            {cob_idx_k,  sym_off_k}  <= k_in;
            {cob_idx_ks, sym_off_ks} <= ks_in;
        end
    end

    // aw
    always_comb m_axi_occlu.awaddr  = '0;
    always_comb m_axi_occlu.awprot  = '0;
    always_comb m_axi_occlu.awvalid = '0;
    // w
    always_comb m_axi_occlu.wdata  = '0;
    always_comb m_axi_occlu.wstrb  = '0;
    always_comb m_axi_occlu.wvalid = '0;
    // b
    always_comb m_axi_occlu.bready = '1;
    // ar
    always_comb m_axi_occlu.arprot = '0;
    always_ff @(posedge clk) begin : proc_araddr
        if(rst) begin
            m_axi_occlu.araddr <= '0;
        end 
        else if(status == S_Prepare && nxt_sts == S_ReadMem1) begin    // lookup k
            m_axi_occlu.araddr <= OCC_BASE | {cob_idx_k, 5'b0};
        end
        else if(status == S_ReadMem1 && nxt_sts == S_Dec1Read2) begin   // lookup ks
            m_axi_occlu.araddr <= OCC_BASE | {cob_idx_ks, 5'b0};
        end
    end
    always_ff @(posedge clk) begin : proc_arvalid
        if(rst) begin
            m_axi_occlu.arvalid <= 1'b0;
        end 
        else if(status == S_Prepare && nxt_sts == S_ReadMem1) begin
            m_axi_occlu.arvalid <= 1'b1;
        end
        else if(status == S_ReadMem1 && nxt_sts == S_Dec1Read2) begin
            m_axi_occlu.arvalid <= 1'b1;
        end
        else if(m_axi_occlu.arvalid & m_axi_occlu.arready) begin
            m_axi_occlu.arvalid <= 1'b0;
        end
    end
    // r
    assign m_axi_occlu.rready = 1'b1;
    always_ff @(posedge clk) begin : proc_cob
        if(rst) begin
            sto_cob <= 256'b0;
        end
        else if(m_axi_occlu.rvalid & m_axi_occlu.rready) begin
            sto_cob <= m_axi_occlu.rdata;
        end
    end

    OccDecompress occDecompr
    (
        .clk      (clk),
        .rst      (rst),
        .occ_block(dec_cob),
        .i        (dec_i),
        .start    (dec_start),
        .finish   (dec_finish),
        .busy     (),
        .val      (dec_val)
    );
    assign dec_i = nxt_sts == S_Decompr2 ? sym_off_ks : sym_off_k;
    assign dec_start = (status != S_Dec1Read2 && nxt_sts == S_Dec1Read2)
                       | (status != S_Decompr2 && nxt_sts == S_Decompr2);
    assign dec_cob = status == S_WaitDec1 ? sto_cob : m_axi_occlu.rdata;

    always_ff @(posedge clk) begin : proc_val_k_ks
        if(rst) begin
            val_k  <= '{4{KLS_W'(0)}};
            val_ks <= '{4{KLS_W'(0)}};
        end 
        else if(dec_finish) begin
            if(status == S_Dec1Read2 || status == S_WaitDec1) begin
                val_k <= dec_val;
            end
            else if(status == S_Decompr2) begin
                val_ks <= dec_val;
            end
        end
    end

    always_ff @(posedge clk) begin : proc_finish
        if(rst) begin
            val_valid <= 1'b0;
        end
        else if(status == S_Decompr2 && nxt_sts == S_Idle) begin
            val_valid <= 1'b1;
        end
        else begin
            val_valid <= 1'b0;
        end
    end

`endif

endmodule // OccLookup
