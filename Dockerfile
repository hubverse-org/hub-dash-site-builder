FROM ubuntu:jammy
ARG QUARTO_VERSION="1.5.57"
ARG YQ_VERSION="v4.44.3"
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
RUN useradd -s /bin/bash -m docker \
  && usermod -a -G staff docker \
  && apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  locales \
  wget \
  && rm -rf /var/lib/apt/lists/* \
  && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen en_US.utf8 \
  && /usr/sbin/update-locale LANG=en_US.UTF-8 \
  && wget https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb \
  && dpkg -i quarto-*-linux-amd64.deb
RUN wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64.tar.gz -O - |\
  tar xz && mv yq_linux_amd64 /usr/bin/yq 

WORKDIR /static
COPY static /static
COPY render.sh /usr/local/bin/render.sh
COPY modify-quarto-yml.sh /usr/local/bin/modify-quarto-yml.sh
RUN chmod u+x /usr/local/bin/render.sh /usr/local/bin/modify-quarto-yml.sh
CMD ["render.sh"]
