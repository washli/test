
//控制字类型
`define		FPGA_PACK_CMD_TYPE_SETTING_TRAVELLING_WAVE_COLLECT_FREQUENCY        8'h01
`define		FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_COLLECT_FREQUENCY        8'ha1
`define		FPGA_PACK_CMD_TYPE_SETTING_TRAVELLING_WAVE_COLLECT_DURATION         8'h02
`define		FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_COLLECT_DURATION         8'ha2
`define		FPGA_PACK_CMD_TYPE_SETTING_TRAVELLING_WAVE_ALARM_THRESHOLD          8'h03
`define		FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_ALARM_THRESHOLD          8'ha3


`define		FPGA_PACK_CMD_TYPE_SETTING_POWER_FREQUENCY_COLLECT_FREQUENCY        8'h04
`define		FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_COLLECT_FREQUENCY        8'ha4
`define		FPGA_PACK_CMD_TYPE_SETTING_POWER_FREQUENCY_COLLECT_DURATION         8'h05
`define		FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_COLLECT_DURATION         8'ha5
`define		FPGA_PACK_CMD_TYPE_SETTING_POWER_FREQUENCY_ALARM_THRESHOLD          8'h06
`define		FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_ALARM_THRESHOLD          8'ha6

`define		FPGA_PACK_CMD_TYPE_ENQUIRE_CURRENT_VAILD_VALUE                      8'hb1
`define		FPGA_PACK_CMD_TYPE_ENQUIRE_GPS_INFO                                 8'hb2
`define		FPGA_PACK_CMD_TYPE_FPGA_RESET                                       8'hb3
`define		FPGA_PACK_CMD_TYPE_MCU_AND_FPGA_COMMUNICATION                       8'hb4

`define		FPGA_PACK_CMD_TYPE_ENQUIRE_POWER_FREQUENCY_DATA                     8'hc1
`define		FPGA_PACK_CMD_TYPE_FPGA_UPLOAD_POWER_FREQUENCY_DATA_INFO            8'hc2
`define		FPGA_PACK_CMD_TYPE_FPGA_UPLOAD_POWER_FREQUENCY_DATA                 8'hc3

`define		FPGA_PACK_CMD_TYPE_ENQUIRE_TRAVELLING_WAVE_DATA                     8'hd1
`define		FPGA_PACK_CMD_TYPE_FPGA_UPLOAD_TRAVELLING_WAVE_DATA_INFO            8'hd2
`define		FPGA_PACK_CMD_TYPE_FPGA_UPLOAD_TRAVELLING_WAVE_DATA                 8'hd3

`define		FPGA_PACK_CMD_TYPE_FPGA_UPLOAD_TRAVELLING_WAVE_ALARM_DATA_INFO      8'he1
`define		FPGA_PACK_CMD_TYPE_FPGA_UPLOAD_TRAVELLING_WAVE_ALARM_DATA           8'he2

`define		FPGA_PACK_CMD_TYPE_FPGA_UPLOAD_POWER_FREQUENCY_ALARM_DATA_INFO      8'hf1
`define		FPGA_PACK_CMD_TYPE_FPGA_UPLOAD_POWER_FREQUENCY_ALARM_DATA           8'hf2


//参数设置和查询
`define		FPGA_PACK_CMD_TYPE_FPGA_SETTING_PARA                                8'h11
`define		FPGA_PACK_CMD_TYPE_FPGA_ENQUIRE_PARA                                8'h12

//起始码
`define		FPGA_PACK_CMD_TYPE_START_CODE                                       8'h68
`define		FPGA_PACK_CMD_TYPE_END_CODE                                         8'h16


`define		FPGA_PACK_CMD_TYPE_OK                                               8'hff
`define		FPGA_PACK_CMD_TYPE_ERROR                                            8'h00

//定义每包数据长度
`define		FPGA_DATA_NUMS_OF_PER_PACK                                         16'd512
`define		FPGA_DATA_NUMS_PACK_NO_RIGHT_SHIFT                                 16'd9
`define		FPGA_DATA_NUMS_PACK_NO_RIGHT_SHIFT_SUB_ONE                         16'd8
//等待MCU超时时间s
`define		FPGA_WAIT_MCU_REPLY_OUTTIME                                        8'd5
