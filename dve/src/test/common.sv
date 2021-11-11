
typedef struct {
  int DATA_WIDTH         = 16;
  int ACCUMULATION_WIDTH = 32;
  int EXT_MEM_HEIGHT     = 1<<20;
  int EXT_MEM_WIDTH      = 32;
  int FEATURE_MAP_WIDTH  = 32;
  int FEATURE_MAP_HEIGHT = 32;
  int INPUT_NB_CHANNELS  = 16;
  int OUTPUT_NB_CHANNELS = 16;
  int KERNEL_SIZE        = 3;
} config_t;
