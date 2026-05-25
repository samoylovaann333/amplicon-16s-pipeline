#!/usr/bin/env bash
# scripts/05_taxonomy.sh — таксономическая классификация + экспорт TSV
set -euo pipefail
source "$(dirname "$0")/../config/params.sh"
conda activate "$QIIME2_ENV"

echo "════════════════════════════════════════"
echo " 05 · Таксономия (SILVA 138)"
echo "════════════════════════════════════════"

Q2_DIR="$PROJECT_DIR/qiime2"
EXPORT_DIR="$PROJECT_DIR/results/taxonomy"
mkdir -p "$EXPORT_DIR"

# ── Классификация ─────────────────────────────────────────────
echo "[INFO] classify-sklearn с SILVA 138 (confidence=$CLASSIFIER_CONFIDENCE)..."
qiime feature-classifier classify-sklearn \
  --i-classifier "$CLASSIFIER_PATH" \
  --i-reads "$Q2_DIR/rep-seqs.qza" \
  --p-n-jobs "$THREADS" \
  --p-confidence "$CLASSIFIER_CONFIDENCE" \
  --o-classification "$Q2_DIR/taxonomy.qza"

# ── Визуализация таксономии ───────────────────────────────────
echo "[INFO] Создаём визуализации таксономии..."
qiime metadata tabulate \
  --m-input-file "$Q2_DIR/taxonomy.qza" \
  --o-visualization "$Q2_DIR/taxonomy.qzv"

# ── Фильтрация: убрать митохондрии и хлоропласты ─────────────
echo "[INFO] Фильтрация митохондрий и хлоропластов..."
qiime taxa filter-table \
  --i-table "$Q2_DIR/table.qza" \
  --i-taxonomy "$Q2_DIR/taxonomy.qza" \
  --p-exclude mitochondria,chloroplast \
  --o-filtered-table "$Q2_DIR/table-filtered.qza"

# ── Taxa barplot ──────────────────────────────────────────────
echo "[INFO] Генерируем taxa-barplot..."
# Простой metadata файл (один образец)
META="$PROJECT_DIR/metadata.tsv"
if [ ! -f "$META" ]; then
  printf "sample-id\tdisease_status\thost\tstudy\n" > "$META"
  printf "%s\tcAD\tCanis_lupus_familiaris\tPRJNA810286\n" "$SAMPLE_ID" >> "$META"
fi

qiime taxa barplot \
  --i-table "$Q2_DIR/table-filtered.qza" \
  --i-taxonomy "$Q2_DIR/taxonomy.qza" \
  --m-metadata-file "$META" \
  --o-visualization "$Q2_DIR/taxa-barplot.qzv"

# ── Collapse to genus (L6) и экспорт TSV ─────────────────────
echo "[INFO] Collapse to genus + экспорт TSV..."
qiime taxa collapse \
  --i-table "$Q2_DIR/table-filtered.qza" \
  --i-taxonomy "$Q2_DIR/taxonomy.qza" \
  --p-level 6 \
  --o-collapsed-table "$Q2_DIR/table-genus.qza"

qiime tools export \
  --input-path "$Q2_DIR/table-genus.qza" \
  --output-path "$EXPORT_DIR/genus_biom/"

biom convert \
  -i "$EXPORT_DIR/genus_biom/feature-table.biom" \
  -o "$EXPORT_DIR/genus_table.tsv" \
  --to-tsv

# Экспорт таксономии как TSV
qiime tools export \
  --input-path "$Q2_DIR/taxonomy.qza" \
  --output-path "$EXPORT_DIR/"

echo ""
echo "[OK] Таксономия завершена."
echo "     Результаты:"
echo "       - $Q2_DIR/taxa-barplot.qzv      ← открыть на view.qiime2.org"
echo "       - $EXPORT_DIR/genus_table.tsv   ← TSV таблица родов"
echo "       - $EXPORT_DIR/taxonomy.tsv      ← классификация всех ASV"
