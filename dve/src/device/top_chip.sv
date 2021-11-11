module top_chip #(
    parameter int IO_DATA_WIDTH = 16,
    parameter int ACCUMULATION_WIDTH = 32,
    parameter int EXT_MEM_HEIGHT = 1<<20,
    parameter int EXT_MEM_WIDTH = ACCUMULATION_WIDTH,
    parameter int FEATURE_MAP_WIDTH = 1024,
    parameter int FEATURE_MAP_HEIGHT = 1024,
    parameter int INPUT_NB_CHANNELS = 64,
    parameter int OUTPUT_NB_CHANNELS = 64,
    parameter int KERNEL_SIZE = 3
  )
  (input logic clk,
   input logic arst_n_in,  //asynchronous reset, active low

   //external_memory
   //read port
   output logic unsigned[$clog2(EXT_MEM_HEIGHT)-1:0] ext_mem_read_addr,
   output logic ext_mem_read_en,
   input logic[EXT_MEM_WIDTH-1:0] ext_mem_qout,

   //write port
   output logic unsigned[$clog2(EXT_MEM_HEIGHT)-1:0] ext_mem_write_addr,
   output logic [EXT_MEM_WIDTH-1:0] ext_mem_din,
   output logic ext_mem_write_en,

   //system inputs and outputs
   input logic [IO_DATA_WIDTH-1:0] a_input,
   input logic a_valid,
   output logic a_ready,
   input logic [IO_DATA_WIDTH-1:0] b_input,
   input logic b_valid,
   output logic b_ready,

   //output
   output logic signed [IO_DATA_WIDTH-1:0] out,
   output logic output_valid,
   output logic [$clog2(FEATURE_MAP_WIDTH)-1:0] output_x,
   output logic [$clog2(FEATURE_MAP_HEIGHT)-1:0] output_y,
   output logic [$clog2(OUTPUT_NB_CHANNELS)-1:0] output_ch,


   input logic start,
   output logic running
  );


  logic write_a;
  logic write_b;

  `REG(IO_DATA_WIDTH, a);
  `REG(IO_DATA_WIDTH, b);
  assign a_next = a_input;
  assign b_next = b_input;
  assign a_we = write_a;
  assign b_we = write_b;

  logic mac_valid;
  logic mac_accumulate_internal;
  logic mac_accumulate_with_0;


  controller_fsm #(
  .LOG2_OF_MEM_HEIGHT($clog2(EXT_MEM_HEIGHT)),
  .FEATURE_MAP_WIDTH(FEATURE_MAP_WIDTH),
  .FEATURE_MAP_HEIGHT(FEATURE_MAP_HEIGHT),
  .INPUT_NB_CHANNELS(INPUT_NB_CHANNELS),
  .OUTPUT_NB_CHANNELS(OUTPUT_NB_CHANNELS),
  .KERNEL_SIZE(KERNEL_SIZE)
  )
  controller
  (.clk(clk),
  .arst_n_in(arst_n_in),
  .start(start),
  .running(running),

  .mem_we(ext_mem_write_en),
  .mem_write_addr(ext_mem_write_addr),
  .mem_re(ext_mem_read_en),
  .mem_read_addr(ext_mem_read_addr),

  .a_valid(a_valid),
  .a_ready(a_ready),
  .b_valid(b_valid),
  .b_ready(b_ready),
  .write_a(write_a),
  .write_b(write_b),
  .mac_valid(mac_valid),
  .mac_accumulate_internal(mac_accumulate_internal),
  .mac_accumulate_with_0(mac_accumulate_with_0),

  .output_valid(output_valid),
  .output_x(output_x),
  .output_y(output_y),
  .output_ch(output_ch)

  );



  logic signed [ACCUMULATION_WIDTH-1:0] mac_partial_sum;
  assign mac_partial_sum = mac_accumulate_with_0 ? 0 : ext_mem_qout;

  logic signed [ACCUMULATION_WIDTH-1:0] mac_out;
  assign ext_mem_dout = mac_out;

  mac #(
    .A_WIDTH(IO_DATA_WIDTH),
    .B_WIDTH(IO_DATA_WIDTH),
    .ACCUMULATOR_WIDTH(ACCUMULATION_WIDTH),
    .OUTPUT_WIDTH(ACCUMULATION_WIDTH),
    .OUTPUT_SCALE(0)
  )
  mac_unit
  (.clk(clk),
   .arst_n_in(arst_n_in),

   .input_valid(mac_valid),
   .accumulate_internal(mac_accumulate_internal),
   .partial_sum_in(mac_partial_sum),
   .a(a),
   .b(b),
   .out(mac_out));

  assign out = mac_out;
  assign ext_mem_din = mac_out;

endmodule
