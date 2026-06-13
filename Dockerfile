FROM ubuntu:22.04 AS builder

ARG WITH_DOCS=1
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG http_proxy
ARG https_proxy
ARG NO_PROXY
ARG no_proxy

ENV DEBIAN_FRONTEND=noninteractive \
    HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    http_proxy=${http_proxy} \
    https_proxy=${https_proxy} \
    NO_PROXY="${NO_PROXY},mirrors.aliyun.com" \
    no_proxy="${no_proxy},mirrors.aliyun.com"

# ── 0. Apt mirror ──────────────────────────────────────────────────
# Always use aliyun mirrors for apt (fast in China, no proxy needed).
# Other steps (cmake/vcpkg/github) still go direct or via proxy.
RUN sed -i \
      -e 's|http://archive.ubuntu.com/ubuntu/|http://mirrors.aliyun.com/ubuntu/|g' \
      -e 's|http://security.ubuntu.com/ubuntu/|http://mirrors.aliyun.com/ubuntu/|g' \
      /etc/apt/sources.list

# ── 1. Build dependencies ──────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    g++ \
    ninja-build \
    flex \
    bison \
    pkg-config \
    autopoint \
    git \
    ca-certificates \
    curl \
    unzip \
    tar \
    gnupg \
    perl \
    python3 \
    python3-jinja2 \
    libncursesw5-dev \
    libxinerama-dev \
    libxcursor-dev \
    xorg-dev \
    libglu1-mesa-dev \
    libwayland-dev \
    libtirpc-dev \
    ccache \
    autoconf \
    automake \
    autoconf-archive \
    libtool \
    libltdl-dev \
    && if [ "$WITH_DOCS" = "1" ]; then \
         apt-get install -y --no-install-recommends \
           texlive texlive-latex-extra texinfo ghostscript; \
       fi \
    && rm -rf /var/lib/apt/lists/*

# ── 2. CMake >= 3.27 ──────────────────────────────────────────────
RUN curl -fsSL https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null \
        | gpg --dearmor -o /usr/share/keyrings/kitware-archive-keyring.gpg \
    && . /etc/os-release \
    && echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ ${UBUNTU_CODENAME} main" \
        > /etc/apt/sources.list.d/kitware.list \
    && apt-get update && apt-get install -y --no-install-recommends cmake \
    && rm -rf /var/lib/apt/lists/*

# ── 2.5 Ninja (v1.13.2+) ──────────────────────────────────────────
# apt's ninja-build 1.10.x is too old for vcpkg compiler detection.
# Pre-install newer version so vcpkg doesn't download its own at runtime.
RUN curl -fsSL "https://github.com/ninja-build/ninja/releases/download/v1.13.2/ninja-linux.zip" \
      -o /tmp/ninja.zip && \
    unzip -o /tmp/ninja.zip -d /usr/local/bin && \
    rm /tmp/ninja.zip && \
    chmod +x /usr/local/bin/ninja

# ── 3. vcpkg ──────────────────────────────────────────────────────
# zip is required by bootstrap-vcpkg.sh (not installed by default)
RUN apt-get update && apt-get install -y --no-install-recommends zip \
    && rm -rf /var/lib/apt/lists/*
ENV VCPKG_ROOT=/opt/vcpkg
RUN for i in 1 2 3 4 5; do \
      echo "==> vcpkg clone attempt $i/5"; \
      git clone --depth 1 https://github.com/microsoft/vcpkg.git "$VCPKG_ROOT" && break; \
      echo "clone failed, retrying in 10s..."; sleep 10; \
    done \
    && test -f "$VCPKG_ROOT"/bootstrap-vcpkg.sh || { echo "ERROR: vcpkg clone failed after 5 attempts"; exit 1; } \
    && cd "$VCPKG_ROOT" \
    && for i in 1 2 3 4 5; do \
      echo "==> vcpkg baseline fetch attempt $i/5"; \
      git fetch --depth 1 origin f33cc491c85a7d643c5ab6da1667c1458e6d7abf && break; \
      echo "fetch failed, retrying in 10s..."; sleep 10; \
    done \
    && for i in 1 2 3 4 5; do \
      echo "==> vcpkg bootstrap attempt $i/5"; \
      ./bootstrap-vcpkg.sh && break; \
      echo "bootstrap failed, retrying in 10s..."; sleep 10; \
    done

# ── 3.5 Pre-build vcpkg dependencies ──────────────────────────────
# Pre-compile all vcpkg deps during image build so cmake configure
# at runtime finds them installed and skips download+compile entirely.
# ── 3.25 gettext (needed by libxcrypt autotools configure) ──────────
RUN apt-get update && apt-get install -y --no-install-recommends gettext \
    && rm -rf /var/lib/apt/lists/*

# vcpkg's cmake-get-vars passes DLLTOOL='CMAKE_DLLTOOL-NOTFOUND' (literal)
# when dlltool is not found. This causes libxcrypt's configure to fail
# because it sees non-empty DLLTOOL and tries to execute the bogus string.
# Symlink a no-op so configure treats it as "available but unused".
RUN ln -s /usr/bin/true /usr/local/bin/dlltool

# libxcrypt autotools configure needs 'make' during config.status bootstrapping.
RUN apt-get update && apt-get install -y --no-install-recommends make \
    && rm -rf /var/lib/apt/lists/*

COPY vcpkg.json /tmp/vcpkg-deps/vcpkg.json
RUN echo 'set(VCPKG_BUILD_TYPE release)' >> "$VCPKG_ROOT"/triplets/x64-linux.cmake
RUN cd /tmp/vcpkg-deps && \
    ( "$VCPKG_ROOT"/vcpkg install \
        --triplet x64-linux \
        --x-feature=readline \
        --x-feature=curl \
        --x-feature=threading \
        --x-feature=gsl \
        --x-feature=eigen3 \
        --x-feature=fftw3 \
        --x-feature=lsp \
        --x-install-root=/opt/vcpkg-deps \
      || ( echo "=== LIBCRYPT BUILD LOGS ==="; \
           find /opt/vcpkg/buildtrees/libxcrypt -name "*.log" \
             -exec echo "--- {} ---" \; -exec tail -100 {} \; ; \
           exit 1 ) \
    ) && \
    rm -rf /tmp/vcpkg-deps

# ── 4. ccache ─────────────────────────────────────────────────────
ENV CCACHE_DIR=/home/builder/.ccache \
    CCACHE_MAXSIZE=1G
RUN mkdir -p /home/builder/.ccache

# ── 5. Workspace ──────────────────────────────────────────────────
WORKDIR /workspace

# ═══════════════════════════════════════════════════════════════════
# Usage
# ═══════════════════════════════════════════════════════════════════
#
# --- Build (apt → aliyun mirrors, other downloads need internet) ---
#   docker build --target builder -t asy-builder .
#
# --- Build with proxy (proxy on host, use --network host) ---
#   docker build --target builder --network host \
#     --build-arg http_proxy=http://127.0.0.1:33210 \
#     --build-arg https_proxy=http://127.0.0.1:33210 \
#     -t asy-builder .
#
# --- Skip docs (~500MB smaller) ---
#   docker build --target builder --build-arg WITH_DOCS=0 -t asy-builder .
#
# --- Compile asy (no proxy needed at runtime) ---
#   docker run --rm -v "$PWD":/workspace asy-builder sh -c '
#     cmake --preset linux/release/ci/with-ccache/docker &&
#     cmake --build --preset linux/release/ci/with-ccache/docker --target asy-with-basefiles -j$(nproc)
#   '
# Output: cmake-build-linux/release/asy + base/
#
# --- Build docs (requires WITH_DOCS=1) ---
#   docker run --rm -v "$PWD":/workspace asy-builder sh -c '
#     cmake --preset linux/release/ci/with-ccache/docker &&
#     cmake --build --preset linux/release/ci/with-ccache/docker --target docgen -j$(nproc)
#   '
# Output: cmake-build-linux/release/docbuild/asymptote.pdf


# ═══════════════════════════════════════════════════════════════════
# Stage: runtime — slim image with pre-built binary only (~200MB)
# ═══════════════════════════════════════════════════════════════════
#
# This stage produces a minimal runtime image WITHOUT compilation
# capability. It expects a pre-compiled asy binary in the workspace.
#
# Build workflow:
#   1. Compile asy using the builder stage (see above).
#   2. docker build --target runtime -t asy-runtime .
#
# Uncomment the block below to enable:

# FROM ubuntu:22.04 AS runtime
#
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     libxinerama1 libxcursor1 libglu1-mesa libwayland-client0 \
#     libtirpc3 libstdc++6 libgcc-s1 zlib1g \
#     && rm -rf /var/lib/apt/lists/*
#
# COPY --from=builder /workspace/cmake-build-linux/release/asy /usr/local/bin/asy
# COPY --from=builder /workspace/cmake-build-linux/release/base /usr/local/share/asymptote/
#
# ENV ASYMPTOTE_SYSDIR=/usr/local/share/asymptote
# ENTRYPOINT ["asy"]