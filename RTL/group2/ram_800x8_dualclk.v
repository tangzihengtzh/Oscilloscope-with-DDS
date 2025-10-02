// ram_800x8_dualclk.v
module ram_800x8_dualclk #(
    parameter integer LEN = 800
)(
    // Write port (ADC domain)
    input  wire             wr_clk,
    input  wire             wr_en,
    input  wire [9:0]       wr_addr,  // 0..799
    input  wire [7:0]       wr_data,

    // Read port (LCD pixel clock domain)
    input  wire             rd_clk,
    input  wire [9:0]       rd_addr,  // 0..799
    output reg  [7:0]       rd_data
);
    // 提示综合器用块RAM
    // Intel/Altera:
    // synthesis ramstyle = "M9K"
    // Xilinx:
    // (* ram_style = "block" *) 
    reg [7:0] mem [0:LEN-1];

    // 写口
    always @(posedge wr_clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    // 读口（时序读，1 拍延迟）
    always @(posedge rd_clk) begin
        rd_data <= mem[rd_addr];
    end
endmodule
