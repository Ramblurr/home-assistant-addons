ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apk add --no-cache \
        borgbackup \
        curl \
        openssh-keygen \
        openssh-client

# Home Assistant CLI
ARG BUILD_ARCH
ARG BUILD_VERSION
ARG CLI_VERSION
RUN curl -Lso /usr/bin/ha \
        "https://github.com/home-assistant/cli/releases/download/${CLI_VERSION}/ha_${BUILD_ARCH}" \
    && chmod a+x /usr/bin/ha

COPY rootfs /
