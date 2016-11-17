FROM java:8
MAINTAINER Alex Filatov <greybax@gmail.com>

## apt-get update
RUN apt-get update && \
    apt-get install -y libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1

# Download and untar Android SDK
ENV ANDROID_SDK_URL http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz
RUN curl -L "${ANDROID_SDK_URL}" | tar --no-same-owner -xz -C /usr/local
ENV ANDROID_HOME /usr/local/android-sdk-linux
ENV ANDROID_SDK /usr/local/android-sdk-linux
ENV PATH ${ANDROID_HOME}/tools:$ANDROID_HOME/platform-tools:$PATH

# Install Android SDK components
# License Id: android-sdk-license-ed0d0a5b
ENV ANDROID_COMPONENTS platform-tools,build-tools-23.0.3,build-tools-24.0.0
# License Id: android-sdk-license-5be876d5
ENV GOOGLE_COMPONENTS extra-android-m2repository,extra-google-m2repository

RUN echo y | android update sdk --no-ui --all --filter "${ANDROID_COMPONENTS}" ; \
    echo y | android update sdk --no-ui --all --filter "${GOOGLE_COMPONENTS}"

# Install dependencies for emulator
RUN echo y | android update sdk --no-ui --all -t `android list sdk --all|grep "SDK Platform Android 6.0, API 23"|awk -F'[^0-9]*' '{print $2}'` && \
    echo y | android update sdk --no-ui --all --filter sys-img-armeabi-v7a-android-23 --force && \
    echo y | android update sdk --no-ui --all --filter sys-img-x86-android-23 --force

RUN echo n | android create avd --force -n "x86" -t android-23 --abi default/x86
RUN echo n | android create avd --force -n "arm" -t android-23 --abi default/armeabi-v7a

# --- Node JS -------------------------------------
# Add the Node.js-maintained repositories to Ubuntu package source list
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
# The nodejs package contains the nodejs binary as well as npm
RUN apt-get install -y nodejs
# "build-essential" required, but were pre-installed in base image
RUN nodejs -v
RUN npm -v

# --- Cordova CLI -------------------------------------
RUN npm install -g cordova
RUN cordova -v

# Copy PWD to container /project directory
ENV PROJECT /project
RUN mkdir $PROJECT
WORKDIR $PROJECT
COPY . $PROJECT

## Cordova build android app and generate .apk
RUN /bin/bash -c 'cd ${PROJECT} && \
    cordova platform add android && \
    cordova build'