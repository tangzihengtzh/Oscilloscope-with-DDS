module outctrl (
    input wire clk,
    input wire rst,
	 input wire [15:0]vec,
    output reg enable,
    output reg databit,
    output wire shcp,
    output reg stcp
);

    reg [3:0] cnt_clk_16;
    reg flag_cnt_clk_16;

    always @(negedge clk) begin
			if (cnt_clk_16 == 4'b0000) begin  
				 cnt_clk_16 <= 0;               
				 flag_cnt_clk_16 <= ~flag_cnt_clk_16;          
			end else begin
				 cnt_clk_16 <= cnt_clk_16 + 1;
			end
    end

reg [3:0] index;

assign shcp=flag_cnt_clk_16;

always @(posedge flag_cnt_clk_16) begin
		 enable<=0;
		 index<=index+1'b1;
		 if(index==4'b1000)
			stcp<=1'b1;
		 else
			stcp<=1'b0;		
end

reg [15:0]ShowAll;
always @(negedge flag_cnt_clk_16) begin
	if(rst==0)begin
		ShowAll<=16'hFF00;
		databit<=ShowAll[index];
	end
	else begin
		databit<=vec[index];
	 end
end

endmodule