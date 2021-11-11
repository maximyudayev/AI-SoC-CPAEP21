
class Environment #(config_t cfg);

  virtual intf #(cfg) intf_i;

  // instantiate TB blocks
  Generator #(cfg) gen;
  Driver    #(cfg) drv;
  Monitor   #(cfg) mon;
  Checker   #(cfg) chk;
  Scoreboard scb;

  // instantiate mailboxes for communication between TB blocks
  mailbox #(Transaction_Feature #(cfg)) gen2drv_feature, gen2chk_feature;
  mailbox #(Transaction_Kernel #(cfg)) gen2drv_kernel, gen2chk_kernel;
  mailbox #(Transaction_Output_Word #(cfg)) mon2chk;
  mailbox #(bit)chk2scb;

  // constructor
  function new(virtual intf #(cfg) i);

    intf_i = i;

    // construct mailboxes
    // number in the parantheses indicate the depth of mailboxes
    gen2drv_feature = new(5);
    gen2chk_feature = new(5);
    gen2drv_kernel  = new(5);
    gen2chk_kernel  = new(5);
    mon2chk         = new(5);
    chk2scb         = new(5);

    // construct TB blocks and pass mailboxes to be used for communication
    gen = new(gen2drv_feature, gen2chk_feature, gen2drv_kernel, gen2chk_kernel);
    drv = new(i, gen2drv_feature, gen2drv_kernel);
    mon = new(i, mon2chk);
    chk = new(gen2chk_feature, gen2chk_kernel, mon2chk, chk2scb);
    scb = new(chk2scb);
  endfunction : new


  //run task
  task run;
    $display("[ENV] start-of-life");
    pre_test();
    test();
    post_test();
    $display("[ENV] end-of-life");
    repeat (100) @(intf_i.cb);
    $finish;
  endtask

  task pre_test();
    drv.reset();
  endtask

  task test();
    // fork to run all the blocks in parallel
    fork
    begin
      fork
        gen.run();  // runs forever
        drv.run();  // runs forever
        mon.run();  // runs forever
        chk.run();  // runs forever
        scb.run();  // runs until NO_tests is reached
      join_any // join when scoreboard ends it's execution
      disable fork;
    end
    join
  endtask

  task post_test();
    scb.showReport();
  endtask

endclass : Environment
