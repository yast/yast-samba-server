FROM yastdevel/ruby:sle12-sp5

RUN zypper --non-interactive in --no-recommends \
  perl-Crypt-SmbHash \
  yast2-samba-client

COPY . /usr/src/app

