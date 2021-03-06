//input wraps both top_chip and an external memory
//bandwidth to be counted is all bandwidth in and out of top_chip
module top_system #(
    parameter int IO_DATA_WIDTH       = 16,
    parameter int ACCUMULATION_WIDTH  = 32,
    parameter int EXT_MEM_HEIGHT      = 1<<20,
    parameter int EXT_MEM_WIDTH       = ACCUMULATION_WIDTH,
    parameter int ACTIVATIONS_WIDTH   = 1024,
    parameter int ACTIVATIONS_HEIGHT  = 1024,
    parameter int INPUT_NB_CHANNELS   = 64,
    parameter int OUTPUT_NB_CHANNELS  = 64,
    parameter int KERNEL_SIZE         = 3,
    parameter int SIMD_WIDTH          = 36
  )
  (
    input   logic clk,
    input   logic arst_n_in,  //asynchronous reset, active low
    
    //system inputs and outputs
    input   logic [IO_DATA_WIDTH-1:0] a_input,
    input   logic                     a_valid,
    output  logic                     a_ready,
    
    input   logic [IO_DATA_WIDTH-1:0] b_input,
    input   logic                     b_valid,
    output  logic                     b_ready,
    
    //output
    output  logic signed  [IO_DATA_WIDTH-1:0]               out,
    output  logic         [$clog2(ACTIVATIONS_WIDTH)-1:0]   output_x,
    output  logic         [$clog2(ACTIVATIONS_HEIGHT)-1:0]  output_y,
    output  logic         [$clog2(OUTPUT_NB_CHANNELS)-1:0]  output_ch,
    output  logic                                           output_valid,
    
    //status
    input   logic start,
    output  logic running
  );


  /*
  * internal signals between external memory and processor
  */
  logic unsigned  [$clog2(EXT_MEM_HEIGHT)-1:0]  ext_mem_read_addr;
  logic [EXT_MEM_WIDTH-1:0]                     ext_mem_qout;
  logic                                         ext_mem_read_en;
  
  logic unsigned  [$clog2(EXT_MEM_HEIGHT)-1:0]  ext_mem_write_addr;
  logic           [EXT_MEM_WIDTH-1:0]           ext_mem_din;
  logic                                         ext_mem_write_en;


  /*
  * external memory
  */
  memory #(
    .WIDTH                ( EXT_MEM_WIDTH ),
    .HEIGHT               ( EXT_MEM_HEIGHT ),
    .USED_AS_EXTERNAL_MEM ( 1 ))
  ext_mem(
    .clk(clk),
    
    .read_addr            ( ext_mem_read_addr ),
    .read_en              ( ext_mem_read_en ),
    .qout                 ( ext_mem_qout ),
    
    .write_addr           ( ext_mem_write_addr ),
    .din                  ( ext_mem_din ),
    .write_en             ( ext_mem_write_en ));


  /*
  * hardware accelerator
  */
  top_chip #(
    .IO_DATA_WIDTH        ( IO_DATA_WIDTH ),
    .ACCUMULATION_WIDTH   ( ACCUMULATION_WIDTH ),
    .EXT_MEM_HEIGHT       ( EXT_MEM_HEIGHT ),
    .EXT_MEM_WIDTH        ( EXT_MEM_WIDTH ),
    .ACTIVATIONS_WIDTH    ( ACTIVATIONS_WIDTH ),
    .ACTIVATIONS_HEIGHT   ( ACTIVATIONS_HEIGHT ),
    .INPUT_NB_CHANNELS    ( INPUT_NB_CHANNELS ),
    .OUTPUT_NB_CHANNELS   ( OUTPUT_NB_CHANNELS ),
    .KERNEL_SIZE          ( KERNEL_SIZE ),
    .SIMD_WIDTH           ( SIMD_WIDTH )) 
  top_chip(
    .clk                  ( clk ),
    .arst_n_in            ( arst_n_in ),
    
    .ext_mem_read_addr    ( ext_mem_read_addr ),
    .ext_mem_read_en      ( ext_mem_read_en ),
    .ext_mem_qout         ( ext_mem_qout ),
    .ext_mem_write_addr   ( ext_mem_write_addr ),
    .ext_mem_din          ( ext_mem_din ),
    .ext_mem_write_en     ( ext_mem_write_en ),
    
    .a_input              ( a_input ),
    .a_valid              ( a_valid ),
    .a_ready              ( a_ready ),
    .b_input              ( b_input ),
    .b_valid              ( b_valid ),
    .b_ready              ( b_ready ),
    
    .out                  ( out ),
    .output_valid         ( output_valid ),
    .output_x             ( output_x ),
    .output_y             ( output_y ),
    .output_ch            ( output_ch ),
    .start                ( start ),
    .running              ( running ));
    
endmodule
