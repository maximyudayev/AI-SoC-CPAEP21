module adder_tree_stage #(
    parameter int NUM_INPUTS              = 36,
    parameter int ACCUMULATOR_WIDTH       = 33,
    parameter int INPUT_WIDTH             = 32,
    
    parameter int TEMP_NUM_INPUTS         = 36, 
    parameter int TEMP_ACCUMULATOR_WIDTH  = 38
  )
  (
    input   logic clk,
    input   logic arst_n_in, //asynchronous reset, active low
    
    input   logic signed  [TEMP_ACCUMULATOR_WIDTH-1:0] in   [0:TEMP_NUM_INPUTS-1],
    output  logic signed  [TEMP_ACCUMULATOR_WIDTH-1:0] out  [0:TEMP_NUM_INPUTS-1]
  );
  
  localparam NUM_ADDERS = NUM_INPUTS/2;
  
  //nets to connect inputs and outputs of adders to temporary oversized nets
  logic signed [INPUT_WIDTH-1:0]        operand  [0:NUM_INPUTS-1];
  logic signed [ACCUMULATOR_WIDTH-1:0]  result   [0:((NUM_INPUTS+2-1)/2)-1];
  
  //connect inputs and outputs of adder stage black box to the rest of the tree adder module
  always_comb
    for(int i=0; i<((NUM_INPUTS+2-1)/2); i=i+1) begin
      if(TEMP_ACCUMULATOR_WIDTH == ACCUMULATOR_WIDTH)
        out[i] = result[i];
      else begin
        out[i][TEMP_ACCUMULATOR_WIDTH-1:ACCUMULATOR_WIDTH] = 0;
        out[i][ACCUMULATOR_WIDTH-1:0] = result[i];
      end
    end
      
  //adder array
  generate
    for(genvar i=0; i<NUM_INPUTS; i=i+1) begin //each signal in that stage
      `REG(INPUT_WIDTH, partial_sum); //register in the critical path between adder stages for each operand
      assign partial_sum_next = in[i][INPUT_WIDTH-1:0];
      assign operand[i] = partial_sum;
      assign partial_sum_we = 1'b1; //register always enabled
    end
    
    for(genvar i=0; i<NUM_ADDERS; i=i+1) begin //each pair of signals in that stage, connect to adder
      adder #(
        .A_WIDTH(INPUT_WIDTH),
        .B_WIDTH(INPUT_WIDTH),
        .OUT_WIDTH(ACCUMULATOR_WIDTH), //each stage has an extra bit to account for double the range during add
        .OUT_SCALE(0))
      add(
        .a(operand[i*2]),
        .b(operand[i*2+1]),
        .out(result[i]));
    end
    
    if(NUM_ADDERS*2 < NUM_INPUTS) //orphan signal (only holds for binary adder tree. if 2+ ports are used, must be adjusted
      assign result[((NUM_INPUTS+2-1)/2)-1] = {operand[NUM_ADDERS*2][INPUT_WIDTH-1], operand[NUM_ADDERS*2]}; //duplicate MSB

  endgenerate
  
endmodule
