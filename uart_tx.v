`timescale 1ns / 1ps
module uart_tx(
	input 		clk_i         ,
	input 	    rst_n         ,	 	
	input [7:0] uart_tx_data_i, //待发送数据
	input 		uart_tx_en_i  , //发送发送使能信号
	output 		uart_tx_o     , 	
	output 		uart_tx_busy
);
parameter [14:0] BAUD_DIV = 15'd867;//波特率时钟，115200bps，100Mhz/115200 - 1'b1=867  
parameter [14:0] STOP_DIV = 15'd866; 
//reg define
reg        bps_start_en = 1'b0 ;
reg        uart_tx      = 1'b1 ;
reg [3:0]  bit_cnt      = 4'd0 ; 
reg [3:0]  bit          = 4'd0 ; 
reg [12:0] baud_div     = 13'd0;
wire bps_en = (baud_div == BAUD_DIV);
wire stop_en = (bit_cnt==4'd9)&&(baud_div == STOP_DIV) ? 1'b1 : 1'b0;
assign uart_tx_busy = bps_start_en;
assign uart_tx_o = uart_tx;

always@(posedge clk_i)begin
    if(!rst_n)
        baud_div <= 13'd0;
	else if(bps_start_en && baud_div < BAUD_DIV)
		baud_div <= baud_div + 1'b1; 
	else
		baud_div <= 13'd0;
end

always@(posedge clk_i)begin
    if(!rst_n)
        bit_cnt <= 4'd0;
	else if(bps_en)
		bit_cnt <=bit_cnt+4'd1;
	else
		bit_cnt <=bit_cnt;
	if(bit_cnt==4'd9&&bps_en)
	    bit_cnt <=4'd0;
end

always@(posedge clk_i)begin
    if(!rst_n)begin
        bps_start_en <= 1'b0;
        uart_tx      <= 1'b1;
	    bit          <= 4'b0;
    end
    else if(uart_tx_en_i) 
        bps_start_en <= 1'b1;
	else if(bps_start_en&&bps_en&&(bit_cnt<4'd9)) begin
	    bit <=4'd7 - bit_cnt;
	   if(bit_cnt==4'd0)                     uart_tx <=1'b0;
	   if((bit_cnt>=4'd1)&&(bit_cnt<=4'd8))  uart_tx<=uart_tx_data_i[bit];
	end 
    if(bit_cnt==4'd9&&stop_en)begin
	    uart_tx      <= 1'b1;
	    bit          <= 4'b0;
	    bps_start_en <= 1'b0;
	end
end
endmodule
