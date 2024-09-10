module decoderAlt #(
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
  // output channel
  output reg [SIZE * (DATA_TYPE) - 1 : 0] outs,
  output reg [SIZE - 1 : 0] outs_valid,
  input 	[SIZE - 1 : 0] outs_ready
);

	
	reg [SELECT_TYPE - 1 : 0] condition_next;
  reg [SELECT_TYPE - 1 : 0] condition;
	reg condition_valid;
	wire condition_ready;
	
  decoder #(.SIZE(SIZE), .DATA_TYPE(DATA_TYPE), .SELECT_TYPE(SELECT_TYPE)) decoder_unit
    (.clk(clk), .rst(rst), .ins(ins), .ins_valid(ins_valid), .ins_ready(ins_ready),
    .index({condition}), .index_valid(condition_valid), .index_ready(condition_ready),
    .outs(outs), .outs_valid(outs_valid), .outs_ready(outs_ready));

	always @(posedge clk or posedge rst) begin
    if (rst) begin
      condition_valid <= 1'b0;
      condition_next <= 0;
      condition <= -1;
    end else if (ins_valid == 1'b1) begin
      if (outs_ready[condition_next] == 1'b1) begin
        condition_valid <= 1'b1;
        if (condition == SIZE - 1) begin
          condition <= 0;
        end else begin
          condition <= condition + 1;
        end
        if (condition_next == SIZE - 1) begin
          condition_next <= 0;
        end else begin
          condition_next <= condition_next + 1;
        end
      end else begin
        condition_valid <= 1'b0;
      end
    end
  end

endmodule