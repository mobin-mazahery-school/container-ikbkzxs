# --- STAGE 1: Fetch Pre-Compiled Production Binaries Directly ---
FROM alpine:latest AS fetcher
RUN apk add --no-cache curl tar wget

# Download official compiled GOST v3 binary directly
RUN wget https://github.com/go-gost/gost/releases/download/v3.2.6/gost_3.2.6_linux_amd64.tar.gz && \
    tar -xf gost_3.2.6_linux_amd64.tar.gz && \
    mv gost /usr/local/bin/gost && \
    chmod +x /usr/local/bin/gost

# Download official compiled GoTTY binary directly
RUN wget https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz && \
    tar -xf gotty_linux_amd64.tar.gz && \
    mv gotty /usr/local/bin/gotty && \
    chmod +x /usr/local/bin/gotty


# --- STAGE 2: Construct the Main Running Stack ---
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=production

# Install essential dev utilities, runtime dependencies, Caddy, and Nginx
# Fixed: Node.js and Caddy setup scripts are optimized to use modern, certified Ubuntu 24.04 repository standards
RUN apt update && apt install -y --no-install-recommends \
    curl ca-certificates gnupg git build-essential python3 python3-pip python3-venv \
    supervisor nginx sqlite3 libcap2-bin wget unzip rsync debian-keyring debian-archive-keyring apt-transport-https \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list \
    && chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && chmod o+r /etc/apt/sources.list.d/caddy-stable.list \
    && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt update \
    && apt install -y nodejs caddy \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Install Hugging Face Hub CLI
RUN pip3 install --no-cache-dir --break-system-packages "huggingface_hub[cli]"

# Install code-server (VSCode Web Engine)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Deploy clean binaries extracted securely from Stage 1
COPY --from=fetcher /usr/local/bin/gost /usr/local/bin/gost
COPY --from=fetcher /usr/local/bin/gotty /usr/local/bin/gotty
COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared

# <fixme> 
# Download & Setup Nginx Proxy Manager Frontend/Backend Frameworks
# WORKDIR /app
# RUN curl -L https://github.com -o npm.tar.gz \
#     && tar -xzf npm.tar.gz --strip-components=1 && rm npm.tar.gz \
#     && cd /app/backend && npm ci --prod \
#     && mkdir -p /tmp/nginx /var/log/nginx /var/lib/nginx /var/cache/nginx /data /etc/nginx/logs \
#     && cp -r /app/global /etc/nginx/ \
#     && ln -sf /app/backend /app/dist
# </fixme>

# Build the custom landing dashboard workspace folder
RUN mkdir -p /var/www/dashboard
COPY index.html /var/www/dashboard/index.html

# Copy remaining configuration structures
COPY Caddyfile /etc/caddy/Caddyfile
COPY gost.json /etc/gost/gost.json
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY backup-sync.sh /usr/local/bin/backup-sync.sh
RUN chmod +x /usr/local/bin/backup-sync.sh

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
