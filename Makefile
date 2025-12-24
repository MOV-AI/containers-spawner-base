# Makefile for MOV.AI Spawner Base Docker Images
# Active flavors: noetic, ign-noetic, humble

# Configuration
REGISTRY ?= movai-spawner
DOCKER_PLATFORMS ?= linux/amd64
BUILD_OPTIONS ?= --pull --progress=plain #--no-cache

# Active image tags
NOETIC_TAG = $(REGISTRY):noetic
IGN_NOETIC_TAG = $(REGISTRY):ign-noetic
HUMBLE_TAG = $(REGISTRY):humble
HUMBLE_PYTHON38_TAG = $(REGISTRY):humble-python38

# All image tags
ALL_TAGS = $(NOETIC_TAG) $(IGN_NOETIC_TAG) $(HUMBLE_TAG) $(HUMBLE_PYTHON38_TAG)

.PHONY: help build build-all run test clean setup-multiarch
.PHONY: build-noetic build-ign-noetic build-humble build-humble-python38
.PHONY: run-noetic run-ign-noetic run-humble run-humble-python38
.PHONY: test-noetic test-ign-noetic test-humble test-humble-python38
.PHONY: buildx-all push-all

# Default target
help:
	@echo "MOV.AI Spawner Base Docker Images Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  help                	- Show this help message"
	@echo ""
	@echo "Active Build targets:"
	@echo "  build-all           	- Build all active image flavors"
	@echo "  build-noetic        	- Build noetic flavor (ROS Noetic)"
	@echo "  build-ign-noetic         	- Build ign-noetic flavor (Ignition Noetic)"
	@echo "  build-humble        	- Build humble flavor (ROS2 Humble)"
	@echo "  build-humble-python38 	- Build humble flavor with Python 3.8"
	@echo ""
	@echo "Run targets:"
	@echo "  run-<flavor>        - Run interactive container for specific flavor"
	@echo ""
	@echo "Test targets:"
	@echo "  test-all            - Test all active image flavors"
	@echo "  test-<flavor>       - Test specific flavor with verification"
	@echo ""
	@echo "Multi-arch targets:"
	@echo "  setup-multiarch     - Setup Docker buildx for multi-arch builds"
	@echo "  buildx-all          - Build all flavors for multiple architectures"
	@echo "  push-all            - Build and push all flavors to registry"
	@echo ""
	@echo "Utility targets:"
	@echo "  clean               - Remove all built images"
	@echo ""
	@echo "Environment variables:"
	@echo "  REGISTRY            - Docker registry/image prefix (default: movai-spawner)"
	@echo "  DOCKER_PLATFORMS    - Target platforms for buildx (default: linux/amd64)"

# Active Build targets
build-all: build-noetic build-ign-noetic build-humble build-humble-python38
build-noetic:
	@echo "Building MOV.AI Spawner Base Noetic (ROS Noetic)..."
	docker build $(BUILD_OPTIONS) -t $(NOETIC_TAG) -f docker/noetic/Dockerfile --target spawner .

build-ign-noetic:
	@echo "Building MOV.AI Spawner Base Ignition Noetic (Ignition Noetic)..."
	docker build $(BUILD_OPTIONS) -t $(IGN_NOETIC_TAG) -f docker/noetic/Dockerfile --target spawner-ign .

build-humble:
	@echo "Building MOV.AI Spawner Base Humble (ROS2 Humble)..."
	docker build $(BUILD_OPTIONS) -t $(HUMBLE_TAG) -f docker/humble/Dockerfile --target spawner .

build-ign-humble:
	@echo "Building MOV.AI Spawner Base Humble (ROS2 Humble)..."
	docker build $(BUILD_OPTIONS) -t $(HUMBLE_TAG) -f docker/humble/Dockerfile --target spawner-ign .

build-humble-python38:
	@echo "Building MOV.AI Spawner Base Humble with Python 3.8..."
	docker build $(BUILD_OPTIONS) -t $(HUMBLE_PYTHON38_TAG) --target humble-python38 -f docker/humble/Dockerfile .

# Run targets - Start interactive containers
run-noetic: build-noetic
	@echo "Starting interactive noetic container..."
	docker run --rm -it --user movai $(NOETIC_TAG) bash

run-ign-noetic: build-ign-noetic
	@echo "Starting interactive ign-noetic container..."
	docker run --rm -it --user movai $(IGN_NOETIC_TAG) bash

run-humble: build-humble
	@echo "Starting interactive humble container..."
	docker run --rm -it --user movai $(HUMBLE_TAG) bash

