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
    input rx_ok, //串口接收数据有效标志，监测上升沿
    input gp_save_ok, //工频数据保存完成标志
    input xb_save_ok, //行波数据保存完成标志
    input [7:0] rx_data, //串口接收数据输入
	 input com_done_ok,//本次和mcu通信完成标志，由下游模块给出，1-本模块回到初始状态
	 output reg sram_io_dir_ctrl,//SRAMIO口输入输出方向控制标志
	 
	 output reg [7:0] ctrl_code,  //输出控制字，给后续解析单元
	 output reg para_setting_flag, //参数设置标志，1-表示参数设置
	 output reg para_enquire_flag, //参数查询标志，1-表示参数查询
	 
	 output reg para_setting_all_flag, //参数整体设置标志，1-表示参数设置
	 output reg para_enquire_all_flag, //参数整体查询标志，1-表示参数查询
	 
	 output reg gps_rms_enquire_flag, //数据查询标志，GPS和工况查询，1-有效
	 
	 output reg wave_data_enquire_flag, //行波数据查询标志
	 
	 output reg xb_fault_flag,     //行波数据上传标志
	 output reg gp_fault_flag      //工频数据上传标志
    );

`include "com_with_mcu_para.v"	
//////////////////////////////////////////////////////
//监测rx_ok信号上升沿
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
//监测gp_save_ok信号上升沿
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
//监测xb_save_ok信号上升沿
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
				ct <= waitCtrlCode;//串口起始码0x68 ,进入控制器状态
			else if(gp_save_ok_en)
				ct <= setGpFlag;
			else if(xb_save_ok_en) 
				ct <= setXbFlag;
		end
		waitCtrlCode:begin  //等待控制字状态
			if(rx_ok_rise)
				ct <= analysisCtrlCode;
			else 
				ct <= waitCtrlCode;
		end
		analysisCtrlCode:begin//解析控制字
			case(rx_data)
				//参数设置控制字
				`FPGA_PACK_CMD_TYPE_SETTING_TRAVELLING_WAVE_COLLECT_FREQUENCY ,
				`FPGA_PACK_CMD_TYPE_SETTING_TRAVELLING_WAVE_COLLECT_DURATION  ,
				`FPGA_PACK_CMD_TYPE_SETTING_TRAVELLING_WAVE_ALARM_THRESHOLD   ,
				`FPGA_PACK_CMD_TYPE_SETTING_POWER_FREQUENCY_COLLECT_FREQUENCY ,
				`FPGA_PACK_CMD_TYPE_SETTING_POWER_FREQUENCY_COLLECT_DURATION  ,
				`FPGA_PACK_CMD_TYPE_SETTING_POWER_FREQUENCY_ALARM_THRESHOLD   
				:begin
					para_setting_flag <= 1'b1;//置位参数设置标志
					ctrl_code <= rx_data; //输出当前控制字
					ct <= waitComDone;
				end
				//参数查询控制字
				`FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_COLLECT_FREQUENCY ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_COLLECT_DURATION  ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_ALARM_THRESHOLD   ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_COLLECT_FREQUENCY ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_COLLECT_DURATION  ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_ALARM_THRESHOLD   
				:begin
					para_enquire_flag <= 1'b1;//置位参数查询标志
					ctrl_code <= rx_data; //输出当前控制字
					ct <= waitComDone;
				end
				//工况和GPS数据查询
				`FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE               ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_GPS_INFO                          
				:begin
					gps_rms_enquire_flag <= 1'b1;//置位标志
					ctrl_code <= rx_data; //输出当前控制字
					ct <= waitComDone;
				end
				//查询波形数据
				`FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_DATA               ,
				`FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_DATA               
				:begin
					wave_data_enquire_flag <= 1'b1;//置位标志
					ctrl_code <= rx_data; //输出当前控制字
					ct <= waitComDone;
				end
				//参数设置
				`FPGA_PACK_CMD_TYPE_FPGA_SETTING_PARA:begin
					para_setting_all_flag <= 1'b1;//置位标志
					ctrl_code <= rx_data; //输出当前控制字
					ct <= waitComDone;
				end
				//参数查询
				`FPGA_PACK_CMD_TYPE_FPGA_ENQUIRE_PARA :begin
					para_enquire_all_flag <= 1'b1;//置位标志
					ctrl_code <= rx_data; //输出当前控制字
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
		   //复位标志
			para_setting_flag <= 1'b0;
			para_enquire_flag <= 1'b0;
			para_setting_all_flag <= 1'b0;
			para_enquire_all_flag <= 1'b0;
			gps_rms_enquire_flag <= 1'b0;
			wave_data_enquire_flag <= 1'b0;
			gp_fault_flag <= 1'b0;
			xb_fault_flag <= 1'b0;
			if(com_done_ok)ct <= listenSt; //等待下游模块处理完成
			else ct <= waitComDone;
		end
		default:begin
			 ct <= listenSt;
		end
	  endcase
  end
end
   


endmodule
