

//This is a simple testbench, not in object-oriented style.
//This is fine for a small, simple block such as this, but not for a more complex design


module fifo_tb;

  logic clk = 0;
  always #0.5ns clk = ~clk;
  logic arst_n;
  initial begin
    #1ns;
    arst_n = 0;
    #2ns;
    @(posedge clk);
    #0.1ns;
    arst_n = 1;
  end


  logic [32-1:0] to_fifo, from_fifo;
  logic we, re;
  logic fifo_ready;
  logic fifo_valid;
  fifo #(.WIDTH(32), .LOG2_OF_DEPTH(3)) dut
    (.clk(clk),
    .arst_n_in(arst_n),
    .din(to_fifo),
    .input_valid(we),
    .input_ready(fifo_ready),

    .output_ready(re),
    .output_valid(fifo_valid),
    .qout(from_fifo));

  mailbox #(logic [32-1:0]) sw_fifo = new();



  //write
  initial begin
    we = 0;
    @(posedge clk iff arst_n);
    repeat(10000) begin
      repeat ($urandom() % 16) begin
        @(posedge clk);
        std::randomize(to_fifo);
      end
      we = 1;
      @(posedge clk iff fifo_ready);
      sw_fifo.put(to_fifo);
      std::randomize(to_fifo);
      we = 0;
    end
  end

  //read;
  initial begin
    logic [31:0] from_sw_fifo;
    re = 0;
    @(posedge clk iff arst_n);
    repeat(10000) begin
      sw_fifo.get(from_sw_fifo);
      repeat ($urandom() % 16) begin
        @(posedge clk);
      end
      re = 1;
      @(posedge clk iff fifo_valid);
      assert(from_sw_fifo == from_fifo) else $display("real %0x != %0x expected at time %t", from_fifo, from_sw_fifo, $time);
      re = 0;
    end
    $finish();
  end

endmodule;
