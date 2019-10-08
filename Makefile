IMAGE_NAME?=neuromation/base
DOCKERFILE?=targets/Dockerfile.python36-jupyter-pytorch-tensorflow-jupyterlab
TEST_COMMAND?=python ./run_tests.py
DOCKER_MOUNT_OPTION?=--volume=`pwd`/testing:/testing

.PHONY: image
image:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
# 	docker build -t $(IMAGE_NAME) -f $(DOCKERFILE) .
	@echo ok

.PHONY: generate-recipes
generate-recipes:
	python3 testing/generate_recipes.py $(DOCKERFILE)
	git status

.PHONY: test
test:
	docker run --tty --env PLATFORMAPI_SERVICE_HOST=test $(DOCKER_MOUNT_OPTION) --workdir /testing $(IMAGE_NAME) pwd
	docker run --tty --env PLATFORMAPI_SERVICE_HOST=test $(DOCKER_MOUNT_OPTION) --workdir /testing $(IMAGE_NAME) ls -la
	docker run --tty --env PLATFORMAPI_SERVICE_HOST=test $(DOCKER_MOUNT_OPTION) --workdir /testing $(IMAGE_NAME) ls -la /testing
# 	docker run --tty --env PLATFORMAPI_SERVICE_HOST=test $(DOCKER_MOUNT_OPTION) --workdir /testing $(IMAGE_NAME) $(TEST_COMMAND)
	@echo ok
