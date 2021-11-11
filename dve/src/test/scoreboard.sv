class Scoreboard;

  mailbox #(bit) chk2scb;

  int NO_tests;

  int no_tests_done;
  int no_tests_ok;
  int no_tests_nok;

  function new(mailbox #(bit) c2s);
    this.chk2scb = c2s;
    NO_tests = 1;
    no_tests_done = 0;
    no_tests_ok = 0;
    no_tests_nok = 0;
  endfunction : new


  task run;
    bit result;

    while (no_tests_done < NO_tests) begin
      chk2scb.get(result);
      no_tests_done++;
      if (result)
      begin
        no_tests_ok++;
        $display("[SCB] successful test registered");
      end else begin
        no_tests_nok++;
        $display("[SCB] unsuccessful test registered");
      end
      if(no_tests_done % 100 == 0) begin
        $display("[SCB] INTERMEDIATE:");
        showReport();
      end
    end

  endtask : run


  task showReport;
    $display("[SCB] Test report");
    $display("[SCB] ------------");
    $display("[SCB] # tests done         : %0d", no_tests_done);
    $display("[SCB] # tests ok           : %0d", no_tests_ok);
    $display("[SCB] # tests failed       : %0d", no_tests_nok);
    $display("[SCB] # tests success rate : %0.2f", 1.0*no_tests_ok/no_tests_done*100);
  endtask : showReport


endclass : Scoreboard
