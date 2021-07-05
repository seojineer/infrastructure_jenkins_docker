FROM jenkins/jenkins:lts

USER root

# make /bin/sh symlink to bash instead of dash
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

RUN apt-get update && apt-get install -y wget
RUN apt-get update && apt-get install -y gawk git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat cpio bc
RUN apt-get update && apt-get install -y autoconf automake libtool libglib2.0-dev libarchive-dev
RUN apt-get update && apt-get install -y python-git libcap2-bin
  
RUN apt-get update && apt-get install -y lzop
RUN apt-get update && apt-get install -y lynx device-tree-compiler

#ARG user=jenkins
#ARG group=jenkins
#ARG uid=1000
#ARG gid=1000
#RUN groupadd -g ${gid} ${group} && RUN useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_SLAVE_AGENT_PORT 50000
 
RUN apt-get update && apt-get install -y sudo
RUN apt-get update && apt-get install -y apt-transport-https apt-utils software-properties-common

RUN echo "jenkins:jenkins" | chpasswd && adduser jenkins sudo

# HOME directory
VOLUME /var/jenkins_home

# python 3.6
RUN apt-get install -y libgdbm-dev libc6-dev libnss3-dev
RUN apt-get update && apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
		libreadline-dev libsqlite3-dev wget llvm libncurses5-dev libncursesw5-dev \
		tk-dev libffi-dev liblzma-dev
RUN cd /opt \
    && wget https://www.python.org/ftp/python/3.6.10/Python-3.6.10.tar.xz \
    && tar xvf Python-3.6.10.tar.xz \
    && cd Python-3.6.10 \
    && ./configure && make && make install

RUN apt-get update && apt-get install -y vim locales rsync 

RUN apt-get update && apt-get install -y python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 xterm
RUN apt-get update && apt-get install -y img2simg simg2img
RUN pip3 install --upgrade pip
RUN pip3 install pycrypto

#RUN locale-gen en_US.UTF-8
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
	dpkg-reconfigure --frontend=noninteractive locales && \
	update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8 

RUN rm -rf /var/lib/apt/lists/*
RUN apt clean
RUN apt-get update && apt-get install -y tzdata keyboard-configuration console-setup
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata keyboard-configuration console-setup

#Android Build setup
RUN apt-get update && apt-get install -y curl
ENV ANDROID_EMULATOR_DEPS "file libqt5widgets5"

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs expect $ANDROID_EMULATOR_DEPS \
    && apt-get autoclean

# Install the Android SDK
ENV ANDROID_SDK_URL https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
RUN cd /opt \
    && wget --output-document=android-sdk.zip --quiet $ANDROID_SDK_URL \
    && unzip android-sdk.zip -d android-sdk-linux \
    && rm -f android-sdk.zip \
    && chown -R root:root android-sdk-linux

ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH ${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${PATH}

# Install custom tools
COPY tools /opt/tools
ENV PATH /opt/tools:${PATH}

# repo
RUN cd /opt/tools && wget https://storage.googleapis.com/git-repo-downloads/repo && chmod a+x /opt/tools/repo

# Install Android platform and things
ENV ANDROID_PLATFORM_VERSION 28
ENV ANDROID_BUILD_TOOLS_VERSION 28.0.3
ENV ANDROID_EXTRA_PACKAGES "build-tools;28.0.0" "build-tools;28.0.1" "build-tools;28.0.2"
ENV ANDROID_REPOSITORIES "extras;android;m2repository" "extras;google;m2repository"
ENV ANDROID_CONSTRAINT_PACKAGES "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.1" "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.0"
ENV ANDROID_EMULATOR_PACKAGE "system-images;android-$ANDROID_PLATFORM_VERSION;google_apis_playstore;x86_64"
RUN android-accept-licenses "sdkmanager --verbose \"platform-tools\" \"emulator\" \"platforms;android-$ANDROID_PLATFORM_VERSION\" \"build-tools;$ANDROID_BUILD_TOOLS_VERSION\" $ANDROID_EXTRA_PACKAGES $ANDROID_REPOSITORIES $ANDROID_CONSTRAINT_PACKAGES $ANDROID_EMULATOR_PACKAGE"
RUN android-avdmanager-create "avdmanager create avd --package \"$ANDROID_EMULATOR_PACKAGE\" --name test --abi \"google_apis_playstore/x86_64\""
ENV PATH ${ANDROID_HOME}/build-tools/${ANDROID_BUILD_TOOLS_VERSION}:${PATH}

# Fix for emulator detect 64bit
ENV SHELL /bin/bash

# Install upload-apk helper
RUN npm install -g xcode-build-tools

# Extra package
RUN apt-get update && apt-get install -y zip libxml2-utils

# Jenkins job builder
RUN pip3 install jenkins-job-builder
RUN pip3 install ruamel_yaml

# Squad report parsing
RUN apt-get update && apt-get install -y libcurl4-gnutls-dev librtmp-dev
RUN pip3 install pycurl

RUN echo "jenkins ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers

USER jenkins
