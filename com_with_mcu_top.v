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
parameter  BRAM_ADDR_WIDTH     = 11, //BRAM地址宽度
parameter  BRAM_DATA_WIDTH     = 16, //BRAM数据宽度
parameter  SRAM_ADDR_WIDTH     = 17, //SRAM地址宽度
parameter  SRAM_DATA_WIDTH     = 16) //SRAM数据宽度
	(
		input clk,  //100M
		input rst, 

		input gp_save_ok, //工频数据保存完成标志
		input xb_save_ok, //行波数据保存完成标志

		input [31:0]travelling_wave_collect_freq_in,//行波采样率输入
		input [15:0]travelling_wave_collect_duration_in,//行波采样时间输入
		input [15:0]travelling_wave_alarm_threshold_in,//行波电流阈值输入

		input [31:0]power_frequency_collect_freq_in,//工频采样率输入
		input [15:0]power_frequency_collect_duration_in,//工频采样时间输入
		input [15:0]power_frequency_alarm_threshold_in,//工频电流阈值输入


		//output [31:0]para, //参数数据输出
		output [31:0]travelling_wave_collect_freq,//行波采样率输出
		output [15:0]travelling_wave_collect_duration,//行波采样时间输出
		output [15:0]travelling_wave_alarm_threshold,//行波电流阈值输出

		output [31:0]power_frequency_collect_freq,//工频采样率输出
		output [15:0]power_frequency_collect_duration,//工频采样时间输出
		output [15:0]power_frequency_alarm_threshold,//工频电流阈值输出

		output travelling_wave_collect_freq_cs,//行波采样率设置选择
		output travelling_wave_collect_duration_cs,//行波采样时间设置选择
		output travelling_wave_alarm_threshold_cs,//行波电流阈值设置选择

		output power_frequency_collect_freq_cs,//工频采样率设置选择
		output power_frequency_collect_duration_cs,//工频采样时间设置选择
		output power_frequency_alarm_threshold_cs,//工频电流阈值设置选择

		input getMegOk, //1-数据输出有效，当检测到下个GPRMC时清零

		input [7:0]hour,//小时
		input [7:0]min,//分钟
		input [7:0]sec,//秒钟

		input [7:0]latDu,//纬度 度
		input [7:0]latMin,//纬度 分

		input [7:0]longDu,//经度 度
		input [7:0]longMin,//经度 分

		input [7:0]day,//日
		input [7:0]mon,//月
		input [7:0]year,//年

		input [15:0]rms, //有效值
		input rms_ok,    //有效值有效标志
	 
		input [BRAM_DATA_WIDTH - 1:0]gp_ram_data,//BRAM工频数据输入
		output [BRAM_ADDR_WIDTH - 1:0]gp_ram_rd_addr,//BRAM工频读地址输出
		output gp_ram_rd_en,//BRAM 工频读使能输出

		input [SRAM_DATA_WIDTH - 1:0]xb_ram_data,//SRAM行波数据输入
		output [SRAM_ADDR_WIDTH - 1:0]sram_addr,
		output sram_cs1_n,
		output sram_cs2,
		output sram_oe_n,
		output sram_we_n,
		output sram_ub_n,
		output sram_lb_n,
		output sram_io_dir_ctrl,//SRAMIO口输入输出方向控制标志

		output send_xb_data_done, //数据上传完成标志
	   output send_gp_data_done, //数据上传完成标志
		// output [7:0]tx_fifo_data,
		// output tx_fifo_wr,
		// input tx_fifo_full,

		output xb_auto_trigger_flag,//行波自动触发标志
		output gp_auto_trigger_flag,//工频自动触发标志
		
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
	.rs232_rx(rs232_rx),   // RS232接收数据信号
	.rs232_tx(rs232_tx),  // RS232发送数据信号
	
	.tx_data(tx_data),  //发送数据寄存器
	.start_tx(start_tx), //上升沿开始发送数据tx_data
		
	.rx_data(rx_data), //接收数据寄存器，保存直至下一个数据来到
	.rx_ok(rx_ok),//接受完8bit数据后产生一个时钟周期的高电平信号，用于下游模块的数据锁存
	.busy(),//高电平表示模块在发送或者接受数据
	.tx_idle(tx_idle)
    );

wire [7:0] ctrl_code;  //输出控制字，给后续解析单元
//wire para_setting_flag; //参数设置标志，1-表示参数设置
//wire para_enquire_flag; //参数查询标志，1-表示参数查询

