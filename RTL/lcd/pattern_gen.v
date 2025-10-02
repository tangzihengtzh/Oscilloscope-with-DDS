// pattern_gen.v —— 精确 8 等宽竖条（RGB565），适配任意 H_VALID（默认800）
module pattern_gen #(
    parameter H_VALID = 11'd800,
    parameter V_VALID = 11'd480
)(
    input  wire        lcd_clk,
    input  wire        sys_rst_n,
    input  wire        lcd_de,
    input  wire [10:0] x,      // 0..H_VALID-1
    input  wire [10:0] y,      // 0..V_VALID-1（本例未用，可扩展）
    output reg  [15:0] pixel   // RGB565
);
    // // 8 等分
    // localparam integer BANDS   = 8;
    // localparam integer BAND_W  = H_VALID / BANDS;  // 800/8 = 100

    // reg [2:0] band;

    // // 用比较器切分，避免除法/移位带来的非等宽问题
    // always @* begin
    //     if      (x < 1*BAND_W) band = 3'd0;
    //     else if (x < 2*BAND_W) band = 3'd1;
    //     else if (x < 3*BAND_W) band = 3'd2;
    //     else if (x < 4*BAND_W) band = 3'd3;
    //     else if (x < 5*BAND_W) band = 3'd4;
    //     else if (x < 6*BAND_W) band = 3'd5;
    //     else if (x < 7*BAND_W) band = 3'd6;
    //     else                    band = 3'd7;  // 收尾到最右侧
    // end
	 
	 
	//  reg[15:0] bis_color;
	//  reg[63:0] color_ref;
	// 	always @(posedge lcd_clk or negedge sys_rst_n) begin
	// 		 if (!sys_rst_n) begin
	// 			  bis_color <= 16'h0000;
	// 			  color_ref <= 64'h0000_0000_0000_0000;
	// 		 end else begin
	// 			  if (color_ref >= 64'h0000_0000_01FC_A54F) begin
	// 					//bis_color <= bis_color + 16'h0101;
	// 					color_ref <= 64'h0000_0000_0000_0000;
	// 			  end else begin
	// 					color_ref <= color_ref + 64'h0000_0000_0000_0001;
	// 			  end
	// 		 end
	// 	end


    // // 上色
    // always @(posedge lcd_clk or negedge sys_rst_n) begin
    //     if (!sys_rst_n) begin
    //         pixel <= 16'h0000;
    //     end else if (lcd_de) begin
    //         case (band)
    //             3'd0: pixel <= 16'hF800 + bis_color; // Red
    //             3'd1: pixel <= 16'h07E0 + bis_color; // Green
    //             3'd2: pixel <= 16'h001F + bis_color; // Blue
    //             3'd3: pixel <= 16'hFFE0 + bis_color; // Yellow
    //             3'd4: pixel <= 16'hF81F + bis_color; // Magenta
    //             3'd5: pixel <= 16'h07FF + bis_color; // Cyan
    //             3'd6: pixel <= 16'hFFFF + bis_color; // White
    //             3'd7: pixel <= 16'h0000 + bis_color; // Black
    //         endcase
    //     end else begin
    //         pixel <= 16'h0000;
    //     end
    // end

localparam integer CX = H_VALID/4;   // 圆心X
localparam integer CY = V_VALID/4;   // 圆心Y
localparam integer R  = 50;         // 半径

always @(posedge lcd_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        pixel <= 16'h0000;
    end else if (lcd_de) begin
        // 圆心和半径
        integer dx, dy;
        dx = x - CX;
        dy = y - CY;

        if (dx*dx + dy*dy <= R*R) begin
            pixel <= 16'hFFFF;   // 圆内：白色
        end else begin
            pixel <= 16'h0000;   // 圆外：黑色
        end
    end else begin
        pixel <= 16'h0000;
    end
end


endmodule
