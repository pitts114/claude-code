# Pre-cache Docker images using multi-stage build (forces Docker to download them)
FROM postgres:17 AS postgres-cache
FROM redis:7-alpine AS redis-cache
FROM confluentinc/cp-kafka:7.4.0 AS kafka-cache
FROM confluentinc/cp-zookeeper:7.2.15 AS zookeeper-cache

# Main build stage
FROM ubuntu:22.04

ARG TZ
ENV TZ="$TZ"

# Install basic development tools and iptables/ipset
RUN apt update && apt install -y less \
  git \
  procps \
  sudo \
  fzf \
  wget \
  curl \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  bash \
  ca-certificates \
  gnupg \
  lsb-release \
  software-properties-common \
  netcat \
  # Ruby build dependencies
  build-essential \
  ruby-build \
  libyaml-dev \
  libssl-dev \
  libreadline-dev \
  zlib1g-dev \
  libncurses5-dev \
  libffi-dev \
  libgdbm-dev \
  libbz2-dev \
  # PostgreSQL client
  postgresql-client \
  # Redis client
  redis-tools \
  # Additional dev tools
  vim \
  htop \
  tree

# Create ubuntu user with home directory
RUN useradd -m -s /bin/bash ubuntu

# Ensure default ubuntu user has access to /usr/local/share
RUN mkdir -p /usr/local/share && \
  chown -R ubuntu:ubuntu /usr/local/share

ARG USERNAME=ubuntu

# Persist bash history.
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/ubuntu/.claude && \
  chown -R ubuntu:ubuntu /workspace /home/ubuntu/.claude

WORKDIR /workspace

# syntax highlighting
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/0.18.2/git-delta_0.18.2_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_0.18.2_${ARCH}.deb" && \
  rm "git-delta_0.18.2_${ARCH}.deb"

# Set up non-root user
USER ubuntu

# Configure bash with better prompt and colors
RUN echo 'export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc
RUN echo 'alias ls="ls --color=auto"' >> ~/.bashrc
RUN echo 'alias grep="grep --color=auto"' >> ~/.bashrc

# Install nvm and Node.js 18.20.8
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
RUN echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
RUN echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
RUN echo 'export PATH="$NVM_DIR/versions/node/$(nvm current)/bin:$PATH"' >> ~/.bashrc

# Install Node.js 18.20.8 via nvm
RUN /bin/bash -c "source ~/.nvm/nvm.sh && nvm install 18.20.8 && nvm use 18.20.8 && nvm alias default 18.20.8"

# Install rvm and Ruby 3.4.4
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s stable

# Source rvm in shell profiles
RUN echo 'source ~/.rvm/scripts/rvm' >> ~/.bashrc

# Install Ruby 3.4.4 via rvm (disable autolibs to skip system requirements)
RUN /bin/bash -l -c "rvm install 3.4.4 --disable-binary --autolibs=disable && rvm use 3.4.4 --default"

# Install global Ruby gems
RUN /bin/bash -l -c "gem install bundler rails"

# Install global npm packages (following Anthropic pattern)
RUN /bin/bash -c "source ~/.nvm/nvm.sh && npm install -g @anthropic-ai/claude-code yarn"

# Set the default shell to sh
ENV SHELL=/bin/sh

# Copy and set up firewall script
COPY init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "ubuntu ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/ubuntu-firewall && \
  chmod 0440 /etc/sudoers.d/ubuntu-firewall
USER ubuntu
