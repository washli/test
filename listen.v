`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:53:24 02/28/2019 
// Design Name: 
// Module Name:    listen 
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
module listen(
    input clk, //
    input rst,
    input rx_ok, //���ڽ���������Ч��־�����������
    input gp_save_ok, //��Ƶ���ݱ�����ɱ�־
    input xb_save_ok, //�в����ݱ�����ɱ�־
    input [7:0] rx_data, //���ڽ�����������
	 input com_done_ok,//���κ�mcuͨ����ɱ�־��������ģ�������1-��ģ��ص���ʼ״̬
	 output reg sram_io_dir_ctrl,//SRAMIO���������������Ʊ�־
	 
	 output reg [7:0] ctrl_code,  //��������֣�������������Ԫ
	 output reg para_setting_flag, //�������ñ�־��1-��ʾ��������
	 output reg para_enquire_flag, //������ѯ��־��1-��ʾ������ѯ
	 
	 output reg para_setting_all_flag, //�����������ñ�־��1-��ʾ��������
	 output reg para_enquire_all_flag, //���������ѯ��־��1-��ʾ������ѯ
	 
	 output reg gps_rms_enquire_flag, //���ݲ�ѯ��־��GPS�͹�����ѯ��1-��Ч
	 
	 output reg wave_data_enquire_flag, //�в����ݲ�ѯ��־
	 
	 output reg xb_fault_flag,     //�в������ϴ���־
	 output reg gp_fault_flag      //��Ƶ�����ϴ���־
    );

`include "com_with_mcu_para.v"	
//////////////////////////////////////////////////////
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

//////////////////////////////////////////////////////
//���gp_save_ok�ź�������
reg gp_save_ok1;
reg gp_save_ok2;
always @(posedge clk) begin
    if(rst)begin 
        gp_save_ok1 <= 1'b1;
        gp_save_ok2 <= 1'b1;
    end
    else begin
        gp_save_ok1 <= gp_save_ok;
        gp_save_ok2 <= gp_save_ok1;
    end
end
wire gp_save_ok_en = (~gp_save_ok2) && (gp_save_ok1);



//////////////////////////////////////////////////////
//���xb_save_ok�ź�������
reg xb_save_ok1;
reg xb_save_ok2;
always @(posedge clk) begin
    if(rst)begin 
        xb_save_ok1 <= 1'b1;
        xb_save_ok2 <= 1'b1;
    end
    else begin
        xb_save_ok1 <= xb_save_ok;
        xb_save_ok2 <= xb_save_ok1;
    end
end
wire xb_save_ok_en = (~xb_save_ok2) && (xb_save_ok1);


/////////////////////////////////////////////////////////
parameter  listenSt                  = 1,
           waitCtrlCode              = 2,
			  analysisCtrlCode          = 3,
			  waitComDone               = 4,
			  setGpFlag                 = 5,
			  setXbFlag                 = 6;

