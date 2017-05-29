FROM ubuntu:14.04

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
  wget

ENV SWIFT_DOWNLOAD_URL=https://swift.org/builds/swift-3.1-release/ubuntu1404/swift-3.1-RELEASE/swift-3.1-RELEASE-ubuntu14.04.tar.gz
ENV SWIFTFILE=swift-3.1-RELEASE-ubuntu14.04

RUN wget $SWIFT_DOWNLOAD_URL
RUN tar -zxf $SWIFTFILE.tar.gz
ENV PATH $PWD/$SWIFTFILE/usr/bin:"${PATH}"

COPY . Hexaville

WORKDIR Hexaville

CMD swift build
