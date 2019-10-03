IMAGE_NAME?=neuromation/base
DOCKERFILE=targets/Dockerfile.python36-jupyter-pytorch-tensorflow-jupyterlab
PIP_CHECK_COMMANDS=`python3 get_pip_check_command.py $(DOCKERFILE)`

.PHONY: image
image:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME) -f $(DOCKERFILE) .

.PHONY: test
test:
	@echo Testing command: $(PIP_CHECK_COMMANDS)
	@echo
	docker run -e PLATFORMAPI_SERVICE_HOST=test -t --entrypoint=bash $(IMAGE_NAME) -c "$(PIP_CHECK_COMMANDS)"
