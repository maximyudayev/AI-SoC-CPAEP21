module adder_tree_stage #(
    parameter int NUM_INPUTS        = 36,
    parameter int ACCUMULATOR_WIDTH = 33,
    parameter int INPUT_WIDTH       = 32
  )
  (
    input logic clk,
    input logic arst_n_in, //asynchronous reset, active low
    
    input logic signed [INPUT_WIDTH-1:0] in [0:NUM_INPUTS-1],
    output logic signed [ACCUMULATOR_WIDTH-1:0] out [0:((NUM_INPUTS+2-1)/2)-1]
  );
  
  localparam NUM_ADDERS = NUM_INPUTS/2;
  
  logic signed [INPUT_WIDTH-1:0] operand [0:NUM_INPUTS-1];
  
  //adder array
  generate
    for(genvar i=0; i<NUM_INPUTS; i=i+1) begin //each signal in that stage
      `REG(INPUT_WIDTH, partial_sum); //register in the critical path between adder stages for each operand
      assign partial_sum_next = in[i];
      assign operand[i] = partial_sum;
      assign partial_sum_we = 1'b1; //register always enabled
    end
    
    for(genvar i=0; i<NUM_ADDERS; i=i+1) begin //each pair of signals in that stage, connect to adder
      adder #(
        .A_WIDTH(INPUT_WIDTH),
        .B_WIDTH(INPUT_WIDTH),
        .OUT_WIDTH(INPUT_WIDTH+1), //each stage has an extra bit to account for double the range during add
        .OUT_SCALE(0))
      add(
        .a(operand[i*2]),
        .b(operand[i*2+1]),
        .out(out[i]));
    end
    for(genvar i=(NUM_ADDERS*2)-1; i<NUM_INPUTS-1; i=i+1) begin //each orphan signal in that stage, sign extend by 1 bit
      assign out[((NUM_INPUTS+2-1)/2)-1] = {operand[i][INPUT_WIDTH-1], operand[i]}; //duplicate MSB
    end
  endgenerate
  
endmodule
