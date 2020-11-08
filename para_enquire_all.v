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
	 input para_enquire_flag, //参数设置标志
	 input [7:0]ctrl_code, //控制字
//	 input [7:0]rx_data,  //串口接收数据
//	 input rx_ok,  //接收数据有效标志

	 input [31:0]travelling_wave_collect_freq,//行波采样率输入
	 input [15:0]travelling_wave_collect_duration,//行波采样时间输入
	 input [15:0]travelling_wave_alarm_threshold,//行波电流阈值输入
	 
	 input [31:0]power_frequency_collect_freq,//工频采样率输入
	 input [15:0]power_frequency_collect_duration,//工频采样时间输入
	 input [15:0]power_frequency_alarm_threshold,//工频电流阈值输入
	 
	 output enquire_para_done,  //参数设置完成标志
	 output module_run_flag,//标志该模块运行，用于串口上传数据选择
	 
	 input tx_idle, //监测下降沿，数据发送完成标志
	 output [7:0]tx_data, //串口发送数据
	 output start_tx  //串口发送使能，上升沿
    );

`include "com_with_mcu_para.v"	
////监测rx_ok信号上升沿
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
			waitEnquireFlag:begin  //等待查询标志到来
				if(para_enquire_flag) begin
					ct <= waitEnquireOk;
					start_enquire_en <= 1'b1;//数据回复使能标志,在监测到查询标志1时，置位该标志 			
				end
				else 
					ct <= waitEnquireFlag;
			end 
			waitEnquireOk:begin   //等待数据上传完成
				ctrl_code_reg <= ctrl_code;	
				start_enquire_en <= 1'b0;
				if(enquire_reply_ok)  //数据上传完成标志
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
						power_frequency_alarm_threshold[7:0]  + power_frequency_alarm_threshold[15:8]); //计算校验位

////////////////////////////////////////////////////////
//回复参数查询标志
reg start_enquire_en;  //数据回复使能标志,在监测到查询标志1时，置位该标志  
//回复数据计数器使能
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

//回复数据计数器
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
			5'd0:tx_data_r <= `FPGA_PACK_CMD_TYPE_START_CODE; //起始码
			5'd1:tx_data_r <= ctrl_code_reg;                  //控制字
			5'd2:tx_data_r <= 8'd24;                          //数据长度低位
			5'd3:tx_data_r <= 8'h0;								     //数据长度高位
			
			//行波采样率
			5'd4:tx_data_r <= travelling_wave_collect_freq[7:0];         
			5'd5:tx_data_r <= travelling_wave_collect_freq[15:8];   
			5'd6:tx_data_r <= travelling_wave_collect_freq[23:16];   
			5'd7:tx_data_r <= travelling_wave_collect_freq[31:24]; 
			
			//行波采样时间
			5'd8:tx_data_r <= travelling_wave_collect_duration[7:0];         
			5'd9:tx_data_r <= travelling_wave_collect_duration[15:8];   
			5'd10:tx_data_r <= 8'h0;   
			5'd11:tx_data_r <= 8'h0;
			
			//行波触发阈值
			5'd12:tx_data_r <= travelling_wave_alarm_threshold[7:0];         
			5'd13:tx_data_r <= travelling_wave_alarm_threshold[15:8];   
			5'd14:tx_data_r <= 8'h0;   
			5'd15:tx_data_r <= 8'h0;
			
			//工频采样率
			5'd16:tx_data_r <= power_frequency_collect_freq[7:0];         
			5'd17:tx_data_r <= power_frequency_collect_freq[15:8];   
			5'd18:tx_data_r <= power_frequency_collect_freq[23:16];   
			5'd19:tx_data_r <= power_frequency_collect_freq[31:24];  

			//工频采样时间
			5'd20:tx_data_r <= power_frequency_collect_duration[7:0];         
			5'd21:tx_data_r <= power_frequency_collect_duration[15:8];   
			5'd22:tx_data_r <= 8'h0;   
			5'd23:tx_data_r <= 8'h0;
			
			//工频触发阈值
			5'd24:tx_data_r <= power_frequency_alarm_threshold[7:0];         
			5'd25:tx_data_r <= power_frequency_alarm_threshold[15:8];   
			5'd26:tx_data_r <= 8'h0;   
			5'd27:tx_data_r <= 8'h0;							     
			
			5'd28:tx_data_r <= crc;                            //校验位 
			5'd29:tx_data_r <= `FPGA_PACK_CMD_TYPE_END_CODE;   //结束码
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
assign enquire_para_done =  (enquire_reply_cnt >= 30); //参数设置完成标志
assign module_run_flag = enquire_reply_cnt_en;//标志该模块运行，用于串口上传数据选择


endmodule
