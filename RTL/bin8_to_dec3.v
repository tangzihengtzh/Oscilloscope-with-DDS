module bin8_to_dec3 (
    input  wire [7:0] bin,         // 0..255
    output reg  [3:0] hund,        // 百位
    output reg  [3:0] tens,        // 十位
    output reg  [3:0] ones         // 个位
);
    integer i;
    reg [17:0] shift; // [17:10]百位, [9:6]十位, [5:2]个位, [1:0]工作区
    always @* begin
        shift = {10'd0, bin};      // 10位BCD清零 + 8位二进制
        for(i=0;i<8;i=i+1) begin
            // 加3校正
            if (shift[17:14] >= 5) shift[17:14] = shift[17:14] + 4'd3; // 百位
            if (shift[13:10] >= 5) shift[13:10] = shift[13:10] + 4'd3; // 十位
            if (shift[9:6]   >= 5) shift[9:6]   = shift[9:6]   + 4'd3; // 个位(中间)
            shift = {shift[16:0],1'b0};
        end
        hund = shift[17:14];
        tens = shift[13:10];
        ones = shift[9:6];
    end
endmodule
