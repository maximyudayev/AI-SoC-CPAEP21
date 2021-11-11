class Transaction_Feature #(config_t cfg);
  rand logic signed [cfg.DATA_WIDTH - 1 : 0] inputs [0 : cfg.FEATURE_MAP_WIDTH - 1][0 : cfg.FEATURE_MAP_HEIGHT - 1][0 : cfg.INPUT_NB_CHANNELS-1];
endclass

class Transaction_Kernel #(config_t cfg);
  rand logic signed [cfg.DATA_WIDTH - 1 : 0] kernel [0:cfg.KERNEL_SIZE - 1][0:cfg.KERNEL_SIZE - 1][0 : cfg.INPUT_NB_CHANNELS - 1][0 : cfg.OUTPUT_NB_CHANNELS - 1];
endclass

class Transaction_Output_Word #(config_t cfg);
  logic signed [cfg.DATA_WIDTH-1:0] output_data;
  logic [$clog2(cfg.FEATURE_MAP_WIDTH)-1:0] output_x;
  logic [$clog2(cfg.FEATURE_MAP_HEIGHT)-1:0] output_y;
  logic [$clog2(cfg.OUTPUT_NB_CHANNELS)-1:0] output_ch;
endclass
