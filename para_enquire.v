`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:41:35 03/01/2019 
// Design Name: 
// Module Name:    para_enquire 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module para_enquire(
    input clk,
    input rst,
	 input para_enquire_flag, //�������ñ�־
	 input [7:0]ctrl_code, //������
//	 input [7:0]rx_data,  //���ڽ�������
//	 input rx_ok,  //����������Ч��־

	 input [31:0]travelling_wave_collect_freq,//�в�����������
	 input [15:0]travelling_wave_collect_duration,//�в�����ʱ������
	 input [15:0]travelling_wave_alarm_threshold,//�в�������ֵ����
	 
	 input [31:0]power_frequency_collect_freq,//��Ƶ����������
	 input [15:0]power_frequency_collect_duration,//��Ƶ����ʱ������
	 input [15:0]power_frequency_alarm_threshold,//��Ƶ������ֵ����
	 
	 output enquire_para_done,  //����������ɱ�־
	 output module_run_flag,//��־��ģ�����У����ڴ����ϴ�����ѡ��
	 
	 input tx_idle, //����½��أ����ݷ�����ɱ�־
	 output [7:0]tx_data, //���ڷ�������
	 output start_tx  //���ڷ���ʹ�ܣ�������
    );

`include "com_with_mcu_para.v"	
////���rx_ok�ź�������
//reg rx_ok1;
//reg rx_ok2;
//always @(posedge clk) begin
//    if(rst)begin 
//        rx_ok1 <= 1'b1;
//        rx_ok2 <= 1'b1;
//    end
//    else begin
//        rx_ok1 <= rx_ok;
//        rx_ok2 <= rx_ok1;
//    end
//end
//wire rx_ok_rise = (~rx_ok2) && (rx_ok1);

//���tx_idle�ź��½���
reg tx_idle1;
reg tx_idle2;
always @(posedge clk) begin
    if(rst)begin 
        tx_idle1 <= 1'b1;
        tx_idle2 <= 1'b1;
    end
    else begin
        tx_idle1 <= tx_idle;
        tx_idle2 <= tx_idle1;
    end
end
wire tx_done = (tx_idle2) && (~tx_idle1);

////////////////////////////////////////////////////////
//�õ��������ݽ���
parameter  waitEnquireFlag            = 1,
           waitEnquireOk              = 2;

reg [2:0] ct;  
reg [7:0]ctrl_code_reg;
always@(posedge clk)begin
    if(rst)begin
        ct <= waitEnquireFlag;
		  start_enquire_en <= 1'b0;
		  ctrl_code_reg <= 8'h0;
    end
    else begin
       case(ct)
			waitEnquireFlag:begin  //�ȴ���ѯ��־����
				if(para_enquire_flag) begin
					ct <= waitEnquireOk;
					start_enquire_en <= 1'b1;//���ݻظ�ʹ�ܱ�־,�ڼ�⵽��ѯ��־1ʱ����λ�ñ�־ 			
				end
				else 
					ct <= waitEnquireFlag;
			end 
			waitEnquireOk:begin   //�ȴ������ϴ����
				ctrl_code_reg <= ctrl_code;	
				start_enquire_en <= 1'b0;
				if(enquire_reply_ok)  //�����ϴ���ɱ�־
					ct <= waitEnquireFlag;
				else
					ct <= waitEnquireOk; 
			end
			default:begin
				ct <= waitEnquireFlag;
				start_enquire_en <= 1'b0;
			end
		  endcase
    end
