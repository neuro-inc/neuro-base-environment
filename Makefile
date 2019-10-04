IMAGE_NAME?=neuromation/base

.PHONY: image
image:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME) -f targets/Dockerfile.python36-jupyter-pytorch-tensorflow-jupyterlab 

.PHONY: test
test:
	docker run -e PLATFORMAPI_SERVICE_HOST=test -t $(IMAGE_NAME) /bin/true
