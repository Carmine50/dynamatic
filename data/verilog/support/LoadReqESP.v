module LoadReqESP #(
  parameter DATA_TYPE = 32
)(
    input clk,
    input rst,
    input [ DATA_TYPE - 1 : 0] conf_info_mat_1_size,
    input conf_info_mat_1_size_valid,
    output conf_info_mat_1_size_ready,

    input [ DATA_TYPE - 1 : 0 ] iBurst,
    input iBurst_valid,
    output iBurst_ready,

    output start_ready,
    input start_valid,

    output end_valid,
    input end_ready,

    output [ DATA_TYPE - 1 : 0] out0,
    output  out0_valid,
    input    out0_ready
);


    muli #(.DATA_TYPE(DATA_TYPE), .LATENCY(4)) muli0
    (.clk(clk), .rst(rst), .lhs(conf_info_mat_1_size), .lhs_valid(conf_info_mat_1_size_valid), .lhs_ready(conf_info_mat_1_size_ready),
    .rhs(iBurst), .rhs_valid(iBurst_valid), .rhs_ready(iBurst_ready), .result(out0), .result_valid(out0_valid), .result_ready(out0_ready));

   assign start_ready = 1;

endmodule

