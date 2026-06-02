#!/usr/bin/env bash
# scripts/02_qc.sh — FastQC + MultiQC + Trimmomatic
set -euo pipefail
source "$(dirname "$0")/../config/params.sh"

echo "════════════════════════════════════════"
echo " 02 · Контроль качества и тримминг"
echo "════════════════════════════════════════"

RAW_DIR="$PROJECT_DIR/raw"
TRIM_DIR="$PROJECT_DIR/trimmed"
QC_DIR="$PROJECT_DIR/qc"
mkdir -p "$QC_DIR/fastqc_raw" "$QC_DIR/fastqc_trimmed" \
         "$QC_DIR/multiqc_raw" "$QC_DIR/multiqc_trimmed" \
         "$TRIM_DIR"

# ── FastQC (raw) ──────────────────────────────────────────────
echo "[INFO] FastQC на сырых данных..."
fastqc "$RAW_DIR/${SAMPLE_ID}_R1.fastq.gz" \
       "$RAW_DIR/${SAMPLE_ID}_R2.fastq.gz" \
       --outdir "$QC_DIR/fastqc_raw" \
       --threads "$THREADS" --extract

# ── MultiQC (raw) ─────────────────────────────────────────────
echo "[INFO] MultiQC (raw)..."
multiqc "$QC_DIR/fastqc_raw/" \
  --outdir "$QC_DIR/multiqc_raw" \
  --filename multiqc_raw_report -q

# ── Trimmomatic ───────────────────────────────────────────────
echo "[INFO] Trimmomatic PE (удаление адаптеров и low-quality)..."
ADAPTER_FA="$(find "$(brew --prefix trimmomatic 2>/dev/null || echo /opt/homebrew/opt/trimmomatic)" \
  -name 'NexteraPE-PE.fa' 2>/dev/null | head -1)"
[ -z "$ADAPTER_FA" ] && \
  ADAPTER_FA="$(find /opt/homebrew -name 'NexteraPE-PE.fa' 2>/dev/null | head -1)"
[ -z "$ADAPTER_FA" ] && { echo "[ERROR] NexteraPE-PE.fa не найден. Установите trimmomatic."; exit 1; }

trimmomatic PE \
  -threads "$THREADS" -phred33 \
  "$RAW_DIR/${SAMPLE_ID}_R1.fastq.gz" \
  "$RAW_DIR/${SAMPLE_ID}_R2.fastq.gz" \
  "$TRIM_DIR/${SAMPLE_ID}_R1_paired.fastq.gz" \
  "$TRIM_DIR/${SAMPLE_ID}_R1_unpaired.fastq.gz" \
  "$TRIM_DIR/${SAMPLE_ID}_R2_paired.fastq.gz" \
  "$TRIM_DIR/${SAMPLE_ID}_R2_unpaired.fastq.gz" \
  ILLUMINACLIP:"$ADAPTER_FA":2:30:10:8:true \
  LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:200

# ── FastQC (trimmed) ──────────────────────────────────────────
echo "[INFO] FastQC на тримированных данных..."
fastqc "$TRIM_DIR/${SAMPLE_ID}_R1_paired.fastq.gz" \
       "$TRIM_DIR/${SAMPLE_ID}_R2_paired.fastq.gz" \
       --outdir "$QC_DIR/fastqc_trimmed" \
       --threads "$THREADS" --extract

# ── MultiQC (trimmed) ─────────────────────────────────────────
echo "[INFO] MultiQC (trimmed)..."
multiqc "$QC_DIR/fastqc_trimmed/" \
  --outdir "$QC_DIR/multiqc_trimmed" \
  --filename multiqc_trimmed_report -q

echo "[OK] QC завершён. Отчёты: $QC_DIR/multiqc_raw/ и $QC_DIR/multiqc_trimmed/"
