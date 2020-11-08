`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/05/14 09:08:04
// Design Name: 
// Module Name: uart_rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_rx_with_mcu(
    clk,
    rst,
    rs232_rx,
    clk_bps,
    bps_start,
    rx_data,
    rx_ok,
    rx_int
    );
 
input clk; // 20MHz主时钟
input rst;  //高电平复位信号
input rs232_rx;   // RS232接收数据信号
input clk_bps;    // clk_bps的高电平为接收或者发送数据位的中间采样点
output bps_start; //接收到数据后，波特率时钟启动信号置位
output[7:0] rx_data; //接收数据寄存器，保存直至下一个数据来到
output rx_int;    //接收数据中断信号,接收到数据期间始终为高电平
output rx_ok;//接受完8bit数据后产生一个时钟周期的高电平信号，用于下游模块的数据锁存

//----------------------------------------------------------------
reg rs232_rx0,rs232_rx1,rs232_rx2; //接收数据寄存器，滤波用
wire neg_rs232_rx;   //表示数据线接收到下降沿
 
always @ (posedge clk ) begin
    if(rst) begin
           rs232_rx0 <= 1'b1;
           rs232_rx1 <= 1'b1;
           rs232_rx2 <= 1'b1;
       end
    else begin
           rs232_rx0 <= rs232_rx;
           rs232_rx1 <= rs232_rx0;
           rs232_rx2 <= rs232_rx1;
       end
end
 
assign neg_rs232_rx = rs232_rx2 & ~rs232_rx1; //接收到下降沿后neg_rs232_rx置高一个时钟周期
 
//----------------------------------------------------------------
reg bps_start_r;
reg[3:0]   num;   //移位次数
reg rx_int;   //接收数据中断信号,接收到数据期间始终为高电平
reg rx_ok;
always @ (posedge clk) begin
    if(rst) begin
           bps_start_r <= 1'bz;
           rx_int <= 1'b0;
       end
    else if(neg_rs232_rx) begin
           bps_start_r <= 1'b1; //启动接收数据
           rx_int <= 1'b1;   //接收数据中断信号使能
           end
    else if(num==4'd10) begin
           bps_start_r <= 1'bz; //数据接收完毕
           rx_int <= 1'b0;      //接收数据中断信号关闭
       end
end
always @ (posedge clk) begin
    if(rst) begin
           rx_ok <= 1'b0;
       end
    else if(num==4'd10) begin
           rx_ok <= 1'b1;
       end
       else if(num==4'd4)begin
            rx_ok <= 1'b0;
       end
end
 
assign bps_start = bps_start_r;
 
//----------------------------------------------------------------
reg[7:0] rx_data_r;  //接收数据寄存器，保存直至下一个数据来到
//----------------------------------------------------------------
 
reg[7:0]   rx_temp_data; //但前接收数据寄存器
reg rx_data_shift;   //数据移位标志
 
always @ (posedge clk ) begin
    if(rst) begin
           rx_data_shift <= 1'b0;
           rx_temp_data <= 8'd0;
           num <= 4'd0;
           rx_data_r <= 8'd0;
       end
    else if(rx_int) begin    //接收数据处理
       if(clk_bps) begin //读取并保存数据,接收数据为一个起始位，8bit数据，一个结束位     
 
              rx_data_shift <= 1'b1;
              num <= num+1'b1;
              if(num<=4'd8) rx_temp_data[7] <= rs232_rx;    //锁存9bit（1bit起始位，8bit数据）
           end
       else if(rx_data_shift) begin    //数据移位处理   
              rx_data_shift <= 1'b0;
              if(num<=4'd8) rx_temp_data <= rx_temp_data >> 1'b1;  //移位8次，第1bit起始位移除，剩下8bit正好时接收数据
              else if(num==4'd10) begin
                     num <= 4'd0;  //接收到STOP位后结束,num清零
                     rx_data_r <= rx_temp_data;  //把数据锁存到数据寄存器rx_data中
                  end
           end
       end
end
 
assign rx_data = rx_data_r;
 
endmodule