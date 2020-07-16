IMAGE_NAME?=neuromation/base
DOCKERFILE_NAME?=python36-jupyter-pytorch-tensorflow-jupyterlab

# Git helpers:
GIT_TAG=$(shell git tag -l --points-at HEAD)
GIT_TAG_NUM=$(shell echo "${GIT_TAG}" | wc -w)

# Shortcuts:
DOCKER_RUN?=docker run --tty --rm
ASSERT_COMMAND_FAILS=&& { echo -e 'Failure!\n'; exit 1; } || { echo -e 'Success!\n'; }
ASSERT_COMMAND_SUCCEEDS=&& echo -e 'Success!\n'

# Testing settings:
IMAGE_TEST_DOCKER_MOUNT_OPTION?=--volume=`pwd`/testing:/testing

.PHONY: dockerhub_login
dockerhub_login:
	[ "$${DOCKERHUB_NAME}" ]     || { echo "env var DOCKERHUB_NAME not set up.";     false; }
	[ "$${DOCKERHUB_PASSWORD}" ] || { echo "env var DOCKERHUB_PASSWORD not set up."; false; }
	docker login -u "$${DOCKERHUB_NAME}" -p "$${DOCKERHUB_PASSWORD}"

.PHONY: image_build
image_build:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py --cuda-ver=10.0 --cudnn-ver=cudnn7-devel --ubuntu-ver=ubuntu18.04 targets/$(DOCKERFILE_NAME)/Dockerfile-deepo tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME) -f targets/$(DOCKERFILE_NAME)/Dockerfile .

.PHONY: image_diff
image_diff:
	diff --color=always --side-by-side  targets/$(DOCKERFILE_NAME)/Dockerfile.deepo targets/$(DOCKERFILE_NAME)/Dockerfile

.PHONY: image_deploy
image_deploy:
	@[ "${GIT_TAG_NUM}" -eq 1 ] || { echo "Must be only 1 tag, found: ${GIT_TAG_NUM}; GIT_TAG='${GIT_TAG}'"; false; }
	docker tag ${IMAGE_NAME} ${IMAGE_NAME}:${GIT_TAG}
	docker push ${IMAGE_NAME}:${GIT_TAG}
	docker push ${IMAGE_NAME}:latest

.PHONY: image_pip_list
image_pip_list:
	$(DOCKER_RUN) $(IMAGE_NAME) pip list

.PHONY: generate_recipes
generate_recipes:
	python3 testing/generate_recipes.py targets/$(DOCKERFILE_NAME)/Dockerfile

.PHONY: test_dependencies_pip
test_dependencies_pip:
	# Note: `--network=host` is used for the Internet access (to use `pip install ...`)
	# however this prevents SSH to start (port 22 is already bind).
	# see https://github.com/neuromation/template-base-image/issues/21
	$(DOCKER_RUN) $(IMAGE_TEST_DOCKER_MOUNT_OPTION) --network=host --workdir=/testing $(IMAGE_NAME) python ./run_tests.py
