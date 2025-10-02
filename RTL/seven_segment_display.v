module seven_segment_display(
    input wire reset,
    input wire clk,
    input wire [7:0] datain1,
    input wire [7:0] datain2,
    input wire [7:0] datain3,
    input wire [7:0] datain4,
    input wire [7:0] datain5,
    input wire [7:0] datain6,
    output wire enable,
    output wire databit,
    output wire shcp,
    output wire stcp
);

//num:
// 00001001;//9
// 00000001;//8
// 00011111;//7
// 01000001;//6
// 01001001;//5
// 10011001;//4
// 00001101;//3
// 00100101;//2
// 10011111;//1
// 00000011;//0

    reg [15:0]vec;

    reg [3:0]index;
    reg [31:0]refresh;
    reg flag_refresh;
    always @(posedge clk) begin
			if (refresh==5209) begin
				 refresh<=0;
				 flag_refresh<=1;
			end else begin
				 refresh<=refresh+1;
				 flag_refresh<=0;
			end
    end

    always @(posedge clk) begin
        if (reset==0) begin
            index<=0;
        end else begin
            if (flag_refresh==1) begin
                if (index<6) begin
                    index<=index+1;
                end else begin
                    index<=0;
                end
            end
        end
    end

    reg [3:0] cnt_clk_16;
    reg flag_cnt_clk_16;

    always @(posedge clk) begin
        if (reset==0) begin
            cnt_clk_16 <= 0;
            flag_cnt_clk_16 <= 0;
        end else begin
            if (cnt_clk_16 == 4'b1111) begin  // 濡傛灉璁℃暟鍣ㄨ揪鍒15
                cnt_clk_16 <= 0;               // 閲嶇疆璁℃暟鍣
                flag_cnt_clk_16 <= 1;          // 鐢熸垚涓€涓椂閽熶娇鑳戒俊鍙
            end else begin
                cnt_clk_16 <= cnt_clk_16 + 1;  // 璁℃暟鍣ㄥ姞 1
                flag_cnt_clk_16 <= 0;          // 娓呴櫎鏃堕挓浣胯兘淇″彿
            end
        end
    end

	 
    always @(posedge clk) begin
			if(flag_refresh)begin
				case (index)
					 0: vec <= {6'b100000, 2'b00, datain1};
					 1: vec <= {6'b010000, 2'b00, datain2};
					 2: vec <= {6'b001000, 2'b00, datain3};
					 3: vec <= {6'b000100, 2'b00, datain4};
					 4: vec <= {6'b000010, 2'b00, datain5};
					 5: vec <= {6'b000001, 2'b00, datain6};
					 default: ;
				endcase
			end
    end
	 
	 
    outctrl driver (
        .clk(clk),
        .rst(reset),
        .vec(vec),
        .enable(enable),
        .databit(databit),
        .shcp(shcp),
        .stcp(stcp)
    );
    
endmodule
