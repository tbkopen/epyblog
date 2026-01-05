#!/usr/bin/env bash
set -euo pipefail

# -------- CONFIG --------
CSV_URL="https://docs.google.com/spreadsheets/d/e/2PACX-1vR0YdZAnc-TzU1_lOv7qVHCbcmcQ21g50KNXBVXltqWmbz28TgXWIeNBFKE7MmwSwgHDxdaJ06nsBFy/pub?gid=0&single=true&output=csv"
DATA_DIR="_data"
OUT_FILE="${DATA_DIR}/topics.csv"
TMP_FILE="${DATA_DIR}/.topics_tmp.csv"
# ------------------------

echo "Updating topics.csv from Google Sheet..."

# Ensure data directory exists
mkdir -p "${DATA_DIR}"

# Fetch CSV
curl -fsSL "${CSV_URL}" -o "${TMP_FILE}"

# Basic sanity check: file should not be empty
if [ ! -s "${TMP_FILE}" ]; then
  echo "ERROR: Downloaded CSV is empty."
  exit 1
fi

# Optional sanity check: header row exists
head -n 1 "${TMP_FILE}" | grep -q "Title" || {
  echo "ERROR: CSV header does not look correct."
  exit 1
}

# Replace old file atomically
mv "${TMP_FILE}" "${OUT_FILE}"

echo "✓ topics.csv updated successfully"