wire para_setting_all_flag; //参数整体设置标志，1-表示参数设置
wire para_enquire_all_flag; //参数整体查询标志，1-表示参数查询

wire gps_rms_enquire_flag; //数据查询标志，GPS和工况查询，1-有效

wire wave_data_enquire_flag; //行波数据查询标志

wire xb_fault_flag;     //行波数据上传标志
wire gp_fault_flag;      //工频数据上传标志

wire com_done_ok = enquire_para_done || para_setting_done || gps_rms_enquire_done || wave_upload_done;
listen listen_module(
    .clk(clk),  //100M
    .rst(rst),  
    .rx_ok(rx_ok), //串口接收数据有效标志，监测上升沿
    .gp_save_ok(gp_save_ok), //工频数据保存完成标志
    .xb_save_ok(xb_save_ok), //行波数据保存完成标志
    .rx_data(rx_data), //串口接收数据输入
	 .com_done_ok(com_done_ok),//本次和mcu通信完成标志，由下游模块给出，1-本模块回到初始状态
	 
	 .sram_io_dir_ctrl(sram_io_dir_ctrl),
	 .ctrl_code(ctrl_code),  //输出控制字，给后续解析单元
	 .para_setting_flag(), //参数设置标志，1-表示参数设置
	 .para_enquire_flag(), //参数查询标志，1-表示参数查询
	 
	 .para_setting_all_flag(para_setting_all_flag), //参数整体设置标志，1-表示参数设置
	 .para_enquire_all_flag(para_enquire_all_flag), //参数整体查询标志，1-表示参数查询
	 
	 .gps_rms_enquire_flag(gps_rms_enquire_flag), //数据查询标志，GPS和工况查询，1-有效
	 
	 .wave_data_enquire_flag(wave_data_enquire_flag), //行波数据查询标志
	 
	 .xb_fault_flag(xb_fault_flag),     //行波数据上传标志
	 .gp_fault_flag(gp_fault_flag)      //工频数据上传标志
    );

wire enquire_para_done;
wire enquire_para_module_run_flag;
wire [7:0]enquire_para_tx_data; //串口发送数据
wire enquire_para_start_tx;  //串口发送使能，上升沿
para_enquire_all para_enquire_all_module(
	 .clk(clk),  //100M
    .rst(rst),  
	 .para_enquire_flag(para_enquire_all_flag), //参数设置标志
	 .ctrl_code(ctrl_code), //控制字

	 .travelling_wave_collect_freq(travelling_wave_collect_freq_in),//行波采样率输入
	 .travelling_wave_collect_duration(travelling_wave_collect_duration_in),//行波采样时间输入
	 .travelling_wave_alarm_threshold(travelling_wave_alarm_threshold_in),//行波电流阈值输入
	 
	 .power_frequency_collect_freq(power_frequency_collect_freq_in),//工频采样率输入
	 .power_frequency_collect_duration(power_frequency_collect_duration_in),//工频采样时间输入
	 .power_frequency_alarm_threshold(power_frequency_alarm_threshold_in),//工频电流阈值输入
	 
	 .enquire_para_done(enquire_para_done),  //参数设置完成标志
	 .module_run_flag(enquire_para_module_run_flag),//标志该模块运行，用于串口上传数据选择
	 
    .tx_idle(tx_idle), //监测下降沿，数据发送完成标志
	 .tx_data(enquire_para_tx_data), //串口发送数据
	 .start_tx(enquire_para_start_tx)  //串口发送使能，上升沿
    );


