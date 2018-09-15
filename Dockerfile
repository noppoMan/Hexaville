FROM ubuntu:14.04

RUN apt-get update -y
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt-get install -y clang-3.8 \
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
  zip \
  gcc-7 g++-7
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 60 --slave /usr/bin/g++ g++ /usr/bin/g++-7
RUN update-alternatives --quiet --install /usr/bin/clang clang /usr/bin/clang-3.8 100
RUN update-alternatives --quiet --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.8 100

ENV SWIFT_VERSION="swift-4.1"
ENV SWIFT_DOWNLOAD_URL=https://swift.org/builds/${SWIFT_VERSION}-release/ubuntu1404/${SWIFT_VERSION}-RELEASE/${SWIFT_VERSION}-RELEASE-ubuntu14.04.tar.gz
ENV SWIFTFILE=${SWIFT_VERSION}-RELEASE-ubuntu14.04
ENV BUILD_CONFIGURATION=release
ENV DEST=/Hexaville/.build

RUN wget $SWIFT_DOWNLOAD_URL
RUN tar -zxf $SWIFTFILE.tar.gz
ENV PATH $PWD/$SWIFTFILE/usr/bin:"${PATH}"

COPY . Hexaville

WORKDIR Hexaville

RUN mkdir -p .build/release

CMD ["/bin/bash", "./Scripts/zip.sh"]
