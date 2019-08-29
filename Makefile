.PHONY: deepo
deepo:
	git clone https://github.com/ufoym/deepo.git
	python deepo/generator/generate.py Dockerfile tensorflow pytorch jupyter jupyterlab python==3.6
	docker build -t neuro/base .

.PHONY: clean
clean:
	rm -rf deepo
	rm Dockerfile
