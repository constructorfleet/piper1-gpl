ARG BUILD_IMAGE=python:3.12
ARG RUNTIME_IMAGE=python:3.12-slim
ARG RUNTIME_APT_PACKAGES=

FROM ${BUILD_IMAGE} AS builder

ARG PIPER_ONNXRUNTIME_PACKAGE=onnxruntime
ENV PIPER_ONNXRUNTIME_PACKAGE=${PIPER_ONNXRUNTIME_PACKAGE}

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
      build-essential cmake ninja-build git

WORKDIR /app

COPY pyproject.toml setup.py CMakeLists.txt MANIFEST.in README.md ./
COPY src/piper/ ./src/piper/
COPY script/setup script/dev_build script/package ./script/
RUN script/setup --dev
RUN script/dev_build
RUN script/package

# -----------------------------------------------------------------------------

FROM ${RUNTIME_IMAGE}

ENV PIP_BREAK_SYSTEM_PACKAGES=1

WORKDIR /app
RUN if [ -n "${RUNTIME_APT_PACKAGES}" ]; then \
      apt-get update && \
      apt-get install --yes --no-install-recommends ${RUNTIME_APT_PACKAGES} && \
      rm -rf /var/lib/apt/lists/*; \
    fi
COPY --from=builder /app/dist/piper_tts-*linux*.whl ./dist/
RUN python3 -m pip install ./dist/piper_tts-*linux*.whl
RUN python3 -m pip install 'flask>=3,<4'

COPY docker/entrypoint.sh /

EXPOSE 5000

ENTRYPOINT ["/entrypoint.sh"]
