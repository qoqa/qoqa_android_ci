FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && \
    apt-get install -qqy --no-install-recommends \
      curl \
      html2text \
      openjdk-8-jdk \
      libc6-i386 \
      lib32stdc++6 \
      lib32gcc1 \
      lib32ncurses5 \
      lib32z1 \
      unzip \
      git \
      ssh \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure

# See versions => https://developer.android.com/studio/index.html#downloads
ENV VERSION_SDK_TOOLS "4333796"

ENV ANDROID_HOME "/sdk/"
ENV PATH "$PATH:/sdk/tools"

RUN curl -s https://dl.google.com/android/repository/sdk-tools-linux-${VERSION_SDK_TOOLS}.zip > /sdk.zip && \
    unzip /sdk.zip -d /sdk && \
    rm -v /sdk.zip

RUN mkdir -p /sdk/licenses/
ADD /licenses/* /sdk/licenses/

ADD packages.txt /sdk/
RUN mkdir -p /root/.android && \
  touch /root/.android/repositories.cfg && \
  /sdk/tools/bin/sdkmanager --update && \
  /sdk/tools/bin/sdkmanager "build-tools;28.0.3" && \
  /sdk/tools/bin/sdkmanager "platforms;android-28" && \
  /sdk/tools/bin/sdkmanager "platform-tools" && \
  /sdk/tools/bin/sdkmanager "extras;android;m2repository" && \
  /sdk/tools/bin/sdkmanager "extras;google;google_play_services" && \
  /sdk/tools/bin/sdkmanager "extras;google;m2repository"