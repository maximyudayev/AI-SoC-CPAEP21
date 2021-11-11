module fifo #(
    parameter int WIDTH,
    parameter int LOG2_OF_DEPTH,
    parameter bit USE_AS_EXTERNAL_FIFO
  )
  (
    input  logic              clk,
    input  logic              arst_n_in, //asynchronous reset, active low
    //write port
    input  logic [WIDTH-1:0]  din,
    input  logic              input_valid, //write enable
    output logic              input_ready, // not fifo full

    output logic [WIDTH-1:0]  qout,
    output logic              output_valid, // not empty
    input  logic              output_ready  //read enable
  );

  logic write_effective;
  assign write_effective = input_valid && input_ready;

  //manual register instantiation example
  logic [LOG2_OF_DEPTH+1-1:0] write_addr, write_addr_next;
  logic write_addr_we;
  register #(.WIDTH(LOG2_OF_DEPTH+1))
  write_addr_r(
    .clk(clk),
    .arst_n_in(arst_n_in),
    .din(write_addr_next),
    .qout(write_addr),
    .we(write_addr_we));
  assign write_addr_we = write_effective;
  assign write_addr_next = write_addr + 1;

  logic read_effective;
  assign read_effective = output_valid && output_ready;

  //macro register instantion example
  `REG(LOG2_OF_DEPTH+1, read_addr);
  assign read_addr_we = read_effective;
  assign read_addr_next = read_addr + 1;

  //if write_addr - read_addr = 2**LOG2_OF_DEPTH = depth, then the fifo is full
  //if write_addr = read_addr, the fifo is empty
  logic [LOG2_OF_DEPTH+1-1:0] write_addr_limit;
  assign write_addr_limit = read_addr + (1 << LOG2_OF_DEPTH);
  assign input_ready = write_addr != write_addr_limit;
  assign output_valid = read_addr != write_addr;

  //actual memory to store the data
  memory #(.WIDTH(WIDTH), .HEIGHT(1<<LOG2_OF_DEPTH), .USED_AS_EXTERNAL_MEM(USE_AS_EXTERNAL_FIFO)) 
  fifo_mem(
    .clk(clk),
    .read_addr(read_addr),
    .read_en(output_ready),
    .qout(qout),
    .write_addr(write_addr),
    .write_en(write_effective),
    .din(din));

endmodule
