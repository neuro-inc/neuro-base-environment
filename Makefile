IMAGE_NAME ?= neuromation/base
DOCKERFILE_PATH ?= targets/python37-jupyter-pytorch-tensorflow-jupyterlab/Dockerfile
GIT_TAGS ?=


.PHONY: image_build
image_build:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py --cuda-ver=10.0 --cudnn-ver=cudnn7-devel --ubuntu-ver=ubuntu18.04 $(DOCKERFILE_PATH) tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME):built --cache-from $(IMAGE_NAME):latest -f $(DOCKERFILE_PATH) .

.PHONY: image_diff
image_diff:
	diff --color=always --side-by-side  $(DOCKERFILE_PATH).deepo $(DOCKERFILE_PATH)

.PHONY: image_deploy
image_deploy:
	@[ "${GIT_TAGS}" ] || { echo "Env var GIT_TAG must be set"; false; }
	for tag in $(shell echo $(GIT_TAGS) | tr "," " ") \
	  do \
		docker tag $(IMAGE_NAME):built $(IMAGE_NAME):$$tag \
	  	docker push $(IMAGE_NAME):$$tag \
	  done

.PHONY: image_pip_list
image_pip_list:
	docker run --tty --rm $(IMAGE_NAME) pip list
