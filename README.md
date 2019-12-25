Neuro Platform Base Image
====================

Base docker image used in [Neuro Platform Template](https://github.com/neuromation/cookiecutter-neuro-project/), deployed on DockerHub as [`neuromation/base`](https://hub.docker.com/r/neuromation/base).

Notes
-----
1. This image is designed for [Neuro Platform](https://neu.ro/platform) only. Running it on public machine might be insecure.
2. Setting environment variable `EXPOSE_SSH` enables SSH server with root account without password. This is safe to do within [Neuro Platform](https://neu.ro/platform), but very dangerous otherwise.
3. By default, a container created from this image will run with a timeout 1 day. To tweak this behaviour, please set a non-zero value to env variable `JOB_TIMEOUT` (for example, `neuro run ... -e JOB_TIMEOUT=1h` for 1 hour timeout). To completely disable the timeout, please set `JOB_TIMEOUT=0`.

License
-------
This project is licensed under the terms of the [Apache License](/LICENSE)

Additional info
---------------
For more details, see [Neuro Platform documentation](https://neu.ro/docs)
