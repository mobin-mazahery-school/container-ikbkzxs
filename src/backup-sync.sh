#!/bin/bash
echo "Checking Hugging Face Bucket for existing persistent snapshots..."
mkdir -p /root/workspace
mkdir -p /data
mkdir -p /tmp/hf_restore

# 1. Pull down data if it exists
huggingface-cli buckets sync hf://buckets/$HF_USERNAME/$HF_BUCKET/dev_machine_backup/ /tmp/hf_restore/

if [ -f "/tmp/hf_restore/workspace_snapshot.tar.gz" ]; then
    echo "Restoring workspace filesystem..."
    tar -xzf /tmp/hf_restore/workspace_snapshot.tar.gz -C /
fi

if [ -f "/tmp/hf_restore/npm_snapshot.tar.gz" ]; then
    echo "Restoring Nginx Proxy Manager configuration engines..."
    tar -xzf /tmp/hf_restore/npm_snapshot.tar.gz -C /
fi

rm -rf /tmp/hf_restore
echo "Workspace system recovery finalized successfully. Booting applications..."

# 2. Start the infinite 5-minute backup loop
mkdir -p /tmp/hf_staging
while true; do
  echo "Compressing environment snapshots into atomic blocks..."
  tar -czf /tmp/hf_staging/workspace_snapshot.tar.gz -C / root/workspace
  tar -czf /tmp/hf_staging/npm_snapshot.tar.gz -C / data
  
  echo "Pushing updates to Hugging Face..."
  huggingface-cli buckets sync /tmp/hf_staging/ hf://buckets/$HF_USERNAME/$HF_BUCKET/dev_machine_backup/ --delete
  
  sleep 300
done
