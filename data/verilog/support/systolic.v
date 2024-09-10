`timescale 1ns/1ps
module systolic_unit #(
  parameter DATA_TYPE = 64,
  parameter SELECT_TYPE = 32
)(
  input clk,
  input rst,
  // data input channels
  input [3 * SELECT_TYPE + 2 * DATA_TYPE - 1 : 0] ins,
  input [4 : 0] ins_valid,
  output [4 : 0] ins_ready,
  // output channel
  output reg [(DATA_TYPE) - 1 : 0] outs,
  output reg outs_valid,
  input 	outs_ready
);

  wire [SELECT_TYPE - 1 : 0] start;
  wire [SELECT_TYPE - 1 : 0] tile_op_mode;
  wire [SELECT_TYPE - 1 : 0] tile_fpsa_config;
	
	wire joinValid;
	wire sysIsReady;
	wire systolic_rst;
  reg [SELECT_TYPE - 1 : 0] tile_op_mode_reg;
  reg [SELECT_TYPE - 1 : 0] tile_fpsa_config_reg;

  assign start = ins[0 * SELECT_TYPE +: SELECT_TYPE];
  assign tile_op_mode = ins[1 * SELECT_TYPE +: SELECT_TYPE];
  assign tile_fpsa_config = ins[2 * SELECT_TYPE +: SELECT_TYPE];

  always @(posedge clk) begin
    if (rst) begin
      tile_op_mode_reg <= 0;
      tile_fpsa_config_reg <= 0;
    end else begin
      if (ins_valid[1]) begin
        tile_op_mode_reg <= tile_op_mode;
      end
      if (ins_valid[2]) begin
        tile_fpsa_config_reg <= tile_fpsa_config;
      end
    end
  end

  systolic_tile_wrapper systolic_tile_unit
  (.clk(clk), .rst(systolic_rst), .in_west(ins[3 * SELECT_TYPE +: DATA_TYPE]), .in_north(ins[3 * SELECT_TYPE + DATA_TYPE +: DATA_TYPE]), .start(start[0]), .tile_op_mode(tile_op_mode_reg[2 : 0]), .tile_config(tile_fpsa_config_reg[18 : 0]),
  .in_valid(joinValid), .in_ready( sysIsReady ), .out_data(outs), .out_valid(outs_valid), .out_ready(outs_ready));

	assign systolic_rst = ~rst;

  // the valid signal of op mode and fpsa config is disconnected since they might not be valid during systolic execution and the systolic unit is not elastic
  join_type #( .SIZE(5) ) join_unit(.ins_valid({ins_valid[0], 1'b1, 1'b1, ins_valid[3], ins_valid[4]}), .outs_ready({sysIsReady}), .ins_ready({ins_ready}), .outs_valid(joinValid));


endmodule

