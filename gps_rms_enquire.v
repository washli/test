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
	 input para_enquire_flag, //�������ñ�־
	 input [7:0]ctrl_code, //������
//	 input [7:0]rx_data,  //���ڽ�������
//	 input rx_ok,  //����������Ч��־

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
	 
	 output gps_rms_enquire_done,  //��ɱ�־
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

//�����ڲ��Ĵ���,���ڱ�����Ҫ�ϴ�������
reg [7:0]hour_reg;//Сʱ
reg [7:0]min_reg;//����
reg [7:0]sec_reg;//����

reg [7:0]latDu_reg;//γ�� ��
reg [7:0]latMin_reg;//γ�� ��

reg [7:0]longDu_reg;//���� ��
reg [7:0]longMin_reg;//���� ��

reg [7:0]day_reg;//��
reg [7:0]mon_reg;//��
reg [7:0]year_reg;//��

reg [15:0]rms_reg;//��Чֵ


////////////////////////////////////////////////////////
parameter  waitEnquireFlag            = 1,
			  getCtrlCode                = 2,
			  analysisCtrlCode           = 3,
           getRms                     = 4,
			  getGpsInfo                 = 5,
			  waitSendOk                 = 6;
			  

reg [3:0] ct;  
reg [7:0]ctrl_code_reg;
reg send_data_en;//��������ʹ�ܱ�־
always@(posedge clk)begin
    if(rst)begin
		ct            <= waitEnquireFlag;
		ctrl_code_reg <= 8'h0;
		rms_reg       <= 16'h0;
		hour_reg      <= 8'h0;//Сʱ
		min_reg       <= 8'h0;//����
		sec_reg       <= 8'h0;//����
		latDu_reg     <= 8'h0;//γ�� ��
		latMin_reg    <= 8'h0;//γ�� ��
		longDu_reg    <= 8'h0;//���� ��
		longMin_reg   <= 8'h0;//���� ��
		day_reg       <= 8'h0;//��
		mon_reg       <= 8'h0;//��
		year_reg      <= 8'h0;//��
		send_data_en  <= 1'b0;
    end
    else begin
       case(ct)
			waitEnquireFlag:begin  //�ȴ���ѯ��־����
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
			getRms:begin   //���������Чֵ
				if(rms_ok)begin
					rms_reg <= rms;
					ct <= getGpsInfo;
				end 
				else
					ct <= getRms;
			end
			getGpsInfo:begin
				if(getMegOk)begin
					hour_reg <= hour;//Сʱ
					min_reg <= min;//����
					sec_reg <= sec;//����

					latDu_reg <= latDu;//γ�� ��
					latMin_reg <= latMin;//γ�� ��

					longDu_reg <= longDu;//���� ��
					longMin_reg <= longMin;//���� ��

					day_reg <= day;//��
					mon_reg <= mon;//��
					year_reg <= year;//��
					ct <= waitSendOk;
					send_data_en  <= 1'b1; //��������ʹ�ܱ�־
				end
				else
					ct <= getGpsInfo;
			end
			waitSendOk:begin
				send_data_en  <= 1'b0;
				if(send_data_ok)   //�ȴ������������
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
					 (~(ctrl_code_reg + 8'd16 + year_reg + mon_reg + day_reg + hour_reg + min_reg + sec_reg + longDu_reg + longMin_reg + latDu_reg + latMin_reg)); //����У��λ
wire [4:0]cnt_sum = (ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE)?5'd20:5'd22;
////////////////////////////////////////////////////////
//�ظ����ݼ�����ʹ��
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

//�ظ����ݼ�����
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
			5'd0:tx_data_r <= `FPGA_PACK_CMD_TYPE_START_CODE; //��ʼ��
			5'd1:tx_data_r <= ctrl_code_reg;                  //������
			5'd2:begin //���ݳ��ȵ�λ
				if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE)// ������Ϊ��Чֵ
					tx_data_r <= 8'd14;    //��Чֵ��8λ  
				else
					tx_data_r <= 8'd16;    //����  ��
			end                       
			5'd3:tx_data_r <= 8'h0;			//���ݳ���	��λ				     
			5'd4:tx_data_r <= year_reg;    //��     
			5'd5:tx_data_r <= mon_reg;     //��
			5'd6:tx_data_r <= day_reg;     //��
			5'd7:tx_data_r <= hour_reg;    //ʱ
			5'd8:tx_data_r <= min_reg;     //��    
			5'd9:tx_data_r <= sec_reg;     //��
			5'd10:tx_data_r <= 8'h0;       //ms
			5'd11:tx_data_r <= 8'h0;       //ms
			5'd12:tx_data_r <= 8'h0;       //us
			5'd13:tx_data_r <= 8'h0;       //us
			5'd14:tx_data_r <= 8'h0;       //ns
			5'd15:tx_data_r <= 8'h0;       //ns
			/////////////////////////////////////////////////
			5'd16:begin
				if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE)// ������Ϊ��Чֵ
					tx_data_r <= rms_reg[7:0];    //��Чֵ��8λ  
				else
					tx_data_r <= longDu_reg;    //����  ��
			end
			5'd17:begin
				if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE)// ������Ϊ��Чֵ
					tx_data_r <= rms_reg[15:8];    //��Чֵ��8λ  
				else
					tx_data_r <= longMin_reg;    //����  ��
			end
			5'd18:begin
				if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE)// ������ΪУ��λ
					tx_data_r <= crc;    //У��λ   
				else
					tx_data_r <= latDu_reg;    //γ��  ��
			end
			5'd19:begin
				if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE)// ������Ϊ������
					tx_data_r <= `FPGA_PACK_CMD_TYPE_END_CODE;    //������  
				else
					tx_data_r <= latMin_reg;    //γ��  ��
			end
			5'd20:begin
				if(ctrl_code_reg == `FPGA_PACK_CMD_TYPE_ENQUIRE_GPS_INFO)
					tx_data_r <= crc;     //У��λ 
			end                            
			5'd21:tx_data_r <= `FPGA_PACK_CMD_TYPE_END_CODE;   //������
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
assign gps_rms_enquire_done =  (send_data_cnt >= cnt_sum); //����������ɱ�־
assign module_run_flag = send_data_cnt_en;//��־��ģ�����У����ڴ����ϴ�����ѡ��

endmodule
