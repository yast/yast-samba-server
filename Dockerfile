FROM yastdevel/ruby:sle15-sp1

RUN zypper --non-interactive in --no-recommends \
  perl-Crypt-SmbHash \
  yast2-samba-client

COPY . /usr/src/app

