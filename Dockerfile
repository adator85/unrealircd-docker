# syntax=docker/dockerfile:1

# ===========================
# Alpine Linux version
# ===========================

ARG ALPINE_VERSION=3.20

# base image
FROM alpine:${ALPINE_VERSION}

# ===========================
# UnrealIRCd Dockerfile
# ===========================

ARG UNREALIRCD_VERSION=6.2.7
ARG UNREALIRCD_USER=ircd
ARG UNREALIRCD_UID=1000
ARG UNREALIRCD_GID=1000
ARG UNREALIRCD_INSTALL_DIR=/opt/unrealircd


# Install build dependencies
RUN apk add --no-cache \
    build-base \
    curl \
    ca-certificates \
    openssl-dev \
    openssl \
    pcre2-dev \
    c-ares-dev \
    curl-dev \
    pkgconf \
    su-exec

# Creation of the UnrealIRCd user
RUN addgroup -S -g ${UNREALIRCD_GID} ${UNREALIRCD_USER} \
    && adduser -S \
        -u ${UNREALIRCD_UID} \
        -G ${UNREALIRCD_USER} \
        -h /home/ircd \
        ${UNREALIRCD_USER}

RUN cat /etc/passwd | grep ${UNREALIRCD_USER}

# Installation directory
RUN mkdir -p ${UNREALIRCD_INSTALL_DIR} \
    && chown -R ${UNREALIRCD_USER}:${UNREALIRCD_USER} ${UNREALIRCD_INSTALL_DIR}

# Working dir
WORKDIR ${UNREALIRCD_INSTALL_DIR}

# Download and extract UnrealIRCd source code
RUN curl -fL \
    https://www.unrealircd.org/downloads/unrealircd-${UNREALIRCD_VERSION}.tar.gz \
    -o /tmp/unrealircd.tar.gz \
    && file /tmp/unrealircd.tar.gz \
    && tar xzf /tmp/unrealircd.tar.gz --strip-components=1 \
    && rm /tmp/unrealircd.tar.gz \
    && chown -R ${UNREALIRCD_USER}:${UNREALIRCD_USER} ${UNREALIRCD_INSTALL_DIR} \
    && chmod +x ./Config

COPY ./entrypoint.sh /home/ircd/entrypoint.sh

RUN chown -R ${UNREALIRCD_USER}:${UNREALIRCD_USER} /home/ircd/entrypoint.sh \
    && chmod +x /home/ircd/entrypoint.sh

# Tout ce qui suit est exécuté en tant que utilisateur non-root
USER ${UNREALIRCD_USER}

RUN ls -la ${UNREALIRCD_INSTALL_DIR} \
    && ls -l ${UNREALIRCD_INSTALL_DIR}/Config \
    && id \
    && stat ${UNREALIRCD_INSTALL_DIR}/Config

# 2️⃣ Configuration rapide (options non-interactive)
#    (c’est possible : le script `./Config` accepte des drapeaux)
RUN ./Config \
    --install-dir=${UNREALIRCD_INSTALL_DIR} \
    --enable-ssl \
    --enable-pcre \
    --disable-debug \
    --with-permissions=0 \
    --quiet

RUN make -j$(nproc) \
    && make install

# 4️⃣ (Optionnel) Copier un fichier de configuration par défaut
#    Vous pouvez remplacer ce fichier par votre propre `unrealircd.conf`
# COPY ./volumes/conf/unrealircd.conf /home/ircd/unrealircd/conf/unrealircd.conf

VOLUME ["/home/ircd/unrealircd/conf", "/home/ircd/unrealircd/data", "/home/ircd/unrealircd/logs"]

# 5️⃣ Port IRC à exposer (défaut : 6667)
EXPOSE 6667 6697

# 6️⃣ Créer un certificat SSL auto-signé pour le serveur IRC (optionnel)
RUN cd /home/ircd/unrealircd \
    && printf 'Y\n\n\n\n\n\n\n' | ./unrealircd mkcert

RUN mkdir -p /home/ircd/unrealircd-defaults && \
    cp -ar /home/ircd/unrealircd/conf /home/ircd/unrealircd-defaults/ && \
    cp -ar /home/ircd/unrealircd/data /home/ircd/unrealircd-defaults/ && \
    cp -ar /home/ircd/unrealircd/cache /home/ircd/unrealircd-defaults/ && \
    cp -ar /home/ircd/unrealircd/tmp /home/ircd/unrealircd-defaults/

# Nettoyage des dossiers actifs (ils seront remplis par l'entrypoint ou les volumes)
RUN rm -rf /home/ircd/unrealircd/conf/* \
           /home/ircd/unrealircd/data/* \
           /home/ircd/unrealircd/cache/* \
           /home/ircd/unrealircd/tmp/*

RUN chown -R ${UNREALIRCD_USER}:${UNREALIRCD_USER} /home/ircd/unrealircd-defaults
RUN chmod -R u+rwX,go+rwX /home/ircd/unrealircd-defaults

USER root
STOPSIGNAL SIGTERM

CMD ["/home/ircd/entrypoint.sh"]
