`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/05/14 09:08:04
// Design Name: 
// Module Name: speed_select
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


module speed_select_with_mcu(
    clk,
    rst,
    bps_start,
    clk_bps
    );
 
input clk; // 100MHz主时钟
input rst;  //高电平复位信号
input bps_start;  //接收到数据后，波特率时钟启动信号置位
output clk_bps;   // clk_bps的高电平为接收或者发送数据位的中间采样点
 //计算cnt公式：f/(bps)
parameter    bps9600    = 10416,    //波特率为9600bps
              bps19200   = 5208,    //波特率为19200bps
              bps38400   = 2604,    //波特率为38400bps
              bps57600   = 1736, //波特率为57600bps
              bps115200  = 868; //波特率为115200bps
 
parameter    bps9600_2  = 5208,
              bps19200_2 = 2604,
              bps38400_2 = 1302,
              bps57600_2 = 868,
              bps115200_2= 434; 

reg[19:0] cnt;           //分频计数
reg clk_bps_r;           //波特率时钟寄存器
 
always @ (posedge clk )
    if(rst) cnt <= 19'd0;
    else if(cnt==bps115200 || !bps_start) cnt <= 19'd0;  //波特率时钟计数启动
    else cnt <= cnt+1'b1;
 
always @ (posedge clk )
    if(rst) clk_bps_r <= 1'b0;
    else if(cnt==bps115200_2 && bps_start) clk_bps_r <= 1'b1;    // clk_bps_r高电平为接收或者发送数据位的中间采样点
    else clk_bps_r <= 1'b0;
 
assign clk_bps = clk_bps_r;
 
endmodule