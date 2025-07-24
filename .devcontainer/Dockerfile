# Ruby build stage - pre-compile Ruby with RVM for faster builds
FROM ruby:3.4 AS ruby-builder

# Install RVM and Ruby 3.4.4 in the Ruby image
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "source /etc/profile.d/rvm.sh && rvm install 3.4.4 && rvm use 3.4.4 --default"
RUN /bin/bash -l -c "source /etc/profile.d/rvm.sh && gem install bundler rails"

# Install python3 and uv
FROM python:3.12-slim-bookworm
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Main Ubuntu build stage
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
  # Python for SuperClaude
  python3 \
  python3-pip \
  python3-venv \
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

# Copy pre-built RVM and Ruby installation from build stage (much faster than compiling)
COPY --from=ruby-builder /usr/local/rvm /usr/local/rvm
COPY --from=ruby-builder /etc/profile.d/rvm.sh /etc/profile.d/rvm.sh

# Copy uv from python build stage
COPY --from=1 /bin/uv /bin/uvx /usr/local/bin/

# Set up RVM for ubuntu user
RUN echo 'source /usr/local/rvm/scripts/rvm' >> ~/.bashrc && \
    echo 'export PATH="$PATH:/usr/local/rvm/bin"' >> ~/.bashrc

# Configure bundler to install gems in vendor/bundle
RUN /bin/bash -l -c "source /usr/local/rvm/scripts/rvm && bundle config set --global path 'vendor/bundle'"

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

# Install SuperClaude
RUN uv tool install SuperClaude
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
RUN /bin/bash -c "source ~/.nvm/nvm.sh && export PATH=\"$HOME/.local/bin:$HOME/.nvm/versions/node/v18.20.8/bin:$PATH\" && SuperClaude install --profile developer -y"

# Copy project's claude files after SuperClaude installation (preserve SuperClaude installation)
COPY .claude/README.md /home/ubuntu/.claude/README.md
COPY .claude/commands/ /home/ubuntu/.claude/commands/

# Create empty authentication files for volume mounting
RUN echo '{}' > /home/ubuntu/.claude/.credentials.json
RUN echo '{}' > /home/ubuntu/.claude/.claude.json
RUN echo '{}' > /home/ubuntu/.claude/settings.json

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

COPY .claude/commands /home/ubuntu/.claude/commands
COPY .claude/README.md /home/ubuntu/.claude/README

# Set entrypoint for runtime GitHub authentication
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
USER ubuntu