run-humble-python38: build-humble-python38
	@echo "Starting interactive humble-python38 container..."
	docker run --rm -it --user movai $(HUMBLE_PYTHON38_TAG) bash

# Use container-structure-test for image verification
CONTAINER_STRUCTURE_TEST ?= container-structure-test

# Test targets - Run verification tests (only active flavors)
test-all: test-noetic test-humble test-humble-python38 test-ign-noetic

test-noetic: build-noetic
	@echo "Testing noetic image with container-structure-test..."
	@$(CONTAINER_STRUCTURE_TEST) test --image $(NOETIC_TAG) --config tests/test-noetic.yaml

test-humble: build-humble
	@echo "Testing humble image with container-structure-test..."
	@$(CONTAINER_STRUCTURE_TEST) test --image $(HUMBLE_TAG) --config tests/test-humble.yaml

test-humble-python38: build-humble-python38
	@echo "Testing humble-python38 image with container-structure-test..."
	@$(CONTAINER_STRUCTURE_TEST) test --image $(HUMBLE_PYTHON38_TAG) --config tests/test-humble-python38.yaml

test-ign-noetic: build-ign-noetic
	@echo "Testing ign-noetic image with container-structure-test..."
	@$(CONTAINER_STRUCTURE_TEST) test --image $(IGN_NOETIC_TAG) --config tests/test-ign-noetic.yaml

# Multi-architecture build setup
setup-multiarch:
	@echo "Setting up Docker buildx for multi-architecture builds..."
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx create --name multiarch --driver docker-container --use || true
	docker buildx inspect --bootstrap

# Multi-architecture builds
buildx-all: setup-multiarch
	@echo "Building all flavors for multiple architectures..."
	docker buildx build $(BUILD_OPTIONS) --load --platform $(DOCKER_PLATFORMS) -t $(NOETIC_TAG) -f docker/noetic/Dockerfile .
	docker buildx build $(BUILD_OPTIONS) --load --platform $(DOCKER_PLATFORMS) -t $(IGN_NOETIC_TAG) -f docker/noetic/Dockerfile .
	docker buildx build $(BUILD_OPTIONS) --load --platform $(DOCKER_PLATFORMS) -t $(HUMBLE_TAG) -f docker/humble/Dockerfile .
	docker buildx build $(BUILD_OPTIONS) --load --platform $(DOCKER_PLATFORMS) -t $(HUMBLE_PYTHON38_TAG) --target humble-python38 -f docker/humble/Dockerfile .

# Push all images (includes building)
push-all: setup-multiarch
	@echo "Building and pushing all flavors for multiple architectures..."
	docker buildx build $(BUILD_OPTIONS) --push --platform $(DOCKER_PLATFORMS) -t $(NOETIC_TAG) -f docker/noetic/Dockerfile .
	docker buildx build $(BUILD_OPTIONS) --push --platform $(DOCKER_PLATFORMS) -t $(IGN_NOETIC_TAG) -f docker/noetic/Dockerfile .
	docker buildx build $(BUILD_OPTIONS) --push --platform $(DOCKER_PLATFORMS) -t $(HUMBLE_TAG) -f docker/humble/Dockerfile .
	docker buildx build $(BUILD_OPTIONS) --push --platform $(DOCKER_PLATFORMS) -t $(HUMBLE_PYTHON38_TAG) --target humble-python38 -f docker/humble/Dockerfile .
print-sizes:
	@echo "images sizes:"
	@docker images $(REGISTRY) --format "{{.Repository}}\t{{.Tag}}\t{{.Size}}"

check-main-images-sizes:
	@MAX_SIZE_MB=1250; \
	for tag in $(ALL_TAGS); do \
		size=$$(docker images $$tag --format "{{.Size}}" | sed 's/MB//;s/GB/*1024/' | bc); \
		if [ -z "$$size" ]; then \
			echo "Image $$tag does not exist. Skipping size check."; \
			continue; \
		fi; \
		echo "Checking image:$$tag, size:$$size MB < $$MAX_SIZE_MB MB"; \
		awk_result=$$(awk -v s="$$size" -v m="$$MAX_SIZE_MB" 'BEGIN {if (s > m) exit 1; else exit 0}'); \
		if [ $$? -ne 0 ]; then \
			echo "Error: Image $$tag size $${size}MB exceeds limit of $${MAX_SIZE_MB}MB"; \
			exit 1; \
		else \
			echo "Image $$tag size $${size}MB is within limit."; \
		fi \
	done

# Clean up built images
clean:
	@echo "Removing all MOV.AI base images..."
	docker rmi $(ALL_TAGS)
	@echo "Cleanup complete"

# Quick build shortcuts
build: build-all
run: run-humble
test: test-all