reg [3:0] ct;      
always@(posedge clk)begin
 if(rst)begin
	   ct <= listenSt;
		para_setting_flag <= 1'b0;
		para_enquire_flag <= 1'b0;
		para_setting_all_flag <= 1'b0;
		para_enquire_all_flag <= 1'b0;
		gps_rms_enquire_flag <= 1'b0;
		wave_data_enquire_flag <= 1'b0;
		gp_fault_flag <= 1'b0;
		xb_fault_flag <= 1'b0;
		ctrl_code <= 0;
		sram_io_dir_ctrl <= 1'b0;
 end
 else begin
	 case(ct)
		listenSt:begin
		   ctrl_code <= 0;
			sram_io_dir_ctrl <= 1'b0;
			if(rx_ok_rise && rx_data == `FPGA_PACK_CMD_TYPE_START_CODE)
				ct <= waitCtrlCode;//������ʼ��0x68 ,���������״̬
			else if(gp_save_ok_en)
				ct <= setGpFlag;
			else if(xb_save_ok_en) 
				ct <= setXbFlag;
		end
		waitCtrlCode:begin  //�ȴ�������״̬
			if(rx_ok_rise)
				ct <= analysisCtrlCode;
			else 
				ct <= waitCtrlCode;
		end
		analysisCtrlCode:begin//����������
			case(rx_data)
				//�������ÿ�����
				`FPGA_PACK_CMD_TYPE_SETTING_TRAVELLING_WAVE_COLLECT_FREQUENCY ,
				`FPGA_PACK_CMD_TYPE_SETTING_TRAVELLING_WAVE_COLLECT_DURATION  ,
				`FPGA_PACK_CMD_TYPE_SETTING_TRAVELLING_WAVE_ALARM_THRESHOLD   ,
				`FPGA_PACK_CMD_TYPE_SETTING_POWER_FREQUENCY_COLLECT_FREQUENCY ,
				`FPGA_PACK_CMD_TYPE_SETTING_POWER_FREQUENCY_COLLECT_DURATION  ,
				`FPGA_PACK_CMD_TYPE_SETTING_POWER_FREQUENCY_ALARM_THRESHOLD   
				:begin
					para_setting_flag <= 1'b1;//��λ�������ñ�־
					ctrl_code <= rx_data; //�����ǰ������
					ct <= waitComDone;
				end
				//������ѯ������
				`FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_COLLECT_FREQUENCY ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_COLLECT_DURATION  ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_ALARM_THRESHOLD   ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_COLLECT_FREQUENCY ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_COLLECT_DURATION  ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_ALARM_THRESHOLD   
				:begin
					para_enquire_flag <= 1'b1;//��λ������ѯ��־
					ctrl_code <= rx_data; //�����ǰ������
					ct <= waitComDone;
				end
				//������GPS���ݲ�ѯ
				`FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE               ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_GPS_INFO                          
				:begin
					gps_rms_enquire_flag <= 1'b1;//��λ��־
					ctrl_code <= rx_data; //�����ǰ������
					ct <= waitComDone;
				end
				//��ѯ��������
				`FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_DATA               ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_DATA               
				:begin
					wave_data_enquire_flag <= 1'b1;//��λ��־
					ctrl_code <= rx_data; //�����ǰ������
					ct <= waitComDone;
				end
				//��������
				`FPGA_PACK_CMD_TYPE_FPGA_SETTING_PARA:begin
					para_setting_all_flag <= 1'b1;//��λ��־
					ctrl_code <= rx_data; //�����ǰ������
					ct <= waitComDone;
				end
				//������ѯ
				`FPGA_PACK_CMD_TYPE_FPGA_ENQUIRE_PARA :begin
					para_enquire_all_flag <= 1'b1;//��λ��־
					ctrl_code <= rx_data; //�����ǰ������
					ct <= waitComDone;
				end
				
				default:begin
					ct <= listenSt;
					para_setting_flag <= 1'b0;
					para_enquire_flag <= 1'b0;
					para_setting_all_flag <= 1'b0;
					para_enquire_all_flag <= 1'b0;
					gps_rms_enquire_flag <= 1'b0;
					wave_data_enquire_flag <= 1'b0;
					gp_fault_flag <= 1'b0;
					xb_fault_flag <= 1'b0;
				end
			endcase
		end
		setGpFlag:begin
			gp_fault_flag <= 1'b1;
			ct <= waitComDone;
		end
		setXbFlag:begin
			xb_fault_flag <= 1'b1;
			sram_io_dir_ctrl <= 1'b1;
			ct <= waitComDone;
		end
		waitComDone:begin
		   //��λ��־
			para_setting_flag <= 1'b0;
			para_enquire_flag <= 1'b0;
			para_setting_all_flag <= 1'b0;
			para_enquire_all_flag <= 1'b0;
			gps_rms_enquire_flag <= 1'b0;
			wave_data_enquire_flag <= 1'b0;
			gp_fault_flag <= 1'b0;
			xb_fault_flag <= 1'b0;
			if(com_done_ok)ct <= listenSt; //�ȴ�����ģ�鴦�����
			else ct <= waitComDone;
		end
		default:begin
			 ct <= listenSt;
		end
	  endcase
  end
end
   


endmodule
