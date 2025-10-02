// lcd_hde.v
// 生成水平数据使能 h_de（位于有效区 H_VALID 个像素周期）
// 并给出水平像素坐标 pixel_xpos: 0..H_VALID-1（仅在 h_de=1 时有效）

module lcd_hde #(
    parameter H_SYNC  = 11'd1,    // 同步脉冲宽度
    parameter H_BACK  = 11'd46,   // 后沿
    parameter H_VALID = 11'd800,  // 有效区像素数
    parameter H_FRONT = 11'd210   // 前沿
)(
    input  wire       lcd_clk,     // 像素时钟
    input  wire       sys_rst_n,   // 低有效复位
    output reg        h_de,        // 水平数据使能（仅水平方向）
    output reg [10:0] pixel_xpos   // 0..H_VALID-1，有效区水平像素坐标
);
    // 总行周期与有效区边界
    localparam [10:0] H_TOTAL   = H_SYNC + H_BACK + H_VALID + H_FRONT;
    localparam [10:0] ACT_BEG_H = H_FRONT + H_SYNC + H_BACK;           // 有效区起点 210+1+46=257
    localparam [10:0] ACT_END_H = H_FRONT + H_SYNC + H_BACK + H_VALID; // 有效区终点(不含)

    reg [10:0] h_cnt;

    // 行内像素计数（0 .. H_TOTAL-1）
    always @(posedge lcd_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            h_cnt <= 11'd0;
        end else if (h_cnt == H_TOTAL - 1) begin
            h_cnt <= 11'd0;
        end else begin
            h_cnt <= h_cnt + 11'd1;
        end
    end

    // 水平 DE 与像素坐标（展开写法）
    always @(posedge lcd_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            h_de        <= 1'b0;
            pixel_xpos  <= 11'd0;
        end else begin
            // 进入有效区起点：置 h_de、坐标清零
            if (h_cnt == ACT_BEG_H) begin
                h_de       <= 1'b1;
                pixel_xpos <= 11'd0;

            // 有效区内部：h_de=1，坐标自增
            end else if ((h_cnt > ACT_BEG_H) && (h_cnt < ACT_END_H)) begin
                h_de <= 1'b1;
                // 仅在有效区内自增到 H_VALID-1
                if (pixel_xpos == (H_VALID - 1)) begin
                    pixel_xpos <= pixel_xpos; // 保持（理论上到不了这里，因为离区前会 < H_VALID-1）
                end else begin
                    pixel_xpos <= pixel_xpos + 11'd1;
                end

            // 离开有效区：拉低 h_de，坐标清零
            end else if (h_cnt == ACT_END_H) begin
                h_de       <= 1'b0;
                pixel_xpos <= 11'd0;

            // 其余阶段：DE 低，坐标清零
            end else begin
                h_de       <= 1'b0;
                pixel_xpos <= 11'd0;
            end
        end
    end

endmodule
