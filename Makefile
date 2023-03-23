PROJECT=fft

# Directories
SRC_DIR = $(PROJECT)/src
INC_DIR = $(PROJECT)/include
OBJ_DIR = $(PROJECT)/obj
BIN_DIR = $(PROJECT)/bin
ASSET_DIR = assets
OUT_DIR = ../project/out

VEN_DIR = vendor

NVCC = nvcc
CXX = gcc
LIBS = -lcuda -lcufft

# CPP setup
DEBUG_FLAGS = -g -O0 -fno-omit-frame-pointer
RELEASE_FLAGS = -O3
CXXFLAGS = -std=c++17 -Wall -Wextra -pedantic $(DEBUG_FLAGS)
NVCCFLAGS = -std=c++17

INCLUDES = -I$(INC_DIR) -I/usr/local/cuda/include -I$(VEN_DIR)
CU_SRC_FILES := $(shell find $(SRC_DIR) -name '*.cu')
CU_OBJ_FILES := $(patsubst $(SRC_DIR)/%.cu,$(OBJ_DIR)/%.o,$(CU_SRC_FILES))

CPP_SRC_FILES := $(shell find $(SRC_DIR) -name '*.cpp')
CPP_OBJ_FILES := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(CPP_SRC_FILES))

SRC_FILES := $(CU_OBJ_FILES) $(CPP_SRC_FILES)
OBJ_FILES := $(CU_OBJ_FILES) $(CPP_OBJ_FILES)

TARGET = $(BIN_DIR)/$(PROJECT)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	@echo "Compiling $<"
	@mkdir -p $(dir $@)
	@$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cu
	@echo "Compiling $<"
	@mkdir -p $(dir $@)
	@$(NVCC) $(NVCCFLAGS) $(INCLUDES) -c $< -o $@

# Link target binary
$(TARGET): $(OBJ_FILES)
	@echo "Linking $@"
	@mkdir -p $(dir $@)
	@$(NVCC) $^ -o $@ $(LIBS)

all: clean run

log:
	@echo $(OBJ_FILES)

clean:
	rm -f $(TARGET)
	rm -rf $(OBJ_DIR)/*

build: $(TARGET)

run: $(TARGET)
	./$(TARGET) $(ASSET_DIR)/out.ppm $(ASSET_DIR)/finished
	# cp $(ASSET_DIR)/*.ppm $(OUT_DIR)
	