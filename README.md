Neuro Platform Base Image
====================

Base docker image used in [Neuro Platform Template](https://github.com/neuromation/cookiecutter-neuro-project/), deployed on DockerHub as [`neuromation/base`](https://hub.docker.com/r/neuromation/base).

Notes
-----
1. Please don't use this image outside [Neuro Platform](https://neu.ro/platform) as it might be insecure!
2. If the env variable `EXPOSE_SSH` is set, then **the unpassworded SSH server with root access** will start. Please don't use this image outside [Neuro Platform](https://neu.ro/platform).
3. By default, a container created from this image will run with a timeout 1 day. To tweak this behaviour, please set a non-zero value to env variable `JOB_TIMEOUT` (for example, `neuro run ... -e JOB_TIMEOUT=1h` for 1 hour timeout). To completely disable the timeout, please set `JOB_TIMEOUT=0`.

License
-------
This project is licensed under the terms of the [MIT License](/LICENSE)

Additional info
---------------
For more details, see [Neuro Platform documentation](https://neu.ro/docs)
