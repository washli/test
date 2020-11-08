`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:50:33 03/11/2019 
// Design Name: 
// Module Name:    com_with_mcu_top 
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
module com_with_mcu_top#(
parameter  BRAM_ADDR_WIDTH     = 11, //BRAM��ַ���
parameter  BRAM_DATA_WIDTH     = 16, //BRAM���ݿ��
parameter  SRAM_ADDR_WIDTH     = 17, //SRAM��ַ���
parameter  SRAM_DATA_WIDTH     = 16) //SRAM���ݿ��
	(
		input clk,  //100M
		input rst, 

		input gp_save_ok, //��Ƶ���ݱ�����ɱ�־
		input xb_save_ok, //�в����ݱ�����ɱ�־

		input [31:0]travelling_wave_collect_freq_in,//�в�����������
		input [15:0]travelling_wave_collect_duration_in,//�в�����ʱ������
		input [15:0]travelling_wave_alarm_threshold_in,//�в�������ֵ����

		input [31:0]power_frequency_collect_freq_in,//��Ƶ����������
		input [15:0]power_frequency_collect_duration_in,//��Ƶ����ʱ������
		input [15:0]power_frequency_alarm_threshold_in,//��Ƶ������ֵ����


		//output [31:0]para, //�����������
		output [31:0]travelling_wave_collect_freq,//�в����������
		output [15:0]travelling_wave_collect_duration,//�в�����ʱ�����
		output [15:0]travelling_wave_alarm_threshold,//�в�������ֵ���

		output [31:0]power_frequency_collect_freq,//��Ƶ���������
		output [15:0]power_frequency_collect_duration,//��Ƶ����ʱ�����
		output [15:0]power_frequency_alarm_threshold,//��Ƶ������ֵ���

		output travelling_wave_collect_freq_cs,//�в�����������ѡ��
		output travelling_wave_collect_duration_cs,//�в�����ʱ������ѡ��
		output travelling_wave_alarm_threshold_cs,//�в�������ֵ����ѡ��

		output power_frequency_collect_freq_cs,//��Ƶ����������ѡ��
		output power_frequency_collect_duration_cs,//��Ƶ����ʱ������ѡ��
		output power_frequency_alarm_threshold_cs,//��Ƶ������ֵ����ѡ��

		input getMegOk, //1-���������Ч������⵽�¸�GPRMCʱ����

		input [7:0]hour,//Сʱ
		input [7:0]min,//����
		input [7:0]sec,//����

		input [7:0]latDu,//γ�� ��
		input [7:0]latMin,//γ�� ��

		input [7:0]longDu,//���� ��
		input [7:0]longMin,//���� ��

		input [7:0]day,//��
		input [7:0]mon,//��
		input [7:0]year,//��

		input [15:0]rms, //��Чֵ
		input rms_ok,    //��Чֵ��Ч��־
	 
		input [BRAM_DATA_WIDTH - 1:0]gp_ram_data,//BRAM��Ƶ��������
		output [BRAM_ADDR_WIDTH - 1:0]gp_ram_rd_addr,//BRAM��Ƶ����ַ���
		output gp_ram_rd_en,//BRAM ��Ƶ��ʹ�����

		input [SRAM_DATA_WIDTH - 1:0]xb_ram_data,//SRAM�в���������
		output [SRAM_ADDR_WIDTH - 1:0]sram_addr,
		output sram_cs1_n,
		output sram_cs2,
		output sram_oe_n,
		output sram_we_n,
		output sram_ub_n,
		output sram_lb_n,
		output sram_io_dir_ctrl,//SRAMIO���������������Ʊ�־

		output send_xb_data_done, //�����ϴ���ɱ�־
	   output send_gp_data_done, //�����ϴ���ɱ�־
		// output [7:0]tx_fifo_data,
		// output tx_fifo_wr,
		// input tx_fifo_full,

		output xb_auto_trigger_flag,//�в��Զ�������־
		output gp_auto_trigger_flag,//��Ƶ�Զ�������־
		
		input rs232_rx,
		output rs232_tx
	 
	 
	 
    );

//assign sram_io_dir_ctrl = wave_upload_module_run_flag;
wire rx_ok;
wire [7:0] rx_data;
wire [7:0] tx_data = enquire_para_module_run_flag    ? enquire_para_tx_data       :
							para_setting_module_run_flag    ? para_setting_tx_data       :
							gps_rms_enquire_module_run_flag ? gps_rms_enquire_tx_data    :
							wave_upload_module_run_flag     ? wave_upload_tx_data        : 8'h0;
wire start_tx      = enquire_para_module_run_flag    ? enquire_para_start_tx      :
							para_setting_module_run_flag    ? para_setting_start_tx      :
							gps_rms_enquire_module_run_flag ? gps_rms_enquire_start_tx   :
							wave_upload_module_run_flag     ? wave_upload_start_tx       : 1'b0;
wire tx_idle;
uart232_with_mcu uart_muc_module(
   .clk(clk),  //100M
   .rst(rst),  
	.rs232_rx(rs232_rx),   // RS232���������ź�
	.rs232_tx(rs232_tx),  // RS232���������ź�
	
	.tx_data(tx_data),  //�������ݼĴ���
	.start_tx(start_tx), //�����ؿ�ʼ��������tx_data
		
	.rx_data(rx_data), //�������ݼĴ���������ֱ����һ����������
	.rx_ok(rx_ok),//������8bit���ݺ����һ��ʱ�����ڵĸߵ�ƽ�źţ���������ģ�����������
	.busy(),//�ߵ�ƽ��ʾģ���ڷ��ͻ��߽�������
	.tx_idle(tx_idle)
    );

wire [7:0] ctrl_code;  //��������֣�������������Ԫ
//wire para_setting_flag; //�������ñ�־��1-��ʾ��������
//wire para_enquire_flag; //������ѯ��־��1-��ʾ������ѯ

wire para_setting_all_flag; //�����������ñ�־��1-��ʾ��������
wire para_enquire_all_flag; //���������ѯ��־��1-��ʾ������ѯ

wire gps_rms_enquire_flag; //���ݲ�ѯ��־��GPS�͹�����ѯ��1-��Ч

wire wave_data_enquire_flag; //�в����ݲ�ѯ��־

wire xb_fault_flag;     //�в������ϴ���־
wire gp_fault_flag;      //��Ƶ�����ϴ���־

wire com_done_ok = enquire_para_done || para_setting_done || gps_rms_enquire_done || wave_upload_done;
listen listen_module(
    .clk(clk),  //100M
    .rst(rst),  
    .rx_ok(rx_ok), //���ڽ���������Ч��־�����������
    .gp_save_ok(gp_save_ok), //��Ƶ���ݱ�����ɱ�־
    .xb_save_ok(xb_save_ok), //�в����ݱ�����ɱ�־
    .rx_data(rx_data), //���ڽ�����������
	 .com_done_ok(com_done_ok),//���κ�mcuͨ����ɱ�־��������ģ�������1-��ģ��ص���ʼ״̬
	 
	 .sram_io_dir_ctrl(sram_io_dir_ctrl),
	 .ctrl_code(ctrl_code),  //��������֣�������������Ԫ
	 .para_setting_flag(), //�������ñ�־��1-��ʾ��������
	 .para_enquire_flag(), //������ѯ��־��1-��ʾ������ѯ
	 
	 .para_setting_all_flag(para_setting_all_flag), //�����������ñ�־��1-��ʾ��������
	 .para_enquire_all_flag(para_enquire_all_flag), //���������ѯ��־��1-��ʾ������ѯ
	 
	 .gps_rms_enquire_flag(gps_rms_enquire_flag), //���ݲ�ѯ��־��GPS�͹�����ѯ��1-��Ч
	 
	 .wave_data_enquire_flag(wave_data_enquire_flag), //�в����ݲ�ѯ��־
	 
	 .xb_fault_flag(xb_fault_flag),     //�в������ϴ���־
	 .gp_fault_flag(gp_fault_flag)      //��Ƶ�����ϴ���־
    );

wire enquire_para_done;
wire enquire_para_module_run_flag;
wire [7:0]enquire_para_tx_data; //���ڷ�������
wire enquire_para_start_tx;  //���ڷ���ʹ�ܣ�������
para_enquire_all para_enquire_all_module(
	 .clk(clk),  //100M
    .rst(rst),  
	 .para_enquire_flag(para_enquire_all_flag), //�������ñ�־
	 .ctrl_code(ctrl_code), //������

	 .travelling_wave_collect_freq(travelling_wave_collect_freq_in),//�в�����������
	 .travelling_wave_collect_duration(travelling_wave_collect_duration_in),//�в�����ʱ������
	 .travelling_wave_alarm_threshold(travelling_wave_alarm_threshold_in),//�в�������ֵ����
	 
	 .power_frequency_collect_freq(power_frequency_collect_freq_in),//��Ƶ����������
	 .power_frequency_collect_duration(power_frequency_collect_duration_in),//��Ƶ����ʱ������
	 .power_frequency_alarm_threshold(power_frequency_alarm_threshold_in),//��Ƶ������ֵ����
	 
	 .enquire_para_done(enquire_para_done),  //����������ɱ�־
	 .module_run_flag(enquire_para_module_run_flag),//��־��ģ�����У����ڴ����ϴ�����ѡ��
	 
    .tx_idle(tx_idle), //����½��أ����ݷ�����ɱ�־
	 .tx_data(enquire_para_tx_data), //���ڷ�������
	 .start_tx(enquire_para_start_tx)  //���ڷ���ʹ�ܣ�������
    );


wire para_setting_done;
wire para_setting_module_run_flag;
wire [7:0]para_setting_tx_data; //���ڷ�������
wire para_setting_start_tx;  //���ڷ���ʹ�ܣ�������	 
para_setting_all para_setting_all_module(
	.clk(clk),  //100M
   .rst(rst),  
	.para_setting_flag(para_setting_all_flag), //�������ñ�־
	.ctrl_code(ctrl_code), //������
	.rx_data(rx_data), //�������ݼĴ���������ֱ����һ����������
	.rx_ok(rx_ok),//������8bit���ݺ����һ��ʱ�����ڵĸߵ�ƽ�źţ���������ģ�����������

	//output [31:0]para, //�����������
	.travelling_wave_collect_freq(travelling_wave_collect_freq),//�в����������
	.travelling_wave_collect_duration(travelling_wave_collect_duration),//�в�����ʱ�����
	.travelling_wave_alarm_threshold(travelling_wave_alarm_threshold),//�в�������ֵ���

	.power_frequency_collect_freq(power_frequency_collect_freq),//��Ƶ���������
	.power_frequency_collect_duration(power_frequency_collect_duration),//��Ƶ����ʱ�����
	.power_frequency_alarm_threshold(power_frequency_alarm_threshold),//��Ƶ������ֵ���

	.travelling_wave_collect_freq_cs(travelling_wave_collect_freq_cs),//�в�����������ѡ��
	.travelling_wave_collect_duration_cs(travelling_wave_collect_duration_cs),//�в�����ʱ������ѡ��
	.travelling_wave_alarm_threshold_cs(travelling_wave_alarm_threshold_cs),//�в�������ֵ����ѡ��

	.power_frequency_collect_freq_cs(power_frequency_collect_freq_cs),//��Ƶ����������ѡ��
	.power_frequency_collect_duration_cs(power_frequency_collect_duration_cs),//��Ƶ����ʱ������ѡ��
	.power_frequency_alarm_threshold_cs(power_frequency_alarm_threshold_cs),//��Ƶ������ֵ����ѡ��

	.set_para_done(para_setting_done),  //����������ɱ�־
	.module_run_flag(para_setting_module_run_flag),//��־��ģ�����У����ڴ����ϴ�����ѡ��

	.tx_idle(tx_idle), //����½��أ����ݷ�����ɱ�־
	.tx_data(para_setting_tx_data), //���ڷ�������
	.start_tx(para_setting_start_tx)  //���ڷ���ʹ�ܣ�������
	);


wire gps_rms_enquire_done;
wire gps_rms_enquire_module_run_flag;
wire [7:0]gps_rms_enquire_tx_data; //���ڷ�������
wire gps_rms_enquire_start_tx;  //���ڷ���ʹ�ܣ�������	 
gps_rms_enquire gps_rms_enquire_module(
    .clk(clk),  //100M
    .rst(rst),  
	 .para_enquire_flag(gps_rms_enquire_flag), //�������ñ�־
	 .ctrl_code(ctrl_code), //������
//	 input [7:0]rx_data,  //���ڽ�������
//	 input rx_ok,  //����������Ч��־

	 .getMegOk(getMegOk),
	 .hour(hour), 
	 .min(min), 
	 .sec(sec), 
	 .latDu(latDu), 
	 .latMin(latMin), 
	 .longDu(longDu), 
	 .longMin(longMin), 
	 .day(day), 
	 .mon(mon), 
	 .year(year),
	 
	 .rms(rms), //��Чֵ
	 .rms_ok(rms_ok),    //��Чֵ��Ч��־
	 
	 .gps_rms_enquire_done(gps_rms_enquire_done),  //��ɱ�־
	 .module_run_flag(gps_rms_enquire_module_run_flag),//��־��ģ�����У����ڴ����ϴ�����ѡ��
	 
	 .tx_idle(tx_idle), //����½��أ����ݷ�����ɱ�־
	 .tx_data(gps_rms_enquire_tx_data), //���ڷ�������
	 .start_tx(gps_rms_enquire_start_tx)  //���ڷ���ʹ�ܣ�������
    );

wire wave_upload_done;
wire wave_upload_module_run_flag;
wire [7:0]wave_upload_tx_data; //���ڷ�������
wire wave_upload_start_tx;  //���ڷ���ʹ�ܣ�������	 
wave_upload_ctrl wave_upload_ctrl_module(
    .clk(clk),  //100M
    .rst(rst),  
	 .wave_data_enquire_flag(wave_data_enquire_flag), //�����ϴ����ݱ�־ʹ��
	 .ctrl_code(ctrl_code), //������
	 .rx_data(rx_data), //�������ݼĴ���������ֱ����һ����������
	 .rx_ok(rx_ok),//������8bit���ݺ����һ��ʱ�����ڵĸߵ�ƽ�źţ���������ģ�����������

	 .xb_fault_flag(xb_fault_flag),     //�в������ϴ���־
	 .gp_fault_flag(gp_fault_flag),      //��Ƶ�����ϴ���־
	 
	 .gp_ram_data(gp_ram_data), 
	 .gp_ram_rd_addr(gp_ram_rd_addr), 
	 .gp_ram_rd_en(gp_ram_rd_en), 
	 
	 .xb_ram_data(xb_ram_data), 
	 .sram_addr(sram_addr), 
	 .sram_cs1_n(sram_cs1_n), 
	 .sram_cs2(sram_cs2), 
	 .sram_oe_n(sram_oe_n), 
	 .sram_we_n(sram_we_n), 
	 .sram_ub_n(sram_ub_n), 
	 .sram_lb_n(sram_lb_n), 
	 
	 // output [7:0]tx_fifo_data,
	 // output tx_fifo_wr,
	 // input tx_fifo_full,
	  
	 .xb_auto_trigger_flag(xb_auto_trigger_flag),//�в��Զ�������־
	 .gp_auto_trigger_flag(gp_auto_trigger_flag),//��Ƶ�Զ�������־
	 .send_xb_data_done(send_xb_data_done), //�����ϴ���ɱ�־
	 .send_gp_data_done(send_gp_data_done), //�����ϴ���ɱ�־
	  
	 .wave_data_enquire_done(wave_upload_done),  //��ɱ�־
	 .module_run_flag(wave_upload_module_run_flag), //��־��ģ�����У����ڴ����ϴ�����ѡ��
	 
	 .tx_idle(tx_idle), //����½��أ����ݷ�����ɱ�־
	 .tx_data(wave_upload_tx_data), //���ڷ�������
	 .start_tx(wave_upload_start_tx)  //���ڷ���ʹ�ܣ�������
    );

endmodule
