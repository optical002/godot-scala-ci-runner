FROM ubuntu:24.04

LABEL org.opencontainers.image.source=https://github.com/optical002/godot-scala-ci-runner
LABEL org.opencontainers.image.description="CI runner for building Godot with Kotlin/JVM support"
LABEL org.opencontainers.image.licenses=MIT

ENV DEBIAN_FRONTEND=noninteractive
ENV GODOT_VERSION=4.5.1.stable.jvm.0.14.3

# Minimal runtime deps for Godot headless
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libgl1 \
    libxi6 \
    libxcursor1 \
    libxinerama1 \
    libxrandr2 \
    libfontconfig1 \
    libxkbcommon0 \
    patchelf \
    git \
    && rm -rf /var/lib/apt/lists/*

# Download Godot editor
ADD https://github.com/optical002/godot-scala-ci-runner/releases/download/1.0/godot.linuxbsd.editor.x86_64.jvm.0.14.3 /usr/local/bin/godot
RUN chmod +x /usr/local/bin/godot \
    && patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 /usr/local/bin/godot

# Create export templates directory
RUN mkdir -p /root/.local/share/godot/export_templates/${GODOT_VERSION}

# Download export templates
ADD https://github.com/optical002/godot-scala-ci-runner/releases/download/1.0/godot.linuxbsd.template_debug.x86_64.jvm.0.14.3 \
    /root/.local/share/godot/export_templates/${GODOT_VERSION}/linux_debug.x86_64
ADD https://github.com/optical002/godot-scala-ci-runner/releases/download/1.0/godot.linuxbsd.template_release.x86_64.jvm.0.14.3 \
    /root/.local/share/godot/export_templates/${GODOT_VERSION}/linux_release.x86_64
ADD https://github.com/optical002/godot-scala-ci-runner/releases/download/1.0/godot.windows.template_debug.x86_64.jvm.0.14.3.exe \
    /root/.local/share/godot/export_templates/${GODOT_VERSION}/windows_debug_x86_64.exe
ADD https://github.com/optical002/godot-scala-ci-runner/releases/download/1.0/godot.windows.template_release.x86_64.jvm.0.14.3.exe \
    /root/.local/share/godot/export_templates/${GODOT_VERSION}/windows_release_x86_64.exe

# Create version.txt
RUN echo "${GODOT_VERSION}" > /root/.local/share/godot/export_templates/${GODOT_VERSION}/version.txt

WORKDIR /workspace