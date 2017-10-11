FROM ubuntu:17.10

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

ENV VERSION_SDK_TOOLS "3859397"

ENV PATH "$PATH:/sdk/tools"

RUN curl -s https://dl.google.com/android/repository/sdk-tools-linux-${VERSION_SDK_TOOLS}.zip > /sdk.zip && \
    unzip /sdk.zip -d /sdk && \
    rm -v /sdk.zip

RUN mkdir -p /sdk/licenses/ \
  && echo -e "\n8933bad161af4178b1185d1a37fbf41ea5269c55" > /sdk/licenses/android-sdk-license \
  && echo -e "\nd56f5187479451eabf01fb78af6dfcb131a6481e" > /sdk/licenses/android-sdk-license \
  && echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > /sdk/licenses/android-sdk-preview-license \
  && echo -e "\n504667f4c0de7af1a06de9f4b1727b84351f2910" > /sdk/licenses/android-sdk-preview-license

ADD packages.txt /sdk/
RUN mkdir -p /root/.android && \
  touch /root/.android/repositories.cfg && \
  /sdk/tools/bin/sdkmanager --update && \
  (while [ 1 ]; do sleep 5; echo y; done) | /sdk/tools/bin/sdkmanager --package_file=/sdk/packages.txt