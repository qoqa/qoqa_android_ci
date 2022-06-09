FROM ubuntu:21.10
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update && \
    apt-get install -qqy --no-install-recommends \
      curl \
      default-jdk \
      unzip \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure
ENV ANDROID_SDK_ROOT "/sdk/"
ENV PATH "$PATH:/sdk/cmdline-tools"
# See versions => https://developer.android.com/studio/index.html#downloads
RUN curl -s https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip > /sdk.zip && \
    unzip /sdk.zip -d /sdk && \
    rm -v /sdk.zip
RUN mv /sdk/cmdline-tools /sdk/tools
RUN mkdir /sdk/cmdline-tools
RUN mv /sdk/tools /sdk/cmdline-tools/tools
RUN mkdir -p /sdk/licenses/
ADD /licenses/* /sdk/licenses/
RUN mkdir -p /root/.android
RUN touch /root/.android/repositories.cfg
RUN /sdk/cmdline-tools/tools/bin/sdkmanager "tools"
RUN /sdk/cmdline-tools/tools/bin/sdkmanager --update
RUN /sdk/cmdline-tools/tools/bin/sdkmanager "build-tools;32.0.0"
RUN /sdk/cmdline-tools/tools/bin/sdkmanager "platforms;android-32"
RUN /sdk/cmdline-tools/tools/bin/sdkmanager "platform-tools"
RUN /sdk/cmdline-tools/tools/bin/sdkmanager "extras;android;m2repository"
RUN /sdk/cmdline-tools/tools/bin/sdkmanager "extras;google;google_play_services"
RUN /sdk/cmdline-tools/tools/bin/sdkmanager "extras;google;m2repository"


FROM openjdk:15-slim
COPY --from=0 /sdk/build-tools /sdk/build-tools
COPY --from=0 /sdk/emulator /sdk/emulator
COPY --from=0 /sdk/extras /sdk/extras
COPY --from=0 /sdk/licenses /sdk/licenses
COPY --from=0 /sdk/patcher /sdk/patcher
COPY --from=0 /sdk/platform-tools /sdk/platform-tools
COPY --from=0 /sdk/platforms /sdk/platforms
COPY --from=0 /sdk/cmdline-tools /sdk/cmdline-tools
COPY --from=0 /root/.android /root/.android

RUN apt-get update -qq && apt-get install -y git curl gnupg2

ENV ANDROID_HOME "/sdk/"
ENV ANDROID_SDK_ROOT "/sdk/"
ENV PATH "$PATH:/sdk/cmdline-tools:/sdk/platform-tools"
ENV HOME "/root"

RUN groupadd -g 1000 jenkins
RUN useradd -m -g jenkins -u 1000 jenkins
RUN usermod -a -G root jenkins
RUN chmod -R 777 /root

ADD debug.keystore /root/.android/
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && \
  apt-get update -y && apt-get install google-cloud-sdk unzip -y

RUN mkdir /opt/gradle
RUN curl https://gradle.org/next-steps/?version=7.4.2&format=bin --output /opt/gradle/gradle-7.4.2-bin.zip
RUN unzip -d /opt/gradle /opt/gradle/gradle-7.4.2-bin.zip
RUN /opt/gradle/gradle-7.4.2/bin/gradle wrapper --gradle-version=7.4.2
