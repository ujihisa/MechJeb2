FROM mono:6.12

# mono:6.12 is based on Debian buster (EOL). Use archive.debian.org for apt.
RUN sed -i \
    -e 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' \
    -e 's|http://deb.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
    -e 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
    /etc/apt/sources.list \
  && printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99no-check-valid-until \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    findutils \
    git \
    make \
    nuget \
    zip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
