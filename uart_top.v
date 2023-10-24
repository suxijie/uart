`timescale 1ns / 1ps
module uart_top(
	input  clk_i    ,
	input  rst_n    ,
	input  uart_rx_i,
	output uart_tx_o
);

wire [7:0] uart_rx_data_o;
wire uart_rx_done;
wire uart_tx_busy;


uart_rx u_uart_rx
(
	.clk_i    		           (clk_i ), 
	.rst_n    		           (rst_n ), 	
    .uart_rx_i	         	 (uart_rx_i), 
    .uart_rx_data_o 	(uart_rx_data_o),
    .uart_rx_done         (uart_rx_done)

);

uart_tx u_uart_tx
(
	.clk_i				         (clk_i ), 	
	.rst_n    		           (rst_n ), 
    .uart_tx_data_i		  (uart_rx_data_o),
    .uart_tx_en_i		    (uart_rx_done), 
	.uart_tx_o			       (uart_tx_o), 	
    .uart_tx_busy           (uart_tx_busy)

);

endmodule
