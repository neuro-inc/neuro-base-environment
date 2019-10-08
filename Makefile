IMAGE?=neuromation/base
DOCKERFILE?=targets/Dockerfile.python36-jupyter-pytorch-tensorflow-jupyterlab

# Testing settings:
DOCKER_MOUNT_OPTION?=--volume=`pwd`/testing:/testing
DOCKER_COMMAND?=python ./run_tests.py


.PHONY: image
image:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE) -f $(DOCKERFILE) .
	@echo ok


.PHONY: generate-recipes
generate-recipes:
	python3 testing/generate_recipes.py $(DOCKERFILE)
	git status


.PHONY: test
test:
	# Note: `--network=host` is used for the Internet access (to use `pip install ...`)
	# however this prevents SSH to start (port 22 is already bind).
	# see https://github.com/neuromation/template-base-image/issues/21
	docker run --tty --env PLATFORMAPI_SERVICE_HOST=test $(DOCKER_MOUNT_OPTION) --network=host --workdir=/testing $(IMAGE) $(DOCKER_COMMAND)
	@echo ok
