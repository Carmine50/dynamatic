module systolicCtrlConv #(
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
  output [SELECT_TYPE + DATA_TYPE - 1 : 0] outs,
  output [1 : 0] outs_valid,
  input 	[1 : 0] outs_ready
);

  // IMPORTANT: This code assumes that the size of the input data is 64 bits
  // and each element of the matrix is 16 bits.

	localparam ROWS_SIZE_INPUT_MAT = TEMPLATE_ROWS_SIZE_INPUT_MAT;
	localparam ROWS_SIZE_KERNEL_MAT = TEMPLATE_ROWS_SIZE_KERNEL_MAT;
	localparam SIZE_INPUT_MAT = TEMPLATE_SIZE_INPUT_MAT;
	localparam SIZE_KERNEL_MAT = TEMPLATE_SIZE_KERNEL_MAT;

	integer cnt_read;
	integer cnt_index_inMat;
	integer cnt_index_kernelMat;
	integer read_inMat;
	reg start_write;
	reg [9:0] cnt_write_rows;
	reg [9:0] cnt_write_cols;
	reg [(16 - 1) : 0] inputMatrix [SIZE_INPUT_MAT - 1:0];
	reg [(16 - 1) : 0] kernelMatrix [SIZE_KERNEL_MAT - 1:0];

  reg [SELECT_TYPE - 1 : 0] startSignal;
  reg startSignal_valid;
  reg [DATA_TYPE - 1 : 0 ] dataOutSignal;
  reg dataOutSignal_valid;
  reg [1:0] readyOut;
  wire [SELECT_TYPE - 1 : 0] condition;
  wire condition_valid;
  wire [DATA_TYPE - 1 : 0] dataInSignal;
  wire dataInSignal_valid;
  wire tehbReady;

  assign condition = ins[0 * SELECT_TYPE +: SELECT_TYPE];
  assign condition_valid = ins_valid[0];
  assign dataInSignal = ins[1 * SELECT_TYPE +: DATA_TYPE];
  assign dataInSignal_valid = ins_valid[1];

  assign outs[1 * DATA_TYPE +: SELECT_TYPE] = startSignal;
  //assign outs[0 * DATA_TYPE +: DATA_TYPE] = dataOutSignal;
  assign outs_valid[1] = startSignal_valid;
  //assign outs_valid[0] = dataOutSignal_valid;
  assign ins_ready = readyOut;

  always @(posedge clk) begin
    if (rst) begin
      cnt_read <= 0;
      cnt_index_inMat <= 0;
      cnt_index_kernelMat <= 0;
      read_inMat <= 1;
      start_write <= 0;
      cnt_write_rows <= 0;
      cnt_write_cols <= 0;
      // set all signals for output to 0 and ready to 11
      startSignal <= 0;
      startSignal_valid <= 0;
      dataOutSignal <= 0;
      dataOutSignal_valid <= 0;
      readyOut <= 2'd3;
    end else begin 
      if (cnt_read > (condition -1) && condition_valid ) begin
        cnt_read <= 0;
        readyOut <= 2'd0;
        start_write <= 1;
        cnt_write_rows <= 9'd0;
        cnt_write_cols <= 9'd0;
      end else begin
          if (dataInSignal_valid && start_write == 1'b0) begin
            if (read_inMat == 1'd1) begin
              inputMatrix[cnt_index_inMat] <= dataInSignal[(16 - 1) : 0];
              // PLACE_HOLDER_INPUT_MATRIX_1
              inputMatrix[cnt_index_inMat+1] <= dataInSignal[(32 - 1) : 16];
              // PLACE_HOLDER_INPUT_MATRIX_2
              inputMatrix[cnt_index_inMat+2] <= dataInSignal[(48 - 1) : 32];
              // PLACE_HOLDER_INPUT_MATRIX_3
              inputMatrix[cnt_index_inMat+3] <= dataInSignal[(64 - 1) : 48];
              // PLACE_HOLDER_INPUT_MATRIX_4
              cnt_index_inMat <= cnt_index_inMat + 4;
              if (cnt_index_kernelMat >= SIZE_KERNEL_MAT ) begin
                read_inMat <= 1;
              end else begin
                read_inMat <= 0;
              end
            end else begin
              kernelMatrix[cnt_index_kernelMat] <= dataInSignal[(16 - 1) : 0];
              // PLACE_HOLDER_KERNEL_MATRIX_1
              kernelMatrix[cnt_index_kernelMat+1] <= dataInSignal[(32 - 1) : 16];
              // PLACE_HOLDER_KERNEL_MATRIX_2
              kernelMatrix[cnt_index_kernelMat+2] <= dataInSignal[(48 - 1) : 32];
              // PLACE_HOLDER_KERNEL_MATRIX_3
              kernelMatrix[cnt_index_kernelMat+3] <= dataInSignal[(64 - 1) : 48];
              // PLACE_HOLDER_KERNEL_MATRIX_4
              cnt_index_kernelMat <= cnt_index_kernelMat + 4;
              if (cnt_index_inMat >=  SIZE_INPUT_MAT ) begin
                read_inMat <= 0;
              end else begin
                read_inMat <= 1;
              end
            end
            cnt_read <= cnt_read + 1;
            dataOutSignal_valid <= 0;
            startSignal_valid <= 0;
            readyOut <= 2'd3;
          end
      end
    end
  end

  RESHAPE_LOOP
  
  tehb #(
    .DATA_TYPE(DATA_TYPE)
  ) data_tehb (
    .clk        (clk            ),
    .rst        (rst            ),
    .ins        (dataOutSignal         ),
    .ins_valid  (dataOutSignal_valid   ),
    .ins_ready  (tehbReady   ),
    .outs       (outs[0 * DATA_TYPE +: DATA_TYPE]        ),
    .outs_valid (outs_valid[0]  ),
    .outs_ready (outs_ready[0]  )
  );

endmodule