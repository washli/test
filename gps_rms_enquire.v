`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:32:44 03/01/2019 
// Design Name: 
// Module Name:    gps_rms_enquire 
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
module gps_rms_enquire(
    input clk,
    input rst,
	 input para_enquire_flag, //参数设置标志
	 input [7:0]ctrl_code, //控制字
//	 input [7:0]rx_data,  //串口接收数据
//	 input rx_ok,  //接收数据有效标志

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
	 
	 output gps_rms_enquire_done,  //完成标志
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

//定义内部寄存器,用于保存需要上传的数据
reg [7:0]hour_reg;//小时
reg [7:0]min_reg;//分钟
reg [7:0]sec_reg;//秒钟

reg [7:0]latDu_reg;//纬度 度
reg [7:0]latMin_reg;//纬度 分

reg [7:0]longDu_reg;//经度 度
reg [7:0]longMin_reg;//经度 分

reg [7:0]day_reg;//日
reg [7:0]mon_reg;//月
reg [7:0]year_reg;//年

reg [15:0]rms_reg;//有效值


////////////////////////////////////////////////////////
parameter  waitEnquireFlag            = 1,
			  getCtrlCode                = 2,
			  analysisCtrlCode           = 3,
           getRms                     = 4,
			  getGpsInfo                 = 5,
			  waitSendOk                 = 6;
			  

reg [3:0] ct;  
reg [7:0]ctrl_code_reg;
reg send_data_en;//启动发送使能标志
always@(posedge clk)begin
    if(rst)begin
		ct            <= waitEnquireFlag;
		ctrl_code_reg <= 8'h0;
		rms_reg       <= 16'h0;
		hour_reg      <= 8'h0;//小时
		min_reg       <= 8'h0;//分钟
		sec_reg       <= 8'h0;//秒钟
		latDu_reg     <= 8'h0;//纬度 度
		latMin_reg    <= 8'h0;//纬度 分
		longDu_reg    <= 8'h0;//经度 度
		longMin_reg   <= 8'h0;//经度 分
		day_reg       <= 8'h0;//日
		mon_reg       <= 8'h0;//月
		year_reg      <= 8'h0;//年
		send_data_en  <= 1'b0;
    end
    else begin
       case(ct)
			waitEnquireFlag:begin  //等待查询标志到来
				send_data_en  <= 1'b0;
				if(para_enquire_flag) begin
					ctrl_code_reg <= ctrl_code;
					ct <= analysisCtrlCode;
				end
				else 
					ct <= waitEnquireFlag;
			end 
			analysisCtrlCode:begin
				if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE)
					ct <= getRms;
				else if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_GPS_INFO)
					ct <= getGpsInfo;
				else 
					ct <= waitEnquireFlag;
			end
			getRms:begin   //保存电流有效值
				if(rms_ok)begin
					rms_reg <= rms;
					ct <= getGpsInfo;
				end 
				else
					ct <= getRms;
			end
			getGpsInfo:begin
				if(getMegOk)begin
					hour_reg <= hour;//小时
					min_reg <= min;//分钟
					sec_reg <= sec;//秒钟

					latDu_reg <= latDu;//纬度 度
					latMin_reg <= latMin;//纬度 分

					longDu_reg <= longDu;//经度 度
					longMin_reg <= longMin;//经度 分

					day_reg <= day;//日
					mon_reg <= mon;//月
					year_reg <= year;//年
					ct <= waitSendOk;
					send_data_en  <= 1'b1; //启动发送使能标志
				end
				else
					ct <= getGpsInfo;
			end
			waitSendOk:begin
				send_data_en  <= 1'b0;
				if(send_data_ok)   //等待发送数据完成
					ct <= waitEnquireFlag;
				else 
					ct <= waitSendOk;
			end
			default:begin
				ct <= waitEnquireFlag;
			end
		  endcase
    end
end         

wire send_data_ok = (send_data_cnt >= cnt_sum);
wire [7:0]crc = (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE) ?
					 (~(ctrl_code_reg + 8'd14 + year_reg + mon_reg + day_reg + hour_reg + min_reg + sec_reg + rms_reg[7:0] + rms_reg[15:8])) : 
					 (~(ctrl_code_reg + 8'd16 + year_reg + mon_reg + day_reg + hour_reg + min_reg + sec_reg + longDu_reg + longMin_reg + latDu_reg + latMin_reg)); //计算校验位
wire [4:0]cnt_sum = (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE)?5'd20:5'd22;
////////////////////////////////////////////////////////
//回复数据计数器使能
reg send_data_cnt_en;
always@(posedge clk)begin
    if(rst)begin
		send_data_cnt_en <= 1'b0;
    end
    else if(send_data_en)
			send_data_cnt_en <= 1'b1;
	 else if(send_data_cnt >= cnt_sum)
			send_data_cnt_en <= 1'b0;
end

//回复数据计数器
reg [4:0]send_data_cnt;
always@(posedge clk)begin
    if(rst)begin
		send_data_cnt <= 0;
    end
    else if(send_data_cnt_en && tx_done)
			send_data_cnt <= send_data_cnt + 1'b1;
	 else if(!send_data_cnt_en)
			send_data_cnt <= 0;
end

reg [7:0]tx_data_r;
always@(posedge clk)begin
    if(rst)begin
		tx_data_r <= 0;
    end
    else if(send_data_cnt_en)begin
		case(send_data_cnt)
			5'd0:tx_data_r <= `FPGA_PACK_CMD_TYPE_START_CODE; //起始码
			5'd1:tx_data_r <= ctrl_code_reg;                  //控制字
			5'd2:begin //数据长度低位
				if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE)// 接下来为有效值
					tx_data_r <= 8'd14;    //有效值低8位  
				else
					tx_data_r <= 8'd16;    //经度  度
			end                       
			5'd3:tx_data_r <= 8'h0;			//数据长度	高位				     
			5'd4:tx_data_r <= year_reg;    //年     
			5'd5:tx_data_r <= mon_reg;     //月
			5'd6:tx_data_r <= day_reg;     //日
			5'd7:tx_data_r <= hour_reg;    //时
			5'd8:tx_data_r <= min_reg;     //分    
			5'd9:tx_data_r <= sec_reg;     //秒
			5'd10:tx_data_r <= 8'h0;       //ms
			5'd11:tx_data_r <= 8'h0;       //ms
			5'd12:tx_data_r <= 8'h0;       //us
			5'd13:tx_data_r <= 8'h0;       //us
			5'd14:tx_data_r <= 8'h0;       //ns
			5'd15:tx_data_r <= 8'h0;       //ns
			/////////////////////////////////////////////////
			5'd16:begin
				if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE)// 接下来为有效值
					tx_data_r <= rms_reg[7:0];    //有效值低8位  
				else
					tx_data_r <= longDu_reg;    //经度  度
			end
			5'd17:begin
				if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE)// 接下来为有效值
					tx_data_r <= rms_reg[15:8];    //有效值高8位  
				else
					tx_data_r <= longMin_reg;    //经度  分
			end
			5'd18:begin
				if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE)// 接下来为校验位
					tx_data_r <= crc;    //校验位   
				else
					tx_data_r <= latDu_reg;    //纬度  度
			end
			5'd19:begin
				if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE)// 接下来为结束码
					tx_data_r <= `FPGA_PACK_CMD_TYPE_END_CODE;    //结束码  
				else
					tx_data_r <= latMin_reg;    //纬度  分
			end
			5'd20:begin
				if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_GPS_INFO)
					tx_data_r <= crc;     //校验位 
			end                            
			5'd21:tx_data_r <= `FPGA_PACK_CMD_TYPE_END_CODE;   //结束码
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
			 if(send_data_cnt_en)begin
				case(send_data_cnt)
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
					5'd20:begin
					if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_GPS_INFO)
						start_tx_r <= 1'b1;
						st <= 1;
					end
					5'd21:begin start_tx_r <= 1'b1; st <= 1;end
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

assign tx_data = tx_data_r;
assign start_tx = start_tx_r;
assign gps_rms_enquire_done =  (send_data_cnt >= cnt_sum); //参数设置完成标志
assign module_run_flag = send_data_cnt_en;//标志该模块运行，用于串口上传数据选择

endmodule
