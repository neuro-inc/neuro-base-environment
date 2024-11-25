TARGET_IMAGE_NAME ?= ghcr.io/neuro-inc/base
TARGET_IMAGE_TAGS ?=

TEST_IMAGE_NAME ?= image:e2e-neuro-base-environment
TEST_STORAGE ?= storage:.neuro-base-environment
TEST_STORAGE_SUFFIX := $(shell bash -c 'echo $$(date +"%Y-%m-%d--%H-%M-%S")-$$RANDOM')

BASE_IMAGE ?= nvidia/cuda:12.4.0-cudnn-devel-ubuntu24.04
BASE_IMAGE_TYPE ?=

DOCKERFILE ?= Dockerfile

.PHONY: setup
setup:
	pip install pre-commit
	pre-commit install

.PHONY: image_build
image_build:
	docker build --platform linux/amd64 \
		-t $(TARGET_IMAGE_NAME):built-$(BASE_IMAGE_TYPE) \
		--build-arg BASE_IMAGE=${BASE_IMAGE} \
		-f $(DOCKERFILE) .

.PHONY: image_deploy
image_deploy:
	@[ "${TARGET_IMAGE_TAGS}" ] || { echo "Env var TARGET_IMAGE_TAGS must be set"; false; }
	for t in $(shell echo $(TARGET_IMAGE_TAGS) | tr "," " "); do \
      docker tag $(TARGET_IMAGE_NAME):built-$(BASE_IMAGE_TYPE) $(TARGET_IMAGE_NAME):$$t && \
      docker push $(TARGET_IMAGE_NAME):$$t ; \
    done

.PHONY: e2e_neuro_push
e2e_neuro_push:
	apolo push $(TARGET_IMAGE_NAME):built-$(BASE_IMAGE_TYPE) $(TEST_IMAGE_NAME):$(BASE_IMAGE_TYPE)

TEST_PRESET ?= gpu-large
TEST_CMD ?= bash /var/storage/dependencies.sh
.PHONY: test_dependencies
test_dependencies:
	apolo mkdir -p $(TEST_STORAGE)/$(TEST_STORAGE_SUFFIX)
	apolo cp -ru files/testing/ -T $(TEST_STORAGE)/$(TEST_STORAGE_SUFFIX)
	apolo run \
		--pass-config \
		--schedule-timeout 20m \
	    -s $(TEST_PRESET) \
		-v $(TEST_STORAGE)/$(TEST_STORAGE_SUFFIX):/var/storage \
		--workdir /var/storage \
	    $(TEST_IMAGE_NAME):$(BASE_IMAGE_TYPE) -- $(TEST_CMD)
	apolo rm -r $(TEST_STORAGE)/$(TEST_STORAGE_SUFFIX)
