module controller_fsm #(
    parameter int MEM_ADDRESS_WIDTH   = 20,
    
    parameter int ACTIVATIONS_SIZE    = 64,
    parameter int INPUT_CHANNELS      = 4,
    parameter int PADDING             = 1,
    
    parameter int KERNEL_SIZE         = 3,
    parameter int NUM_FILTERS         = 32,
    parameter int STRIDE              = 1,
    
    parameter int OUTPUT_SIZE         = 64,
    
    parameter int VLEN                = 36,
    parameter int TB_BANDWIDTH        = 3,
    parameter int FETCH_BANDWIDTH     = 2
  )
  (
    input logic clk,
    input logic arst_n_in, //asynchronous reset, active low
    
    //startup handshake interface
    input logic start,
    output logic running,
  
    //memory control interface
    output logic mem_we,
    output logic [MEM_ADDRESS_WIDTH-1:0] mem_write_addr,
    output logic mem_re,
    output logic [MEM_ADDRESS_WIDTH-1:0] mem_read_addr,
  
    //datapath control interface & external handshaking communication of a and b
    //TODO: consider removing these signals -> outputs are clocked at each clock cycle with 7 cycle latency after prefetch state 
    input logic a_valid,
    input logic b_valid,
    output logic b_ready,
    output logic a_ready,
    output logic write_a,
    output logic write_b,
    output logic mac_valid,
    
    //output
    output logic output_valid,
    output logic [$clog2(OUTPUT_SIZE)-1:0] output_x,
    output logic [$clog2(OUTPUT_SIZE)-1:0] output_y,
    output logic [$clog2(NUM_FILTERS)-1:0] output_ch
  );
  
  //number of activations to load before starting MAC
  //overestimate that assumes prefetch BW of 2 words/cycle
  localparam NUM_PREFETCH   = ((ACTIVATIONS_SIZE**2)*(INPUT_CHANNELS**2) +
                              (ACTIVATIONS_SIZE+1)*INPUT_CHANNELS*FETCH_BANDWIDTH) /
                              (FETCH_BANDWIDTH+INPUT_CHANNELS); 
  //same thing, but in number of cycles
  //rounds up
  localparam ACTIVATION_PREFETCH_DELAY  = (NUM_PREFETCH+TB_BANDWIDTH-1)/TB_BANDWIDTH;
  localparam TOTAL_PREFETCH_DELAY       = (NUM_PREFETCH+(KERNEL_SIZE**2)*INPUT_CHANNELS+TB_BANDWIDTH-1)/TB_BANDWIDTH;
  
  //datapath latency of the pipelined MAC unit
  localparam MAC_LATENCY    = $clog2(VLEN)+1;

  /* chosen loop order:
  for ch_out //kernel stationary -> each weight involved in 64x64 computations vs 9x32 for activations
    for o_y //kernel slid across actvations
      for o_x
        parfor k_v //MAC of 36 simultaneous element pairs
        parfor k_h
        parfor ch_in
  */

  //loop counters
  `REG($clog2(OUTPUT_SIZE), x_out);
  `REG($clog2(OUTPUT_SIZE), y_out);
  `REG($clog2(NUM_FILTERS), ch_out);

  logic reset_x_out, reset_y_out, reset_ch_out;
  assign x_out_next   = reset_x_out ?   0 : x_out + 1;
  assign y_out_next   = reset_y_out ?   0 : y_out + 1;
  assign ch_out_next  = reset_ch_out ?  0 : ch_out + 1;

  logic last_x_out, last_y_out, last_ch_out;
  assign last_x_out   = x_out   == (ACTIVATIONS_SIZE - 1);
  assign last_y_out   = y_out   == (ACTIVATIONS_SIZE - 1);
  assign last_ch_out  = ch_out  == (NUM_FILTERS - 1);

  assign reset_x_out  = last_x_out;
  assign reset_y_out  = last_y_out;
  assign reset_ch_out = last_ch_out;
  
  assign x_out_we     = mac_valid; //each time a mac is done, x increments (or resets to 0 if last)
  assign y_out_we     = mac_valid && last_x_out;
  assign ch_out_we    = mac_valid && last_x_out && last_y_out; 
  
  //state definitions
  typedef enum {IDLE, PREFETCH, MAC} fsm_state;
  fsm_state current_state, next_state;
  
  //delays start of MAC until enough values were loaded on chip and placed into correct part of memory hierarchy
  `REG($clog2(TOTAL_PREFETCH_DELAY), prefetch_counter);
 
  logic reset_prefetch_counter;
  assign prefetch_counter_next      = reset_prefetch_counter ? 0 : prefetch_counter + 1;
  
  logic activations_prefetch_end, total_prefetch_end;
  assign activations_prefetch_end   = prefetch_counter == (ACTIVATION_PREFETCH_DELAY-1);
  assign total_prefetch_end         = prefetch_counter == (TOTAL_PREFETCH_DELAY-1);
  
  //delays marking outputs ready before the MAC pipeline fills up
  //also delays transition to IDLE to allow MAC pipeline to empty
  `REG($clog2(MAC_LATENCY), latency_counter_fill);
  `REG($clog2(MAC_LATENCY), latency_counter_empty);
  
  logic reset_latency_counter;
  assign latency_counter_fill_next  = reset_latency_counter ? 0 : latency_counter_fill + 1;
  assign latency_counter_empty_next = reset_latency_counter ? 0 : latency_counter_empty + 1;
  
  logic mac_pipe_fill, mac_pipe_empty;
  assign mac_pipe_fill  = latency_counter_fill != MAC_LATENCY-1;
  assign mac_pipe_empty = latency_counter_empty != MAC_LATENCY-1;
  
  logic last_overall, mac_end;
  assign last_overall = last_x_out && last_y_out && last_ch_out;
  assign mac_end      = last_overall && mac_pipe_empty;

  //mark outputs
  //mac valid after 7 cycles from entering MAC state
  assign output_valid = mac_pipe_fill && !mac_end;
  
  //Moore machine - state registers
  always @ (posedge clk or negedge arst_n_in) begin
    if(arst_n_in == 0) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  //next state update logic
  always_comb begin
    case (current_state)
      IDLE : 
        next_state = start ? PREFETCH : IDLE;
      PREFETCH : 
        next_state = total_prefetch_end ? MAC : PREFETCH;      
      MAC :
        next_state = mac_end ? IDLE : MAC;
      default :
        next_state = current_state;
    endcase
  end
  
  //state-specific logic
  always_comb begin
    case (current_state)
      IDLE : begin
        running = 0;
        
        //reset mac pipe latency counters
        reset_prefetch_counter = 1;
        reset_latency_counter = 1;
        //resets are synchronous, need to clock enable
        prefetch_counter_we = 1;
        latency_counter_fill_we = 1;
        latency_counter_empty_we = 1;
      end
      PREFETCH : begin
        
        reset_prefetch_counter = 0;
        prefetch_counter_we = !total_prefetch_end;

      end
      MAC : begin 
      //adjust FSM to load weights before activations and to load the last 7xBW words during the MAC state
      //to get first output when MAC state is entered
        reset_latency_counter = 0; //start MAC pipe latency counters
        latency_counter_fill_we = mac_pipe_fill;
        latency_counter_empty_we = mac_pipe_empty;
        
        if (output_valid) begin
          if (x_out >= MAC_LATENCY-1) begin
            output_x = x_out - (MAC_LATENCY-1);
            output_y = y_out;
            output_ch = ch_out;
          end else if (x_out < MAC_LATENCY-1 && ) begin
          
          end else begin
          
          end
          
        end else begin
          output_x = 0;
          output_y = 0;
          output_ch = 0;
        end
      end
      default : begin
        running = 1;
        reset_prefetch_counter = 1;

      end
    endcase
  end
  
endmodule
