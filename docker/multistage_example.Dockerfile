#
# BUILD RUN TIME
#
FROM python:3.8.6-buster AS build-image

RUN apt-get update -y && apt-get upgrade -y
RUN pip install --upgrade pip pipenv

WORKDIR /app
COPY Pipfile* ./
RUN pipenv install --system --deploy --clear

#
# APPLICATION RUN TIME
#
FROM python:3.8.6-slim-buster

ARG AIRFLOW_USER_HOME=/usr/local/airflow
ENV AIRFLOW_HOME ${AIRFLOW_USER_HOME}

RUN groupadd --gid 2000 airflow && useradd --gid 2000 -ms /bin/bash -d ${AIRFLOW_USER_HOME} airflow

RUN apt-get update -y && apt-get upgrade -y
RUN apt-get clean && rm -rf /var/cache/* /var/lib/apt/lists/* /var/lib/dpkg/*

COPY --from=build-image /usr/local/bin/ /usr/local/bin/
COPY --from=build-image /usr/local/lib/python3.8/site-packages/ /usr/local/lib/python3.8/site-packages/

WORKDIR ${AIRFLOW_USER_HOME}
COPY --chown=airflow:airflow airflow.cfg airflow.cfg
COPY --chown=airflow:airflow dags dags

USER airflow

ENV PYTHONPATH=${AIRFLOW_USER_HOME}
