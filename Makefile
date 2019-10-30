IMAGE_NAME?=neuromation/base
DOCKERFILE?=targets/Dockerfile.python36-jupyter-pytorch-tensorflow-jupyterlab

# Shortcuts:
DOCKER_RUN?=docker run --env PLATFORMAPI_SERVICE_HOST=test --tty --rm
ASSERT_COMMAND_FAILS=&& { echo "failure!"; exit 1; } || { echo "success!"; }

# Testing settings:
TEST_IMAGE_DOCKER_MOUNT_OPTION?=--volume=`pwd`/testing:/testing


.PHONY: image
image:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME) -f $(DOCKERFILE) .


.PHONY: generate_recipes
generate_recipes:
	python3 testing/generate_recipes.py $(DOCKERFILE)


.PHONY: test_dependencies_pip
test_dependencies_pip:
	# Note: `--network=host` is used for the Internet access (to use `pip install ...`)
	# however this prevents SSH to start (port 22 is already bind).
	# see https://github.com/neuromation/template-base-image/issues/21
	$(DOCKER_RUN) $(TEST_IMAGE_DOCKER_MOUNT_OPTION) --network=host --workdir=/testing $(IMAGE_NAME) python ./run_tests.py

.PHONY: test_timeout
test_timeout:
	# job exits within the timeout 3 sec (ok):
	$(DOCKER_RUN) -e JOB_TIMEOUT=3 $(IMAGE_NAME) sleep 1 && echo "success!"
	# job exits within the timeout sec (exit code 124):
	$(DOCKER_RUN) -e JOB_TIMEOUT=3 $(IMAGE_NAME) sleep 10 $(ASSERT_COMMAND_FAILS)
