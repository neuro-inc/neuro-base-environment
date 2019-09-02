.PHONY: image
image:
	git clone https://github.com/ufoym/deepo.git
	python3 deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t neuro/base .

.PHONY: test
test:
	docker run -t neuro/base /bin/true

.PHONY: docker_push
docker_push:
	echo docker push neuro/base

.PHONY: clean
clean:
	rm -rf deepo
	rm Dockerfile
