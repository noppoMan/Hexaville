FROM ubuntu:16.04

RUN apt-get update -y
RUN apt-get install -y clang \
  libicu-dev \
  libbsd-dev \
  uuid-dev \
  git \
  libxml2-dev \
  libxslt1-dev \
  python-dev \
  libcurl4-openssl-dev \
  emacs \
  wget \
  zip

ENV SWIFT_VERSION="swift-4.2"
ENV SWIFT_DOWNLOAD_URL=https://swift.org/builds/${SWIFT_VERSION}-release/ubuntu1404/${SWIFT_VERSION}-RELEASE/${SWIFT_VERSION}-RELEASE-ubuntu16.04.tar.gz
ENV SWIFTFILE=${SWIFT_VERSION}-RELEASE-ubuntu16.04
ENV BUILD_CONFIGURATION=release
ENV DEST=/Hexaville/.build

RUN wget $SWIFT_DOWNLOAD_URL
RUN tar -zxf $SWIFTFILE.tar.gz
ENV PATH $PWD/$SWIFTFILE/usr/bin:"${PATH}"

COPY . Hexaville

WORKDIR Hexaville

RUN mkdir -p .build/release

CMD ["/bin/bash", "./Scripts/zip.sh"]
