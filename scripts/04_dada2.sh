#!/usr/bin/env bash
# scripts/04_dada2.sh — DADA2 денойзинг, генерация ASV
set -euo pipefail
source "$(dirname "$0")/../config/params.sh"
conda activate "$QIIME2_ENV"

echo "════════════════════════════════════════"
echo " 04 · DADA2: денойзинг → ASV"
echo "════════════════════════════════════════"

Q2_DIR="$PROJECT_DIR/qiime2"

echo "[INFO] DADA2 denoise-paired (это самый долгий шаг, ~4-8 мин на M4)..."
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs "$Q2_DIR/demux-trimmed.qza" \
  --p-trim-left-f "$TRIM_LEFT_F" \
  --p-trim-left-r "$TRIM_LEFT_R" \
  --p-trunc-len-f "$TRUNC_LEN_F" \
  --p-trunc-len-r "$TRUNC_LEN_R" \
  --p-n-threads "$THREADS" \
  --p-chimera-method "$CHIMERA_METHOD" \
  --o-table "$Q2_DIR/table.qza" \
  --o-representative-sequences "$Q2_DIR/rep-seqs.qza" \
  --o-denoising-stats "$Q2_DIR/dada2-stats.qza" \
  --verbose

# ── Визуализации статистики DADA2 ────────────────────────────
echo "[INFO] Генерируем визуализации DADA2..."
qiime metadata tabulate \
  --m-input-file "$Q2_DIR/dada2-stats.qza" \
  --o-visualization "$Q2_DIR/dada2-stats.qzv"

qiime feature-table summarize \
  --i-table "$Q2_DIR/table.qza" \
  --o-visualization "$Q2_DIR/table-summary.qzv"

qiime feature-table tabulate-seqs \
  --i-data "$Q2_DIR/rep-seqs.qza" \
  --o-visualization "$Q2_DIR/rep-seqs.qzv"

# ── Подсчёт ASV ──────────────────────────────────────────────
echo ""
echo "[OK] DADA2 завершён."
echo "     Проверьте результаты: qiime tools view $Q2_DIR/dada2-stats.qzv"
echo "     или откройте на https://view.qiime2.org"
