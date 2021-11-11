module multiplier #(
  parameter int A_WIDTH = 16,
  parameter int B_WIDTH = 16,
  parameter int OUT_WIDTH = A_WIDTH + B_WIDTH,
  parameter int OUT_SCALE = 16
  )
  (
  input logic signed [A_WIDTH-1:0] a,
  input logic signed [B_WIDTH-1:0] b,
  output logic signed [OUT_WIDTH-1:0] out);

  localparam INTERMEDIATE_WIDTH = A_WIDTH + B_WIDTH;

  logic signed [INTERMEDIATE_WIDTH-1:0] a_extended;
  assign a_extended = a;
  logic signed [INTERMEDIATE_WIDTH-1:0] b_extended;
  assign b_extended = b;
  logic signed [INTERMEDIATE_WIDTH-1:0] unscaled_out;
  assign unscaled_out = a*b;


  logic signed [OUT_WIDTH-1:0] out_wo_delay;
  assign out_wo_delay = unscaled_out >>> OUT_SCALE;;

  always @(out_wo_delay) begin
    // random delay between 0 and 1 as both hold and setup simulation
    int delay_x100;
    std::randomize(delay_x100) with {delay_x100 dist {1:=1, [2:99]:/1};};
    fork begin
      fork begin
        #(delay_x100/100.0);
        out <= out_wo_delay;
      end begin
        @(posedge tbench_top.clk);
        $display("ERROR: rising clock edge detected while datapath is still busy. Your clock period is too short for your critical path! Increase it at the top of tbench_top.sv");
        $finish;
      end join_any;
      disable fork;
    end join;
  end

  //area logging
  initial begin
    #0;
    tbench_top.area += 5800;
    $display("%m added %d to area", 5800);
  end


endmodule
