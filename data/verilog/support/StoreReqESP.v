module StoreReqESP #(parameter INPUTS = 4,
		parameter OUTPUTS = 1,
		parameter DATA_IN_SIZE = 32,
		parameter DATA_OUT_SIZE = 32)
	(
		input clk,
		input rst,
		input [INPUTS * (DATA_IN_SIZE)- 1 : 0]data_in_bus,
		input [INPUTS - 1 : 0]valid_in_bus,
		output [INPUTS - 1 : 0] ready_in_bus,
		
		output [OUTPUTS * (DATA_OUT_SIZE) - 1 : 0]data_out_bus,
		output [OUTPUTS - 1 : 0]valid_out_bus,
		input 	[OUTPUTS - 1 : 0] ready_out_bus
);

    wire [(DATA_IN_SIZE)- 1 : 0] result_mul0;
    wire valid_mul0;
    wire ready_mul0;
    wire [(DATA_IN_SIZE)- 1 : 0] result_mul1;
    wire valid_mul1;
    wire ready_mul1;
	wire [3 : 0] readyOutMul;
	wire joinValid;
	wire joinReady;	


    mul_op #(.INPUTS(2), .OUTPUTS(OUTPUTS), .DATA_IN_SIZE(DATA_IN_SIZE), .DATA_OUT_SIZE(DATA_OUT_SIZE)) muli0
    (.clk(clk), .rst(rst), .data_in_bus({data_in_bus[0 * DATA_IN_SIZE +: DATA_IN_SIZE], data_in_bus[2 * DATA_IN_SIZE +: DATA_IN_SIZE]}), .valid_in_bus({valid_in_bus[0], valid_in_bus[2]}), .ready_in_bus({readyOutMul[0], readyOutMul[2]}),
    .data_out_bus(result_mul0), .valid_out_bus(valid_mul0), .ready_out_bus(ready_mul0));

    mul_op #(.INPUTS(2), .OUTPUTS(OUTPUTS), .DATA_IN_SIZE(DATA_IN_SIZE), .DATA_OUT_SIZE(DATA_OUT_SIZE)) muli1
    (.clk(clk), .rst(rst), .data_in_bus({data_in_bus[1 * DATA_IN_SIZE +: DATA_IN_SIZE], data_in_bus[3 * DATA_IN_SIZE +: DATA_IN_SIZE]}), .valid_in_bus({valid_in_bus[1], valid_in_bus[3]}), .ready_in_bus({readyOutMul[1], readyOutMul[3]}),
    .data_out_bus(result_mul1), .valid_out_bus(valid_mul1), .ready_out_bus(ready_mul1));

    add_op #(.INPUTS(2), .OUTPUTS(OUTPUTS), .DATA_IN_SIZE(DATA_IN_SIZE), .DATA_OUT_SIZE(DATA_OUT_SIZE)) add0
    (.clk(clk), .rst(rst), .data_in_bus({result_mul0, result_mul1}), .valid_in_bus({valid_mul0, valid_mul1}), .ready_in_bus({ready_mul0, ready_mul1}),
    .data_out_bus(data_out_bus), .valid_out_bus(valid_out_bus), .ready_out_bus(ready_out_bus));

	// synchronize inputs
	//
	 	joinC #(.N(4)) j(.valid_in(valid_in_bus), .ready_in(ready_in_bus), .valid_out(joinValid), .ready_out(joinReady));
	//
	 		assign joinReady = readyOutMul[0] & readyOutMul[1] & readyOutMul[2] & readyOutMul[3];
	//
	 		endmodule
	 		

