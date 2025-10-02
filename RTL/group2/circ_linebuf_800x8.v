module circ_linebuf_800x8 #(
    parameter integer LEN = 800
)(
    // 写侧（ADC / sys_clk 域）
    input  wire        wr_clk,
    input  wire        wr_rst_n,
    input  wire        wr_en,        // 每个有效采样=1 个拍
    input  wire [7:0]  wr_data,

    // 读侧（LCD 像素时钟域）
    input  wire        rd_clk,
    input  wire        rd_rst_n,
    input  wire [9:0]  rd_x,         // 一般接 pixel_xpos[9:0]（0..799）
    output reg  [7:0]  rd_data       // 当前屏幕列的样本值（滚动映射）
);
    // -------- 存储体（真双端口 RAM, 建议综合为 Block RAM） --------
    
    // synthesis ramstyle = "M9K"
    reg [7:0] mem [0:LEN-1];

    // ========== 写侧：环形写指针 ==========
    reg [9:0] wr_idx;  // 0..799
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_idx <= 10'd0;
        end else if (wr_en) begin
            mem[wr_idx] <= wr_data;
            wr_idx <= (wr_idx == LEN-1) ? 10'd0 : (wr_idx + 10'd1);
        end
    end

    // ========== 写指针跨域（Gray 编码同步） ==========
    // 二进制 -> Gray
    wire [9:0] wr_idx_gray = wr_idx ^ (wr_idx >> 1);

    // 位宽 10 的 2 级同步
    reg [9:0] gsync1, gsync2;
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            gsync1 <= 10'd0;
            gsync2 <= 10'd0;
        end else begin
            gsync1 <= wr_idx_gray;
            gsync2 <= gsync1;
        end
    end

    // Gray -> 二进制
    function [9:0] gray2bin(input [9:0] g);
        integer i;
        begin
            gray2bin[9] = g[9];
            for (i = 8; i >= 0; i=i-1)
                gray2bin[i] = gray2bin[i+1] ^ g[i];
        end
    endfunction

    wire [9:0] wr_idx_bin_rd = gray2bin(gsync2); // 已在 rd_clk 域

    // ========== 读地址滚动映射 ==========
    // base = wr_idx + 1 (mod LEN) 作为屏幕最左像素地址（左老右新 → 向左滚动）
    wire [10:0] base_sum = {1'b0, wr_idx_bin_rd} + 11'd1;
    wire [9:0]  base     = (base_sum >= LEN) ? base_sum - LEN : base_sum[9:0];

    // addr = base + rd_x (mod LEN)
    wire [10:0] addr_sum = {1'b0, base} + {1'b0, rd_x};
    wire [9:0]  rd_addr  = (addr_sum >= LEN) ? addr_sum - LEN : addr_sum[9:0];

    // 时序读（1 拍延迟）
    always @(posedge rd_clk) begin
        rd_data <= mem[rd_addr];
    end
endmodule
