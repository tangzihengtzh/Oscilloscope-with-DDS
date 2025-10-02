// AD_IN_CTRL.v —— 用板载时钟直驱 AD9280（ADC输入极简版）
// 说明：sys_clk 同时作为提供给 AD9280 的 ad_clk；
// 在同一时钟的上升沿把 ad_data[7:0] 打一拍到 data_out，供FPGA内部使用。
module AD_IN_CTRL (
    input  wire       sys_clk,   // 板载50MHz
    input  wire       rst_n,     // 低有效复位
    input  wire [7:0] ad_data,   // 来自 AD9280 的并行数字输出
    output wire       ad_clk,    // 输出给 AD9280 的采样时钟 (25MHz)
    output reg  [7:0] data_out   // 打一拍后的采样数据（与ad_clk同域）
);

    // ========== 1. 二分频产生 ad_clk ==========
    reg ad_clk_r;
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n)
            ad_clk_r <= 1'b0;
        else
            ad_clk_r <= ~ad_clk_r;
    end
    assign ad_clk = ad_clk_r;   // 给 AD9280 的采样时钟

    // ========== 2. 在 ad_clk 上升沿采样 ADC 数据 ==========
    always @(posedge ad_clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'd0;
        else
            data_out <= ad_data;
    end

endmodule

