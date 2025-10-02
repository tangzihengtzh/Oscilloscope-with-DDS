// ------------------------------------------------------------
// UART TX (8N1) - simple, edge-triggered start, no handshakes
// - LSB first
// - 1 start bit (0), 8 data bits, 1 stop bit (1)
// - Low-active reset
// - Optional runtime baud divider via baud_div_i
// ------------------------------------------------------------

// ------------------------------------------------------------
// UART TX v2 (8N1)
// - 1 start (0) + 8 data LSB-first + 1 stop (1)
// - Low-active reset
// - 固定位内相位点切换位值，确保首位(起始位)宽度准确
// ------------------------------------------------------------
module uart_tx_simple #(
    parameter integer CLK_FREQ = 50_000_000,
    parameter integer BAUD     = 115200
)(
    input  wire        clk,
    input  wire        reset_n,     // 低电平复位
    input  wire        start,       // 上升沿触发
    input  wire [7:0]  data_in,
    input  wire [31:0] baud_div_i,  // 0=>用参数；非0=>运行时
    output reg         tx           // 空闲为 1
);
    localparam integer P_BAUD_DIV = (CLK_FREQ + BAUD/2) / BAUD;
    reg [31:0] BAUD_DIV;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) BAUD_DIV <= P_BAUD_DIV;
        else          BAUD_DIV <= (baud_div_i!=0) ? baud_div_i : P_BAUD_DIV;
    end

    // start 上升沿
    reg start_d1, start_d2;
    wire start_rise;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            start_d1 <= 1'b0; start_d2 <= 1'b0;
        end else begin
            start_d1 <= start; start_d2 <= start_d1;
        end
    end
    assign start_rise = start_d1 & ~start_d2;

    reg        busy;
    reg [3:0]  bit_idx;        // 0..9: start, d0..d7, stop
    reg [7:0]  data_lat;
    reg [31:0] bit_cnt;        // 0..BAUD_DIV-1

    // 根据“当前 bit_idx”求“下一位”应输出的电平
    function automatic next_bit_level;
        input [3:0] cur_idx;
        input [7:0] d;
        begin
            case (cur_idx)
                4'd0: next_bit_level = d[0];  // 刚发完 start，下一个是 d0
                4'd1: next_bit_level = d[1];
                4'd2: next_bit_level = d[2];
                4'd3: next_bit_level = d[3];
                4'd4: next_bit_level = d[4];
                4'd5: next_bit_level = d[5];
                4'd6: next_bit_level = d[6];
                4'd7: next_bit_level = d[7];
                4'd8: next_bit_level = 1'b1;  // 下一个是 stop
                default: next_bit_level = 1'b1;
            endcase
        end
    endfunction

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            tx       <= 1'b1;
            busy     <= 1'b0;
            bit_idx  <= 4'd0;
            bit_cnt  <= 32'd0;
            data_lat <= 8'h00;
        end else begin
            if (!busy) begin
                tx      <= 1'b1;
                bit_cnt <= 32'd0;
                if (start_rise) begin
                    busy     <= 1'b1;
                    bit_idx  <= 4'd0;     // 先发 start
                    data_lat <= data_in;  // 锁存
                    tx       <= 1'b0;     // 立刻输出 start=0（随后跑满一个位宽）
                end
            end else begin
                // 发送中：位内计数
                if (bit_cnt == (BAUD_DIV - 1)) begin
                    bit_cnt <= 32'd0;
                    if (bit_idx == 4'd9) begin
                        // stop 结束
                        busy    <= 1'b0;
                        tx      <= 1'b1;
                    end else begin
                        // 结束当前位，切到“下一位”的电平
                        tx      <= next_bit_level(bit_idx, data_lat);
                        bit_idx <= bit_idx + 1'b1;
                    end
                end else begin
                    bit_cnt <= bit_cnt + 1'b1;
                    tx      <= tx; // 保持
                end
            end
        end
    end
endmodule
