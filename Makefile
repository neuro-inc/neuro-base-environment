IMAGE_NAME ?= neuromation/base
DOCKERFILE_VERSION ?= python37-jupyter-pytorch-tensorflow-jupyterlab
GIT_TAGS ?=


.PHONY: image_build
image_build:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py --cuda-ver=10.0 --cudnn-ver=cudnn7-devel --ubuntu-ver=ubuntu18.04 targets/$(DOCKERFILE_VERSION)/Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME):built --cache-from ubuntu -f targets/$(DOCKERFILE_VERSION)/Dockerfile .

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


TEST_IMAGE_NAME ?= image:e2e-$(IMAGE_NAME)
TEST_IMAGE_TAG ?= debug
TEST_STORAGE=storage:.neuro-base-environment


.PHONY: e2e_neuro_push
e2e_neuro_push:
	neuro push $(TEST_IMAGE_NAME):$(TEST_IMAGE_TAG)


TEST_SCRIPT=
.PHONY: _test_e2e
_test_e2e:
	neuro mkdir -p $(TEST_STORAGE)/
	neuro cp -u files/testing/$(TEST_SCRIPT) $(TEST_STORAGE)/
	neuro run -s gpu-small -v $(TEST_STORAGE):/var/storage $(TEST_IMAGE_NAME):$(TEST_IMAGE_TAG) python /var/storage/$(TEST_SCRIPT)


.PHONY: test_e2e_pytorch
test_e2e_pytorch: TEST_SCRIPT=gpu_pytorch.py
test_e2e_pytorch: _test_e2e

.PHONY: test_e2e_tensorflow
test_e2e_tensorflow: TEST_SCRIPT=gpu_tensorflow.py
test_e2e_tensorflow: _test_e2e