wire para_setting_done;
wire para_setting_module_run_flag;
wire [7:0]para_setting_tx_data; //串口发送数据
wire para_setting_start_tx;  //串口发送使能，上升沿	 
para_setting_all para_setting_all_module(
	.clk(clk),  //100M
   .rst(rst),  
	.para_setting_flag(para_setting_all_flag), //参数设置标志
	.ctrl_code(ctrl_code), //控制字
	.rx_data(rx_data), //接收数据寄存器，保存直至下一个数据来到
	.rx_ok(rx_ok),//接受完8bit数据后产生一个时钟周期的高电平信号，用于下游模块的数据锁存

	//output [31:0]para, //参数数据输出
	.travelling_wave_collect_freq(travelling_wave_collect_freq),//行波采样率输出
	.travelling_wave_collect_duration(travelling_wave_collect_duration),//行波采样时间输出
	.travelling_wave_alarm_threshold(travelling_wave_alarm_threshold),//行波电流阈值输出

	.power_frequency_collect_freq(power_frequency_collect_freq),//工频采样率输出
	.power_frequency_collect_duration(power_frequency_collect_duration),//工频采样时间输出
	.power_frequency_alarm_threshold(power_frequency_alarm_threshold),//工频电流阈值输出

	.travelling_wave_collect_freq_cs(travelling_wave_collect_freq_cs),//行波采样率设置选择
	.travelling_wave_collect_duration_cs(travelling_wave_collect_duration_cs),//行波采样时间设置选择
	.travelling_wave_alarm_threshold_cs(travelling_wave_alarm_threshold_cs),//行波电流阈值设置选择

	.power_frequency_collect_freq_cs(power_frequency_collect_freq_cs),//工频采样率设置选择
	.power_frequency_collect_duration_cs(power_frequency_collect_duration_cs),//工频采样时间设置选择
	.power_frequency_alarm_threshold_cs(power_frequency_alarm_threshold_cs),//工频电流阈值设置选择

	.set_para_done(para_setting_done),  //参数设置完成标志
	.module_run_flag(para_setting_module_run_flag),//标志该模块运行，用于串口上传数据选择

	.tx_idle(tx_idle), //监测下降沿，数据发送完成标志
	.tx_data(para_setting_tx_data), //串口发送数据
	.start_tx(para_setting_start_tx)  //串口发送使能，上升沿
	);


wire gps_rms_enquire_done;
wire gps_rms_enquire_module_run_flag;
wire [7:0]gps_rms_enquire_tx_data; //串口发送数据
wire gps_rms_enquire_start_tx;  //串口发送使能，上升沿	 
gps_rms_enquire gps_rms_enquire_module(
    .clk(clk),  //100M
    .rst(rst),  
	 .para_enquire_flag(gps_rms_enquire_flag), //参数设置标志
	 .ctrl_code(ctrl_code), //控制字
//	 input [7:0]rx_data,  //串口接收数据
//	 input rx_ok,  //接收数据有效标志

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
	 
	 .rms(rms), //有效值
	 .rms_ok(rms_ok),    //有效值有效标志
	 
	 .gps_rms_enquire_done(gps_rms_enquire_done),  //完成标志
	 .module_run_flag(gps_rms_enquire_module_run_flag),//标志该模块运行，用于串口上传数据选择
	 
	 .tx_idle(tx_idle), //监测下降沿，数据发送完成标志
	 .tx_data(gps_rms_enquire_tx_data), //串口发送数据
	 .start_tx(gps_rms_enquire_start_tx)  //串口发送使能，上升沿
    );

wire wave_upload_done;
wire wave_upload_module_run_flag;
wire [7:0]wave_upload_tx_data; //串口发送数据
wire wave_upload_start_tx;  //串口发送使能，上升沿	 
wave_upload_ctrl wave_upload_ctrl_module(
    .clk(clk),  //100M
    .rst(rst),  
	 .wave_data_enquire_flag(wave_data_enquire_flag), //主动上传数据标志使能
	 .ctrl_code(ctrl_code), //控制字
	 .rx_data(rx_data), //接收数据寄存器，保存直至下一个数据来到
	 .rx_ok(rx_ok),//接受完8bit数据后产生一个时钟周期的高电平信号，用于下游模块的数据锁存

	 .xb_fault_flag(xb_fault_flag),     //行波数据上传标志
	 .gp_fault_flag(gp_fault_flag),      //工频数据上传标志
	 
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
	  
	 .xb_auto_trigger_flag(xb_auto_trigger_flag),//行波自动触发标志
	 .gp_auto_trigger_flag(gp_auto_trigger_flag),//工频自动触发标志
	 .send_xb_data_done(send_xb_data_done), //数据上传完成标志
	 .send_gp_data_done(send_gp_data_done), //数据上传完成标志
	  
	 .wave_data_enquire_done(wave_upload_done),  //完成标志
	 .module_run_flag(wave_upload_module_run_flag), //标志该模块运行，用于串口上传数据选择
	 
	 .tx_idle(tx_idle), //监测下降沿，数据发送完成标志
	 .tx_data(wave_upload_tx_data), //串口发送数据
	 .start_tx(wave_upload_start_tx)  //串口发送使能，上升沿
    );

endmodule
