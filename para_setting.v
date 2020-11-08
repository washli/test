`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:11:56 02/28/2019 
// Design Name: 
// Module Name:    para_setting 
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
module para_setting(
    input clk,
    input rst,
	 input para_setting_flag, //�������ñ�־
	 input [7:0]ctrl_code, //������
	 input [7:0]rx_data,  //���ڽ�������
	 input rx_ok,  //����������Ч��־

	 output [31:0]para, //�����������
	 output travelling_wave_collect_freq_cs,//�в�����������ѡ��
	 output travelling_wave_collect_duration_cs,//�в�����ʱ������ѡ��
	 output travelling_wave_alarm_threshold_cs,//�в�������ֵ����ѡ��
	 
	 output power_frequency_collect_freq_cs,//��Ƶ����������ѡ��
	 output power_frequency_collect_duration_cs,//��Ƶ����ʱ������ѡ��
	 output power_frequency_alarm_threshold_cs,//��Ƶ������ֵ����ѡ��
	 
	 output set_para_done,  //����������ɱ�־
	 output module_run_flag,//��־��ģ�����У����ڴ����ϴ�����ѡ��
	 
	 input tx_idle, //����½��أ����ݷ�����ɱ�־
	 output [7:0]tx_data, //���ڷ�������
	 output start_tx  //���ڷ���ʹ�ܣ�������
	 
	 
    );

`include "com_with_mcu_para.v"	

//���rx_ok�ź�������
reg rx_ok1;
reg rx_ok2;
always @(posedge clk) begin
    if(rst)begin 
        rx_ok1 <= 1'b1;
        rx_ok2 <= 1'b1;
    end
    else begin
        rx_ok1 <= rx_ok;
        rx_ok2 <= rx_ok1;
    end
end
wire rx_ok_rise = (~rx_ok2) && (rx_ok1);

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
parameter  waitSetFlag          = 1,
           enRxCnt              = 2,
			  getPara              = 3,
			  setParaEn            = 4;

reg [3:0] ct,nt;      
always@(posedge clk)begin
    if(rst)begin
        ct <= waitSetFlag;
    end
    else begin
        ct <= nt;
    end
