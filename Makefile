TARGET_IMAGE_NAME ?= neuromation/base
TARGET_IMAGE_TAGS ?=

TEST_IMAGE_NAME ?= image:e2e-neuro-base-environment
TEST_STORAGE ?= storage:.neuro-base-environment

BASE_IMAGE ?= nvidia/cuda:11.2.2-cudnn8-runtime-ubuntu20.04
BASE_IMAGE_TYPE ?=

.PHONY: image_build
image_build:
	docker build \
		-t $(TARGET_IMAGE_NAME):built-$(BASE_IMAGE_TYPE) \
		--build-arg BASE_IMAGE=${BASE_IMAGE} \
		-f Dockerfile .

.PHONY: image_deploy
image_deploy:
	@[ "${TARGET_IMAGE_TAGS}" ] || { echo "Env var TARGET_IMAGE_TAGS must be set"; false; }
	for t in $(shell echo $(TARGET_IMAGE_TAGS) | tr "," " "); do \
      docker tag $(TARGET_IMAGE_NAME):built-$(BASE_IMAGE_TYPE) $(TARGET_IMAGE_NAME):$$t && \
      docker push $(TARGET_IMAGE_NAME):$$t ; \
    done

.PHONY: image_pip_list
image_pip_list:
	docker run --tty --rm $(TARGET_IMAGE_NAME):built-$(BASE_IMAGE_TYPE) pip list

.PHONY: e2e_neuro_push
e2e_neuro_push:
	neuro push $(TARGET_IMAGE_NAME):built-$(BASE_IMAGE_TYPE) $(TEST_IMAGE_NAME):$(BASE_IMAGE_TYPE)

TEST_PRESET=cpu-small
TEST_CMD=
.PHONY: _test_e2e
_test_e2e:
	neuro mkdir -p $(TEST_STORAGE)/
	neuro cp -ru files/testing/ -T $(TEST_STORAGE)/
	neuro run \
		--pass-config \
	    -s $(TEST_PRESET) \
		-v $(TEST_STORAGE):/var/storage \
	    $(TEST_IMAGE_NAME):$(BASE_IMAGE_TYPE) \
		$(TEST_CMD)

.PHONY: test_e2e_pytorch
test_e2e_pytorch: TEST_CMD=python /var/storage/gpu_pytorch.py
test_e2e_pytorch: TEST_PRESET=gpu-k80-small-p
test_e2e_pytorch: _test_e2e

.PHONY: test_e2e_tensorflow
test_e2e_tensorflow: TEST_CMD=python /var/storage/gpu_tensorflow.py
test_e2e_tensorflow: TEST_PRESET=gpu-k80-small-p
test_e2e_tensorflow: _test_e2e

.PHONY: test_e2e_dependencies
test_e2e_dependencies: TEST_CMD=bash /var/storage/dependencies.sh
test_e2e_dependencies: _test_e2e
