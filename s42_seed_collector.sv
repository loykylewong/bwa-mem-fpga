// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@gamil.com 20180814

`default_nettype none

// module SeedCollectMDC  // max data_cnt priority
// #(
//     parameter CH = 16,
//     parameter DW = 128,
//     parameter DCW = 9
// )(
//     input wire clk, rst,
//     input  wire [DW - 1 : 0] si_data [CH],
//     input  wire              si_last [CH],
//     input  wire              si_valid[CH],
//     output logic             si_ready[CH],
//     input wire [DCW - 1 : 0] si_data_cnt[CH],

//     output logic [DW - 1 : 0] so_data,
//     output logic              so_last,
//     output logic              so_valid,
//     input  wire               so_ready
// );
//     localparam CHW = $clog2(CH);

//     logic [CHW - 1 : 0] ch;
//     logic chen;
//     // wire [CH - 1 : 0] sil = {<<{si_last}};  -_-!!! not work correctly in modelsim
//     // wire [CH - 1 : 0] siv = {<<{si_valid}};
//     // wire [CH - 1 : 0] sir = {<<{si_ready}};
//     logic [CH - 1 : 0] sil, siv, sir;
//     always_comb begin
//         for(integer i = 0; i < CH; i++) begin
//             sil[i] = si_last[i];
//             siv[i] = si_valid[i];
//             si_ready[i] = sir[i];
//         end
//     end

//     logic [DCW - 1 : 0] dc_max;
//     logic [CHW - 1 : 0] ch_candi;
//     always_ff @(posedge clk) begin : proc_ch
//         if(rst) begin
//             ch <= '0;
//             chen <= 1'b0;
//             ch_candi <= '0;
//             dc_max <= '0;
//         end
//         else if(|(sil & sir & siv)) begin
//             ch <= 1'b0;
//             ch_candi <= 1'b0;
//             dc_max <= 1'b0;
//             chen <= 1'b0;
//         end
//         else if(chen == 1'b0) begin // ch seeking TODO: BUG here
//             if(ch == (CHW)'(CH - 1)) begin
//                 if(si_valid[ch] && si_data_cnt[ch] > dc_max) begin
//                     // ch <= (CHW)'(CH - 1);
//                     chen <= 1'b1;
//                 end
//                 else begin
//                     ch <= ch_candi;
//                     chen <= 1'b1;   // seek finish
//                 end
//             end
//             else begin
//                 ch <= ch + 1'b1;
//                 if(si_valid[ch] && si_data_cnt[ch] > dc_max) begin
//                     ch_candi <= ch;
//                     dc_max <= si_data_cnt[ch];
//                 end
//             end
//         end
//     end

//     logic stored;
//     always_ff @(posedge clk) begin : proc_stored
//         if(rst) begin
//             stored <= 1'b0;
//         end 
//         else if(|(siv & sir)) begin
//             stored <= 1'b1;
//         end
//         else if(so_valid & so_ready) begin
//             stored <= 1'b0;
//         end
//     end
//     assign sir = stored ? CH'(0) : (chen ? CH'(1) << ch : CH'(0));

//     logic [DW - 1 : 0] data;
//     logic last;
//     always_ff @(posedge clk) begin : proc_data
//         if(rst) begin
//             data <= '0;
//             last <= 1'b0;
//         end 
//         else if(|(siv & sir)) begin
//             data <= si_data[ch];
//             last <= si_last[ch];
//         end
//     end

//     assign so_data = data;
//     assign so_last = last;

//     always_ff @(posedge clk) begin : proc_so_valid
//         if(rst) begin
//             so_valid <= 1'b0;
//         end
//         else if(|(siv & sir)) begin
//             so_valid <= 1'b1;
//         end
//         else if(so_valid & so_ready) begin
//             so_valid <= 1'b0;
//         end
//     end

// endmodule // SeedCollect

module SeedCollectRR   // round robin
#(
    parameter CH = 16,
    parameter DW = 128
)(
    input wire clk, rst,
    input  wire [DW - 1 : 0] si_data [CH],
    input  wire              si_last [CH],
    input  wire              si_valid[CH],
    output logic             si_ready[CH],

    output logic [DW - 1 : 0] so_data,
    output logic              so_last,
    output logic              so_valid,
    input  wire               so_ready
);

    logic [$clog2(CH) - 1 : 0] ch;
    logic chen;
    // wire [CH - 1 : 0] sil = {<<{si_last}};  -_-!!! not work correctly in modelsim
    // wire [CH - 1 : 0] siv = {<<{si_valid}};
    // wire [CH - 1 : 0] sir = {<<{si_ready}};
    logic [CH - 1 : 0] sil, siv, sir;
    always_comb begin
        for(integer i = 0; i < CH; i++) begin
            sil[i] = si_last[i];
            siv[i] = si_valid[i];
            si_ready[i] = sir[i];
        end
    end

    always_ff @(posedge clk) begin : proc_ch
        if(rst) begin
            ch <= '0;
            chen <= 1'b0;
        end
        else if(|(sil & sir & siv)) begin
            if(ch < CH - 1) begin
                ch <= ch + 1'b1;
            end
            else begin
                ch <= 1'b0;
            end
            chen <= 1'b0;
        end
        else if(chen == 1'b0) begin // ch seeking
            if(siv[ch]) begin
                chen <= 1'b1;   // seek finish
            end
            else begin
                if(ch < CH - 1) begin  // try next ch
                    ch <= ch + 1'b1;
                end
                else begin
                    ch <= 1'b0;
                end
            end
        end
    end

    logic stored;
    always_ff @(posedge clk) begin : proc_stored
        if(rst) begin
            stored <= 1'b0;
        end 
        else if(|(siv & sir)) begin
            stored <= 1'b1;
        end
        else if(so_valid & so_ready) begin
            stored <= 1'b0;
        end
    end
    assign sir = stored ? CH'(0) : (chen ? CH'(1) << ch : CH'(0));

    logic [DW - 1 : 0] data;
    logic last;
    always_ff @(posedge clk) begin : proc_data
        if(rst) begin
            data <= '0;
            last <= 1'b0;
        end 
        else if(|(siv & sir)) begin
            data <= si_data[ch];
            last <= si_last[ch];
        end
    end

    assign so_data = data;
    assign so_last = last;

    always_ff @(posedge clk) begin : proc_so_valid
        if(rst) begin
            so_valid <= 1'b0;
        end
        else if(|(siv & sir)) begin
            so_valid <= 1'b1;
        end
        else if(so_valid & so_ready) begin
            so_valid <= 1'b0;
        end
    end

endmodule // SeedCollect

module SeedCollectRRWrapper
#(
    parameter DW = 256,
    parameter DCW = 8
)(
    input wire clk, rst_n,
    
    input  wire [ DW-1:0] s00_axis_tdata ,
    input  wire           s00_axis_tlast ,
    input  wire           s00_axis_tvalid,
    output wire           s00_axis_tready,
    // input  wire [DCW-1:0] s00_axis_tuser ,

    input  wire [ DW-1:0] s01_axis_tdata ,
    input  wire           s01_axis_tlast ,
    input  wire           s01_axis_tvalid,
    output wire           s01_axis_tready,
    // input  wire [DCW-1:0] s01_axis_tuser ,

    input  wire [ DW-1:0] s02_axis_tdata ,
    input  wire           s02_axis_tlast ,
    input  wire           s02_axis_tvalid,
    output wire           s02_axis_tready,
    // input  wire [DCW-1:0] s02_axis_tuser ,

    input  wire [ DW-1:0] s03_axis_tdata ,
    input  wire           s03_axis_tlast ,
    input  wire           s03_axis_tvalid,
    output wire           s03_axis_tready,
    // input  wire [DCW-1:0] s03_axis_tuser ,

    input  wire [ DW-1:0] s04_axis_tdata ,
    input  wire           s04_axis_tlast ,
    input  wire           s04_axis_tvalid,
    output wire           s04_axis_tready,
    // input  wire [DCW-1:0] s04_axis_tuser ,

    input  wire [ DW-1:0] s05_axis_tdata ,
    input  wire           s05_axis_tlast ,
    input  wire           s05_axis_tvalid,
    output wire           s05_axis_tready,
    // input  wire [DCW-1:0] s05_axis_tuser ,

    input  wire [ DW-1:0] s06_axis_tdata ,
    input  wire           s06_axis_tlast ,
    input  wire           s06_axis_tvalid,
    output wire           s06_axis_tready,
    // input  wire [DCW-1:0] s06_axis_tuser ,

    input  wire [ DW-1:0] s07_axis_tdata ,
    input  wire           s07_axis_tlast ,
    input  wire           s07_axis_tvalid,
    output wire           s07_axis_tready,
    // input  wire [DCW-1:0] s07_axis_tuser ,

    input  wire [ DW-1:0] s08_axis_tdata ,
    input  wire           s08_axis_tlast ,
    input  wire           s08_axis_tvalid,
    output wire           s08_axis_tready,
    // input  wire [DCW-1:0] s08_axis_tuser ,

    input  wire [ DW-1:0] s09_axis_tdata ,
    input  wire           s09_axis_tlast ,
    input  wire           s09_axis_tvalid,
    output wire           s09_axis_tready,
    // input  wire [DCW-1:0] s09_axis_tuser ,

    input  wire [ DW-1:0] s10_axis_tdata ,
    input  wire           s10_axis_tlast ,
    input  wire           s10_axis_tvalid,
    output wire           s10_axis_tready,
    // input  wire [DCW-1:0] s10_axis_tuser ,

    input  wire [ DW-1:0] s11_axis_tdata ,
    input  wire           s11_axis_tlast ,
    input  wire           s11_axis_tvalid,
    output wire           s11_axis_tready,
    // input  wire [DCW-1:0] s11_axis_tuser ,

    input  wire [ DW-1:0] s12_axis_tdata ,
    input  wire           s12_axis_tlast ,
    input  wire           s12_axis_tvalid,
    output wire           s12_axis_tready,
    // input  wire [DCW-1:0] s12_axis_tuser ,

    input  wire [ DW-1:0] s13_axis_tdata ,
    input  wire           s13_axis_tlast ,
    input  wire           s13_axis_tvalid,
    output wire           s13_axis_tready,
    // input  wire [DCW-1:0] s13_axis_tuser ,

    input  wire [ DW-1:0] s14_axis_tdata ,
    input  wire           s14_axis_tlast ,
    input  wire           s14_axis_tvalid,
    output wire           s14_axis_tready,
    // input  wire [DCW-1:0] s14_axis_tuser ,

    input  wire [ DW-1:0] s15_axis_tdata ,
    input  wire           s15_axis_tlast ,
    input  wire           s15_axis_tvalid,
    output wire           s15_axis_tready,
    // input  wire [DCW-1:0] s15_axis_tuser ,
    
    output wire [ DW-1:0] m_axis_tdata ,
    output wire           m_axis_tlast ,
    output wire           m_axis_tvalid,
    input  wire           m_axis_tready
);
    wire [ DW - 1 : 0] si_data    [16];
    wire               si_last    [16];
    wire               si_valid   [16];
    wire               si_ready   [16];
    // wire [DCW - 1 : 0] si_data_cnt[16];

    assign si_data    [00] =                    s00_axis_tdata;
    assign si_last    [00] =                    s00_axis_tlast;
    assign si_valid   [00] =                    s00_axis_tvalid;
    assign            s00_axis_tready = si_ready[00];
    // assign si_data_cnt[00] =                    s00_axis_tuser;

    assign si_data    [01] =                    s01_axis_tdata;
    assign si_last    [01] =                    s01_axis_tlast;
    assign si_valid   [01] =                    s01_axis_tvalid;
    assign            s01_axis_tready = si_ready[01];
    // assign si_data_cnt[01] =                    s01_axis_tuser;

    assign si_data    [02] =                    s02_axis_tdata;
    assign si_last    [02] =                    s02_axis_tlast;
    assign si_valid   [02] =                    s02_axis_tvalid;
    assign            s02_axis_tready = si_ready[02];
    // assign si_data_cnt[02] =                    s02_axis_tuser;

    assign si_data    [03] =                    s03_axis_tdata;
    assign si_last    [03] =                    s03_axis_tlast;
    assign si_valid   [03] =                    s03_axis_tvalid;
    assign            s03_axis_tready = si_ready[03];
    // assign si_data_cnt[03] =                    s03_axis_tuser;

    assign si_data    [04] =                    s04_axis_tdata;
    assign si_last    [04] =                    s04_axis_tlast;
    assign si_valid   [04] =                    s04_axis_tvalid;
    assign            s04_axis_tready = si_ready[04];
    // assign si_data_cnt[04] =                    s04_axis_tuser;

    assign si_data    [05] =                    s05_axis_tdata;
    assign si_last    [05] =                    s05_axis_tlast;
    assign si_valid   [05] =                    s05_axis_tvalid;
    assign            s05_axis_tready = si_ready[05];
    // assign si_data_cnt[05] =                    s05_axis_tuser;

    assign si_data    [06] =                    s06_axis_tdata;
    assign si_last    [06] =                    s06_axis_tlast;
    assign si_valid   [06] =                    s06_axis_tvalid;
    assign            s06_axis_tready = si_ready[06];
    // assign si_data_cnt[06] =                    s06_axis_tuser;

    assign si_data    [07] =                    s07_axis_tdata;
    assign si_last    [07] =                    s07_axis_tlast;
    assign si_valid   [07] =                    s07_axis_tvalid;
    assign            s07_axis_tready = si_ready[07];
    // assign si_data_cnt[07] =                    s07_axis_tuser;

    assign si_data    [08] =                    s08_axis_tdata;
    assign si_last    [08] =                    s08_axis_tlast;
    assign si_valid   [08] =                    s08_axis_tvalid;
    assign            s08_axis_tready = si_ready[08];
    // assign si_data_cnt[08] =                    s08_axis_tuser;

    assign si_data    [09] =                    s09_axis_tdata;
    assign si_last    [09] =                    s09_axis_tlast;
    assign si_valid   [09] =                    s09_axis_tvalid;
    assign            s09_axis_tready = si_ready[09];
    // assign si_data_cnt[09] =                    s09_axis_tuser;

    assign si_data    [10] =                    s10_axis_tdata;
    assign si_last    [10] =                    s10_axis_tlast;
    assign si_valid   [10] =                    s10_axis_tvalid;
    assign            s10_axis_tready = si_ready[10];
    // assign si_data_cnt[10] =                    s10_axis_tuser;

    assign si_data    [11] =                    s11_axis_tdata;
    assign si_last    [11] =                    s11_axis_tlast;
    assign si_valid   [11] =                    s11_axis_tvalid;
    assign            s11_axis_tready = si_ready[11];
    // assign si_data_cnt[11] =                    s11_axis_tuser;

    assign si_data    [12] =                    s12_axis_tdata;
    assign si_last    [12] =                    s12_axis_tlast;
    assign si_valid   [12] =                    s12_axis_tvalid;
    assign            s12_axis_tready = si_ready[12];
    // assign si_data_cnt[12] =                    s12_axis_tuser;

    assign si_data    [13] =                    s13_axis_tdata;
    assign si_last    [13] =                    s13_axis_tlast;
    assign si_valid   [13] =                    s13_axis_tvalid;
    assign            s13_axis_tready = si_ready[13];
    // assign si_data_cnt[13] =                    s13_axis_tuser;

    assign si_data    [14] =                    s14_axis_tdata;
    assign si_last    [14] =                    s14_axis_tlast;
    assign si_valid   [14] =                    s14_axis_tvalid;
    assign            s14_axis_tready = si_ready[14];
    // assign si_data_cnt[14] =                    s14_axis_tuser;

    assign si_data    [15] =                    s15_axis_tdata;
    assign si_last    [15] =                    s15_axis_tlast;
    assign si_valid   [15] =                    s15_axis_tvalid;
    assign            s15_axis_tready = si_ready[15];
    // assign si_data_cnt[15] =                    s15_axis_tuser;

    // generate
    //     if(MAX_DATA_CNT_PRIO_MODE) begin
    //         SeedCollectMDC #(.CH(16), .DW(DW), .DCW(DCW)) seedCollectorMDC
    //         (
    //             .clk(clk), .rst(~rst_n),
    //             .si_data(si_data),
    //             .si_last(si_last),
    //             .si_valid(si_valid),
    //             .si_ready(si_ready),
    //             .si_data_cnt(si_data_cnt),
    //             .so_data(m_axis_tdata),
    //             .so_last(m_axis_tlast),
    //             .so_valid(m_axis_tvalid),
    //             .so_ready(m_axis_tready)
    //         );
    //     end // if(MAX_DATA_CNT_PRIO_MOD)
    //     else begin
            SeedCollectRR #(.CH(16), .DW(DW)) seedCollectorRR
            (
                .clk(clk), .rst(~rst_n),
                .si_data(si_data),
                .si_last(si_last),
                .si_valid(si_valid),
                .si_ready(si_ready),
                .so_data(m_axis_tdata),
                .so_last(m_axis_tlast),
                .so_valid(m_axis_tvalid),
                .so_ready(m_axis_tready)
            );
    //     end
    // endgenerate

endmodule
