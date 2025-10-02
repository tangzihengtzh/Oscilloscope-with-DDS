// lcd_vtiming.v
// 依据 HSYNC 计数行，生成 VSYNC（场同步）、v_de（垂直数据使能）、pixel_ypos（0..V_VALID-1）
// 展开写法，无三目

module lcd_vtiming #(
    parameter V_SYNC  = 11'd1,    // VSYNC 脉宽（行数）
    parameter V_BACK  = 11'd23,   // 垂直后沿（行数）
    parameter V_VALID = 11'd480,  // 垂直有效行数
    parameter V_FRONT = 11'd22,   // 垂直前沿（行数）
    parameter VS_POL  = 1'b1      // 1: VSYNC 脉冲高有效；0: 低有效
)(
    input  wire       lcd_clk,     // 与像素域同一时钟
    input  wire       sys_rst_n,   // 低有效复位
    input  wire       lcd_hs,      // 行同步；其上升沿作为行tick
    output reg        lcd_vs,      // 场同步输出
    output reg        v_de,        // 垂直数据使能
    output reg [10:0] pixel_ypos   // 0..V_VALID-1（仅在 v_de=1 时有效）
);
    // 总行数与区间
    localparam [10:0] V_TOTAL   = V_SYNC + V_BACK + V_VALID + V_FRONT;
    localparam [10:0] VS_BEG    = V_FRONT;                   // VSYNC 区间起
    localparam [10:0] VS_END    = V_FRONT + V_SYNC;          // VSYNC 区间止(不含)
    localparam [10:0] ACT_BEG_V = V_FRONT + V_SYNC + V_BACK; // 有效区起
    localparam [10:0] ACT_END_V = ACT_BEG_V + V_VALID;       // 有效区止(不含)

    // 行tick：HSYNC 上升沿
    reg hs_d;
    always @(posedge lcd_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) hs_d <= 1'b0;
        else            hs_d <= lcd_hs;
    end
    wire line_tick = (hs_d == 1'b0) && (lcd_hs == 1'b1);

    // 垂直计数
    reg [10:0] v_cnt;
    wire [10:0] v_cnt_next = (v_cnt == V_TOTAL - 1) ? 11'd0 : (v_cnt + 11'd1);

    always @(posedge lcd_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            v_cnt <= 11'd0;
        end else if (line_tick) begin
            v_cnt <= v_cnt_next;
        end
    end

    // VSYNC 输出（按极性分支，展开写法）
    generate if (VS_POL == 1'b1) begin : gen_vs_high
        always @(posedge lcd_clk or negedge sys_rst_n) begin
            if (!sys_rst_n)                          lcd_vs <= 1'b0;
            else if ((v_cnt >= VS_BEG) && (v_cnt < VS_END)) lcd_vs <= 1'b1;
            else                                      lcd_vs <= 1'b0;
        end
    end else begin : gen_vs_low
        always @(posedge lcd_clk or negedge sys_rst_n) begin
            if (!sys_rst_n)                          lcd_vs <= 1'b1;
            else if ((v_cnt >= VS_BEG) && (v_cnt < VS_END)) lcd_vs <= 1'b0;
            else                                      lcd_vs <= 1'b1;
        end
    end endgenerate

    // v_de 与 pixel_ypos（在行边界更新，避免与 v_cnt 同拍竞争）
    always @(posedge lcd_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            v_de       <= 1'b0;
            pixel_ypos <= 11'd0;
        end else if (line_tick) begin
            if (v_cnt_next == ACT_BEG_V) begin
                v_de       <= 1'b1;
                pixel_ypos <= 11'd0;
            end else if ((v_cnt_next > ACT_BEG_V) && (v_cnt_next < ACT_END_V)) begin
                v_de       <= 1'b1;
                pixel_ypos <= pixel_ypos + 11'd1; // 0..V_VALID-1
            end else if (v_cnt_next == ACT_END_V) begin
                v_de       <= 1'b0;
                pixel_ypos <= 11'd0;
            end else begin
                v_de       <= 1'b0;
                pixel_ypos <= 11'd0;
            end
        end
    end
endmodule
