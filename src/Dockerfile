FROM golang:1.22-alpine AS builder
RUN apk add --no-cache git tar wget
RUN git clone https://github.com /go/src/://github.com && \
    cd /go/src/://github.com/cmd/gost && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w" -o /usr/local/bin/gost
RUN wget https://github.com && \
    tar -xzf gotty_linux_amd64.tar.gz && mv gotty /usr/local/bin/

FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=production

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg git build-essential python3 python3-pip python3-venv \
    supervisor nginx sqlite3 libcap2-bin wget unzip rsync \
    && curl -fsSL https://nodesource.com | bash - \
    && apt-get install -y nodejs \
    && curl -fsSL https://cloudsmith.io | tee /etc/apt/sources.list.d/caddy-stable.list \
    && curl -fsSL https://cloudsmith.io | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] https://cloudsmith.io any main" | tee /etc/apt/sources.list.d/caddy-stable.list \
    && apt-get update && apt-get install -y caddy \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --break-system-packages "huggingface_hub[cli]"
RUN curl -fsSL https://code-server.dev | sh

COPY --from=builder /usr/local/bin/gost /usr/local/bin/gost
COPY --from=builder /usr/local/bin/gotty /usr/local/bin/gotty
COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared

WORKDIR /app
RUN curl -L https://github.com -o npm.tar.gz \
    && tar -xzf npm.tar.gz --strip-components=1 && rm npm.tar.gz \
    && cd /app/backend && npm ci --prod \
    && mkdir -p /tmp/nginx /var/log/nginx /var/lib/nginx /var/cache/nginx /data /etc/nginx/logs \
    && cp -r /app/global /etc/nginx/ \
    && ln -sf /app/backend /app/dist

RUN mkdir -p /var/www/dashboard
COPY index.html /var/www/dashboard/index.html
COPY Caddyfile /etc/caddy/Caddyfile
COPY gost.json /etc/gost/gost.json
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN echo '#!/bin/bash\n\
echo "Checking Hugging Face Bucket for existing persistent snapshots..."\n\
mkdir -p /root/workspace /data /tmp/hf_restore\n\
huggingface-cli buckets sync hf://buckets/$HF_USERNAME/$HF_BUCKET/dev_machine_backup/ /tmp/hf_restore/\n\
if [ -f "/tmp/hf_restore/workspace_snapshot.tar.gz" ]; then\n\
    tar -xzf /tmp/hf_restore/workspace_snapshot.tar.gz -C /\n\
fi\n\
if [ -f "/tmp/hf_restore/npm_snapshot.tar.gz" ]; then\n\
    tar -xzf /tmp/hf_restore/npm_snapshot.tar.gz -C /\n\
fi\n\
rm -rf /tmp/hf_restore\n\
mkdir -p /tmp/hf_staging\n\
while true; do\n\
  tar -czf /tmp/hf_staging/workspace_snapshot.tar.gz -C / root/workspace\n\
  tar -czf /tmp/hf_staging/npm_snapshot.tar.gz -C / data\n\
  huggingface-cli buckets sync /tmp/hf_staging/ hf://buckets/$HF_USERNAME/$HF_BUCKET/dev_machine_backup/ --delete\n\
  sleep 300\n\
done' > /usr/local/bin/backup-sync.sh && chmod +x /usr/local/bin/backup-sync.sh

# Port 5000 is used as the base application routing link
EXPOSE 5000
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
