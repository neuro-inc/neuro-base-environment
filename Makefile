IMAGE_NAME ?= neuromation/base
DOCKERFILE_VERSION ?= python37-jupyter-pytorch-tensorflow-jupyterlab
GIT_TAGS ?=

TEST_IMAGE ?= image:e2e-neuro-base-environment:debug
TEST_STORAGE ?= storage:.neuro-base-environment


.PHONY: image_build
image_build:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py --cuda-ver=10.0 --cudnn-ver=cudnn7-devel --ubuntu-ver=ubuntu18.04 targets/$(DOCKERFILE_VERSION)/Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME):built -f targets/$(DOCKERFILE_VERSION)/Dockerfile .

.PHONY: image_diff
image_diff:
	diff --color=always --side-by-side  targets/$(DOCKERFILE_VERSION)/Dockerfile.deepo targets/$(DOCKERFILE_VERSION)/Dockerfile ||:

.PHONY: image_deploy
image_deploy:
	@[ "${GIT_TAGS}" ] || { echo "Env var GIT_TAGS must be set"; false; }
	for t in $(shell echo $(GIT_TAGS) | tr "," " "); do \
      docker tag $(IMAGE_NAME):built $(IMAGE_NAME):$$t && \
      docker push $(IMAGE_NAME):$$t ; \
    done

.PHONY: image_pip_list
image_pip_list:
	docker run --tty --rm $(IMAGE_NAME) pip list

.PHONY: e2e_neuro_push
e2e_neuro_push:
	neuro push $(IMAGE_NAME):built $(TEST_IMAGE)

TEST_PRESET=cpu-small
TEST_CMD=
.PHONY: _test_e2e
_test_e2e:
	neuro mkdir -p $(TEST_STORAGE)/
	neuro cp -ru files/testing/ -T $(TEST_STORAGE)/
	neuro run \
	    -s $(TEST_PRESET) \
		-v $(TEST_STORAGE):/var/storage \
	    $(TEST_IMAGE) \
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
