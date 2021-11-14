module mac_tb;
  //local parameters for module configuration
  localparam ACCUMULATOR_WIDTH  = 38;
  localparam OPERAND_WIDTH      = 16;
  localparam SIMD_WIDTH         = 36;
  localparam OUTPUT_SCALE       = 0;
  
  //define DUT IO signals
  logic clk=0, arst_n_in, input_valid;
  logic [ACCUMULATOR_WIDTH-1:0] out;
  logic [OPERAND_WIDTH-1:0] a, b [0:SIMD_WIDTH-1];
  
  //instantiate DUT
  mac #(
    .A_WIDTH(OPERAND_WIDTH),
    .B_WIDTH(OPERAND_WIDTH),
    .OUTPUT_WIDTH(ACCUMULATOR_WIDTH),
    .OUTPUT_SCALE(OUTPUT_SCALE),
    .SIMD_WIDTH(SIMD_WIDTH))
  MAC(
    .clk(clk),
    .arst_n_in(arst_n_in),
    .input_valid(input_valid),
    .a(a),
    .b(b),
    .out(out));
  
  //provide clock signal for TB
  always #10ns clk = ~clk;
  
  //test vectors
  initial begin
    //reset the DUT
  	arst_n_in = 0;
  	input_valid = 1;
  	#10;
    arst_n_in = 1;
    
    $display("Starting MAC test");
    for(int i = 0; i<100; i++) begin
      longint long_a, long_b, long_out=0;
      
      for(int j = 0; j<SIMD_WIDTH; j++) begin  
        std::randomize(long_a) with {long_a >= -(1<<(OPERAND_WIDTH-1)) && long_a < (1 << (OPERAND_WIDTH-1));};
        std::randomize(long_b) with {long_b >= -(1<<(OPERAND_WIDTH-1)) && long_b < (1 << (OPERAND_WIDTH-1));};
  
        a[j] = long_a; //place randomized values into the operand vectors
        b[j] = long_b;
          
        long_out += (long_a * long_b); //sum up the randomized values
      end
      
      long_out = long_out >>> OUTPUT_SCALE;
      long_out = unsigned'(long_out) % (1<<ACCUMULATOR_WIDTH);
      if(long_out >= (1<<ACCUMULATOR_WIDTH-1)) begin
        long_out -= (1<<ACCUMULATOR_WIDTH);
      end
      
      #6; //result obtained with latency ceil(log2(N)), N operand vector width
      assert(long_out == out) else begin
        $display("Wrong: real %0x != %0x expected for", out, long_out);
        for(int n = 0; n<SIMD_WIDTH; n++)
           $display("%0x (%0x) and %0x (%0x)", a[n], long_a[n], b[n], long_b[n]);
      end
    end
    $finish;
  end
endmodule