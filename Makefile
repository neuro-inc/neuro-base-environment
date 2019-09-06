IMAGE_NAME?=neuromation/base-2

.PHONY: image
image:
	# git clone https://github.com/ufoym/deepo.git
	# python3 deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t $(IMAGE_NAME) -f targets/Dockerfile.python36-jupyter-pytorch-tensorflow-jupyterlab .

.PHONY: test
test:
	docker run -t $(IMAGE_NAME) -e PLATFORMAPI_SERVICE_HOST=test /bin/true

.PHONY: docker_push
docker_push:
	echo docker push $(IMAGE_NAME)

.PHONY: clean
clean:
	echo clean
	# rm -rf deepo
	# rm Dockerfile
