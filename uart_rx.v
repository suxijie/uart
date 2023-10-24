`timescale 1ns / 1ps
module uart_rx(
	input 			    clk_i         , 	
	input 			    rst_n         , 	
	input               uart_rx_i     , 
	output    [7:0]     uart_rx_data_o, 
	output              uart_rx_done
);
parameter [14:0] BAUD_DIV = 15'd867;//波特率时钟，115200bps，100Mhz/115200 - 1'b1=867
parameter [14:0] STOP_DIV = 15'd830;
parameter [9:0]  BAUD_DIV_SAMP = 10'd59;//(BAUD_DIV/14 - 1'b1) 14次采样滤波去毛刺
//reg define
reg           uart_rx_1    = 1'b1;
reg           uart_rx_2    = 1'b1;
reg           uart_rx_3    = 1'b1;
reg  [3:0]    bit_cnt      = 4'b0; 
reg  [5:0]    cap_cnt     =  6'b0;     
reg           start_div    = 1'b0;
reg           start_work   = 1'b0;
reg           rx_work      = 1'b0;
reg           stop_work    = 1'b0;
reg           data_stable  = 1'b1;
reg           data_cap     = 1'b1;
reg  [14:0]   baud_div     = 15'd0; //波特率设置计数器
reg  [6:0]    samp_cnt     = 7'b0 ; 
reg  [6:0]    rx_tmp       = 7'd30;   
reg  [7:0]    uart_rx_data =8'b1111_1111 ;
reg  [7:0]    rx_data_o    =8'b1111_1111 ;
wire bps_en  = (baud_div == BAUD_DIV);
wire stop_en  = (baud_div == STOP_DIV);
wire samp_en = (samp_cnt == BAUD_DIV_SAMP);
wire edge_p  = uart_rx_2 && !uart_rx_3;
wire edge_n  = !uart_rx_2 && uart_rx_3;
assign uart_rx_data_o = rx_data_o;
assign uart_rx_done = stop_work;

//波特率时钟
always@(posedge clk_i)begin
	if( !rst_n)
		baud_div <= 15'd0;
	else if( start_div&&baud_div < BAUD_DIV)
		baud_div <= baud_div + 1'b1;
	else
		baud_div <= 15'd0;
end

//一个波特率时钟周期中有14个采样时钟周期
always@(posedge clk_i)begin
    if(!rst_n||bps_en)
        samp_cnt <=  'd0;  
	else if(start_div&&samp_cnt < BAUD_DIV_SAMP)
		samp_cnt <= samp_cnt + 1'b1;
	else
		samp_cnt <=  'd0;
end

//消除亚稳态
always@(posedge clk_i)begin
	if( !rst_n)begin
		uart_rx_1  <=1'b1;
		uart_rx_2  <=1'b1;
		uart_rx_3  <=1'b1;
		data_stable<=1'b1;
	end
	else  begin
		uart_rx_1<=uart_rx_i;
		uart_rx_2<=uart_rx_1;
		uart_rx_3<=uart_rx_2;
		data_stable<= edge_n ? 1'd0 :  edge_p ? 1'd1 :data_stable;
	end
end

//14次滤波采样
always@(posedge clk_i)begin
    if(!rst_n)begin
        cap_cnt <=  'd0;
        data_cap<=  'd1;
        rx_tmp  <= 7'd30;
    end
	else if(samp_en)begin
		cap_cnt <= cap_cnt + 1'b1;
		rx_tmp <= data_stable ? rx_tmp + 1'b1 : rx_tmp - 1'b1;
	end
	else if(bps_en) begin //每次波特率时钟使能，重新设置 rx_tmp 初值为 8
		rx_tmp <= 7'd30;
		cap_cnt <= 4'd0;
	end
	if(cap_cnt==6'd11)begin
	   data_cap <= (rx_tmp > 7'd30) ? 1 : 0;
	end	
end


 always@(posedge clk_i)begin
     	if(!rst_n)begin
		bit_cnt     <=4'd0;
		uart_rx_data<=8'b1111_1111 ;
	end
	else if(bps_en)begin
       uart_rx_data<={uart_rx_data[6:0],data_cap};
	   bit_cnt <=bit_cnt+4'd1;
	end
	else if(stop_work&&stop_en)begin
	   uart_rx_data<=8'b1111_1111 ;
	   bit_cnt     <=4'd0;
	end
	else
		bit_cnt <=bit_cnt;
end 
  
always@(posedge clk_i)begin
	if( !rst_n)begin
		start_div   <=1'b0;
		start_work  <=1'b0;
		rx_work     <=1'b0;
		stop_work   <=1'b0;
		rx_data_o   <=8'b1111_1111 ;
	end
    else if(!start_div&&!data_stable)begin
        start_work  <= 1'd1;
        start_div   <= 1'd1;
     end
    else if(start_work&&bps_en)begin
        start_work  <= 1'd0;
        rx_work     <= 1'd1;
    end
    else if(rx_work&&bit_cnt==4'd9) begin
        rx_data_o <= uart_rx_data;
	    rx_work   <= 1'd0;
		stop_work <= 1'd1;
    end
    if(stop_work&&stop_en)begin
        stop_work      <= 1'd0;
        start_div      <= 1'd0;
    end 
end
endmodule 
 
