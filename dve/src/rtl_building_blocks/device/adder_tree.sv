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
  
  localparam ACCUMULATOR_WIDTH = $clog2(NUM_INPUTS)+INPUT_WIDTH;
  
  //binary tree adder nets for each stage
  generate
    for(genvar n=0; n<=$clog2(NUM_INPUTS); n=n+1) begin : nets //7 nets for 6 stage tree, 0 <= n <= 6
      logic signed [INPUT_WIDTH+n-1:0] sum [0:((NUM_INPUTS+(2**n)-1)/(2**n))-1];
    end : nets
  endgenerate

  assign nets.sum[0] = in; //connect first net to input of adder tree
  assign out = nets.sum[$clog2(NUM_INPUTS)]; //connect module output to output of adder tree
  
  //adder stages (not radix-2)
  //orphan elements get sign extended before next stage
  generate    
    for(genvar i=0; i<$clog2(NUM_INPUTS); i=i+1)
      adder_tree_stage #(
        .NUM_INPUTS((NUM_INPUTS+(2**i)-1)/(2**i)), //number of inputs for that stage
        .ACCUMULATOR_WIDTH(INPUT_WIDTH+i+1), //each stage has an extra bit (to account for double the range during add)
        .INPUT_WIDTH(INPUT_WIDTH+i)) //input width for that stage
      adder_stage(
        .clk(clk),
        .arst_n_in(arst_n_in),
        .in(nets.sum[i]),
        .out(nets.sum[i+1]));
  endgenerate
  
//NOTE: Vivado cannot resolve hierarchical names. Alternative requires connecting signals by reference to generated blocks
//  //binary tree adder buffers for each stage
//  generate
//    for(genvar n=0; n<=$clog2(NUM_INPUTS); n=n+1) begin : adder_stage_buffer //7 nets for 6 stage tree, 0 <= n <= 6
//      for(genvar i=0; i<((NUM_INPUTS+(2**n)-1)/(2**n)); i=i+1) begin : adder_stage_buffer_inst //each signal in that stage
//        `REG(INPUT_WIDTH+n, partial_sum); //register in the critical path between adder stages for each operand
//        assign partial_sum_we = 1'b1; //register always enabled
//      end : adder_stage_buffer_inst
//    end : adder_stage_buffer
//  endgenerate
  
//  always @(*) begin
//    for(int j=0; j<$clog2(NUM_INPUTS); j=j+1)
//      for(int i=0; i<NUM_INPUTS; i=i+1) begin 
//        adder_stage_buffer[j].adder_stage_buffer_inst[i].partial_sum_next = in[i]; //connect first net to input of adder tree
//      end
    
//    assign out = nets[$clog2(NUM_INPUTS)].sum; //connect module output to output of adder tree
//  end
//  assign adder_stage_buffer[0].adder_stage_buffer_inst[].partial_sum_next = in[i];

endmodule
