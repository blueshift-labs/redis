#########################################################
# This image currently only works for dev env.
# Production configuration is not included.
#
# To build the image, do:
#   `docker build -t blueshift_labs/redis:3.2_rpush .`
#
# To run the container, do:
#   `docker run -itd -p 7001-7010:7001-7010 -e REDIS_MASTERS=3 -e REDIS_SLAVES=1 -e REDIS_START_PORT=7001 blueshift_labs/redis:3.2_rpush`
# By default:
#   REDIS_MASTERS=3
#   REDIS_SLAVES=1
#   REDIS_START_PORT=7001
#########################################################
#  For Mac Users, when connecting to the redis cluster.
#  Use the host of: $(docker-machine ip default)
#  For example: `redis-cli -c -h $(docker-machine ip default) -p 7001`
#########################################################

FROM ruby:2.1
MAINTAINER yang@getblueshift.com

# Add redis user
RUN adduser --home /home/redis --shell /bin/bash -gecos '' --disabled-password redis

# Install ruby client
RUN gem install redis -v 3.2

# Install packages
RUN \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y supervisor && \
  apt-get install -y build-essential && \
  apt-get install -y gcc make curl vim wget && \
  rm -rf /var/lib/apt/lists/*

# Build redis
RUN mkdir /home/redis/redis
COPY . /home/redis/redis
WORKDIR /home/redis/redis
RUN make && \
    chown -R redis.redis /home/redis && \
    chmod u+rwx /home/redis/redis/bootstrap/cluster.sh && \
    ln -s /home/redis/redis/src/redis-server /usr/local/bin/redis-server && \
    ln -s /home/redis/redis/src/redis-cli /usr/local/bin/redis-cli && \
    ln -s /home/redis/redis/src/redis-sentinel /usr/local/bin/redis-sentinel && \
    ln -s /home/redis/redis/src/redis-trib.rb /usr/local/bin/redis-trib

RUN mkdir -p /var/redis/data/ && \
    chown -R redis.redis /var/redis/data/

# Config supervisord
RUN mkdir -p /var/log/supervisor && \
    mkdir -p /etc/supervisor/conf.d && \
    ln -s /home/redis/redis/bootstrap/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set default ENV's
ENV REDIS_MASTERS 3
ENV REDIS_SLAVES 1
ENV REDIS_START_PORT 7001

CMD ["/usr/bin/supervisord"]
