FROM debian:10.8-slim AS builder

ENV TERM=xterm
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y locales git wget vim gnupg gnupg1 gnupg2

## Set LOCALE to UTF8
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    dpkg-reconfigure locales && \
    /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8

RUN \
  wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && \
  dpkg -i erlang-solutions_2.0_all.deb && \
  rm erlang-solutions_2.0_all.deb && \
  apt-get update -y && \
  apt-get install -y esl-erlang elixir

RUN apt-get install -y build-essential

WORKDIR /app
ENV HOME /tmp/home

USER 1000:1000
CMD ["/bin/bash"]
