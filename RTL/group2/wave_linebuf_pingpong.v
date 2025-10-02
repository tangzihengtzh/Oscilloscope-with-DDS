module wave_linebuf_pingpong #(
    parameter integer LEN = 800
)(
    // ===== 写侧（ADC 时钟域）=====
    input  wire             wr_clk,
    input  wire             wr_rst_n,
    input  wire             wr_valid,      // 有效采样输入
    input  wire [7:0]       wr_data,       // 0..255 原始ADC码
    output reg              wr_busy,       // 正在接收一行
    output reg              line_ready,    // 一行写满，读侧可切换
    // 可选：对齐外部帧的“行开始”触发
    input  wire             wr_line_start, // 置1开始新一行（可不接，内部自启）

    // ===== 读侧（LCD 像素时钟域）=====
    input  wire             rd_clk,
    input  wire             rd_rst_n,
    input  wire [9:0]       rd_addr,       // 一般接 pixel_xpos[9:0]
    output reg  [7:0]       rd_data
);
    // 两块 800x8 的双端口 RAM 作为 A/B 面
    // synthesis ramstyle = "M9K"
    reg [7:0] memA [0:LEN-1];
    reg [7:0] memB [0:LEN-1];

    // ------- 写侧控制 -------
    reg        wr_buf_sel;      // 0 -> 写A, 1 -> 写B
    reg [9:0]  wr_cnt;          // 0..799

    wire start_line = wr_line_start | (~wr_busy & wr_valid); // 无外部触发时，首个 valid 即开行

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_busy     <= 1'b0;
            wr_cnt      <= 10'd0;
            wr_buf_sel  <= 1'b0;
            line_ready  <= 1'b0;
        end else begin
            line_ready <= 1'b0;

            // 开始一行
            if (start_line && !wr_busy) begin
                wr_busy <= 1'b1;
                wr_cnt  <= 10'd0;
            end

            // 接收数据
            if (wr_busy && wr_valid) begin
                if (wr_buf_sel == 1'b0) begin
                    memA[wr_cnt] <= wr_data;
                end else begin
                    memB[wr_cnt] <= wr_data;
                end
                wr_cnt <= wr_cnt + 10'd1;

                // 写满一行
                if (wr_cnt == (LEN-1)) begin
                    wr_busy     <= 1'b0;
                    wr_buf_sel  <= ~wr_buf_sel; // 翻面
                    line_ready  <= 1'b1;        // 通知读侧可以切换到新完成的面
                end
            end
        end
    end

    // ------- 读侧控制 -------
    // 读侧当前使用的面（与写侧异步，需要同步）
    reg        rd_use_buf;      // 0 -> 读A, 1 -> 读B

    // 将 line_ready 跨域同步到 rd_clk，并在上升沿时翻转 rd_use_buf
    reg [2:0]  lr_sync;
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            lr_sync    <= 3'b000;
            rd_use_buf <= 1'b1;      // 初始先读B，写侧从A开始写，避免同面冲突
        end else begin
            lr_sync <= {lr_sync[1:0], line_ready};
            // 检测上升沿
            if (lr_sync[2:1] == 2'b01) begin
                rd_use_buf <= ~rd_use_buf; // 收到“写满一行”后切换读面
            end
        end
    end

    // 真双端口读：同步时序读，1 拍延迟
    reg [7:0] rd_data_a, rd_data_b;
    always @(posedge rd_clk) begin
        rd_data_a <= memA[rd_addr];
        rd_data_b <= memB[rd_addr];
        rd_data   <= rd_use_buf ? rd_data_b : rd_data_a;
    end
endmodule