end         
//װ����Ч����
wire [31:0]payload = (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_COLLECT_FREQUENCY) ? travelling_wave_collect_freq                         :
						   (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_COLLECT_DURATION)  ? {{16{1'b0}},travelling_wave_collect_duration[15:0]}  :
						   (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_ALARM_THRESHOLD)   ? {{16{1'b0}},travelling_wave_alarm_threshold[15:0]}   :
						   (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_COLLECT_FREQUENCY) ? power_frequency_collect_freq                         :
						   (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_COLLECT_DURATION)  ? {{16{1'b0}},power_frequency_collect_duration[15:0]}  :
						   (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_ALARM_THRESHOLD)   ? {{16{1'b0}},power_frequency_alarm_threshold[15:0]}   : 32'h0;  

wire [7:0]crc = ~(ctrl_code_reg + 8'h04 + 8'h0 + payload[7:0] + payload[15:8] + payload[23:16] + payload[31:24]); //����У��λ

////////////////////////////////////////////////////////
//�ظ�������ѯ��־
reg start_enquire_en;  //���ݻظ�ʹ�ܱ�־,�ڼ�⵽��ѯ��־1ʱ����λ�ñ�־  
//�ظ����ݼ�����ʹ��
reg enquire_reply_cnt_en;
always@(posedge clk)begin
    if(rst)begin
		enquire_reply_cnt_en <= 1'b0;
    end
    else if(start_enquire_en)
			enquire_reply_cnt_en <= 1'b1;
	 else if(enquire_reply_cnt >= 10)
			enquire_reply_cnt_en <= 1'b0;
end

//�ظ����ݼ�����
reg [3:0]enquire_reply_cnt;
always@(posedge clk)begin
    if(rst)begin
		enquire_reply_cnt <= 0;
    end
    else if(enquire_reply_cnt_en && tx_done)
			enquire_reply_cnt <= enquire_reply_cnt + 1'b1;
	 else if(!enquire_reply_cnt_en)
			enquire_reply_cnt <= 0;
end

reg [7:0]tx_data_r;
always@(posedge clk)begin
    if(rst)begin
		tx_data_r <= 0;
    end
    else if(enquire_reply_cnt_en)begin
		case(enquire_reply_cnt)
			4'd0:tx_data_r <= `FPGA_PACK_CMD_TYPE_START_CODE; //��ʼ��
			4'd1:tx_data_r <= ctrl_code_reg;                  //������
			4'd2:tx_data_r <= 8'h04;                          //���ݳ��ȵ�λ
			4'd3:tx_data_r <= 8'h0;								     //���ݳ��ȸ�λ
			4'd4:tx_data_r <= payload[7:0];         
			4'd5:tx_data_r <= payload[15:8];   
			4'd6:tx_data_r <= payload[23:16];   
			4'd7:tx_data_r <= payload[31:24];   
			4'd8:tx_data_r <= crc;                            //У��λ 
			4'd9:tx_data_r <= `FPGA_PACK_CMD_TYPE_END_CODE;   //������
		endcase
	 end 
end
reg start_tx_r;
reg [2:0]st;
always@(posedge clk)begin
    if(rst)begin
		start_tx_r <= 1'b0;
		st <= 0;
    end
    else begin
		case(st)
		0:begin
			 if(enquire_reply_cnt_en)begin
				case(enquire_reply_cnt)
					4'd0:start_tx_r <= 1'b1;
					4'd1:start_tx_r <= 1'b1;                
					4'd2:start_tx_r <= 1'b1;                     
					4'd3:start_tx_r <= 1'b1;							    
					4'd4:start_tx_r <= 1'b1;       
					4'd5:start_tx_r <= 1'b1;                      
					4'd6:start_tx_r <= 1'b1; 
					4'd7:start_tx_r <= 1'b1;  
					4'd8:start_tx_r <= 1'b1; 
					4'd9:start_tx_r <= 1'b1; 
				endcase
				st <= 1;
			 end 
			 else st <= 0;
		 end
		 1:begin
			start_tx_r <= 1'b0;
			if(tx_done)
				st <= 0;
			else 
				st <= 1;
		 end
		 default:st <= 0;
		endcase
	end
end

wire enquire_reply_ok = (enquire_reply_cnt >= 10);
assign tx_data = tx_data_r;
assign start_tx = start_tx_r;
assign enquire_para_done =  (enquire_reply_cnt >= 10); //����������ɱ�־
assign module_run_flag = enquire_reply_cnt_en;//��־��ģ�����У����ڴ����ϴ�����ѡ��

endmodule