end         
always@(*)begin
 case(ct)
	waitSetFlag:begin  //�ȴ����ñ�־����
		if(para_setting_flag) 
			nt = enRxCnt;
		else 
			nt = waitSetFlag;
	end 
	enRxCnt:begin   //�����������ݼ�����
		nt = getPara; 
	end
	getPara:begin    //�������ò�������
		if(rx_byte_cnt >= 4'd8)
			nt = setParaEn;
		else
			nt = getPara;
	end
	setParaEn:begin  //�����������ñ�־
		nt = waitSetFlag;
	end
	default:begin
		nt = waitSetFlag;
	end
  endcase
end

reg [7:0]ctrl_code_reg;
reg [31:0]para_data;
reg set_para_en;
always@(posedge clk)begin
    if(rst)begin
		ctrl_code_reg <= 8'h0;
		set_para_en <= 1'b0;
		para_data <= 0;
    end
    else begin
	  case(ct)
		 waitSetFlag:begin
			set_para_en <= 1'b0;
		 end
		 enRxCnt:begin
			ctrl_code_reg <= ctrl_code; //���������
			rx_byte_cnt_en <= 1'b1; //�������ݼ�����ʹ��
		 end
		 getPara:begin
			case(rx_byte_cnt)
				4'd3:para_data[7:0]   <= data_in_reg;
				4'd4:para_data[15:8]  <= data_in_reg;
				4'd5:para_data[23:16] <= data_in_reg;
				4'd6:para_data[31:24] <= data_in_reg;
			endcase				
		 end
		 setParaEn:begin
			rx_byte_cnt_en <= 1'b0;
			set_para_en <= 1'b1; //������������ʹ�ܱ�־
       end
		endcase
	end
end

//�������ݼ�����
reg rx_byte_cnt_en;
reg [3:0]rx_byte_cnt;//������յ����ݼ�����
always@(posedge clk)begin
    if(rst)begin
		rx_byte_cnt <= 0;
    end
    else if(rx_ok_rise && rx_byte_cnt_en)
			rx_byte_cnt <= rx_byte_cnt + 1'b1;
	 else if(!rx_byte_cnt_en)
			rx_byte_cnt <= 0;
end

//�����������ݵ�data_in_reg
reg [7:0]data_in_reg;
always@(posedge clk)begin
    if(rst)begin
		data_in_reg <= 0;
    end
    else if(rx_ok_rise && rx_byte_cnt_en)
			data_in_reg <= rx_data;
end

///////////////////////////////////////////////////////////////////
//�������ý���
parameter  waitSetEn            = 1,
           setPara              = 2;

reg [3:0] ct_set,nt_set;      
always@(posedge clk)begin
    if(rst)begin
        ct_set <= waitSetEn;
    end
    else begin
        ct_set <= nt_set;
    end
end 
													
always@(*)begin
 case(ct_set)
	waitSetEn:begin  //�ȴ����ò���ʹ��
		if(set_para_en) 
			nt_set = setPara;
		else 
			nt_set = waitSetEn;
	end 
	setPara:begin   //�����������ݼ�����
		if(set_para_dly_cnt >= 20)
			nt_set = waitSetEn; 
		else
			nt_set = setPara;
	end
	default:begin
		nt_set = waitSetEn;
	end
  endcase
end

//���ò�����ʱ������
reg [4:0]set_para_dly_cnt;
always@(posedge clk)begin
    if(rst)begin
		set_para_dly_cnt <= 0;
    end
    else if(set_para_dly_cnt_en)
			set_para_dly_cnt <= set_para_dly_cnt + 1'b1;
	 else if(!set_para_dly_cnt_en)
			set_para_dly_cnt <= 0;
end

wire set_para_dly_cnt_en = (ct_set == setPara) && (set_para_dly_cnt <= 20);//�������������ӳټ��������ܱ�־,��ʱ20��ʱ������

assign  travelling_wave_collect_freq_cs     =  (ct_set == setPara) && 
													        (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_SETTING_TRAVELLING_WAVE_COLLECT_FREQUENCY); 
assign  travelling_wave_collect_duration_cs =  (ct_set == setPara) && 
													        (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_SETTING_TRAVELLING_WAVE_COLLECT_DURATION); 
assign  travelling_wave_alarm_threshold_cs  =  (ct_set == setPara) && 
													        (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_SETTING_TRAVELLING_WAVE_ALARM_THRESHOLD); 												
assign  power_frequency_collect_freq_cs     =  (ct_set == setPara) && 
													        (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_SETTING_POWER_FREQUENCY_COLLECT_FREQUENCY); 
assign  power_frequency_collect_duration_cs =  (ct_set == setPara) && 
													        (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_SETTING_POWER_FREQUENCY_COLLECT_DURATION); 
assign  power_frequency_alarm_threshold_cs  =  (ct_set == setPara) && 
													        (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_SETTING_POWER_FREQUENCY_ALARM_THRESHOLD); 

assign para = para_data;

////////////////////////////////////////////////////////
//�ظ��������óɹ���־
wire reply_en = (set_para_dly_cnt >= 20);//�ñ�־��1����ʾ��ʼ��mcu�ظ��ɹ�

//�ظ����ݼ�����ʹ��
reg reply_data_cnt_en;
always@(posedge clk)begin
    if(rst)begin
		reply_data_cnt_en <= 1'b0;
    end
    else if(reply_en)
			reply_data_cnt_en <= 1'b1;
	 else if(reply_data_cnt >= 7)
			reply_data_cnt_en <= 1'b0;
end

//�ظ����ݼ�����
reg [3:0]reply_data_cnt;
always@(posedge clk)begin
    if(rst)begin
		reply_data_cnt <= 0;
    end
    else if(reply_data_cnt_en && tx_done)
			reply_data_cnt <= reply_data_cnt + 1'b1;
	 else if(!reply_data_cnt_en)
			reply_data_cnt <= 0;
end

reg [7:0]tx_data_r;
wire [7:0]crc = ~(ctrl_code_reg + 8'h01 + 8'h0 + `FPGA_PACK_CMD_TYPE_OK); //����У��λ
always@(posedge clk)begin
    if(rst)begin
		tx_data_r <= 0;
    end
    else if(reply_data_cnt_en)begin
		case(reply_data_cnt)
			4'd0:tx_data_r <= `FPGA_PACK_CMD_TYPE_START_CODE; //��ʼ��
			4'd1:tx_data_r <= ctrl_code_reg;                  //������
			4'd2:tx_data_r <= 8'h01;                          //���ݳ��ȵ�λ
			4'd3:tx_data_r <= 8'h0;								     //���ݳ��ȸ�λ
			4'd4:tx_data_r <= `FPGA_PACK_CMD_TYPE_OK;         //�ɹ�0xff
			4'd5:tx_data_r <= crc;                            //У��λ 
			4'd6:tx_data_r <= `FPGA_PACK_CMD_TYPE_END_CODE;   //������
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
			 if(reply_data_cnt_en)begin
				case(reply_data_cnt)
					4'd0:start_tx_r <= 1'b1;
					4'd1:start_tx_r <= 1'b1;                
					4'd2:start_tx_r <= 1'b1;                     
					4'd3:start_tx_r <= 1'b1;							    
					4'd4:start_tx_r <= 1'b1;       
					4'd5:start_tx_r <= 1'b1;                      
					4'd6:start_tx_r <= 1'b1; 
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


assign tx_data = tx_data_r;
assign start_tx = start_tx_r;
assign set_para_done =  (reply_data_cnt >= 7); //����������ɱ�־
assign module_run_flag = reply_data_cnt_en;//��־��ģ�����У����ڴ����ϴ�����ѡ��

endmodule
