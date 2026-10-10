# qdata, containerized. No binary lives in this repo — the image fetches the same Linux
# release tarball install.sh does, so `docker build` works from a clean checkout.
# To build from a local ./release.sh output instead:
#   docker build --build-arg QDATA_TARBALL=dist/qdata-cli-linux-x86_64.tar.gz -t qdata .
FROM debian:trixie-slim AS fetch
ARG QDATA_TARBALL=
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*
COPY ${QDATA_TARBALL:-VERSION} /tmp/local-src
RUN if [ -n "${QDATA_TARBALL}" ]; then tar xzf /tmp/local-src -C /opt; \
    else curl -fsSL --retry 3 --retry-delay 2 https://github.com/cuiqanalytics/qdata/releases/latest/download/qdata-cli-linux-x86_64.tar.gz \
         | tar xz -C /opt; fi \
    && mv /opt/qdata-cli-linux-x86_64 /opt/qdata

# The binary is dynamically linked against glibc (static glibc breaks vduckdb's dlopen() of
# libduckdb.so), so this image's glibc must be >= the release build machine's.
FROM debian:trixie-slim
LABEL org.opencontainers.image.source="https://github.com/cuiqanalytics/qdata"
# ca-certificates: https sources and scrape steps verify TLS against the system store.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=fetch /opt/qdata/bin /usr/local/lib/qdata/bin
COPY --from=fetch /opt/qdata/extensions /usr/local/lib/qdata/extensions
RUN chmod +x /usr/local/lib/qdata/bin/qdata && chmod -R a+rX /usr/local/lib/qdata
ENV LIBDUCKDB_DIR=/usr/local/lib/qdata/bin
ENV LD_LIBRARY_PATH=/usr/local/lib/qdata/bin
ENV PATH="/usr/local/lib/qdata/bin:${PATH}"
ENV HOME=/home/qdata
RUN mkdir -p "$HOME" && chmod 1777 "$HOME"

# Pipelines live in the caller's working directory, which they mount here:
#   docker run --rm -v "$PWD:/work" ghcr.io/cuiqanalytics/qdata run sql
# Own the output files:  --user "$(id -u):$(id -g)"
# Pro license:           -v ~/.cuiq:/home/qdata/.cuiq:ro
# Scheduler + API:       docker run -d -p 5000:5000 -v "$PWD:/work" ghcr.io/cuiqanalytics/qdata scheduler 0.0.0.0 5000
WORKDIR /work
EXPOSE 5000
ENTRYPOINT ["qdata"]
