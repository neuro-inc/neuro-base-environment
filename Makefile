IMAGE_NAME?=neuromation/base
DOCKERFILE=targets/Dockerfile.python36-jupyter-pytorch-tensorflow-jupyterlab
PIP_CHECK_COMMANDS=`python3 get_pip_check_command.py $(DOCKERFILE)`

.PHONY: image
image:
	@echo Testing command: "$(PIP_CHECK_COMMANDS)"
	docker run -t nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04 bash -c $$"$(PIP_CHECK_COMMANDS)"
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME) -f $(DOCKERFILE) .

.PHONY: test
test:
	@echo $(PIP_CHECK_COMMANDS)
	docker run -e PLATFORMAPI_SERVICE_HOST=test -t $(IMAGE_NAME) bash -c $$"$(PIP_CHECK_COMMANDS)"
