# syntax=docker/dockerfile:1

ARG ALPINE_VERSION=3.24.1
ARG UNREALIRCD_VERSION=6.2.7
ARG UNREALIRCD_USER=ircd
ARG UNREALIRCD_UID=1000
ARG UNREALIRCD_GID=1000
ARG UNREALIRCD_INSTALL_DIR=/home/ircd/unrealircd

# -------------------------
# Build stage
# -------------------------
FROM alpine:${ALPINE_VERSION} AS builder

ARG UNREALIRCD_VERSION
ARG UNREALIRCD_USER
ARG UNREALIRCD_UID
ARG UNREALIRCD_GID
ARG UNREALIRCD_INSTALL_DIR

RUN apk add --no-cache build-base openssl-dev openssl wget \
    && addgroup -S -g "${UNREALIRCD_GID}" "${UNREALIRCD_USER}" \
    && adduser -S -u "${UNREALIRCD_UID}" -G "${UNREALIRCD_USER}" -h /home/ircd "${UNREALIRCD_USER}" \
    && mkdir -p /src /build "${UNREALIRCD_INSTALL_DIR}" \
    && chown -R "${UNREALIRCD_USER}:${UNREALIRCD_USER}" /src /build /home/ircd

WORKDIR /src
USER ${UNREALIRCD_USER}

RUN wget --trust-server-names -O /tmp/unrealircd.tar.gz \
    "https://www.unrealircd.org/downloads/unrealircd-${UNREALIRCD_VERSION}.tar.gz" \
    && tar -xzf /tmp/unrealircd.tar.gz --strip-components=1 \
    && rm -f /tmp/unrealircd.tar.gz \
    && ./configure \
         --enable-dynamic-linking \
         --enable-ssl \
         --with-bindir="${UNREALIRCD_INSTALL_DIR}/bin" \
         --with-scriptdir="${UNREALIRCD_INSTALL_DIR}" \
         --with-confdir="${UNREALIRCD_INSTALL_DIR}/conf" \
         --with-datadir="${UNREALIRCD_INSTALL_DIR}/data" \
         --with-modulesdir="${UNREALIRCD_INSTALL_DIR}/modules" \
         --with-logdir="${UNREALIRCD_INSTALL_DIR}/logs" \
         --with-cachedir="${UNREALIRCD_INSTALL_DIR}/cache" \
         --with-tmpdir="${UNREALIRCD_INSTALL_DIR}/tmp" \
         --with-docdir="${UNREALIRCD_INSTALL_DIR}/doc" \
         --with-privatelibdir="${UNREALIRCD_INSTALL_DIR}/lib" \
         --with-pidfile="${UNREALIRCD_INSTALL_DIR}/data/unrealircd.pid" \
         --with-controlfile="${UNREALIRCD_INSTALL_DIR}/data/unrealircd.ctl" \
         --with-permissions=0 \
         --disable-libcurl \
         --enable-mmdb \
         --disable-debug \
    && make -j"$(nproc)" \
    && make install

# Remove files that are only useful for development/runtime self-debugging.
# The installed source tree is intentionally NOT copied to the final image.
USER root
RUN ls -l /
RUN rm -rf \
      "${UNREALIRCD_INSTALL_DIR}/doc" \
      "${UNREALIRCD_INSTALL_DIR}"/lib/*.a \
      "${UNREALIRCD_INSTALL_DIR}"/lib/*.la \
      "${UNREALIRCD_INSTALL_DIR}"/lib/pkgconfig \
      /build \
    && find "${UNREALIRCD_INSTALL_DIR}" -type f -name '*.so' -exec strip --strip-unneeded {} + \
    && strip --strip-unneeded "${UNREALIRCD_INSTALL_DIR}/bin/unrealircd"

# -------------------------
# Runtime stage
# -------------------------
FROM alpine:${ALPINE_VERSION} AS runtime

ARG UNREALIRCD_USER
ARG UNREALIRCD_UID
ARG UNREALIRCD_GID
ARG UNREALIRCD_INSTALL_DIR

RUN apk add --no-cache openssl su-exec \
    && addgroup -S -g "${UNREALIRCD_GID}" "${UNREALIRCD_USER}" \
    && adduser -S -u "${UNREALIRCD_UID}" -G "${UNREALIRCD_USER}" -h /home/ircd "${UNREALIRCD_USER}" \
    && mkdir -p /home/ircd

COPY --from=builder --chown=${UNREALIRCD_USER}:${UNREALIRCD_USER} \
     ${UNREALIRCD_INSTALL_DIR} ${UNREALIRCD_INSTALL_DIR}

# Keep the shipped config outside the volume mount point so first-run
# initialization still works when /home/ircd/unrealircd/conf is bind-mounted.
RUN mv "${UNREALIRCD_INSTALL_DIR}/conf" "${UNREALIRCD_INSTALL_DIR}/conf.default" \
    && mkdir -p \
         "${UNREALIRCD_INSTALL_DIR}/conf" \
         "${UNREALIRCD_INSTALL_DIR}/data" \
         "${UNREALIRCD_INSTALL_DIR}/cache" \
         "${UNREALIRCD_INSTALL_DIR}/tmp" \
         "${UNREALIRCD_INSTALL_DIR}/logs" \
    && chown -R "${UNREALIRCD_USER}:${UNREALIRCD_USER}" "${UNREALIRCD_INSTALL_DIR}"

WORKDIR ${UNREALIRCD_INSTALL_DIR}

COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 6667 6697
STOPSIGNAL SIGTERM

CMD ["/usr/local/bin/entrypoint.sh"]
