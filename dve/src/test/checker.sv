
class Checker #(config_t cfg);

  localparam COUNT_ALL_OUTPUT= cfg.OUTPUT_NB_CHANNELS * cfg.FEATURE_MAP_WIDTH * cfg.FEATURE_MAP_HEIGHT;

  mailbox #(Transaction_Feature    #(cfg)) gen2chk_feature;
  mailbox #(Transaction_Kernel     #(cfg)) gen2chk_kernel;
  mailbox #(Transaction_Output_Word#(cfg)) mon2chk;
  mailbox #(bit) chk2scb;
  
  bit verbose= 0;

  function new(
      mailbox #(Transaction_Feature    #(cfg)) g2c_feature,
      mailbox #( Transaction_Kernel    #(cfg)) g2c_kernel,
      mailbox #(Transaction_Output_Word#(cfg)) m2c,
      mailbox #(bit) c2s
    );
    mon2chk         = m2c;
    gen2chk_feature = g2c_feature;
    gen2chk_kernel  = g2c_kernel;
    chk2scb         = c2s;
  endfunction : new

  // function to create golden reference output value.
  // output of this function is used to check if the DUT output is correct
  function logic signed [cfg.DATA_WIDTH -1 : 0]
    golden_output(
    logic signed [cfg.DATA_WIDTH - 1 : 0] inputs [0 : cfg.FEATURE_MAP_WIDTH - 1][0 : cfg.FEATURE_MAP_HEIGHT - 1][0 : cfg.INPUT_NB_CHANNELS-1],
    logic signed [cfg.DATA_WIDTH - 1 : 0] kernel [0 : cfg.KERNEL_SIZE - 1][0 : cfg.KERNEL_SIZE - 1][0 : cfg.INPUT_NB_CHANNELS - 1][0 : cfg.OUTPUT_NB_CHANNELS - 1],
    logic [$clog2(cfg.FEATURE_MAP_WIDTH)-1:0] output_x,
    logic [$clog2(cfg.FEATURE_MAP_HEIGHT)-1:0] output_y,
    logic [$clog2(cfg.OUTPUT_NB_CHANNELS)-1:0] output_ch

  );
    logic signed [cfg.DATA_WIDTH] expected;
    expected = 0;
    for(int inch=0  ;inch<cfg.INPUT_NB_CHANNELS ;inch++) begin
      for(int kx=0  ;kx<cfg.KERNEL_SIZE        ;kx++) begin
        for(int ky=0;ky<cfg.KERNEL_SIZE        ;ky++) begin
          logic signed [cfg.DATA_WIDTH-1:0] feature;
          logic signed [cfg.DATA_WIDTH-1:0] weight;
          logic signed [cfg.ACCUMULATION_WIDTH-1:0] prod;

          if( output_x+kx-cfg.KERNEL_SIZE/2 >= 0 && output_x+kx-cfg.KERNEL_SIZE/2 < cfg.FEATURE_MAP_WIDTH
            &&output_y+ky-cfg.KERNEL_SIZE/2 >= 0 && output_y+ky-cfg.KERNEL_SIZE/2 < cfg.FEATURE_MAP_HEIGHT)
            feature = inputs[output_y+ky-cfg.KERNEL_SIZE/2 ][output_x+kx-cfg.KERNEL_SIZE/2][inch];
          else
            feature = 0; // zero padding for boundary cases

          weight = kernel[ky][kx][inch][output_ch];
          prod = weight * feature;
          expected = expected + prod;
        end
      end
    end

    return expected;
  endfunction: golden_output

  task run;
    //  Get kernel from the Generator, only once
    Transaction_Kernel #(cfg) tract_kernel;
    gen2chk_kernel.get(tract_kernel);

    forever 
    begin
      Transaction_Feature #(cfg) tract_feature;

      // keep track of how many words are tested so far
      int count= 0;

      bit no_error_in_full_output_frame= 1;

      // output_tested makes sure that the same output word is not tested again
      bit output_tested [0:cfg.FEATURE_MAP_WIDTH-1][0:cfg.FEATURE_MAP_HEIGHT-1][0:cfg.OUTPUT_NB_CHANNELS-1];
      // initialize
      for(int x=0;x<cfg.FEATURE_MAP_WIDTH; x++) begin
        for(int y=0;y<cfg.FEATURE_MAP_HEIGHT; y++) begin
          for(int outch=0;outch<cfg.OUTPUT_NB_CHANNELS; outch++) begin
            output_tested[x][y][outch] = 0;
          end
        end
      end

      // get input feature from the Generator
      gen2chk_feature.get(tract_feature);
      forever // run until all the words for the current output are checked
      begin
        logic signed [cfg.DATA_WIDTH] expected;
        bit output_correct;
        Transaction_Output_Word #(cfg) tract_output;
        mon2chk.get(tract_output);

        expected = this.golden_output(tract_feature.inputs, tract_kernel.kernel,
                      tract_output.output_x, tract_output.output_y, tract_output.output_ch);

        // Make sure there are no Xs
        assert (!$isunknown(tract_output.output_data)) else $stop;
        assert (!$isunknown(tract_output.output_x)) else $stop;
        assert (!$isunknown(tract_output.output_y)) else $stop;
        assert (!$isunknown(tract_output.output_ch)) else $stop;
        assert (!$isunknown(expected)) else $stop;

        assert (!output_tested[tract_output.output_x][tract_output.output_y][tract_output.output_ch]) else
        begin
          $error("\
            An output word is being received twice, or dimensions output_x, etc are corrupted.\n\
            Possible problem with Monitor or driving of output_valid from DUT.\n\
            output_valid should be high for only 1 cycle for every valid output_data\n");
          $stop;
        end
        output_tested[tract_output.output_x][tract_output.output_y][tract_output.output_ch] = 1;

        output_correct = (expected == tract_output.output_data);
        no_error_in_full_output_frame = no_error_in_full_output_frame & output_correct;
        if(output_correct) begin
          if (verbose) $display("[CHK] Result is correct");
        end else begin
          $display("[CHK] Result is incorrect");
          $stop;
        end
        count++;
        if (count == COUNT_ALL_OUTPUT) begin
          break;
        end
      end
      if(no_error_in_full_output_frame) begin
        $display("[CHK] all the words in the current output are currect");
      end else begin
        $display("[CHK] NOT all the words in the current output are currect");
      end
      chk2scb.put(no_error_in_full_output_frame);
    end
  endtask

endclass : Checker
