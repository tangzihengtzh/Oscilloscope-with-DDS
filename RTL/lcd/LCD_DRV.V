// ================================================
// Top: LCD_DRV
// 作用：连接图案发生器(pattern_gen) 与 LCD_DRIVER，
//      并把板上LCD引脚引出。不对外导出 x/y。
// ================================================
module LCD_DRV (
    input  wire        sys_clk,   // 50 MHz 板载时钟
    input  wire        sys_rst_n, // 低有效复位

    // 板上 RGB LCD 引脚
    output wire        lcd_hs,
    output wire        lcd_vs,
    output wire        lcd_de,
    output wire [15:0] lcd_rgb,
    output wire        lcd_bl,
    output wire        lcd_rst,
    output wire        lcd_pclk
);

    // 与 LCD_DRIVER 内部交互的信号（仅内部连线，不对外导出）
    wire [10:0] pixel_xpos;
    wire [10:0] pixel_ypos;
    wire [15:0] pixel_data;

    // -------------------------
    // 实例化 LCD_DRIVER
    // （内部含：PLL、HS/VS、h_de/v_de、lcd_de 组合、
    //   空白期输出黑色、背光/复位常高等）
    // -------------------------
    LCD_DRIVER u_lcd_driver (
        .sys_clk    (sys_clk),
        .sys_rst_n  (sys_rst_n),

        .lcd_hs     (lcd_hs),
        .lcd_vs     (lcd_vs),
        .lcd_de     (lcd_de),
        .lcd_rgb    (lcd_rgb),
        .lcd_bl     (lcd_bl),
        .lcd_rst    (lcd_rst),
        .lcd_pclk   (lcd_pclk),

        .pixel_data (pixel_data),   // ← 来自图案发生器
        .pixel_xpos (pixel_xpos),   // → 提供给图案发生器
        .pixel_ypos (pixel_ypos)    // → 提供给图案发生器
    );

    // -------------------------
    // 简单数据发生器（示例：8色竖条）
    // 使用 LCD_DRIVER 提供的 x/y 与 lcd_de 生成像素
    // 你可随时替换为自己的图像模块
    // -------------------------
    pattern_gen u_pattern (
        .lcd_clk   (lcd_pclk),
        .sys_rst_n (sys_rst_n),
        .lcd_de    (lcd_de),
        .x         (pixel_xpos),
        .y         (pixel_ypos),
        .pixel     (pixel_data)
    );

endmodule
