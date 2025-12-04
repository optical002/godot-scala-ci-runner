FROM ubuntu:24.04

LABEL org.opencontainers.image.source=https://github.com/optical002/godot-scala-ci-runner
LABEL org.opencontainers.image.description="CI runner for building Godot with Kotlin/JVM support"
LABEL org.opencontainers.image.licenses=MIT

ENV DEBIAN_FRONTEND=noninteractive
ENV GODOT_VERSION=4.5.1.stable.jvm.0.14.3
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV XDG_DATA_HOME=/root/.local/share

# Runtime deps for Godot + JVM
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
    git-lfs \
    openjdk-17-jre-headless \
    openjdk-17-jdk-headless \
    curl \
    unzip \
    gnupg \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Install SBT
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list && \
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | gpg --dearmor | tee /etc/apt/trusted.gpg.d/sbt.gpg > /dev/null && \
    apt-get update && \
    apt-get install -y sbt && \
    rm -rf /var/lib/apt/lists/*

# Pre-install JREs for both Linux and Windows to speed up CI builds
ENV JDK_VERSION=17.0.13+11
ENV JDK_VERSION_ENCODED=17.0.13%2B11

# Download and extract Linux JRE
RUN mkdir -p /opt/jre && \
    curl -L -o /tmp/jre-linux.tar.gz \
    "https://api.adoptium.net/v3/binary/version/jdk-${JDK_VERSION_ENCODED}/linux/x64/jre/hotspot/normal/eclipse?project=jdk" && \
    tar xzf /tmp/jre-linux.tar.gz -C /tmp && \
    mv /tmp/jdk-${JDK_VERSION}-jre /opt/jre/jre-amd64-linux && \
    rm /tmp/jre-linux.tar.gz

# Download and extract Windows JRE
RUN curl -L -o /tmp/jre-windows.zip \
    "https://api.adoptium.net/v3/binary/version/jdk-${JDK_VERSION_ENCODED}/windows/x64/jre/hotspot/normal/eclipse?project=jdk" && \
    unzip -q /tmp/jre-windows.zip -d /tmp && \
    mv /tmp/jdk-${JDK_VERSION}-jre /opt/jre/jre-amd64-windows && \
    rm /tmp/jre-windows.zip

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