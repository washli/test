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
	 input para_setting_flag, //参数设置标志
	 input [7:0]ctrl_code, //控制字
	 input [7:0]rx_data,  //串口接收数据
	 input rx_ok,  //接收数据有效标志

	 output [31:0]para, //参数数据输出
	 output travelling_wave_collect_freq_cs,//行波采样率设置选择
	 output travelling_wave_collect_duration_cs,//行波采样时间设置选择
	 output travelling_wave_alarm_threshold_cs,//行波电流阈值设置选择
	 
	 output power_frequency_collect_freq_cs,//工频采样率设置选择
	 output power_frequency_collect_duration_cs,//工频采样时间设置选择
	 output power_frequency_alarm_threshold_cs,//工频电流阈值设置选择
	 
	 output set_para_done,  //参数设置完成标志
	 output module_run_flag,//标志该模块运行，用于串口上传数据选择
	 
	 input tx_idle, //监测下降沿，数据发送完成标志
	 output [7:0]tx_data, //串口发送数据
	 output start_tx  //串口发送使能，上升沿
	 
	 
    );

`include "com_with_mcu_para.v"	

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

//监测tx_idle信号下降沿
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
//得到参数数据进程
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
	waitSetFlag:begin  //等待设置标志到来
		if(para_setting_flag) 
			nt = enRxCnt;
		else 
			nt = waitSetFlag;
	end 
	enRxCnt:begin   //启动接收数据计数器
		nt = getPara; 
	end
	getPara:begin    //保存设置参数数据
		if(rx_byte_cnt >= 4'd8)
			nt = setParaEn;
		else
			nt = getPara;
	end
	setParaEn:begin  //启动参数设置标志
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
			ctrl_code_reg <= ctrl_code; //保存控制字
			rx_byte_cnt_en <= 1'b1; //接收数据计数器使能
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
			set_para_en <= 1'b1; //启动参数设置使能标志
       end
		endcase
	end
end

//接收数据计数器
reg rx_byte_cnt_en;
reg [3:0]rx_byte_cnt;//定义接收到数据计数器
always@(posedge clk)begin
    if(rst)begin
		rx_byte_cnt <= 0;
    end
    else if(rx_ok_rise && rx_byte_cnt_en)
			rx_byte_cnt <= rx_byte_cnt + 1'b1;
	 else if(!rx_byte_cnt_en)
			rx_byte_cnt <= 0;
end

//缓存输入数据到data_in_reg
reg [7:0]data_in_reg;
always@(posedge clk)begin
    if(rst)begin
		data_in_reg <= 0;
    end
    else if(rx_ok_rise && rx_byte_cnt_en)
			data_in_reg <= rx_data;
end

///////////////////////////////////////////////////////////////////
//参数设置进程
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
	waitSetEn:begin  //等待设置参数使能
		if(set_para_en) 
			nt_set = setPara;
		else 
			nt_set = waitSetEn;
	end 
	setPara:begin   //启动接收数据计数器
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

//设置参数延时计数器
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

wire set_para_dly_cnt_en = (ct_set == setPara) && (set_para_dly_cnt <= 20);//启动参数设置延迟计数器是能标志,延时20个时钟周期

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
//回复参数设置成功标志
wire reply_en = (set_para_dly_cnt >= 20);//该标志置1，表示开始给mcu回复成功

//回复数据计数器使能
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

//回复数据计数器
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
wire [7:0]crc = ~(ctrl_code_reg + 8'h01 + 8'h0 + `FPGA_PACK_CMD_TYPE_OK); //计算校验位
always@(posedge clk)begin
    if(rst)begin
		tx_data_r <= 0;
    end
    else if(reply_data_cnt_en)begin
		case(reply_data_cnt)
			4'd0:tx_data_r <= `FPGA_PACK_CMD_TYPE_START_CODE; //起始码
			4'd1:tx_data_r <= ctrl_code_reg;                  //控制字
			4'd2:tx_data_r <= 8'h01;                          //数据长度低位
			4'd3:tx_data_r <= 8'h0;								     //数据长度高位
			4'd4:tx_data_r <= `FPGA_PACK_CMD_TYPE_OK;         //成功0xff
			4'd5:tx_data_r <= crc;                            //校验位 
			4'd6:tx_data_r <= `FPGA_PACK_CMD_TYPE_END_CODE;   //结束码
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
assign set_para_done =  (reply_data_cnt >= 7); //参数设置完成标志
assign module_run_flag = reply_data_cnt_en;//标志该模块运行，用于串口上传数据选择

endmodule
