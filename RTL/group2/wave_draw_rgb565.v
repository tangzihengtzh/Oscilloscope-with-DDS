module wave_draw_rgb565 #(
// wave_draw_rgb565_thick.v —— 8bit -> Y，支持像素厚度（垂直加粗）

    parameter integer H_VALID = 800,
    parameter integer V_VALID = 480,
    parameter integer Y_GAIN_SHIFT = 0,      // 垂直放大
    parameter integer Y_BIAS       = 0,      // 正值向上
    parameter integer THICK        = 3,      // 线条厚度（像素，≥1，建议奇数）
    parameter [15:0] WAVE_COLOR    = 16'hF800,
    parameter [15:0] BG_COLOR      = 16'h0000
)(
    input  wire        pclk,
    input  wire        rst_n,
    input  wire        lcd_de,
    input  wire [10:0] x,
    input  wire [10:0] y,
    input  wire [7:0]  sample_8b,
    output reg  [15:0] pixel_out
);
    // 计算目标 y
    wire [17:0] mult = sample_8b << Y_GAIN_SHIFT;
    wire [17:0] y_scaled = (mult * V_VALID) >> 8;       // ≈ * V/256
    wire [11:0] y_base   = (V_VALID-1) - y_scaled[10:0];

    wire signed [12:0] y_bias_applied = $signed({1'b0,y_base}) - $signed(Y_BIAS);
    wire [10:0] y_target = (y_bias_applied < 0) ? 11'd0 :
                           (y_bias_applied > (V_VALID-1)) ? (V_VALID-1) :
                           y_bias_applied[10:0];

    // 加粗：|y - y_target| <= half
    localparam integer HALF = (THICK<=1) ? 0 : (THICK>>1);
    wire [11:0] y_low  = (y_target > HALF) ? (y_target - HALF) : 11'd0;
    wire [11:0] y_high = (y_target + HALF >= V_VALID) ? (V_VALID-1) : (y_target + HALF);

    wire is_wave = (y >= y_low) && (y <= y_high);

    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_out <= 16'h0000;
        end else if (lcd_de) begin
            pixel_out <= is_wave ? WAVE_COLOR : BG_COLOR;
        end else begin
            pixel_out <= 16'h0000;
        end
    end
endmodule

