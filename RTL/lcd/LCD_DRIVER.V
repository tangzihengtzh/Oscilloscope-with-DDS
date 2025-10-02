module LCD_DRIVER (
    input  wire        sys_clk,
    input  wire        sys_rst_n,

    // RGB LCD 连接
    output wire        lcd_hs,       // 行同步
    output wire        lcd_vs,       // 场同步
    output wire        lcd_de,       // 数据使能
    output wire [15:0] lcd_rgb,      // RGB565
    output wire        lcd_bl,       // 背光
    output wire        lcd_rst,      // 面板复位（若原理图无此脚，先常高）
    output wire        lcd_pclk,     // 采样时钟

    // 与上层的数据交互
    input  wire [15:0] pixel_data,   // 像素数据（有效期输出）
    output wire [10:0] pixel_xpos,   // x 坐标（0..H_VALID-1）
    output wire [10:0] pixel_ypos    // y 坐标（0..V_VALID-1）
);

    //=====================
    // 参数
    //=====================
    parameter H_SYNC  = 11'd1;
    parameter H_BACK  = 11'd46;
    parameter H_FRONT = 11'd210;
    parameter H_VALID = 11'd800;     // 有效像素
    parameter H_TOTAL = 11'd1057;    // 800+46+210+1=1057

    parameter V_SYNC  = 11'd1;
    parameter V_BACK  = 11'd23;
    parameter V_FRONT = 11'd22;
    parameter V_VALID = 11'd480;
    parameter V_TOTAL = 11'd526;     // 23+480+22+1=526

    //=====================
    // PLL
    //=====================
    wire locked_sig;
    pll_ip pll_ip_inst (
        .inclk0 (sys_clk),
        .c0     (lcd_pclk),
        .locked (locked_sig)
    );

    // 建议用“系统复位 & PLL锁定”作为下游复位
    wire rst_n_int = sys_rst_n & locked_sig;

    //=====================
    // 水平时序/DE/X 坐标
    //=====================
    wire h_de;
    lcd_hsync #(
        .H_SYNC (H_SYNC),
        .H_BACK (H_BACK),
        .H_VALID(H_VALID),
        .H_FRONT(H_FRONT),
        .HS_POL (1'b1)     // 若屏要求低有效，改 1'b0
    ) u_lcd_hsync (
        .lcd_clk   (lcd_pclk),
        .sys_rst_n (rst_n_int),
        .lcd_hs    (lcd_hs)
    );

    lcd_hde #(
        .H_SYNC (H_SYNC),
        .H_BACK (H_BACK),
        .H_VALID(H_VALID),
        .H_FRONT(H_FRONT)
    ) u_lcd_hde (
        .lcd_clk    (lcd_pclk),
        .sys_rst_n  (rst_n_int),
        .h_de       (h_de),
        .pixel_xpos (pixel_xpos)
    );

    //=====================
    // 垂直时序/DE/Y 坐标（用 HSYNC 计行）
    //=====================
    wire v_de;
    lcd_vtiming #(
        .V_SYNC (V_SYNC),
        .V_BACK (V_BACK),
        .V_VALID(V_VALID),
        .V_FRONT(V_FRONT),
        .VS_POL (1'b1)     // 若屏要求低有效，改 1'b0
    ) u_lcd_vtiming (
        .lcd_clk    (lcd_pclk),
        .sys_rst_n  (rst_n_int),
        .lcd_hs     (lcd_hs),
        .lcd_vs     (lcd_vs),
        .v_de       (v_de),
        .pixel_ypos (pixel_ypos)
    );

    //=====================
    // 输出拼装
    //=====================
    assign lcd_de  = h_de & v_de;
    assign lcd_rgb = lcd_de ? pixel_data : 16'h0000;  // 无效期输出黑色
    //assign lcd_bl  = 1'b1;                            // 背光常开
    //assign lcd_rst = 1'b1;                            // 若原理图无LCD复位脚，先常高
	 assign lcd_bl  = sys_rst_n;
	 assign lcd_rst = sys_rst_n;

endmodule
