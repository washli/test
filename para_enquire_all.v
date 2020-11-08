`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:30:37 03/02/2019 
// Design Name: 
// Module Name:    para_enquire_all 
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
module para_enquire_all(
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

wire [7:0]crc = ~(ctrl_code_reg                         + 8'd24                                  + 
						travelling_wave_collect_freq[7:0]     + travelling_wave_collect_freq[15:8]     + travelling_wave_collect_freq[23:16] + travelling_wave_collect_freq[31:24] + 
						travelling_wave_collect_duration[7:0] + travelling_wave_collect_duration[15:8] + 
						travelling_wave_alarm_threshold[7:0]  + travelling_wave_alarm_threshold[15:8]  + 
						power_frequency_collect_freq[7:0]     + power_frequency_collect_freq[15:8]     + power_frequency_collect_freq[23:16] + power_frequency_collect_freq[31:24] +
						power_frequency_collect_duration[7:0] + power_frequency_collect_duration[15:8] + 
						power_frequency_alarm_threshold[7:0]  + power_frequency_alarm_threshold[15:8]); //����У��λ

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
	 else if(enquire_reply_cnt >= 30)
			enquire_reply_cnt_en <= 1'b0;
end

//�ظ����ݼ�����
reg [4:0]enquire_reply_cnt;
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
			5'd0:tx_data_r <= `FPGA_PACK_CMD_TYPE_START_CODE; //��ʼ��
			5'd1:tx_data_r <= ctrl_code_reg;                  //������
			5'd2:tx_data_r <= 8'd24;                          //���ݳ��ȵ�λ
			5'd3:tx_data_r <= 8'h0;								     //���ݳ��ȸ�λ
			
			//�в�������
			5'd4:tx_data_r <= travelling_wave_collect_freq[7:0];         
			5'd5:tx_data_r <= travelling_wave_collect_freq[15:8];   
			5'd6:tx_data_r <= travelling_wave_collect_freq[23:16];   
			5'd7:tx_data_r <= travelling_wave_collect_freq[31:24]; 
			
			//�в�����ʱ��
			5'd8:tx_data_r <= travelling_wave_collect_duration[7:0];         
			5'd9:tx_data_r <= travelling_wave_collect_duration[15:8];   
			5'd10:tx_data_r <= 8'h0;   
			5'd11:tx_data_r <= 8'h0;
			
			//�в�������ֵ
			5'd12:tx_data_r <= travelling_wave_alarm_threshold[7:0];         
			5'd13:tx_data_r <= travelling_wave_alarm_threshold[15:8];   
			5'd14:tx_data_r <= 8'h0;   
			5'd15:tx_data_r <= 8'h0;
			
			//��Ƶ������
			5'd16:tx_data_r <= power_frequency_collect_freq[7:0];         
			5'd17:tx_data_r <= power_frequency_collect_freq[15:8];   
			5'd18:tx_data_r <= power_frequency_collect_freq[23:16];   
			5'd19:tx_data_r <= power_frequency_collect_freq[31:24];  

			//��Ƶ����ʱ��
			5'd20:tx_data_r <= power_frequency_collect_duration[7:0];         
			5'd21:tx_data_r <= power_frequency_collect_duration[15:8];   
			5'd22:tx_data_r <= 8'h0;   
			5'd23:tx_data_r <= 8'h0;
			
			//��Ƶ������ֵ
			5'd24:tx_data_r <= power_frequency_alarm_threshold[7:0];         
			5'd25:tx_data_r <= power_frequency_alarm_threshold[15:8];   
			5'd26:tx_data_r <= 8'h0;   
			5'd27:tx_data_r <= 8'h0;							     
			
			5'd28:tx_data_r <= crc;                            //У��λ 
			5'd29:tx_data_r <= `FPGA_PACK_CMD_TYPE_END_CODE;   //������
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
					5'd0:begin start_tx_r <= 1'b1; st <= 1;end
					5'd1:begin start_tx_r <= 1'b1; st <= 1;end             
					5'd2:begin start_tx_r <= 1'b1; st <= 1;end                     
					5'd3:begin start_tx_r <= 1'b1; st <= 1;end						    
					5'd4:begin start_tx_r <= 1'b1; st <= 1;end       
					5'd5:begin start_tx_r <= 1'b1; st <= 1;end                   
					5'd6:begin start_tx_r <= 1'b1; st <= 1;end
					5'd7:begin start_tx_r <= 1'b1; st <= 1;end
					5'd8:begin start_tx_r <= 1'b1; st <= 1;end 
					5'd9:begin start_tx_r <= 1'b1; st <= 1;end
					5'd10:begin start_tx_r <= 1'b1; st <= 1;end
					5'd11:begin start_tx_r <= 1'b1; st <= 1;end               
					5'd12:begin start_tx_r <= 1'b1; st <= 1;end                     
					5'd13:begin start_tx_r <= 1'b1; st <= 1;end						    
					5'd14:begin start_tx_r <= 1'b1; st <= 1;end       
					5'd15:begin start_tx_r <= 1'b1; st <= 1;end                      
					5'd16:begin start_tx_r <= 1'b1; st <= 1;end
					5'd17:begin start_tx_r <= 1'b1; st <= 1;end
					5'd18:begin start_tx_r <= 1'b1; st <= 1;end
					5'd19:begin start_tx_r <= 1'b1; st <= 1;end
					5'd20:begin start_tx_r <= 1'b1; st <= 1;end
					5'd21:begin start_tx_r <= 1'b1; st <= 1;end                
					5'd22:begin start_tx_r <= 1'b1; st <= 1;end                  
					5'd23:begin start_tx_r <= 1'b1; st <= 1;end						    
					5'd24:begin start_tx_r <= 1'b1; st <= 1;end      
					5'd25:begin start_tx_r <= 1'b1; st <= 1;end                   
					5'd26:begin start_tx_r <= 1'b1; st <= 1;end 
					5'd27:begin start_tx_r <= 1'b1; st <= 1;end  
					5'd28:begin start_tx_r <= 1'b1; st <= 1;end
					5'd29:begin start_tx_r <= 1'b1; st <= 1;end
					default:begin start_tx_r <= 1'b0; st <= 0;end
				endcase
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

wire enquire_reply_ok = (enquire_reply_cnt >= 30);
assign tx_data = tx_data_r;
assign start_tx = start_tx_r;
assign enquire_para_done =  (enquire_reply_cnt >= 30); //����������ɱ�־
assign module_run_flag = enquire_reply_cnt_en;//��־��ģ�����У����ڴ����ϴ�����ѡ��


endmodule
