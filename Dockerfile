FROM ubuntu:19.10
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update && \
    apt-get install -qqy --no-install-recommends \
      curl \
      openjdk-8-jdk \
      unzip \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure
ENV ANDROID_HOME "/sdk/"
ENV PATH "$PATH:/sdk/tools"
# See versions => https://developer.android.com/studio/index.html#downloads
RUN curl -s https://dl.google.com/android/repository/commandlinetools-linux-6200805_latest.zip > /sdk.zip && \
    unzip /sdk.zip -d /sdk && \
    rm -v /sdk.zip
RUN mkdir -p /sdk/licenses/
ADD /licenses/* /sdk/licenses/
RUN mkdir -p /root/.android && \
  touch /root/.android/repositories.cfg && \
  /sdk/tools/bin/sdkmanager --sdk_root=${ANDROID_HOME} "tools" && \
  /sdk/tools/bin/sdkmanager --update && \
  /sdk/tools/bin/sdkmanager "ndk;20.0.5594570" && \
  /sdk/tools/bin/sdkmanager "build-tools;29.0.3" && \
  /sdk/tools/bin/sdkmanager "platforms;android-29" && \
  /sdk/tools/bin/sdkmanager "platform-tools" && \
  /sdk/tools/bin/sdkmanager "extras;android;m2repository" && \
  /sdk/tools/bin/sdkmanager "extras;google;google_play_services" && \
  /sdk/tools/bin/sdkmanager "extras;google;m2repository"


FROM openjdk:8-slim
COPY --from=0 /sdk/build-tools /sdk/build-tools
COPY --from=0 /sdk/emulator /sdk/emulator
COPY --from=0 /sdk/extras /sdk/extras
COPY --from=0 /sdk/licenses /sdk/licenses
COPY --from=0 /sdk/ndk /sdk/ndk
COPY --from=0 /sdk/patcher /sdk/patcher
COPY --from=0 /sdk/platform-tools /sdk/platform-tools
COPY --from=0 /sdk/platforms /sdk/platforms
COPY --from=0 /sdk/tools /sdk/tools
COPY --from=0 /root/.android /root/.android

RUN apt-get update -qq && apt-get install -y git curl gnupg2

ENV ANDROID_HOME "/sdk/"
ENV ANDROID_SDK_ROOT "/sdk/"
ENV PATH "$PATH:/sdk/tools:/sdk/platform-tools"
ENV HOME "/root"

RUN groupadd -g 1000 jenkins
RUN useradd -m -g jenkins -u 1000 jenkins
RUN usermod -a -G root jenkins
RUN chmod -R 777 /root

ADD debug.keystore /root/.android/
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && \
  apt-get update -y && apt-get install google-cloud-sdk -y
