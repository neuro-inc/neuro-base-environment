IMAGE_NAME?=neuromation/base
DOCKERFILE=targets/Dockerfile.python36-jupyter-pytorch-tensorflow-jupyterlab
TEST_COMMAND=bash -c $$"`./get_pip_check_command.py $(DOCKERFILE)`"

.PHONY: image
image:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME) -f $(DOCKERFILE) .

.PHONY: test
test:
	docker run -e PLATFORMAPI_SERVICE_HOST=test -t $(IMAGE_NAME) $(TEST_COMMAND) 
