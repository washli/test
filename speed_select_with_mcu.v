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
 
input clk; // 100MHz��ʱ��
input rst;  //�ߵ�ƽ��λ�ź�
input bps_start;  //���յ����ݺ󣬲�����ʱ�������ź���λ
output clk_bps;   // clk_bps�ĸߵ�ƽΪ���ջ��߷�������λ���м������
 //����cnt��ʽ��f/(bps)
parameter    bps9600    = 10416,    //������Ϊ9600bps
              bps19200   = 5208,    //������Ϊ19200bps
              bps38400   = 2604,    //������Ϊ38400bps
              bps57600   = 1736, //������Ϊ57600bps
              bps115200  = 868; //������Ϊ115200bps
 
parameter    bps9600_2  = 5208,
              bps19200_2 = 2604,
              bps38400_2 = 1302,
              bps57600_2 = 868,
              bps115200_2= 434; 

reg[19:0] cnt;           //��Ƶ����
reg clk_bps_r;           //������ʱ�ӼĴ���
 
always @ (posedge clk )
    if(rst) cnt <= 19'd0;
    else if(cnt==bps115200 || !bps_start) cnt <= 19'd0;  //������ʱ�Ӽ�������
    else cnt <= cnt+1'b1;
 
always @ (posedge clk )
    if(rst) clk_bps_r <= 1'b0;
    else if(cnt==bps115200_2 && bps_start) clk_bps_r <= 1'b1;    // clk_bps_r�ߵ�ƽΪ���ջ��߷�������λ���м������
    else clk_bps_r <= 1'b0;
 
assign clk_bps = clk_bps_r;
 
endmodule