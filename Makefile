BUILD_DIR := build

ifeq ($(IMG),)
IMGERROR = $(error Define the target image or device by setting IMG)
endif

# Flash chain loader onto image/device
flash: stage_one stage_two
	@echo $(IMGERROR) > /dev/null
	# Copy stage one onto image/device
	dd if=$(BUILD_DIR)/stage_one/stage_one.bin of=$(IMG)
	# Copy stage two onto image/device
	dd if=$(BUILD_DIR)/stage_two/stage_two.bin of=$(IMG) bs=512 seek=1

stage_one: setup
	nasm -f bin stage_one/stage_one.asm -o $(BUILD_DIR)/stage_one/stage_one.bin

stage_two: setup
	nasm -f bin stage_two/stage_two.asm -o $(BUILD_DIR)/stage_two/stage_two.bin

setup:
	-@mkdir -p $(BUILD_DIR)
	-@mkdir -p $(BUILD_DIR)/stage_one
	-@mkdir -p $(BUILD_DIR)/stage_two

clean:
	rm -rf $(BUILD_DIR)
