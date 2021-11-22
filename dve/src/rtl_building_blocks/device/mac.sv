module mac #(
    parameter int A_WIDTH             = 16,
    parameter int B_WIDTH             = 16, 
    parameter int OUTPUT_WIDTH        = 38,
    parameter int OUTPUT_SCALE        = 0,
    parameter int VLEN                = 36
  )
  (
    input logic clk,
    input logic arst_n_in, //asynchronous reset, active low
    
    //input interface
    input logic input_valid,
    input logic signed [A_WIDTH-1:0] a [0:VLEN-1], 
    input logic signed [B_WIDTH-1:0] b [0:VLEN-1],
  
    //output
    output logic signed [OUTPUT_WIDTH-1:0] out
  );
  
  localparam INTERMEDIATE_WIDTH = A_WIDTH + B_WIDTH; //MUL result width
  localparam ACCUMULATOR_WIDTH = $clog2(VLEN)+INTERMEDIATE_WIDTH; //36 * 2^32 ~= 2^38
  
  //SIMD products (named nets)
  logic signed [INTERMEDIATE_WIDTH-1:0] products [0:VLEN-1];
  
  //SIMD multiplier array
  generate  
    for(genvar i=0; i<VLEN; i=i+1)   
      multiplier #(
        .A_WIDTH    ( A_WIDTH ),
        .B_WIDTH    ( B_WIDTH ),
        .OUT_WIDTH  ( INTERMEDIATE_WIDTH ),
        .OUT_SCALE  ( 0 ))
      mul(
        .a      ( a[i] ),
        .b      ( b[i] ),
        .out    ( products[i]) );
  endgenerate
  
  //accumulator
  logic signed [ACCUMULATOR_WIDTH-1:0] accumulator;
  
  //binary tree adder (not radix-2)
  //requires NUM_INPUTS*(1-2**-ceil(log2(NUM_INPUTS)) adders (35 adders for 36 multipliers)
  adder_tree #(
    .NUM_INPUTS     ( VLEN ),
    .INPUT_WIDTH    ( INTERMEDIATE_WIDTH ))
  sum(
    .clk          ( clk ),
    .arst_n_in    ( arst_n_in ),
    .in           ( products ),
    .out          ( accumulator ));
  
  //scaling
  assign out = accumulator >>> OUTPUT_SCALE;
 
endmodule
