#!/bin/bash
set -e

echo "=== Step 1: Generate test sequences ==="
node gen_sequences.ts

echo ""
echo "=== Step 2: Upload sequences to S3 ==="
aws s3 sync --delete out/ s3://jbrowse.org/demos/msabench/ --size-only

echo ""
echo "=== Done! ==="
