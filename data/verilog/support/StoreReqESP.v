module StoreReqESP #(
    parameter DATA_TYPE = 32
)(
    input clk,
    input rst,

    input [ DATA_TYPE - 1 : 0]conf_info_mat_1_size,
    input conf_info_mat_1_size_valid,
    output conf_info_mat_1_size_ready,

    input [ DATA_TYPE - 1 : 0] iBurst,
    input iBurst_valid,
    output iBurst_ready,

    input [ DATA_TYPE - 1 : 0]conf_info_mat_out_size,
    input conf_info_mat_out_size_valid,
    output conf_info_mat_out_size_ready,


    output start_ready,
    input start_valid,

    output end_valid,
    input end_ready,

    output [ DATA_TYPE - 1 : 0]out0,
    output out0_valid,
    input 	 out0_ready
);

    wire [ DATA_TYPE - 1 : 0] result_mul0;
    wire valid_mul0;
    wire ready_mul0;
    wire [ DATA_TYPE - 1 : 0] result_mul1;
    wire valid_mul1;
    wire ready_mul1;


    wire [3 : 0] readyOutMul;
    wire joinValid;
    wire joinReady;	

    assign start_ready = 1;

    muli #(.DATA_TYPE(DATA_TYPE), .LATENCY(4)) muli0
    (.clk(clk), .rst(rst), .lhs(conf_info_mat_1_size), .lhs_valid(conf_info_mat_1_size_valid), .lhs_ready(readyOutMul[0]),
    .rhs(iBurst), .rhs_valid(iBurst_valid), .rhs_ready(readyOutMul[2]), .result(result_mul0), .result_valid(valid_mul0), .result_ready(ready_mul0));

    muli #(.DATA_TYPE(DATA_TYPE), .LATENCY(4)) muli1
    (.clk(clk), .rst(rst), .lhs(conf_info_mat_out_size), .lhs_valid(conf_info_mat_out_size_valid), .lhs_ready(readyOutMul[1]),
    .rhs(iBurst), .rhs_valid(iBurst_valid), .rhs_ready(readyOutMul[3]), .result(result_mul1), .result_valid(valid_mul1), .result_ready(ready_mul1));

    addi #( .DATA_TYPE(32)  ) add0
    (.clk(clk), .rst(rst), .lhs(result_mul0), .lhs_valid(valid_mul0), .lhs_ready(ready_mul0), .rhs(result_mul1), .rhs_valid(valid_mul1), .rhs_ready(ready_mul1),
    .result(out0), .result_valid(out0_valid), .result_ready(out0_ready));

    // synchronize inputs
    //
    join_type #(.SIZE(3)) j(.ins_valid({conf_info_mat_1_size_valid, conf_info_fpsa_valid, iBurst_valid}), .ins_ready({conf_info_mat_1_size_ready, conf_info_fpsa_ready, iBurst_ready}), 
    .outs_valid(joinValid), .outs_ready(joinReady));

      assign joinReady = readyOutMul[0] & readyOutMul[1] & readyOutMul[2] & readyOutMul[3];

endmodule
	 		

