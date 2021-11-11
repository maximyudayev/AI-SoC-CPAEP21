//a simple pseudo-2 port memory (can read and write simultaneously)
//Feel free to write a single port memory (inout data, either write or read every cycle) to decrease your bandwidth
module memory #(
  parameter int WIDTH = 16,
  parameter int HEIGHT = 1,
  parameter bit USED_AS_EXTERNAL_MEM// for area, bandwidth and energy estimation
  )
  (
  input logic clk,

  //read port (0 cycle: there is no clock edge between changing the read_addr and the output)
  input logic unsigned[$clog2(HEIGHT)-1:0] read_addr,
  input logic read_en,
  output logic[WIDTH-1:0] qout,

  //write port (data is written on the rising clock edge)
  input logic unsigned[$clog2(HEIGHT)-1:0] write_addr,
  input logic [WIDTH-1:0] din,
  input logic write_en
  );


  //storage
  logic [WIDTH-1:0] data [0:HEIGHT-1];

  always @ (posedge clk) begin
    if (write_en) begin
        data[write_addr] <= din;
    end
  end

  assign qout = read_en ? data[read_addr] :'x ;

  //area logging
  initial begin
    #0;
    if(!USED_AS_EXTERNAL_MEM) begin
      if (HEIGHT<256) begin
        tbench_top.area += 17*WIDTH*HEIGHT;
        $display("%m added %d to area", 17*WIDTH*HEIGHT);
      end else begin
        tbench_top.area += 1*WIDTH*HEIGHT;
        $display("%m added %d to area", 1*WIDTH*HEIGHT);
      end
    end
  end

  //energy logging:
  always @(posedge clk) begin
    if(read_en)
      tbench_top.energy += WIDTH*(USED_AS_EXTERNAL_MEM?1:0.1);
  end
  always @(posedge clk) begin
    if(write_en)
      tbench_top.energy += WIDTH*(USED_AS_EXTERNAL_MEM?1:0.1);
  end

endmodule
