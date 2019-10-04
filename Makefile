IMAGE_NAME?=neuromation/base
DOCKER_RUN?=docker run -e PLATFORMAPI_SERVICE_HOST=test -t
ASSERT_COMMAND_FAILS=&& { echo "failure!"; exit 1; } || { echo "success!"; }

.PHONY: image
image:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME) -f targets/Dockerfile.python36-jupyter-pytorch-tensorflow-jupyterlab .

.PHONY: test
test:
	$(DOCKER_RUN) $(IMAGE_NAME) /bin/true
	# Test job timeout:
	# job exits within the timeout 3 sec (ok):
	$(DOCKER_RUN) -e JOB_TIMEOUT=3 -t $(IMAGE_NAME) sleep 1 && echo "success!"
	# job exits within the timeout sec (exit code 124):
	$(DOCKER_RUN) -e JOB_TIMEOUT=3 -t $(IMAGE_NAME) sleep 10 $(ASSERT_COMMAND_FAILS)
