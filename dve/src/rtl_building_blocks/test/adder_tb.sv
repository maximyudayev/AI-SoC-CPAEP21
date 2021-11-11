

//This is a simple testbench, not in object-oriented style.
//This is fine for a small, simple block such as this, but not for a more complex design


module adder_tb;
  localparam a_width = 30, b_width=14, out_width=15, out_scale=20;
  logic signed [a_width-1:0] a;
  logic signed [b_width-1:0] b;
  logic signed [out_width-1:0] out;
  adder #(.a_width(a_width), .b_width(b_width), .out_width(out_width), .out_scale(out_scale))
   dut (.a(a), .b(b), .out(out));

  initial begin
    $display("Starting tests");
    for(int i = 0; i<10000; i++) begin
      longint long_a, long_b, long_out;
      std::randomize(long_a) with {long_a >= -(1<<(a_width-1)) && long_a < (1 << (a_width-1));};
      std::randomize(long_b) with {long_b >= -(1<<(b_width-1)) && long_b < 1 << ((b_width-1));};

      a = long_a;
      b = long_b;
      #1;
      long_out = (long_a + long_b);
      long_out = long_out >>> out_scale;
      long_out = unsigned'(long_out) % (1<<out_width);
      if(long_out >= (1<<out_width-1)) begin
        long_out -= (1<<out_width);
      end
      assert(long_out == out) else $display("Wrong: real %0x != %0x expected for %0x (%0x) and %0x (%0x)", out, long_out, a , long_a, b, long_b);
    end
    $finish;
  end
endmodule
