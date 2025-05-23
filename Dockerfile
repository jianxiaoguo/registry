ARG CODENAME

FROM registry.drycc.cc/drycc/go-dev:latest AS build
ARG LDFLAGS
ADD . /workspace
RUN export GO111MODULE=on \
  && cd /workspace \
  && CGO_ENABLED=0 init-stack go build -ldflags "${LDFLAGS}" -o /bin/boot main.go \
  && upx -9 --brute /bin/boot


FROM registry.drycc.cc/drycc/base:${CODENAME}

ENV DRYCC_UID=1001 \
  DRYCC_GID=1001 \
  DRYCC_HOME_DIR=/var/lib/registry \
  JQ_VERSION="1.7.1" \
  MC_VERSION="2025.04.03.17.07.56" \
  REGISTRY_VERSION="3.0.0"

COPY rootfs/bin/ /bin/
COPY --from=build /bin/boot /bin/boot

RUN groupadd drycc --gid ${DRYCC_GID} \
  && useradd drycc -u ${DRYCC_UID} -g ${DRYCC_GID} -s /bin/bash -m -d ${DRYCC_HOME_DIR} \
  && install-packages apache2-utils \
  && install-stack jq $JQ_VERSION \
  && install-stack mc $MC_VERSION \
  && install-stack registry $REGISTRY_VERSION \
  && chmod +x /bin/init_registry \
  && rm -rf \
      /usr/share/doc \
      /usr/share/man \
      /usr/share/info \
      /usr/share/locale \
      /var/lib/apt/lists/* \
      /var/log/* \
      /var/cache/debconf/* \
      /etc/systemd \
      /lib/lsb \
      /lib/udev \
      /usr/lib/`echo $(uname -m)`-linux-gnu/gconv/IBM* \
      /usr/lib/`echo $(uname -m)`-linux-gnu/gconv/EBC* \
  && mkdir -p /usr/share/man/man{1..8} \
  && chown -R ${DRYCC_UID}:${DRYCC_GID} ${DRYCC_HOME_DIR}

COPY --chown=${DRYCC_UID}:${DRYCC_GID} rootfs/config-example.yml /opt/drycc/registry/etc/config.yml
ENV DRYCC_REGISTRY_CONFIG /opt/drycc/registry/etc/config.yml

USER ${DRYCC_UID}
VOLUME ["${DRYCC_HOME_DIR}"]
CMD ["/bin/boot"]
EXPOSE 5000
