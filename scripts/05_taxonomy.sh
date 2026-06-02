#!/usr/bin/env bash
# scripts/05_taxonomy.sh — таксономическая классификация + экспорт TSV
set -euo pipefail
source "$(dirname "$0")/../config/params.sh"
set +u
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$QIIME2_ENV"
set -u

echo "════════════════════════════════════════"
echo " 05 · Таксономия (SILVA 138)"
echo "════════════════════════════════════════"

Q2_DIR="$PROJECT_DIR/qiime2"
EXPORT_DIR="$PROJECT_DIR/results/taxonomy"
mkdir -p "$EXPORT_DIR"

# ── Обрезка V3-части из V3-V4 ASV через cutadapt ────────────────────────────
# ASV покрывают V3-V4 (~428 bp без праймеров). Обрезаем 515F вперёд,
# получая V4-фрагмент (~253 bp) для классификации по SILVA 515-806.
echo "[INFO] Обрезаем V3-часть ASV (cutadapt, 515F → конец)..."
qiime tools export --input-path "$Q2_DIR/rep-seqs.qza" \
  --output-path "$Q2_DIR/rep-seqs-export/"

cutadapt \
  --front GTGYCAGCMGCCGCGGTAA \
  --discard-untrimmed \
  --cores "$THREADS" \
  -o "$Q2_DIR/dna-sequences-v4.fasta" \
  "$Q2_DIR/rep-seqs-export/dna-sequences.fasta" 2>&1 | grep -E "Total reads|Reads written"

qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path "$Q2_DIR/dna-sequences-v4.fasta" \
  --output-path "$Q2_DIR/rep-seqs-v4.qza"

# ── Классификация (vsearch, не требует предобученного sklearn-классификатора) ──
echo "[INFO] classify-consensus-vsearch с SILVA 138 (identity=$VSEARCH_PERC_IDENTITY)..."
qiime feature-classifier classify-consensus-vsearch \
  --i-query "$Q2_DIR/rep-seqs-v4.qza" \
  --i-reference-reads "$CLASSIFIER_PATH" \
  --i-reference-taxonomy "$TAXONOMY_PATH" \
  --p-threads "$THREADS" \
  --p-perc-identity "$VSEARCH_PERC_IDENTITY" \
  --p-maxaccepts 10 \
  --p-maxrejects 100 \
  --o-classification "$Q2_DIR/taxonomy.qza" \
  --o-search-results "$Q2_DIR/taxonomy-search.qza"

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
