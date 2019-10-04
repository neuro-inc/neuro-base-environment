IMAGE_NAME?=neuromation/base
DOCKERFILE=targets/Dockerfile.python36-jupyter-pytorch-tensorflow-jupyterlab

.PHONY: image
image:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME) -f $(DOCKERFILE) .

.PHONY: generate-recipes
generate-recipes:
	python3 generate_recipes.py $(DOCKERFILE)
	git status

.PHONY: test
test:
	docker run -e PLATFORMAPI_SERVICE_HOST=test --name=test-base-image -t $(IMAGE_NAME) bash

