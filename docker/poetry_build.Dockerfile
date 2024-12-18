# Call using docker build -t $(DOCKER_DIST_IMAGE) --build-arg SSH_KEY="$(shell cat $(SSH_KEY) | tr ' ' '_')" --build-arg GIT_BRANCH=poetry .

#
# BUILD IMAGE
#
FROM python:3.10.6-slim AS build-image

RUN apt-get update -y && apt-get upgrade -y && apt-get -y install libpq-dev gcc build-essential curl git
RUN pip install --upgrade pip
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="${PATH}:/root/.local/bin/"

ARG SSH_KEY
RUN mkdir -p /root/.ssh \
    && (echo "${SSH_KEY} " | tr ' ' '\n' | tr '_' ' ' > /root/.ssh/id_rsa) \
    && chmod 600 /root/.ssh/id_rsa

WORKDIR /build
ARG GIT_BRANCH
RUN  git clone <ssh_repo> \
     && cd <dir> \ 
     && git checkout "${GIT_BRANCH}"
RUN cd <dir> && make build-python

#
# APPLICATION IMAGE
#
FROM python:3.10.6-slim
COPY --from=build-image /path/to/dir /app
ENV PATH="/app/.venv/bin/:$PATH"
