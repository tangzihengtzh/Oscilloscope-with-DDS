// lcd_hsync.v
// 仅生成水平 HSYNC 脉冲（按 Front -> Sync -> Back -> Active 顺序计数）
// 展开写法：无三目运算符；按极性分别时序化输出

module lcd_hsync #(
    parameter H_SYNC  = 11'd1,    // 同步脉冲宽度（像素周期数）
    parameter H_BACK  = 11'd46,   // 后沿（像素周期数）
    parameter H_VALID = 11'd800,  // 有效区（像素周期数）
    parameter H_FRONT = 11'd210,  // 前沿（像素周期数）
    parameter HS_POL  = 1'b1      // 1: HSYNC 脉冲高有效；0: 脉冲低有效
)(
    input  wire lcd_clk,    // 像素时钟 (~33.264 MHz)
    input  wire sys_rst_n,  // 低有效复位
    output reg  lcd_hs      // 行同步输出
);
    // ---------------------------------------------------------
    // 一行总周期与区段边界（计数范围：0 .. H_TOTAL-1）
    // 布局： [Front H_FRONT] [HSYNC H_SYNC] [Back H_BACK] [Active H_VALID]
    // ---------------------------------------------------------
    localparam [10:0] H_TOTAL = H_SYNC + H_BACK + H_VALID + H_FRONT;

    // HSYNC 脉冲的区间（左闭右开）
    localparam [10:0] HS_BEG  = H_FRONT;              // 脉冲起点
    localparam [10:0] HS_END  = H_FRONT + H_SYNC;     // 脉冲终点(不含)

    reg [10:0] h_cnt;

    // 行内像素计数器
    always @(posedge lcd_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            h_cnt <= 11'd0;
        end else if (h_cnt == H_TOTAL - 1) begin
            h_cnt <= 11'd0;
        end else begin
            h_cnt <= h_cnt + 11'd1;
        end
    end

    // ================= 极性为“高脉冲有效” =================
    generate if (HS_POL == 1'b1) begin : gen_hs_active_high
        // 复位时输出为低；处于 [HS_BEG, HS_END) 区间输出拉高，否则拉低
        always @(posedge lcd_clk or negedge sys_rst_n) begin
            if (!sys_rst_n) begin
                lcd_hs <= 1'b0;
            end else if ((h_cnt >= HS_BEG) && (h_cnt < HS_END)) begin
                lcd_hs <= 1'b1;
            end else begin
                lcd_hs <= 1'b0;
            end
        end
    end else begin : gen_hs_active_low
    // ================= 极性为“低脉冲有效” ==================
        // 复位时输出为高；处于 [HS_BEG, HS_END) 区间输出拉低，否则拉高
        always @(posedge lcd_clk or negedge sys_rst_n) begin
            if (!sys_rst_n) begin
                lcd_hs <= 1'b1;
            end else if ((h_cnt >= HS_BEG) && (h_cnt < HS_END)) begin
                lcd_hs <= 1'b0;
            end else begin
                lcd_hs <= 1'b1;
            end
        end
    end endgenerate

endmodule
