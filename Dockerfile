FROM registry.opensuse.org/yast/head/containers/yast-ruby:latest
RUN zypper --non-interactive in --no-recommends \
  perl-Crypt-SmbHash
COPY . /usr/src/app

