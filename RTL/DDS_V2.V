module DDS_V2 #(
    parameter integer H_VALID = 800,
    parameter integer V_VALID = 480
)(
    input  wire        sys_clk,     // 系统时钟（给 AD/DA/波形源等）
    input  wire        rst_n,

    // ---- ADC / DAC 物理引脚（按你板级连接命名）----
    input  wire [7:0]  ad_data,
    output wire        ad_clk,      // 若 AD 需要外部时钟驱动可接出
    output wire        dac_clk,
    output wire [7:0]  dac_data,

    // ---- LCD 物理引脚 ----
    output wire        lcd_hs,
    output wire        lcd_vs,
    output wire        lcd_de,
    output wire [15:0] lcd_rgb,
    output wire        lcd_bl,
    output wire        lcd_rst,
    output wire        lcd_pclk
);

    // =========================
    // 1) AD 采样 & DA 测试源
    // =========================
    wire [7:0] adc_sample;  // 8bit 采样（0..255）
    AD_IN_CTRL u_ad_in (
        .sys_clk  (sys_clk),
        .rst_n    (rst_n),
        .ad_data  (ad_data),
        .ad_clk   (ad_clk),
        .data_out (adc_sample)
    );

    wire [7:0] dac_value;
    wire       step_pulse;  // 每次更新 DAC 值给一个脉冲（我们用它来节流写入 800 点）
    DA_OUT_CTRL u_da_out (
        .sys_clk  (sys_clk),
        .rst_n    (rst_n),
        .data_in  (dac_value),
        .dac_clk  (dac_clk),
        .dac_data (dac_data)
    );
    wave_gen_0_255_10s u_wave (
        .clk        (sys_clk),
        .rst_n      (rst_n),
        .value      (dac_value),
        .step_pulse (step_pulse)
    );

    // =========================
    // 2) LCD 驱动
    // =========================
    wire [15:0] pixel_data;
    wire [10:0] pixel_xpos; // 0..H_VALID-1
    wire [10:0] pixel_ypos; // 0..V_VALID-1

    // 这里直接用你的 LCD_DRIVER 实例名与端口
    LCD_DRIVER u_lcd (
        .sys_clk   (sys_clk),    
        .sys_rst_n (rst_n),
        .lcd_hs    (lcd_hs),
        .lcd_vs    (lcd_vs),
        .lcd_de    (lcd_de),
        .lcd_rgb   (lcd_rgb),
        .lcd_bl    (lcd_bl),
        .lcd_rst   (lcd_rst),
        .lcd_pclk  (lcd_pclk),
        .pixel_data(pixel_data),
        .pixel_xpos(pixel_xpos),
        .pixel_ypos(pixel_ypos)
    );

    // =========================
    // 3) 乒乓行缓冲（800x8）
    // 写侧：sys_clk 域，用 step_pulse 作为 wr_valid，每来一个点写一个
    // 读侧：lcd_pclk 域，地址接 pixel_xpos[9:0]
    // =========================
    wire [7:0] line_rd_data;
    wire       line_ready;    // 写满 800 点后翻面并出脉冲到读侧（内部已做跨域同步）
    wire       wr_busy;

		wire [7:0] sample_for_draw;
		circ_linebuf_800x8 #(.LEN(800)) u_circ (
			 .wr_clk   (sys_clk),      // 或你的 ADC 采样时钟
			 .wr_rst_n (rst_n),
			 .wr_en    (step_pulse),   // 每个采样写一次（真实采样就用采样有效信号）
			 .wr_data  (adc_sample),

			 .rd_clk   (lcd_pclk),
			 .rd_rst_n (rst_n),
			 .rd_x     (pixel_xpos[9:0]),
			 .rd_data  (sample_for_draw)
		);


    // =========================
    // 4) 波形着色（把 8bit 值映射为屏幕 Y，当前 x 列只点亮该 y 像素）
    // =========================
    wire [15:0] wave_pixel;
	wave_draw_rgb565 #(
		 .H_VALID(H_VALID),
		 .V_VALID(V_VALID),
		 .Y_GAIN_SHIFT(0),
		 .Y_BIAS(0),
		 .THICK(5),                // 想更粗就设 5、7
		 .WAVE_COLOR(16'hF800),
		 .BG_COLOR(16'h0000)
	) u_draw (
		 .pclk      (lcd_pclk),
		 .rst_n     (rst_n),
		 .lcd_de    (lcd_de),
		 .x         (pixel_xpos),
		 .y         (pixel_ypos),
		 .sample_8b (sample_for_draw),   // ← 来自 u_circ
		 .pixel_out (pixel_data)
	);

    //assign pixel_data = wave_pixel; // 直接作为 LCD 像素输出

endmodule
