// wave_gen_0_255_10s.v —— 产生 0..255 码值，周期10秒
// DAC: AD9708 输入 0 -> +5V, 255 -> -5V
// 本模块只负责产生码元，不再做电压映射，电压换算由上位机完成
// wave_gen_0_255_10s.v
// 修改版：产生 0.1s 周期的正弦波，输出范围 0~255
// wave_gen_0_255_10s.v
// 产生 0.1s 周期的正弦波（0..255），每次更新 value 时产生一步脉冲 step_pulse
module wave_gen_0_255_10s (
    input  wire       clk,        // 50MHz
    input  wire       rst_n,      // 低有效复位
    output reg  [7:0] value,      // 当前码值 0..255
    output reg        step_pulse  // 每次 value 更新时=1拍
);
    // 周期 0.1 s -> 5,000,000 clk；256 个样点/周期 -> 每步 5,000,000 / 256 ≈ 19531.25
    localparam integer CYCLES_PER_STEP = 32'd64000;

    reg [31:0] cnt;
    reg [7:0]  addr;        // ROM地址 0..255
    reg [7:0]  sin_rom [0:255];

    // —— 用整数常量初始化 ROM（综合友好）——
    // 值为 round(127.5 * (1 + sin(2π*i/256)))，范围 0..255
    initial begin
        sin_rom[0] = 8'd128;
        sin_rom[1] = 8'd131;
        sin_rom[2] = 8'd134;
        sin_rom[3] = 8'd137;
        sin_rom[4] = 8'd140;
        sin_rom[5] = 8'd143;
        sin_rom[6] = 8'd146;
        sin_rom[7] = 8'd149;
        sin_rom[8] = 8'd152;
        sin_rom[9] = 8'd155;
        sin_rom[10] = 8'd158;
        sin_rom[11] = 8'd162;
        sin_rom[12] = 8'd165;
        sin_rom[13] = 8'd167;
        sin_rom[14] = 8'd170;
        sin_rom[15] = 8'd173;
        sin_rom[16] = 8'd176;
        sin_rom[17] = 8'd179;
        sin_rom[18] = 8'd182;
        sin_rom[19] = 8'd185;
        sin_rom[20] = 8'd188;
        sin_rom[21] = 8'd190;
        sin_rom[22] = 8'd193;
        sin_rom[23] = 8'd196;
        sin_rom[24] = 8'd198;
        sin_rom[25] = 8'd201;
        sin_rom[26] = 8'd203;
        sin_rom[27] = 8'd206;
        sin_rom[28] = 8'd208;
        sin_rom[29] = 8'd211;
        sin_rom[30] = 8'd213;
        sin_rom[31] = 8'd215;
        sin_rom[32] = 8'd218;
        sin_rom[33] = 8'd220;
        sin_rom[34] = 8'd222;
        sin_rom[35] = 8'd224;
        sin_rom[36] = 8'd226;
        sin_rom[37] = 8'd228;
        sin_rom[38] = 8'd230;
        sin_rom[39] = 8'd232;
        sin_rom[40] = 8'd234;
        sin_rom[41] = 8'd236;
        sin_rom[42] = 8'd238;
        sin_rom[43] = 8'd239;
        sin_rom[44] = 8'd241;
        sin_rom[45] = 8'd242;
        sin_rom[46] = 8'd244;
        sin_rom[47] = 8'd245;
        sin_rom[48] = 8'd246;
        sin_rom[49] = 8'd247;
        sin_rom[50] = 8'd248;
        sin_rom[51] = 8'd249;
        sin_rom[52] = 8'd250;
        sin_rom[53] = 8'd251;
        sin_rom[54] = 8'd252;
        sin_rom[55] = 8'd252;
        sin_rom[56] = 8'd253;
        sin_rom[57] = 8'd253;
        sin_rom[58] = 8'd254;
        sin_rom[59] = 8'd254;
        sin_rom[60] = 8'd254;
        sin_rom[61] = 8'd255;
        sin_rom[62] = 8'd255;
        sin_rom[63] = 8'd255;
        sin_rom[64] = 8'd255;
        sin_rom[65] = 8'd255;
        sin_rom[66] = 8'd255;
        sin_rom[67] = 8'd255;
        sin_rom[68] = 8'd254;
        sin_rom[69] = 8'd254;
        sin_rom[70] = 8'd254;
        sin_rom[71] = 8'd253;
        sin_rom[72] = 8'd253;
        sin_rom[73] = 8'd252;
        sin_rom[74] = 8'd252;
        sin_rom[75] = 8'd251;
        sin_rom[76] = 8'd250;
        sin_rom[77] = 8'd249;
        sin_rom[78] = 8'd248;
        sin_rom[79] = 8'd247;
        sin_rom[80] = 8'd246;
        sin_rom[81] = 8'd245;
        sin_rom[82] = 8'd244;
        sin_rom[83] = 8'd242;
        sin_rom[84] = 8'd241;
        sin_rom[85] = 8'd239;
        sin_rom[86] = 8'd238;
        sin_rom[87] = 8'd236;
        sin_rom[88] = 8'd234;
        sin_rom[89] = 8'd232;
        sin_rom[90] = 8'd230;
        sin_rom[91] = 8'd228;
        sin_rom[92] = 8'd226;
        sin_rom[93] = 8'd224;
        sin_rom[94] = 8'd222;
        sin_rom[95] = 8'd220;
        sin_rom[96] = 8'd218;
        sin_rom[97] = 8'd215;
        sin_rom[98] = 8'd213;
        sin_rom[99] = 8'd211;
        sin_rom[100] = 8'd208;
        sin_rom[101] = 8'd206;
        sin_rom[102] = 8'd203;
        sin_rom[103] = 8'd201;
        sin_rom[104] = 8'd198;
        sin_rom[105] = 8'd196;
        sin_rom[106] = 8'd193;
        sin_rom[107] = 8'd190;
        sin_rom[108] = 8'd188;
        sin_rom[109] = 8'd185;
        sin_rom[110] = 8'd182;
        sin_rom[111] = 8'd179;
        sin_rom[112] = 8'd176;
        sin_rom[113] = 8'd173;
        sin_rom[114] = 8'd170;
        sin_rom[115] = 8'd167;
        sin_rom[116] = 8'd165;
        sin_rom[117] = 8'd162;
        sin_rom[118] = 8'd158;
        sin_rom[119] = 8'd155;
        sin_rom[120] = 8'd152;
        sin_rom[121] = 8'd149;
        sin_rom[122] = 8'd146;
        sin_rom[123] = 8'd143;
        sin_rom[124] = 8'd140;
        sin_rom[125] = 8'd137;
        sin_rom[126] = 8'd134;
        sin_rom[127] = 8'd131;
        sin_rom[128] = 8'd128;
        sin_rom[129] = 8'd125;
        sin_rom[130] = 8'd122;
        sin_rom[131] = 8'd119;
        sin_rom[132] = 8'd116;
        sin_rom[133] = 8'd113;
        sin_rom[134] = 8'd110;
        sin_rom[135] = 8'd107;
        sin_rom[136] = 8'd104;
        sin_rom[137] = 8'd101;
        sin_rom[138] = 8'd98;
        sin_rom[139] = 8'd94;
        sin_rom[140] = 8'd91;
        sin_rom[141] = 8'd89;
        sin_rom[142] = 8'd86;
        sin_rom[143] = 8'd83;
        sin_rom[144] = 8'd80;
        sin_rom[145] = 8'd77;
        sin_rom[146] = 8'd74;
        sin_rom[147] = 8'd71;
        sin_rom[148] = 8'd68;
        sin_rom[149] = 8'd66;
        sin_rom[150] = 8'd63;
        sin_rom[151] = 8'd60;
        sin_rom[152] = 8'd58;
        sin_rom[153] = 8'd55;
        sin_rom[154] = 8'd53;
        sin_rom[155] = 8'd50;
        sin_rom[156] = 8'd48;
        sin_rom[157] = 8'd46;
        sin_rom[158] = 8'd44;
        sin_rom[159] = 8'd42;
        sin_rom[160] = 8'd40;
        sin_rom[161] = 8'd38;
        sin_rom[162] = 8'd36;
        sin_rom[163] = 8'd34;
        sin_rom[164] = 8'd32;
        sin_rom[165] = 8'd30;
        sin_rom[166] = 8'd28;
        sin_rom[167] = 8'd27;
        sin_rom[168] = 8'd25;
        sin_rom[169] = 8'd24;
        sin_rom[170] = 8'd22;
        sin_rom[171] = 8'd21;
        sin_rom[172] = 8'd20;
        sin_rom[173] = 8'd19;
        sin_rom[174] = 8'd18;
        sin_rom[175] = 8'd17;
        sin_rom[176] = 8'd16;
        sin_rom[177] = 8'd15;
        sin_rom[178] = 8'd14;
        sin_rom[179] = 8'd14;
        sin_rom[180] = 8'd13;
        sin_rom[181] = 8'd13;
        sin_rom[182] = 8'd12;
        sin_rom[183] = 8'd12;
        sin_rom[184] = 8'd12;
        sin_rom[185] = 8'd11;
        sin_rom[186] = 8'd11;
        sin_rom[187] = 8'd11;
        sin_rom[188] = 8'd11;
        sin_rom[189] = 8'd11;
        sin_rom[190] = 8'd11;
        sin_rom[191] = 8'd11;
        sin_rom[192] = 8'd12;
        sin_rom[193] = 8'd12;
        sin_rom[194] = 8'd12;
        sin_rom[195] = 8'd13;
        sin_rom[196] = 8'd13;
        sin_rom[197] = 8'd14;
        sin_rom[198] = 8'd14;
        sin_rom[199] = 8'd15;
        sin_rom[200] = 8'd16;
        sin_rom[201] = 8'd17;
        sin_rom[202] = 8'd18;
        sin_rom[203] = 8'd19;
        sin_rom[204] = 8'd20;
        sin_rom[205] = 8'd21;
        sin_rom[206] = 8'd22;
        sin_rom[207] = 8'd24;
        sin_rom[208] = 8'd25;
        sin_rom[209] = 8'd27;
        sin_rom[210] = 8'd28;
        sin_rom[211] = 8'd30;
        sin_rom[212] = 8'd32;
        sin_rom[213] = 8'd34;
        sin_rom[214] = 8'd36;
        sin_rom[215] = 8'd38;
        sin_rom[216] = 8'd40;
        sin_rom[217] = 8'd42;
        sin_rom[218] = 8'd44;
        sin_rom[219] = 8'd46;
        sin_rom[220] = 8'd48;
        sin_rom[221] = 8'd50;
        sin_rom[222] = 8'd53;
        sin_rom[223] = 8'd55;
        sin_rom[224] = 8'd58;
        sin_rom[225] = 8'd60;
        sin_rom[226] = 8'd63;
        sin_rom[227] = 8'd66;
        sin_rom[228] = 8'd68;
        sin_rom[229] = 8'd71;
        sin_rom[230] = 8'd74;
        sin_rom[231] = 8'd77;
        sin_rom[232] = 8'd80;
        sin_rom[233] = 8'd83;
        sin_rom[234] = 8'd86;
        sin_rom[235] = 8'd89;
        sin_rom[236] = 8'd91;
        sin_rom[237] = 8'd94;
        sin_rom[238] = 8'd98;
        sin_rom[239] = 8'd101;
        sin_rom[240] = 8'd104;
        sin_rom[241] = 8'd107;
        sin_rom[242] = 8'd110;
        sin_rom[243] = 8'd113;
        sin_rom[244] = 8'd116;
        sin_rom[245] = 8'd119;
        sin_rom[246] = 8'd122;
        sin_rom[247] = 8'd125;
        sin_rom[248] = 8'd128;
        sin_rom[249] = 8'd131;
        sin_rom[250] = 8'd134;
        sin_rom[251] = 8'd137;
        sin_rom[252] = 8'd140;
        sin_rom[253] = 8'd143;
        sin_rom[254] = 8'd146;
        sin_rom[255] = 8'd149;
    end

    // —— 时序控制：固定步长推进地址，产生 step_pulse 并输出正弦值 ——
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt        = 32'd0;
            addr       = 8'd0;
            value      = 8'd128;
            step_pulse = 1'b0;
        end else begin
            if (cnt == CYCLES_PER_STEP-1) begin
                cnt        <= 32'd0;
                addr       <= addr + 8'd1;          // 自动回卷
                value      <= sin_rom[addr];
                step_pulse <= 1'b1;
            end else begin
                cnt        <= cnt + 32'd1;
                step_pulse <= 1'b0;
            end
        end
    end
endmodule


/*
module wave_gen_0_255_10s (
    input  wire       clk,        // 50MHz
    input  wire       rst_n,      // 低有效复位
    output reg  [7:0] value,      // 当前码值 0..255 循环
    output reg        step_pulse  // 每次 value 递增时拉高1个clk
);
    // 每步周期 = 10s / 256 ≈ 39.0625 ms
    localparam integer CYCLES_PER_STEP = 32'd1_953_125;

    reg [31:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt        <= 32'd0;
            value      <= 8'd0;
            step_pulse <= 1'b0;
        end else begin
            if (cnt == CYCLES_PER_STEP-1) begin
                cnt        <= 32'd0;
                value      <= value + 8'd1;  // 自动回卷到0
                step_pulse <= 1'b1;
            end else begin
                cnt        <= cnt + 32'd1;
                step_pulse <= 1'b0;
            end
        end
    end
endmodule
*/
