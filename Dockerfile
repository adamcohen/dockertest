# Update dockertest and <REPLACEME> fields
# All docker images should pull a defined image version.

# dockertest
FROM node:8-alpine

ARG DOCKER_QUIET='--quiet'
ENV APP=dockertest

## nodejs
WORKDIR /usr/src/app

COPY . .

ARG NPM_TOKEN=""
ARG OPS_NPM_TOKEN=""

RUN apk update >/dev/null \
    && apk add --no-cache bash \
    && apk --no-cache add git make python g++ libc6-compat >/dev/null \
    && if [ -n "$OPS_NPM_TOKEN" ]; then echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN:-$OPS_NPM_TOKEN}" > /root/.npmrc; fi \
    && npm install \
    && npm cache --force clean \
    && apk del git \
    && rm -rf \
        /root/.gitconfig \
        /root/.npmrc \
        /tmp/* \
        /var/cache/apk

ENTRYPOINT ./entrypoint.sh

EXPOSE 3000
