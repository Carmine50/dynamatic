module systolicCtrl #(
  parameter DATA_TYPE = 64,
  parameter SELECT_TYPE = 32
)(
		input clk,
		input rst,
    // data input channels
    input [SELECT_TYPE + DATA_TYPE - 1 : 0] ins,
    input [1 : 0] ins_valid,
    output [1 : 0] ins_ready,
    // output channel
    output reg [SELECT_TYPE + DATA_TYPE - 1 : 0] outs,
    output reg [1 : 0] outs_valid,
    input 	[1 : 0] outs_ready
);

	integer cnt;
  wire [SELECT_TYPE - 1 : 0] condition;
  assign condition = ins[0 * SELECT_TYPE +: SELECT_TYPE];

	always @(posedge clk) begin
    if (rst) begin
      cnt <= 0;
      outs[1 * DATA_TYPE +: SELECT_TYPE] <= 31'b0; // the second output represents the start control signal for sys unit
      outs_valid <= 2'b0;
    end else begin 
      if (cnt > (condition -1) && ins_valid[0] ) begin // check that the condition is valid
        cnt <= 0;
        outs[1 * DATA_TYPE +: SELECT_TYPE] <= 31'b1;
        outs_valid[1] <= 1;
        outs_valid[0] <= 0;
      end else begin
          if (ins_valid[1] && outs_ready[0]) begin // check that the FIFO data is valid
            cnt <= cnt + 1;
            outs_valid[1] <= 1'd1;
            outs_valid[0] <= 1;
            outs[0 * DATA_TYPE +: DATA_TYPE] <= ins[1 * SELECT_TYPE +: DATA_TYPE];
          end else 
            outs_valid[0] <= 0;
      end
    end
  end


	// propagate the information from the data in array to data out array
	assign ins_ready[1] = outs_ready[0];

	// connect condition and ctrl out
	assign ins_ready[0] = outs_ready[1];

endmodule