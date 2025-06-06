
ARG from=alpine:3.13
FROM alpine:3.13 AS build

#
#  Install build tools
#
RUN apk update
RUN apk add git gcc make

#
#  Create build directory
#
RUN mkdir -p /usr/local/src/repositories
WORKDIR /usr/local/src/repositories

#
#  Shallow clone the FreeRADIUS source
#
ARG source=https://github.com/FreeRADIUS/freeradius-server.git
ARG release=v3.0.x

RUN git clone --depth 1 --single-branch --branch ${release} ${source}
WORKDIR freeradius-server

#
#  Install build dependencies
#
# essential
RUN apk update
RUN apk add libc-dev talloc-dev
RUN apk add openssl openssl-dev
RUN apk add linux-headers
# general
RUN apk add pcre-dev libidn-dev krb5-dev samba-dev curl-dev json-c-dev
RUN apk add openldap-dev unbound-dev
# languages
RUN apk add ruby-dev perl-dev python2-dev
# databases
RUN apk add hiredis-dev libmemcached-dev gdbm-dev libcouchbase-dev
# sql
RUN apk add postgresql-dev mariadb-dev unixodbc-dev sqlite-dev

#
#  Build the server
#
RUN ./configure --prefix=/opt
RUN make -j2
RUN make install
RUN rm /opt/lib/*.a

#
#  Clean environment and run the server
#
FROM ${from}
COPY --from=build /opt /opt

#
# These are needed for the server to start
#
RUN apk update \
    && apk add talloc libressl pcre libwbclient tzdata \
    \
#
#  Libraries that are needed dependent on which modules are used
#  Some of these (especially the languages) are huge. A reasonable
#  selection has been enabled here. If you use modules needing
#  other dependencies then install any others required in your
#  local Dockerfile.
#
    && apk add libcurl json-c libldap hiredis bash nano postgresql-dev\
#RUN apk add libidn krb5
#RUN apk add unbound-libs
#RUN apk add ruby-libs perl python2-dev
#RUN apk add libmemcached gdbm libcouchbase
#RUN apk add postgresql-dev mariadb-dev unixodbc-dev
    \
    && ln -s /opt/etc/raddb /etc/raddb

COPY ./raddb/ /opt/etc/raddb
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
RUN ln -s /etc/raddb/mods-available/sql /etc/raddb/mods-enabled/

EXPOSE 1812/udp 1813/udp
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["radiusd"]
