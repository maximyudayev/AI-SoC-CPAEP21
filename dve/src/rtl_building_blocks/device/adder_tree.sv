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
  
  logic signed [ACCUMULATOR_WIDTH-1:0] temp [0:0]; //adder tree stage creates/outputs a bus
  assign out = temp[0]; //slice that bus into a single 16b signal that MAC output expects
  
  //adder stages (not radix-2)
  //orphan elements get sign extended before next stage
  generate    
    for(genvar i=0; i<NUM_ADDER_STAGES; i=i+1) begin : genaddstg
      
      if(i==0) begin //first stage
        logic signed [INPUT_WIDTH:0] sum [0:((NUM_INPUTS+(2**(i+1))-1)/(2**(i+1)))-1];
        adder_tree_stage #(
          .NUM_INPUTS((NUM_INPUTS+(2**i)-1)/(2**i)),
          .ACCUMULATOR_WIDTH(INPUT_WIDTH+1),
          .INPUT_WIDTH(INPUT_WIDTH))
        adder_stage(
          .clk(clk),
          .arst_n_in(arst_n_in),
          .in(in),
          .out(sum));
      end
      
      else if(i==NUM_ADDER_STAGES-1) begin //last stage
        adder_tree_stage #(
          .NUM_INPUTS((NUM_INPUTS+(2**i)-1)/(2**i)),
          .ACCUMULATOR_WIDTH(INPUT_WIDTH+i+1),
          .INPUT_WIDTH(INPUT_WIDTH+i))
        adder_stage(
          .clk(clk),
          .arst_n_in(arst_n_in),
          .in(genaddstg[i-1].sum),
          .out(temp));
      end
      
      else begin
        logic signed [INPUT_WIDTH+i:0] sum [0:((NUM_INPUTS+(2**(i+1))-1)/(2**(i+1)))-1];
        adder_tree_stage #(
          .NUM_INPUTS((NUM_INPUTS+(2**i)-1)/(2**i)), //number of inputs for that stage
          .ACCUMULATOR_WIDTH(INPUT_WIDTH+i+1), //each stage has an extra bit (to account for double the range during add)
          .INPUT_WIDTH(INPUT_WIDTH+i)) //input width for that stage
        adder_stage(
          .clk(clk),
          .arst_n_in(arst_n_in),
          .in(genaddstg[i-1].sum),
          .out(sum));
      end
      
    end : genaddstg
  endgenerate
endmodule
