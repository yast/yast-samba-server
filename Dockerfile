FROM registry.opensuse.org/yast/sle-15/sp2/containers/yast-ruby
RUN zypper --non-interactive in --no-recommends \
  perl-Crypt-SmbHash \
  yast2-samba-client
COPY . /usr/src/app

