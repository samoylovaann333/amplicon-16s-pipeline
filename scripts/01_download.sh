#!/usr/bin/env bash
# scripts/01_download.sh — скачивание SRR18136502 с NCBI SRA
set -euo pipefail
source "$(dirname "$0")/../config/params.sh"

echo "════════════════════════════════════════"
echo " 01 · Загрузка данных с NCBI SRA"
echo " Accession: $ACCESSION"
echo "════════════════════════════════════════"

RAW_DIR="$PROJECT_DIR/raw"
mkdir -p "$RAW_DIR"

# ── Пропуск если файлы уже скачаны ───────────────────────────
if [ -f "$RAW_DIR/${SAMPLE_ID}_R1.fastq.gz" ] && [ -f "$RAW_DIR/${SAMPLE_ID}_R2.fastq.gz" ]; then
  echo "[SKIP] Файлы уже существуют: ${SAMPLE_ID}_R1/R2.fastq.gz"
  ls -lh "$RAW_DIR/${SAMPLE_ID}"_R*.fastq.gz
  exit 0
fi

# ── prefetch ──────────────────────────────────────────────────
echo "[INFO] prefetch $ACCESSION ..."
prefetch "$ACCESSION" --output-directory "$RAW_DIR" --progress

# ── fasterq-dump ──────────────────────────────────────────────
echo "[INFO] fasterq-dump → paired FASTQ ..."
fasterq-dump "$RAW_DIR/$ACCESSION/$ACCESSION.sra" \
  --outdir "$RAW_DIR" \
  --split-files \
  --threads "$THREADS" \
  --progress

# ── gzip + rename ─────────────────────────────────────────────
echo "[INFO] Сжатие и переименование..."
gzip -f "$RAW_DIR/${ACCESSION}_1.fastq"
gzip -f "$RAW_DIR/${ACCESSION}_2.fastq"
mv "$RAW_DIR/${ACCESSION}_1.fastq.gz" "$RAW_DIR/${SAMPLE_ID}_R1.fastq.gz"
mv "$RAW_DIR/${ACCESSION}_2.fastq.gz" "$RAW_DIR/${SAMPLE_ID}_R2.fastq.gz"

# ── Проверка ──────────────────────────────────────────────────
R1_COUNT=$(gunzip -c "$RAW_DIR/${SAMPLE_ID}_R1.fastq.gz" | wc -l | awk '{print $1/4}')
R2_COUNT=$(gunzip -c "$RAW_DIR/${SAMPLE_ID}_R2.fastq.gz" | wc -l | awk '{print $1/4}')
echo "[OK] R1: $R1_COUNT reads | R2: $R2_COUNT reads"
ls -lh "$RAW_DIR/"
