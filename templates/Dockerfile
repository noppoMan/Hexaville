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
  wget

ENV DEST={{DEST}}
ENV EXECUTABLE_NAME={{EXECUTABLE_NAME}}
ENV SWIFT_DOWNLOAD_URL={{SWIFT_DOWNLOAD_URL}}
ENV SWIFTFILE={{SWIFTFILE}}

RUN wget $SWIFT_DOWNLOAD_URL
RUN tar -zxf $SWIFTFILE.tar.gz
ENV PATH $PWD/$SWIFTFILE/usr/bin:"${PATH}"

COPY . hexaville-app

WORKDIR hexaville-app

CMD ["/bin/bash", "./build-swift.sh"]
