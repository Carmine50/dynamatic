module LoadReqESP #(parameter INPUTS = 1,
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
                input   [OUTPUTS - 1 : 0] ready_out_bus
);

    mul_op #(.INPUTS(INPUTS), .OUTPUTS(OUTPUTS), .DATA_IN_SIZE(DATA_IN_SIZE), .DATA_OUT_SIZE(DATA_OUT_SIZE)) muli0
    (.clk(clk), .rst(rst), .data_in_bus(data_in_bus), .valid_in_bus(valid_in_bus), .ready_in_bus(ready_in_bus),
    .data_out_bus(data_out_bus), .valid_out_bus(valid_out_bus), .ready_out_bus(ready_out_bus));

endmodule

