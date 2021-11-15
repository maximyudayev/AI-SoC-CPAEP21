`define CEIL_DIV(q, d) (q+d-1)/d

module adder_tree #(
    parameter int NUM_INPUTS  = 36,
    parameter int INPUT_WIDTH = 32
  )
  (
    input logic clk,
    input logic arst_n_in, //asynchronous reset, active low
    
    input logic signed [INPUT_WIDTH-1:0] in [0:NUM_INPUTS-1], //vector of NUM_INPUTS products INPUT_WIDTH bit wide
    output logic signed [$clog2(NUM_INPUTS)+INPUT_WIDTH-1:0] out //single reduced sum value
  );
  
  localparam NUM_ADDER_STAGES = $clog2(NUM_INPUTS);
  localparam ACCUMULATOR_WIDTH = NUM_ADDER_STAGES+INPUT_WIDTH;
  
  //adder tree adder nets for each stage
  //unused nets will be discarded by the synthesis tool
  //must ensure to not connect the wires to do that
  logic signed [ACCUMULATOR_WIDTH-1:0] sum [0:NUM_ADDER_STAGES][0:NUM_INPUTS-1];
  
  //connect input and output of adder tree black box to external modules
  always_comb begin
    out = sum[NUM_ADDER_STAGES][0]; //output
    for(int i=0; i<NUM_INPUTS; i=i+1) //input
      sum[0][i] = in[i];
  end
  
  //adder stages (not radix-2)
  generate    
    for(genvar i=0; i<NUM_ADDER_STAGES; i=i+1)
      adder_tree_stage #(
        .NUM_INPUTS               ( `CEIL_DIV(NUM_INPUTS, 2**i) ),
        .ACCUMULATOR_WIDTH        ( INPUT_WIDTH+i+1 ),
        .INPUT_WIDTH              ( INPUT_WIDTH+i ),
        
        .TEMP_NUM_INPUTS          ( NUM_INPUTS ),
        .TEMP_ACCUMULATOR_WIDTH   ( ACCUMULATOR_WIDTH ))
      adder_stage(
        .clk          ( clk ),
        .arst_n_in    ( arst_n_in ),
        .in           ( sum[i] ),
        .out          ( sum[i+1]) );
  endgenerate
  
endmodule
