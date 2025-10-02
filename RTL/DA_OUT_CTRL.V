// DA_OUT_CTRL.v —— 并行DAC驱动控制（含时钟分频 + 上升沿锁存数据）
// 作者：T ZH
module DA_OUT_CTRL (
    input  wire       sys_clk,   // 板载50MHz，直接给 DAC
    input  wire       rst_n,     // 低有效复位
    input  wire [7:0] data_in,   // 上层8位电压数据（与sys_clk同域）
    output wire       dac_clk,   // 直接输出 sys_clk
    output reg  [7:0] dac_data   // 上升沿锁存并输出到DAC
);
    assign dac_clk = sys_clk;

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n)
            dac_data <= 8'd0;
        else
            dac_data <= data_in; // 下一上升沿供 DAC 锁存
    end
endmodule
