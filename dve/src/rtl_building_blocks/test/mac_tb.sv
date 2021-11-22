module mac_tb;
  //local parameters for module configuration
  localparam OPERAND_WIDTH      = 16;
  localparam VLEN               = 4;
  localparam PIPELINE_DEPTH     = $clog2(VLEN);
  localparam ACCUMULATOR_WIDTH  = OPERAND_WIDTH*2 + PIPELINE_DEPTH;
  localparam OUTPUT_SCALE       = 0;
  localparam CLK_PERIOD         = 20;
  
  //define DUT IO signals
  logic clk=0, arst_n_in, input_valid;
  logic [ACCUMULATOR_WIDTH-1:0] out;
  logic [OPERAND_WIDTH-1:0] a [0:VLEN-1];
  logic [OPERAND_WIDTH-1:0] b [0:VLEN-1];
  
  //instantiate DUT
  mac #(
    .A_WIDTH        ( OPERAND_WIDTH ),
    .B_WIDTH        ( OPERAND_WIDTH ),
    .OUTPUT_WIDTH   ( ACCUMULATOR_WIDTH ),
    .OUTPUT_SCALE   ( OUTPUT_SCALE ),
    .VLEN           ( VLEN ))
  mac(
    .clk            ( clk ),
    .arst_n_in      ( arst_n_in ),
    .input_valid    ( input_valid ),
    .a              ( a ),
    .b              ( b ),
    .out            ( out ));
  
  //simulator timescale setup
  initial $timeformat(-9, 3, "ns", 1);
  
  //provide clock signal for TB
  always #(CLK_PERIOD/2) clk = ~clk;
  
  //test vectors
  initial begin
    //reset the DUT
  	arst_n_in = 0;
  	input_valid = 1;
  	#50;
    arst_n_in = 1;
    
    $display("Starting MAC test");
    for(int i = 0; i<100; i++) begin
      longint long_a, long_b, long_out=0;
      
      for(int j = 0; j<VLEN; j++) begin  
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
      
      #((PIPELINE_DEPTH+1)*CLK_PERIOD); //result obtained with latency ceil(log2(N)), N operand vector width
      assert(long_out == out) else begin
        $display("Wrong: real %0x != %0x expected for", out, long_out);
      end
    end
    $finish;
  end
endmodule