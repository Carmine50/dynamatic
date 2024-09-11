module decoder #(
  parameter SIZE = 2,
  parameter DATA_TYPE = 32,
  parameter SELECT_TYPE = 2
)(
		input clk,
		input rst,
    // data input channels
		input [DATA_TYPE - 1 : 0] ins,
		input ins_valid,
		output ins_ready,
    // index input channel
    input [SELECT_TYPE - 1 : 0] index,
		input index_valid,
    output index_ready,
    // output channel
		output reg [SIZE * (DATA_TYPE) - 1 : 0] outs,
		output reg [SIZE - 1 : 0] outs_valid,
		input 	[SIZE - 1 : 0] outs_ready
);

	
  wire joinValid;
  wire joinReady;
  integer i;

  always@(posedge clk) begin
    for (i = 0; i < SIZE ; i=i+1 ) begin
      if ((i[SELECT_TYPE - 1 : 0] == index) && index_valid == 1 && ins_valid == 1 && outs_ready[i] == 1) begin
        outs_valid[i] <= 1'd1;
        outs[(i * DATA_TYPE) +: DATA_TYPE ] <= ins[(DATA_TYPE) - 1 : 0] ;
      end else begin
        outs_valid[i] <= 1'd0;
      end
    end
  end

  join_type #(
    .SIZE(SIZE)
  ) join_inputs (
    .ins_valid  ({ins_valid, index_valid}),
    .outs_ready (joinReady             ),
    .ins_ready  ({ins_ready, index_ready}),
    .outs_valid (joinValid             )
  );

	assign joinReady = &outs_ready;

endmodule
