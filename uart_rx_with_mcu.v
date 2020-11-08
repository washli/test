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
 
input clk; // 20MHz��ʱ��
input rst;  //�ߵ�ƽ��λ�ź�
input rs232_rx;   // RS232���������ź�
input clk_bps;    // clk_bps�ĸߵ�ƽΪ���ջ��߷�������λ���м������
output bps_start; //���յ����ݺ󣬲�����ʱ�������ź���λ
output[7:0] rx_data; //�������ݼĴ���������ֱ����һ����������
output rx_int;    //���������ж��ź�,���յ������ڼ�ʼ��Ϊ�ߵ�ƽ
output rx_ok;//������8bit���ݺ����һ��ʱ�����ڵĸߵ�ƽ�źţ���������ģ�����������

//----------------------------------------------------------------
reg rs232_rx0,rs232_rx1,rs232_rx2; //�������ݼĴ������˲���
wire neg_rs232_rx;   //��ʾ�����߽��յ��½���
 
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
 
assign neg_rs232_rx = rs232_rx2 & ~rs232_rx1; //���յ��½��غ�neg_rs232_rx�ø�һ��ʱ������
 
//----------------------------------------------------------------
reg bps_start_r;
reg[3:0]   num;   //��λ����
reg rx_int;   //���������ж��ź�,���յ������ڼ�ʼ��Ϊ�ߵ�ƽ
reg rx_ok;
always @ (posedge clk) begin
    if(rst) begin
           bps_start_r <= 1'bz;
           rx_int <= 1'b0;
       end
    else if(neg_rs232_rx) begin
           bps_start_r <= 1'b1; //������������
           rx_int <= 1'b1;   //���������ж��ź�ʹ��
           end
    else if(num==4'd10) begin
           bps_start_r <= 1'bz; //���ݽ������
           rx_int <= 1'b0;      //���������ж��źŹر�
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
reg[7:0] rx_data_r;  //�������ݼĴ���������ֱ����һ����������
//----------------------------------------------------------------
 
reg[7:0]   rx_temp_data; //��ǰ�������ݼĴ���
reg rx_data_shift;   //������λ��־
 
always @ (posedge clk ) begin
    if(rst) begin
           rx_data_shift <= 1'b0;
           rx_temp_data <= 8'd0;
           num <= 4'd0;
           rx_data_r <= 8'd0;
       end
    else if(rx_int) begin    //�������ݴ���
       if(clk_bps) begin //��ȡ����������,��������Ϊһ����ʼλ��8bit���ݣ�һ������λ     
 
              rx_data_shift <= 1'b1;
              num <= num+1'b1;
              if(num<=4'd8) rx_temp_data[7] <= rs232_rx;    //����9bit��1bit��ʼλ��8bit���ݣ�
           end
       else if(rx_data_shift) begin    //������λ����   
              rx_data_shift <= 1'b0;
              if(num<=4'd8) rx_temp_data <= rx_temp_data >> 1'b1;  //��λ8�Σ���1bit��ʼλ�Ƴ���ʣ��8bit����ʱ��������
              else if(num==4'd10) begin
                     num <= 4'd0;  //���յ�STOPλ�����,num����
                     rx_data_r <= rx_temp_data;  //���������浽���ݼĴ���rx_data��
                  end
           end
       end
end
 
assign rx_data = rx_data_r;
 
endmodule