# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Supported base images: Ubuntu 24.04, 22.04, 20.04
ARG DISTRIB_RELEASE=24.04
FROM ubuntu:${DISTRIB_RELEASE}
ARG DISTRIB_RELEASE

LABEL maintainer="https://github.com/ehfd,https://github.com/danisla"

ARG DEBIAN_FRONTEND=noninteractive
# Configure rootless user environment for constrained conditions without escalated root privileges inside containers
ARG TZ=UTC
ARG PASSWD=mypasswd
RUN apt-get clean && apt-get update && apt-get dist-upgrade -y && apt-get install --no-install-recommends -y \
    apt-utils \
    dbus-user-session \
    fakeroot \
    locales \
    ssl-cert \
    sudo \
    udev \
    tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/* && \
    locale-gen en_US.UTF-8 && \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone && \
    # Only use sudo-root for root-owned directory (/dev, /proc, /sys) or user/group permission operations, not for apt-get installation or file/directory operations
    mv -f /usr/bin/sudo /usr/bin/sudo-root && \
    ln -snf /usr/bin/fakeroot /usr/bin/sudo && \
    groupadd -g 1000 ubuntu || echo 'Failed to add ubuntu group' && \
    useradd -ms /bin/bash ubuntu -u 1000 -g 1000 || echo 'Failed to add ubuntu user' && \
    usermod -a -G adm,audio,cdrom,dialout,dip,fax,floppy,games,input,lp,plugdev,render,ssl-cert,sudo,tape,tty,video,voice ubuntu && \
    echo "ubuntu ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "ubuntu:${PASSWD}" | chpasswd && \
    chown -R -f --no-preserve-root ubuntu:ubuntu / || echo 'Failed to set filesystem ownership in some paths to ubuntu user'

# Set locales
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"

USER 1000
# Use BUILDAH_FORMAT=docker in buildah
SHELL ["/usr/bin/fakeroot", "--", "/bin/sh", "-c"]

# Install operating system libraries or packages
RUN apt-get update && apt-get install --no-install-recommends -y \
        # Operating system packages
        software-properties-common \
        build-essential \
        ca-certificates \
        cups-browsed \
        cups-bsd \
        cups-common \
        cups-filters \
        printer-driver-cups-pdf \
        alsa-base \
        alsa-utils \
        file \
        gnupg \
        curl \
        wget \
        bzip2 \
        gzip \
        xz-utils \
        unar \
        rar \
        unrar \
        zip \
        unzip \
        zstd \
        gcc \
        git \
        coturn \
        jq \
        python3 \
        python3-cups \
        python3-numpy \
        nano \
        vim \
        htop \
        fonts-dejavu \
        fonts-freefont-ttf \
        fonts-hack \
        fonts-liberation \
        fonts-noto \
        fonts-noto-cjk \
        fonts-noto-cjk-extra \
        fonts-noto-color-emoji \
        fonts-noto-extra \
        fonts-noto-ui-extra \
        fonts-noto-hinted \
        fonts-noto-mono \
        fonts-noto-unhinted \
        fonts-opensymbol \
        fonts-symbola \
        fonts-ubuntu \
        lame \
        less \
        libavcodec-extra \
        libpulse0 \
        supervisor \
        net-tools \
        packagekit-tools \
        pkg-config \
        mesa-utils \
        mesa-va-drivers \
        libva2 \
        vainfo \
        vdpau-driver-all \
        libvdpau-va-gl1 \
        vdpauinfo \
        mesa-vulkan-drivers \
        vulkan-tools \
        radeontop \
        libvulkan-dev \
        ocl-icd-libopencl1 \
        clinfo \
        xkb-data \
        xauth \
        xbitmaps \
        xdg-user-dirs \
        xdg-utils \
        xfonts-base \
        xfonts-scalable \
        xinit \
        xsettingsd \
        libxrandr-dev \
        x11-xkb-utils \
        x11-xserver-utils \
        x11-utils \
        x11-apps \
        xserver-xorg-input-all \
        xserver-xorg-input-wacom \
        xserver-xorg-video-all \
        xserver-xorg-video-intel \
        xserver-xorg-video-qxl \
        # NVIDIA driver installer dependencies
        kmod \
        libc6-dev \
        libpci3 \
        libelf-dev \
        # OpenGL libraries
        libxau6 \
        libxdmcp6 \
        libxcb1 \
        libxext6 \
        libx11-6 \
        libxv1 \
        libxtst6 \
        libdrm2 \
        libegl1 \
        libgl1 \
        libopengl0 \
        libgles1 \
        libgles2 \
        libglvnd0 \
        libglx0 \
        libglu1 \
        libsm6 \
        # NGINX web server
        nginx \
        apache2-utils && \
    # Sanitize NGINX path
    sed -i -e 's/\/var\/log\/nginx\/access\.log/\/dev\/stdout/g' -e 's/\/var\/log\/nginx\/error\.log/\/dev\/stderr/g' -e 's/\/run\/nginx\.pid/\/tmp\/nginx\.pid/g' /etc/nginx/nginx.conf && \
    echo "error_log /dev/stderr;" >> /etc/nginx/nginx.conf && \
    # PipeWire and WirePlumber
    mkdir -pm755 /etc/apt/trusted.gpg.d && curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xFC43B7352BCC0EC8AF2EEB8B25088A0359807596" | gpg --dearmor -o /etc/apt/trusted.gpg.d/pipewire-debian-ubuntu-pipewire-upstream.gpg && \
    mkdir -pm755 /etc/apt/sources.list.d && echo "deb https://ppa.launchpadcontent.net/pipewire-debian/pipewire-upstream/ubuntu $(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"') main" > "/etc/apt/sources.list.d/pipewire-debian-ubuntu-pipewire-upstream-$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"').list" && \
    mkdir -pm755 /etc/apt/sources.list.d && echo "deb https://ppa.launchpadcontent.net/pipewire-debian/wireplumber-upstream/ubuntu $(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"') main" > "/etc/apt/sources.list.d/pipewire-debian-ubuntu-wireplumber-upstream-$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"').list" && \
    apt-get update && apt-get install --no-install-recommends -y \
        pipewire \
        pipewire-alsa \
        pipewire-audio-client-libraries \
        pipewire-jack \
        pipewire-locales \
        pipewire-v4l2 \
        pipewire-libcamera \
        gstreamer1.0-pipewire \
        libpipewire-0.3-modules \
        libpipewire-module-x11-bell \
        libspa-0.2-jack \
        libspa-0.2-modules \
        wireplumber \
        wireplumber-locales \
        gir1.2-wp-0.4 && \
    # Packages only meant for x86_64
    if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
    dpkg --add-architecture i386 && apt-get update && apt-get install --no-install-recommends -y \
        intel-gpu-tools \
        nvtop \
        va-driver-all \
        i965-va-driver-shaders \
        intel-media-va-driver-non-free \
        va-driver-all:i386 \
        i965-va-driver-shaders:i386 \
        intel-media-va-driver-non-free:i386 \
        libva2:i386 \
        vdpau-driver-all:i386 \
        mesa-vulkan-drivers:i386 \
        libvulkan-dev:i386 \
        libc6:i386 \
        libxau6:i386 \
        libxdmcp6:i386 \
        libxcb1:i386 \
        libxext6:i386 \
        libx11-6:i386 \
        libxv1:i386 \
        libxtst6:i386 \
        libdrm2:i386 \
        libegl1:i386 \
        libgl1:i386 \
        libopengl0:i386 \
        libgles1:i386 \
        libgles2:i386 \
        libglvnd0:i386 \
        libglx0:i386 \
        libglu1:i386 \
        libsm6:i386; fi && \
    # Install nvidia-vaapi-driver, requires the kernel parameter `nvidia_drm.modeset=1` set to run correctly
    if [ "$(grep VERSION_ID= /etc/os-release | cut -d= -f2 | tr -d '\"')" \> "20.04" ]; then \
    apt-get update && apt-get install --no-install-recommends -y \
        meson \
        gstreamer1.0-plugins-bad \
        libffmpeg-nvenc-dev \
        libva-dev \
        libegl-dev \
        libgstreamer-plugins-bad1.0-dev && \
    NVIDIA_VAAPI_DRIVER_VERSION="$(curl -fsSL "https://api.github.com/repos/elFarto/nvidia-vaapi-driver/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /tmp && curl -fsSL "https://github.com/elFarto/nvidia-vaapi-driver/archive/v${NVIDIA_VAAPI_DRIVER_VERSION}.tar.gz" | tar -xzf - && mv -f nvidia-vaapi-driver* nvidia-vaapi-driver && cd nvidia-vaapi-driver && meson setup build && meson install -C build && rm -rf /tmp/*; fi && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/* && \
    echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf && \
    # Configure OpenCL manually
    mkdir -pm755 /etc/OpenCL/vendors && echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd && \
    # Configure Vulkan manually
    VULKAN_API_VERSION=$(dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9]+(\.[0-9]+)(\.[0-9]+)') && \
    mkdir -pm755 /etc/vulkan/icd.d/ && echo "{\n\
    \"file_format_version\" : \"1.0.0\",\n\
    \"ICD\": {\n\
        \"library_path\": \"libGLX_nvidia.so.0\",\n\
        \"api_version\" : \"${VULKAN_API_VERSION}\"\n\
    }\n\
}" > /etc/vulkan/icd.d/nvidia_icd.json && \
    # Configure EGL manually
    mkdir -pm755 /usr/share/glvnd/egl_vendor.d/ && echo "{\n\
    \"file_format_version\" : \"1.0.0\",\n\
    \"ICD\": {\n\
        \"library_path\": \"libEGL_nvidia.so.0\"\n\
    }\n\
}" > /usr/share/glvnd/egl_vendor.d/10_nvidia.json
# Expose NVIDIA libraries and paths
ENV PATH="/usr/local/nvidia/bin${PATH:+:${PATH}}"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}/usr/local/nvidia/lib:/usr/local/nvidia/lib64"
# Make all NVIDIA GPUs visible by default
ENV NVIDIA_VISIBLE_DEVICES=all
# All NVIDIA driver capabilities should preferably be used, check `NVIDIA_DRIVER_CAPABILITIES` inside the container if things do not work
ENV NVIDIA_DRIVER_CAPABILITIES=all
# Disable VSYNC for NVIDIA GPUs
ENV __GL_SYNC_TO_VBLANK=0
# Set default DISPLAY environment
ENV DISPLAY=":0"

# Anything above this line should always be kept the same between docker-nvidia-glx-desktop and docker-nvidia-egl-desktop

# Default environment variables (password is "mypasswd")
ENV DISPLAY_SIZEW=1920
ENV DISPLAY_SIZEH=1080
ENV DISPLAY_REFRESH=60
ENV DISPLAY_DPI=96
ENV DISPLAY_CDEPTH=24
ENV VGL_DISPLAY=egl
ENV KASMVNC_ENABLE=false
ENV SELKIES_ENCODER=nvh264enc
ENV SELKIES_ENABLE_RESIZE=false
ENV SELKIES_ENABLE_BASIC_AUTH=true

# Install Xvfb
RUN apt-get update && apt-get install --no-install-recommends -y \
        xvfb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/*

# Install VirtualGL and make libraries available for preload
RUN cd /tmp && VIRTUALGL_VERSION="$(curl -fsSL "https://api.github.com/repos/VirtualGL/virtualgl/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
    dpkg --add-architecture i386 && \
    curl -fsSL -O "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb" && \
    curl -fsSL -O "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl32_${VIRTUALGL_VERSION}_amd64.deb" && \
    apt-get update && apt-get install -y --no-install-recommends "./virtualgl_${VIRTUALGL_VERSION}_amd64.deb" "./virtualgl32_${VIRTUALGL_VERSION}_amd64.deb" && \
    rm -f "virtualgl_${VIRTUALGL_VERSION}_amd64.deb" "virtualgl32_${VIRTUALGL_VERSION}_amd64.deb" && \
    chmod u+s /usr/lib/libvglfaker.so /usr/lib/libvglfaker-nodl.so /usr/lib/libvglfaker-opencl.so /usr/lib/libdlfaker.so /usr/lib/libgefaker.so && \
    chmod u+s /usr/lib32/libvglfaker.so /usr/lib32/libvglfaker-nodl.so /usr/lib32/libvglfaker-opencl.so /usr/lib32/libdlfaker.so /usr/lib32/libgefaker.so && \
    chmod u+s /usr/lib/i386-linux-gnu/libvglfaker.so /usr/lib/i386-linux-gnu/libvglfaker-nodl.so /usr/lib/i386-linux-gnu/libvglfaker-opencl.so /usr/lib/i386-linux-gnu/libdlfaker.so /usr/lib/i386-linux-gnu/libgefaker.so; \
    elif [ "$(dpkg --print-architecture)" = "arm64" ]; then \
    curl -fsSL -O "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_arm64.deb" && \
    apt-get update && apt-get install -y --no-install-recommends ./virtualgl_${VIRTUALGL_VERSION}_arm64.deb && \
    rm -f "virtualgl_${VIRTUALGL_VERSION}_arm64.deb" && \
    chmod u+s /usr/lib/libvglfaker.so /usr/lib/libvglfaker-nodl.so /usr/lib/libdlfaker.so /usr/lib/libgefaker.so; fi && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/*

# Anything below this line should always be kept the same between docker-nvidia-glx-desktop and docker-nvidia-egl-desktop

# Install KDE and other GUI packages
ENV DESKTOP_SESSION=plasma
ENV XDG_SESSION_DESKTOP=KDE
ENV XDG_CURRENT_DESKTOP=KDE
ENV XDG_SESSION_TYPE=x11
ENV XDG_SESSION_ID="${DISPLAY#*:}"
ENV KDE_FULL_SESSION=true
ENV KDE_APPLICATIONS_AS_SCOPE=1
ENV KWIN_COMPOSE=N
ENV KWIN_X11_NO_SYNC_TO_VBLANK=1
# Use sudoedit to change protected files instead of using sudo on kate
ENV SUDO_EDITOR=kate
# Set input to fcitx
ENV GTK_IM_MODULE=fcitx
ENV QT_IM_MODULE=fcitx
ENV XIM=fcitx
ENV XMODIFIERS="@im=fcitx"
# Enable AppImage execution in containers
ENV APPIMAGE_EXTRACT_AND_RUN=1
RUN mkdir -pm755 /etc/apt/preferences.d && echo "Package: firefox*\n\
Pin: version 1:1snap*\n\
Pin-Priority: -1" > /etc/apt/preferences.d/firefox-nosnap && \
    mkdir -pm755 /etc/apt/trusted.gpg.d && curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0AB215679C571D1C8325275B9BDB3D89CE49EC21" | gpg --dearmor -o /etc/apt/trusted.gpg.d/mozillateam-ubuntu-ppa.gpg && \
    mkdir -pm755 /etc/apt/sources.list.d && echo "deb https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu $(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"') main" > "/etc/apt/sources.list.d/mozillateam-ubuntu-ppa-$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"').list" && \
    apt-get update && apt-get install --no-install-recommends -y \
        kde-plasma-desktop \
        adwaita-icon-theme-full \
        appmenu-gtk3-module \
        ark \
        aspell \
        aspell-en \
        breeze \
        breeze-cursor-theme \
        breeze-gtk-theme \
        breeze-icon-theme \
        dbus-x11 \
        debconf-kde-helper \
        desktop-file-utils \
        dolphin \
        dolphin-plugins \
        enchant-2 \
        fcitx \
        fcitx-frontend-gtk2 \
        fcitx-frontend-gtk3 \
        fcitx-frontend-qt5 \
        fcitx-module-dbus \
        fcitx-module-kimpanel \
        fcitx-module-lua \
        fcitx-module-x11 \
        fcitx-tools \
        fcitx-hangul \
        fcitx-libpinyin \
        fcitx-m17n \
        fcitx-mozc \
        fcitx-sayura \
        fcitx-unikey \
        filelight \
        frameworkintegration \
        gwenview \
        haveged \
        hunspell \
        im-config \
        kate \
        kcalc \
        kcharselect \
        kdeadmin \
        kde-config-fcitx \
        kde-config-gtk-style \
        kde-config-gtk-style-preview \
        kdeconnect \
        kdegraphics-thumbnailers \
        kde-spectacle \
        kdf \
        kdialog \
        kget \
        kimageformat-plugins \
        kinfocenter \
        kio \
        kio-extras \
        kmag \
        kmenuedit \
        kmix \
        kmousetool \
        kmouth \
        ksshaskpass \
        ktimer \
        kwayland-integration \
        kwin-addons \
        kwin-x11 \
        libdbusmenu-glib4 \
        libdbusmenu-gtk3-4 \
        libgail-common \
        libgdk-pixbuf2.0-bin \
        libgtk2.0-bin \
        libgtk-3-bin \
        libkf5baloowidgets-bin \
        libkf5dbusaddons-bin \
        libkf5iconthemes-bin \
        libkf5kdelibs4support5-bin \
        libkf5khtml-bin \
        libkf5parts-plugins \
        libqt5multimedia5-plugins \
        librsvg2-common \
        media-player-info \
        okular \
        okular-extra-backends \
        partitionmanager \
        plasma-browser-integration \
        plasma-calendar-addons \
        plasma-dataengines-addons \
        plasma-discover \
        plasma-integration \
        plasma-runners-addons \
        plasma-widgets-addons \
        policykit-desktop-privileges \
        polkit-kde-agent-1 \
        print-manager \
        qapt-deb-installer \
        qml-module-org-kde-runnermodel \
        qml-module-org-kde-qqc2desktopstyle \
        qml-module-qtgraphicaleffects \
        qml-module-qtquick-xmllistmodel \
        qt5-gtk-platformtheme \
        qt5-image-formats-plugins \
        qt5-style-plugins \
        qtspeech5-flite-plugin \
        qtvirtualkeyboard-plugin \
        software-properties-qt \
        sonnet-plugins \
        sweeper \
        systemsettings \
        ubuntu-drivers-common \
        vlc \
        vlc-l10n \
        vlc-plugin-access-extra \
        vlc-plugin-notify \
        vlc-plugin-samba \
        vlc-plugin-skins2 \
        vlc-plugin-video-splitter \
        vlc-plugin-visualization \
        xdg-desktop-portal-kde \
        xdg-user-dirs \
        firefox \
        transmission-qt && \
    apt-get install --install-recommends -y \
        libreoffice \
        libreoffice-kf5 \
        libreoffice-plasma \
        libreoffice-style-breeze && \
    # Install Google Chrome for supported architectures
    if [ "$(dpkg --print-architecture)" = "amd64" ]; then cd /tmp && curl -o google-chrome-stable.deb -fsSL "https://dl.google.com/linux/direct/google-chrome-stable_current_$(dpkg --print-architecture).deb" && apt-get update && apt-get install --no-install-recommends -y ./google-chrome-stable.deb && rm -f google-chrome-stable.deb && sed -i '/^Exec=/ s/$/ --password-store=basic --in-process-gpu/' /usr/share/applications/google-chrome.desktop; fi && \
    # Ensure Firefox as the default web browser
    update-alternatives --set x-www-browser /usr/bin/firefox && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/* && \
    # Fix KDE startup permissions issues in containers
    MULTI_ARCH=$(dpkg --print-architecture | sed -e 's/arm64/aarch64-linux-gnu/' -e 's/armhf/arm-linux-gnueabihf/' -e 's/riscv64/riscv64-linux-gnu/' -e 's/ppc64el/powerpc64le-linux-gnu/' -e 's/s390x/s390x-linux-gnu/' -e 's/i.*86/i386-linux-gnu/' -e 's/amd64/x86_64-linux-gnu/' -e 's/unknown/x86_64-linux-gnu/') && \
    cp -f /usr/lib/${MULTI_ARCH}/libexec/kf5/start_kdeinit /tmp/ && \
    rm -f /usr/lib/${MULTI_ARCH}/libexec/kf5/start_kdeinit && \
    cp -f /tmp/start_kdeinit /usr/lib/${MULTI_ARCH}/libexec/kf5/start_kdeinit && \
    rm -f /tmp/start_kdeinit && \
    # KDE disable screen lock, double-click to open instead of single-click
    echo "[Daemon]\n\
Autolock=false\n\
LockOnResume=false" > /etc/xdg/kscreenlockerrc && \
    echo "[KDE]\n\
SingleClick=false\n\
\n\
[KDE Action Restrictions]\n\
action/lock_screen=false\n\
logout=false\n\
\n\
[General]\n\
BrowserApplication=firefox.desktop" > /etc/xdg/kdeglobals

# Wine, Winetricks, and launchers, this process must be consistent with https://wiki.winehq.org/Ubuntu
ARG WINE_BRANCH=staging
RUN if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
    mkdir -pm755 /etc/apt/keyrings && curl -fsSL -o /etc/apt/keyrings/winehq-archive.key "https://dl.winehq.org/wine-builds/winehq.key" && \
    curl -fsSL -o "/etc/apt/sources.list.d/winehq-$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"').sources" "https://dl.winehq.org/wine-builds/ubuntu/dists/$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"')/winehq-$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"').sources" && \
    apt-get update && apt-get install --install-recommends -y \
        winehq-${WINE_BRANCH} && \
    apt-get install --no-install-recommends -y \
        q4wine \
        playonlinux && \
    LUTRIS_VERSION="$(curl -fsSL "https://api.github.com/repos/lutris/lutris/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    curl -o lutris.deb -fsSL "https://github.com/lutris/lutris/releases/download/v${LUTRIS_VERSION}/lutris_${LUTRIS_VERSION}_all.deb" && apt-get install --no-install-recommends -y ./lutris.deb && rm -f lutris.deb && \
    HEROIC_VERSION="$(curl -fsSL "https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    curl -o heroic_launcher.deb -fsSL "https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v${HEROIC_VERSION}/heroic_${HEROIC_VERSION}_$(dpkg --print-architecture).deb" && apt-get install --no-install-recommends -y ./heroic_launcher.deb && rm -f heroic_launcher.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/* && \
    curl -o /usr/bin/winetricks -fsSL "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" && \
    chmod 755 /usr/bin/winetricks && \
    curl -o /usr/share/bash-completion/completions/winetricks -fsSL "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion"; fi

# Install latest Selkies-GStreamer (https://github.com/selkies-project/selkies-gstreamer) build, Python application, and web application, should be consistent with Selkies-GStreamer documentation
ARG PIP_BREAK_SYSTEM_PACKAGES=1
RUN apt-get update && apt-get install --no-install-recommends -y \
        # GStreamer dependencies
        python3-pip \
        python3-dev \
        python3-gi \
        python3-setuptools \
        python3-wheel \
        libaa1 \
        bzip2 \
        libgcrypt20 \
        libcairo-gobject2 \
        libpangocairo-1.0-0 \
        libgdk-pixbuf2.0-0 \
        libsoup2.4-1 \
        libsoup-gnome2.4-1 \
        libgirepository-1.0-1 \
        glib-networking \
        libglib2.0-0 \
        libjson-glib-1.0-0 \
        libgudev-1.0-0 \
        alsa-utils \
        jackd2 \
        libjack-jackd2-0 \
        libpulse0 \
        libogg0 \
        libopus0 \
        libvorbis-dev \
        libjpeg-turbo8 \
        libopenjp2-7 \
        libvpx-dev \
        libwebp-dev \
        x264 \
        x265 \
        libdrm2 \
        libegl1 \
        libgl1 \
        libopengl0 \
        libgles1 \
        libgles2 \
        libglvnd0 \
        libglx0 \
        wayland-protocols \
        libwayland-dev \
        libwayland-egl1 \
        wmctrl \
        xsel \
        xdotool \
        x11-utils \
        x11-xserver-utils \
        xserver-xorg-core \
        libx11-xcb1 \
        libxcb-dri3-0 \
        libxkbcommon0 \
        libxdamage1 \
        libxfixes3 \
        libxv1 \
        libxtst6 \
        libxext6 && \
    if [ "$(grep VERSION_ID= /etc/os-release | cut -d= -f2 | tr -d '\"')" \> "20.04" ]; then apt-get install --no-install-recommends -y xcvt libopenh264-dev libde265-0 svt-av1 aom-tools; else apt-get install --no-install-recommends -y mesa-utils-extra; fi && \
    # Automatically fetch the latest selkies-gstreamer version and install the components
    SELKIES_VERSION="$(curl -fsSL "https://api.github.com/repos/selkies-project/selkies-gstreamer/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /opt && curl -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/gstreamer-selkies_gpl_v${SELKIES_VERSION}_ubuntu$(grep VERSION_ID= /etc/os-release | cut -d= -f2 | tr -d '\"')_$(dpkg --print-architecture).tar.gz" | tar -xzf - && \
    cd /tmp && curl -O -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" && pip3 install --no-cache-dir --force-reinstall "selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" && rm -f "selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" && \
    cd /opt && curl -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies-gstreamer-web_v${SELKIES_VERSION}.tar.gz" | tar -xzf - && \
    cd /tmp && curl -o selkies-js-interposer.deb -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies-js-interposer_v${SELKIES_VERSION}_ubuntu$(grep VERSION_ID= /etc/os-release | cut -d= -f2 | tr -d '\"')_$(dpkg --print-architecture).deb" && apt-get update && apt-get install --no-install-recommends -y ./selkies-js-interposer.deb && rm -f selkies-js-interposer.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/*
# Add configuration for Selkies-GStreamer Joystick interposer
ENV SELKIES_INTERPOSER='/usr/$LIB/selkies_joystick_interposer.so'
ENV LD_PRELOAD="${SELKIES_INTERPOSER}${LD_PRELOAD:+:${LD_PRELOAD}}"
ENV SDL_JOYSTICK_DEVICE=/dev/input/js0

# Install the KasmVNC web interface and RustDesk for fallback
RUN KASMVNC_VERSION="$(curl -fsSL "https://api.github.com/repos/kasmtech/KasmVNC/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    # Remove sed from noble to jammy after new release
    cd /tmp && curl -o kasmvncserver.deb -fsSL "https://github.com/kasmtech/KasmVNC/releases/download/v${KASMVNC_VERSION}/kasmvncserver_$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"' | sed 's/noble/jammy/')_${KASMVNC_VERSION}_$(dpkg --print-architecture).deb" && apt-get update && apt-get install --no-install-recommends -y ./kasmvncserver.deb libdatetime-perl && rm -f kasmvncserver.deb && \
    RUSTDESK_VERSION="$(curl -fsSL "https://api.github.com/repos/rustdesk/rustdesk/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /tmp && curl -o rustdesk.deb -fsSL "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-$(uname -m).deb" && apt-get update && apt-get install --no-install-recommends -y ./rustdesk.deb && rm -f rustdesk.deb && \
    YQ_VERSION="$(curl -fsSL "https://api.github.com/repos/mikefarah/yq/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /tmp && curl -o yq -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_$(dpkg --print-architecture)" && install ./yq /usr/bin/ && rm -f yq && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/*
ENV PATH="${PATH:+${PATH}:}/usr/lib/rustdesk"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}/usr/lib/rustdesk/lib"

# Add custom packages right below this comment, or use FROM in a new container and replace entrypoint.sh or supervisord.conf, and set ENTRYPOINT to /usr/bin/supervisord

# Copy scripts and configurations used to start the container with `--chown=1000:1000`
COPY --chown=1000:1000 entrypoint.sh /etc/entrypoint.sh
RUN chmod 755 /etc/entrypoint.sh
COPY --chown=1000:1000 selkies-gstreamer-entrypoint.sh /etc/selkies-gstreamer-entrypoint.sh
RUN chmod 755 /etc/selkies-gstreamer-entrypoint.sh
COPY --chown=1000:1000 kasmvnc-entrypoint.sh /etc/kasmvnc-entrypoint.sh
RUN chmod 755 /etc/kasmvnc-entrypoint.sh
COPY --chown=1000:1000 supervisord.conf /etc/supervisord.conf
RUN chmod 755 /etc/supervisord.conf

# Configure coTURN script
RUN echo "#!/bin/bash\n\
set -e\n\
turnserver \
    --verbose \
    --listening-ip=\"0.0.0.0\" \
    --listening-ip=\"::\" \
    --listening-port=\"\${SELKIES_TURN_PORT:-3478}\" \
    --realm=\"\${TURN_REALM:-example.com}\" \
    --external-ip=\"\${SELKIES_TURN_HOST:-\$(curl -fsSL checkip.amazonaws.com)}\" \
    --min-port=\"\${TURN_MIN_PORT:-49152}\" \
    --max-port=\"\${TURN_MAX_PORT:-65535}\" \
    --channel-lifetime=\"\${TURN_CHANNEL_LIFETIME:--1}\" \
    --lt-cred-mech \
    --user \"selkies:\${TURN_RANDOM_PASSWORD}\" \
    --no-cli \
    --cli-password=\"\${TURN_RANDOM_PASSWORD:-\$(tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 24)}\" \
    --allow-loopback-peers \
    \${TURN_EXTRA_ARGS} \$@\
" > /etc/start-turnserver.sh && chmod 755 /etc/start-turnserver.sh

SHELL ["/bin/sh", "-c"]

USER 0
# Enable sudo through sudo-root with uid 0
RUN if [ -d /usr/libexec/sudo ]; then SUDO_LIB="/usr/libexec/sudo"; else SUDO_LIB="/usr/lib/sudo"; fi && \
    chown -R -f --no-preserve-root root:root /usr/bin/sudo-root /etc/sudo.conf /etc/sudoers /etc/sudoers.d /etc/sudo_logsrvd.conf "${SUDO_LIB}" || echo 'Failed to provide root permissions in some paths relevant to sudo' && \
    chmod -f 4755 /usr/bin/sudo-root || echo 'Failed to set chmod with sudo-root'
USER 1000

ENV PIPEWIRE_LATENCY="32/48000"
ENV XDG_RUNTIME_DIR=/tmp/runtime-ubuntu
ENV PIPEWIRE_RUNTIME_DIR="${PIPEWIRE_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-/tmp}}"
ENV PULSE_RUNTIME_PATH="${PULSE_RUNTIME_PATH:-${XDG_RUNTIME_DIR:-/tmp}/pulse}"
ENV PULSE_SERVER="${PULSE_SERVER:-unix:${PULSE_RUNTIME_PATH:-${XDG_RUNTIME_DIR:-/tmp}/pulse}/native}"

USER 1000
ENV SHELL=/bin/bash
ENV USER=ubuntu
WORKDIR /home/ubuntu

EXPOSE 8080

ENTRYPOINT ["/usr/bin/supervisord"]
