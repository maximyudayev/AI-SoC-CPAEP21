// parameterized class
class Generator #(config_t cfg);

  mailbox #(Transaction_Feature #(cfg)) gen2drv_feature, gen2chk_feature;
  mailbox #(Transaction_Kernel #(cfg)) gen2drv_kernel, gen2chk_kernel;

  // class constructor
  function new( 
    mailbox #(Transaction_Feature #(cfg)) g2d_feature, g2c_feature,
    mailbox #( Transaction_Kernel #(cfg)) g2d_kernel, g2c_kernel
  );
    gen2drv_feature = g2d_feature;
    gen2drv_kernel  = g2d_kernel;

    gen2chk_feature = g2c_feature;
    gen2chk_kernel  = g2c_kernel;
  endfunction : new

  task run();
    // instantiate and randomize kernel once
    Transaction_Kernel #(cfg) tract_kernel;
    tract_kernel = new();
    tract_kernel.randomize();
    gen2drv_kernel.put(tract_kernel);
    gen2chk_kernel.put(tract_kernel);

    forever
    begin
      // instantiate and randomize features until simulation ends
      Transaction_Feature #(cfg) tract_feature;
      tract_feature = new();
      tract_feature.randomize();

      gen2drv_feature.put(tract_feature);
      gen2chk_feature.put(tract_feature);
    end
  endtask : run

endclass : Generator
