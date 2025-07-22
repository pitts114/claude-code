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
  libpq-dev \
  # Redis client
  redis-tools \
  # Additional dev tools
  vim \
  htop \
  tree

# Install Docker CE using official APT repository (secure method)
RUN apt-get update && \
    apt-get install -y ca-certificates curl gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras uidmap dbus-user-session fuse-overlayfs slirp4netns

# Install GitHub CLI from official repository (ensures latest version)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh

# Create ubuntu user with home directory
RUN useradd -m -s /bin/bash ubuntu

# Ensure default ubuntu user has access to /usr/local/share
RUN mkdir -p /usr/local/share && \
  chown -R ubuntu:ubuntu /usr/local/share && \
  usermod -aG docker ubuntu

# Persist bash history.
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R ubuntu:ubuntu /commandhistory

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

# Rootless docker setup
RUN mkdir -p /run/user/1000 && chown ubuntu:ubuntu /run/user/1000 && chmod 700 /run/user/1000
RUN echo 'export "PATH=$HOME/bin:$PATH"' >> /home/ubuntu/.bashrc && \
  echo 'export "XDG_RUNTIME_DIR=/run/user/1000"' >> /home/ubuntu/.bashrc && \
  echo 'export "DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock"' >> /home/ubuntu/.bashrc

# Set up non-root user
USER ubuntu

# Install rootless Docker setup
RUN dockerd-rootless-setuptool.sh install --skip-iptables --force

# Install rvm and Ruby 3.4.4 (early for better Docker layer caching)
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io  < /dev/null |  bash -s stable

# Source rvm in shell profiles
RUN echo 'source ~/.rvm/scripts/rvm' >> ~/.bashrc

# Install Ruby 3.4.4 via rvm (disable autolibs to skip system requirements)
RUN /bin/bash -l -c "rvm install 3.4.4 --disable-binary --autolibs=disable && rvm use 3.4.4 --default"

# Install global Ruby gems
RUN /bin/bash -l -c "gem install bundler rails"

# Configure bash with better prompt and colors
RUN echo 'export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc && \
  echo 'alias ls="ls --color=auto"' >> ~/.bashrc && \
  echo 'alias grep="grep --color=auto"' >> ~/.bashrc && \
  echo 'alias cld="claude --dangerously-skip-permissions"' >> ~/.bashrc


# Install nvm and Node.js 18.20.8
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc && \
  echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc && \
  echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc && \
  echo 'export PATH="$NVM_DIR/versions/node/$(nvm current)/bin:$PATH"' >> ~/.bashrc

# Install Node.js 18.20.8 via nvm
RUN /bin/bash -c "source ~/.nvm/nvm.sh && nvm install 18.20.8 && nvm use 18.20.8 && nvm alias default 18.20.8"

# Install global npm packages (following Anthropic pattern)
RUN /bin/bash -c "source ~/.nvm/nvm.sh && npm install -g @anthropic-ai/claude-code yarn"

# Configure Git basic settings (authentication handled by gh auth setup-git)
RUN git config --global init.defaultBranch main
# Set the default shell to sh
ENV SHELL=/bin/sh

# Copy and set up firewall script
COPY init-firewall.sh entrypoint.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh /usr/local/bin/entrypoint.sh && \
  echo "ubuntu ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/ubuntu-firewall && \
  chmod 0440 /etc/sudoers.d/ubuntu-firewall

# Note: .claude configuration is now mounted as volumes in docker-compose.yml
# This provides live updates and proper separation of commands vs runtime data

# Set entrypoint for runtime GitHub authentication
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
USER ubuntu
