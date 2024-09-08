`timescale 1ns/1ps
module dyn_decoder #(parameter INPUTS = 2,
		parameter OUTPUTS = 1,
		parameter DATA_IN_SIZE = 32,
		parameter DATA_OUT_SIZE = 32,
        parameter COND_SIZE = 1)
	(
		input clk,
		input rst,
		input [(INPUTS - 1) * (DATA_IN_SIZE)- 1 : 0]data_in_bus,
		input [INPUTS - 1 : 0]valid_in_bus,
		output [INPUTS - 1 : 0] ready_in_bus,

        input [COND_SIZE - 1 : 0]condition,
		
		output reg [OUTPUTS * (DATA_OUT_SIZE) - 1 : 0]data_out_bus,
		output reg [OUTPUTS - 1 : 0]valid_out_bus,
		input 	[OUTPUTS - 1 : 0] ready_out_bus
);

	
	wire allReady;
	wire joinValid;
	wire joinReady;
	
    integer i;

	//always@(posedge clk, posedge rst)
	always@(posedge clk)
		for (i = 0; i < OUTPUTS ; i=i+1 ) begin
            if (condition[0] == i && valid_in_bus[0] == 1 && valid_in_bus[1] == 1 && ready_out_bus[i] == 1) begin
                valid_out_bus[i] <= 1'd1;
                data_out_bus[(i * DATA_IN_SIZE) +: DATA_IN_SIZE ] <= data_in_bus[(DATA_OUT_SIZE) - 1 : 0] ;
                
            end else begin
                valid_out_bus[i] <= 1'd0;
            end
        end
	
    //and_op #(.INPUTS(SIZE), .OUTPUTS(1), .DATA_IN_SIZE(1), .DATA_OUT_SIZE(1)) ready_out
    //            (.valid_in(valid_in_bus), .ready_in(ready_in_bus), 
	//			    .valid_out(join_valid), .ready_out(join_ready));

    //assign ready_in_bus[0] = ready_out_bus[0] & ready_out_bus[1];
	
    join_type #(.SIZE(2)) join_unit(.ins_valid(valid_in_bus), .ins_ready(ready_in_bus), .outs_valid(joinValid), .outs_ready(joinReady));
	assign joinReady = ready_out_bus[0] & ready_out_bus[1];

endmodule

module DecoderAlt #(parameter INPUTS = 1,
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
		input [OUTPUTS - 1 : 0] ready_out_bus
);

	
	reg decoder_dir;
	reg condition;
	reg condition_valid;
	wire condition_ready;
	
    integer i;

    dyn_decoder #(.INPUTS(2), .OUTPUTS(OUTPUTS), .DATA_IN_SIZE(DATA_IN_SIZE), .DATA_OUT_SIZE(DATA_OUT_SIZE), .COND_SIZE(1)) decoder_unit
    (.clk(clk), .rst(rst), .data_in_bus(data_in_bus), .valid_in_bus({valid_in_bus, condition_valid}), .ready_in_bus({ready_in_bus, condition_ready}),
    .condition(condition), .data_out_bus(data_out_bus), .valid_out_bus(valid_out_bus), .ready_out_bus(ready_out_bus));


	always @(posedge clk or posedge rst) begin
        if (rst) begin
            decoder_dir <= 1'b0;
            condition_valid <= 1'b0;
            condition <= 0;
        end else if (valid_in_bus[0] == 1'b1) begin
            if (ready_out_bus[1] && decoder_dir == 1'b0 ) begin
                condition <= 0; // Assuming condition is a reg of sufficient width
                condition_valid <= 1'b1;
                decoder_dir <= 1'b1;
            end else if (ready_out_bus[0] && decoder_dir == 1'b1) begin
                condition <= 1; // Assuming condition is a reg of sufficient width
                condition_valid <= 1'b1;
                decoder_dir <= 1'b0;
                
            end else begin
                condition_valid <= 1'b1;
            end
        end
    end

endmodule
