FROM ubuntu:23.10
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
RUN curl -s https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip > /sdk.zip && \
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
RUN /sdk/cmdline-tools/tools/bin/sdkmanager "build-tools;34.0.0"
RUN /sdk/cmdline-tools/tools/bin/sdkmanager "platforms;android-34"
RUN /sdk/cmdline-tools/tools/bin/sdkmanager "platform-tools"
RUN /sdk/cmdline-tools/tools/bin/sdkmanager "extras;android;m2repository"
RUN /sdk/cmdline-tools/tools/bin/sdkmanager "extras;google;google_play_services"
RUN /sdk/cmdline-tools/tools/bin/sdkmanager "extras;google;m2repository"


FROM openjdk:17-slim
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
RUN curl "https://services.gradle.org/distributions/gradle-8.2.1-bin.zip" -L --output /root/gradle.zip && \
  unzip -d /opt/gradle /root/gradle.zip && \
  ls /opt/gradle

ADD settings.gradle /
RUN /opt/gradle/gradle-8.2.1/bin/gradle wrapper --gradle-version=8.2.1
RUN ./gradlew --version
RUN chown -R jenkins:jenkins /root/.gradle && rm -rf /root/.gradle/daemon/8.2.1/*.lock
ENV PATH "$PATH:/opt/gradle/gradle-8.2.1/bin"
ENV GRADLE_USER_HOME "/root/.gradle"
