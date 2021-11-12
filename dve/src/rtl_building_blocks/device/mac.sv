module mac #(
    parameter int A_WIDTH             = 16,
    parameter int B_WIDTH             = 16,
    parameter int ACCUMULATOR_WIDTH   = 32,
    parameter int OUTPUT_WIDTH        = 16,
    parameter int OUTPUT_SCALE        = 0
  )
  (
    input logic clk,
    input logic arst_n_in, //asynchronous reset, active low
    NUM_Mult_UNITS = 36;  
	NUM_add_UNITS = 35;  
    //input interface
	// mac 1 may array consisting out of 36 multiplies and 38 adders. 
	// asumme critical path lang enough for 1multiplier and 1adder
    input logic input_valid,
    //input logic accumulate_internal, //accumulate (accumulator <= a*b + accumulator) if high (1) or restart accumulation (accumulator <= a*b+0) if low (0)
    input logic [ACCUMULATOR_WIDTH-1:0] partial_sum_in,
    input logic signed [A_WIDTH-1:0] a [NUM_MAC_UNITS-1:0], // doe ik er hier dan ook 36 apart of 1 grote? // all weigts stay the same over 64 cycles
    input logic signed [B_WIDTH-1:0] b [NUM_MAC_UNITS-1:0]// all input activations for 1  kerel (36) // change every time
  
	  //output
    output logic signed [OUTPUT_WIDTH-1:0] out // slecht 1 'pixel' as output.
   );
  
  /*

                a -->  *  <-- b
                       |
                       |  ____________
                       \ /          __\______
                        +          /1___0__SEL\ <-- accumulate_internal
                        |           |   \------------ <-- partial_sum_in
                     ___|___________|----------> >> ---> out__
                    |  d            q  |
    input_valid --> |we       arst_n_in| <-- arst_n_in
                    |___clk____________|
                         |
                        clk
  */

generate 
genvar i; 
for (i=0; i< NUM_MAC_UNITS; i = i+1) 
 begin  multiply_block  
  logic signed [ACCUMULATOR_WIDTH-1:0] product [NUM_MAC_UNITS:0];
  multiplier #(
    .A_WIDTH(A_WIDTH),
    .B_WIDTH(B_WIDTH),
    .OUT_WIDTH(ACCUMULATOR_WIDTH),
    .OUT_SCALE(0))
  mul(
    .a(a[i]),
    .b(b[i]),
    .out(product[i]));
	end 
endgenerate



  //makes register with we accumulator_value_we, qout accumulator_value, din accumulator_value_next, clk clk and arst_n_in arst_n_in
  //see register.sv
  `REG(ACCUMULATOR_WIDTH, accumulator_value);
   //`REG(ACCUMULATOR_WIDTH, accumulator_value); zo gaan we er meerdere nodig hebben
  
  //assign accumulator_value_we = input_valid;
  logic signed [ACCUMULATOR_WIDTH-1:0] sum [34:0]; // 35 adders
  
  
  //assign accumulator_value_next = sum;


  logic signed [ACCUMULATOR_WIDTH-1:0] adder_a [34:0];
  logic signed [ACCUMULATOR_WIDTH-1:0] adder_b [34:0];
  //assign adder_b = accumulate_internal ? accumulator_value : partial_sum_in;
  
  
generate 
genvar i ;
  for (i=0; i< NUM_add_UNITS; i = i+1) 
  begin  add_block  
  
  adder #( 
    .A_WIDTH(ACCUMULATOR_WIDTH),
    .B_WIDTH(ACCUMULATOR_WIDTH),
    .OUT_WIDTH(ACCUMULATOR_WIDTH),
    .OUT_SCALE(0))
  add(
    .a(adder_a[i]),
    .b(adder_b[i]),
    .out(sum[i]));
  end
endgenerate 
  
  
  
// cyle 1 : multipy + 18 add
  

generate 
genvar i;
for (i=0; i< 18; i = i+1) begin 
 assign  adder_a[i] = product[i]
 end 
 endgenerate
 
 generate 
genvar i;
for (i=18; i< 36; i = i+1) begin 
 assign  adder_b[i-18] = product[i]
 end 
 endgenerate
 
 // put these 18 results in registers
 generate 
 genvar i;  
 for (i=0; i< 18; i = i+1) begin 
 `REG(ACCUMULATOR_WIDTH, sum[i]);
 end 
 endgenerate
 
// cycle 2, 9 adders , at the same time also new multiplications will be done, don't need to set something for that right ? 
 
  
 generate 
  genvar i;
   for (i=0; i< 9; i = i+1) 
   begin 
	assign  adder_a[i+18] = sum[i] // sum is nu register output, other name? 
	assign  adder_b[i+18] = sum[i+9]
   end 
endgenerate

// put in regs

 generate 
 genvar i;  
 for (i=18; i< 27; i = i+1) begin 
 `REG(ACCUMULATOR_WIDTH, sum[i]);
 end 
 endgenerate

// cycle 3  
   generate 
  genvar i;
   for (i=0; i< 4; i = i+1) 
   begin 
	assign  adder_a[i+27] = sum[i+18] // sum is nu register output, other name? 
	assign  adder_b[i+27] = sum[i+22]
   end 
endgenerate


// put in regs

 generate 
 genvar i;  
 for (i=26; i< 31; i = i+1) begin  // second reg for sum26? , this one is just pasted through this cycle.
 `REG(ACCUMULATOR_WIDTH, sum[i]);
 end 
 endgenerate 

// cycle 4 

   generate 
  genvar i;
   for (i=0; i< 2; i = i+1) 
   begin 
	assign  adder_a[i+31] = sum[i+26] // sum is nu register output, other name? 
	assign  adder_b[i+31] = sum[i+28]
   end 
endgenerate

// put in regs

 generate 
 genvar i;  
 for (i=30; i< 33; i = i+1) begin  // second reg for sum30 , this one is just pasted through this cycle.
 `REG(ACCUMULATOR_WIDTH, sum[i]);
 end 
 endgenerate 
  
  
// cycle 5 
  
 assign  adder_a[33] = sum[i+30] // sum is nu register output, other name? 
 assign  adder_b[33] = sum[i+31]

  
 `REG(ACCUMULATOR_WIDTH, sum[32]);
`REG(ACCUMULATOR_WIDTH, sum[33]);

// cycle 6 
  assign  adder_a[34] = sum[32] // sum is nu register output, other name? 
  assign  adder_b[34] = sum[33]
  
  assign out = sum[34];  // ook in register steken? 
  
 //assign out = accumulator_value >>> OUTPUT_SCALE;

endmodule
