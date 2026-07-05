FROM ubuntu:20.04

ARG CLIENT_VERSION=10781.19.0.1214
ARG DEB_FILE_REL_PATH=bin/cn.com.huawei-security-commercial-alliance.univpn_${CLIENT_VERSION}_arm64.deb
ARG APP_ID=cn.com.huawei-security-commercial-alliance.univpn
ARG APP_DIR=/opt/apps/${APP_ID}/files
ARG USERNAME=vpnuser
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV USER=${USERNAME}
ENV HOME=/home/${USERNAME}
ENV TZ=Asia/Shanghai
ENV UNIVPN_APP_DIR=${APP_DIR}
ENV HEALTH_CHECK_INTERVAL=10
ENV RETRY_DELAY=5

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    dante-server \
    dbus \
    expect \
    iproute2 \
    iputils-ping \
    libgl1 \
    libnss3 \
    libproxy1v5 \
    libqt5core5a \
    libqt5dbus5 \
    libqt5gui5 \
    libqt5network5 \
    libqt5widgets5 \
    libqt5x11extras5 \
    libx11-6 \
    libx11-xcb1 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-sync1 \
    libxcb-xfixes0 \
    libxcb-xinerama0 \
    libxcb-xinput0 \
    libxext6 \
    libxi6 \
    libxkbcommon-x11-0 \
    libxrender1 \
    libxtst6 \
    locales \
    net-tools \
    procps \
    sudo \
    supervisor \
    tinyproxy \
    tzdata && \
    sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    mkdir -p /var/run/dbus && \
    chown messagebus:messagebus /var/run/dbus

RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} --shell /bin/bash --create-home ${USERNAME} && \
    adduser ${USERNAME} sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    mkdir -p /home/${USERNAME}/.config/${APP_ID} && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} && \
    chmod 750 /home/${USERNAME}

COPY ${DEB_FILE_REL_PATH} /tmp/univpn-arm64.deb
RUN apt-get update && \
    apt-get install -y --no-install-recommends /tmp/univpn-arm64.deb && \
    rm /tmp/univpn-arm64.deb && \
    ln -s ${APP_DIR} /usr/local/UniVPN && \
    mkdir -p ${APP_DIR}/log && \
    chmod 777 ${APP_DIR}/log && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/supervisor

COPY arm64/supervisord.conf /etc/supervisor/supervisord.conf
COPY danted.conf /etc/danted.conf
COPY tinyproxy.conf /etc/tinyproxy/tinyproxy.conf
COPY wait_and_start_dante.sh /usr/local/bin/wait_and_start_dante.sh
COPY arm64/univpn-keeper.sh /usr/local/bin/univpn-keeper.sh
COPY arm64/entrypoint.sh /usr/local/bin/arm64-cli-entrypoint.sh
RUN chmod +x /usr/local/bin/wait_and_start_dante.sh /usr/local/bin/univpn-keeper.sh /usr/local/bin/arm64-cli-entrypoint.sh

WORKDIR /home/${USERNAME}

EXPOSE 1080 8888

ENTRYPOINT ["/usr/local/bin/arm64-cli-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

LABEL version="${CLIENT_VERSION}"
LABEL description="Docker container for Huawei UniVPN ARM64 CLI Client (v${CLIENT_VERSION})"
