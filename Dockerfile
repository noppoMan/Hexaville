FROM ubuntu:14.04

RUN apt-get update -y
RUN apt-get install -y wget

ENV SWIFT_VERSION="swift-4.2"
ENV SWIFT_DOWNLOAD_URL=https://swift.org/builds/${SWIFT_VERSION}-release/ubuntu1404/${SWIFT_VERSION}-RELEASE/${SWIFT_VERSION}-RELEASE-ubuntu14.04.tar.gz
ENV SWIFTFILE=${SWIFT_VERSION}-RELEASE-ubuntu14.04
ENV BUILD_CONFIGURATION=release
ENV DEST=/Hexaville/.build

RUN wget $SWIFT_DOWNLOAD_URL
RUN tar -zxf $SWIFTFILE.tar.gz
ENV PATH $PWD/$SWIFTFILE/usr/bin:"${PATH}"

# basic dependencies
RUN apt-get update && apt-get install -y git build-essential software-properties-common pkg-config locales
RUN apt-get update && apt-get install -y libbsd-dev uuid-dev libxml2-dev libxslt1-dev python-dev libcurl4-openssl-dev
RUN apt-get update && apt-get install -y libicu-dev libblocksruntime0 libssl-dev

# clang
RUN apt-get update && apt-get install -y clang-3.9
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-3.9 100
RUN update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.9 100

RUN apt-get update && apt-get install -y zip

COPY . Hexaville

WORKDIR Hexaville

RUN mkdir -p .build/release

CMD ["/bin/bash", "./Scripts/zip.sh"]