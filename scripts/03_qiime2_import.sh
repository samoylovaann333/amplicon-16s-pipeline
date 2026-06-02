#!/usr/bin/env bash
# scripts/03_qiime2_import.sh — импорт в QIIME2 + удаление праймеров
set -euo pipefail
source "$(dirname "$0")/../config/params.sh"
set +u
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$QIIME2_ENV"
set -u

echo "════════════════════════════════════════"
echo " 03 · QIIME2: импорт + cutadapt"
echo "════════════════════════════════════════"

TRIM_DIR="$PROJECT_DIR/trimmed"
Q2_DIR="$PROJECT_DIR/qiime2"
mkdir -p "$Q2_DIR"

# ── Манифест ──────────────────────────────────────────────────
MANIFEST="$PROJECT_DIR/manifest.tsv"
printf "sample-id\tforward-absolute-filepath\treverse-absolute-filepath\n" > "$MANIFEST"
printf "%s\t%s\t%s\n" \
  "$SAMPLE_ID" \
  "$TRIM_DIR/${SAMPLE_ID}_R1_paired.fastq.gz" \
  "$TRIM_DIR/${SAMPLE_ID}_R2_paired.fastq.gz" >> "$MANIFEST"

echo "[INFO] Манифест создан: $MANIFEST"

# ── Импорт ────────────────────────────────────────────────────
echo "[INFO] Импорт данных в QIIME2..."
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path "$MANIFEST" \
  --input-format PairedEndFastqManifestPhred33V2 \
  --output-path "$Q2_DIR/demux-paired.qza"

qiime demux summarize \
  --i-data "$Q2_DIR/demux-paired.qza" \
  --o-visualization "$Q2_DIR/demux-summary.qzv"

# ── Cutadapt: удаление праймеров ──────────────────────────────
echo "[INFO] Cutadapt: удаление праймеров 515F/806R..."
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences "$Q2_DIR/demux-paired.qza" \
  --p-front-f "$PRIMER_F" \
  --p-front-r "$PRIMER_R" \
  --p-discard-untrimmed \
  --p-cores "$THREADS" \
  --o-trimmed-sequences "$Q2_DIR/demux-trimmed.qza" \
  --verbose 2>&1 | tail -20

qiime demux summarize \
  --i-data "$Q2_DIR/demux-trimmed.qza" \
  --o-visualization "$Q2_DIR/demux-trimmed-summary.qzv"

echo "[OK] Импорт и trimming праймеров завершены."
echo "     Файлы: $Q2_DIR/demux-trimmed.qza"
