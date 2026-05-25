#!/usr/bin/env bash
# scripts/07_picrust2.sh — функциональный анализ PICRUSt2
set -euo pipefail
source "$(dirname "$0")/../config/params.sh"

echo "════════════════════════════════════════"
echo " 07 · Функциональный анализ (PICRUSt2)"
echo "════════════════════════════════════════"

Q2_DIR="$PROJECT_DIR/qiime2"
P2_DIR="$PROJECT_DIR/picrust2"
RESULTS_DIR="$PROJECT_DIR/results/picrust2"
mkdir -p "$P2_DIR/input" "$RESULTS_DIR"

# ── Активируем PICRUSt2 env ───────────────────────────────────
conda activate picrust2

# ── Экспорт из QIIME2 ─────────────────────────────────────────
echo "[INFO] Экспорт feature table и rep-seqs из QIIME2..."
conda activate "$QIIME2_ENV"

qiime tools export \
  --input-path "$Q2_DIR/table-filtered.qza" \
  --output-path "$P2_DIR/input/"

qiime tools export \
  --input-path "$Q2_DIR/rep-seqs.qza" \
  --output-path "$P2_DIR/input/"

conda activate picrust2

# ── PICRUSt2 полный пайплайн ──────────────────────────────────
echo "[INFO] Запуск picrust2_pipeline.py (~3-5 мин на M4)..."
picrust2_pipeline.py \
  -s "$P2_DIR/input/dna-sequences.fasta" \
  -i "$P2_DIR/input/feature-table.biom" \
  -o "$P2_DIR/output/" \
  -p "$THREADS" \
  --stratified \
  --coverage \
  --verbose

# ── Добавление описаний путей ─────────────────────────────────
echo "[INFO] Добавляем описания MetaCyc путей..."
add_descriptions.py \
  -i "$P2_DIR/output/pathways_out/path_abun_unstrat.tsv.gz" \
  -m METACYC \
  -o "$P2_DIR/output/pathways_out/path_abun_unstrat_descrip.tsv.gz"

add_descriptions.py \
  -i "$P2_DIR/output/EC_metagenome_out/pred_metagenome_unstrat.tsv.gz" \
  -m EC \
  -o "$P2_DIR/output/EC_metagenome_out/pred_metagenome_unstrat_descrip.tsv.gz"

add_descriptions.py \
  -i "$P2_DIR/output/KO_metagenome_out/pred_metagenome_unstrat.tsv.gz" \
  -m KO \
  -o "$P2_DIR/output/KO_metagenome_out/pred_metagenome_unstrat_descrip.tsv.gz"

# ── Конвертация MetaCyc → KEGG ────────────────────────────────
echo "[INFO] Конвертация MetaCyc → KEGG pathways..."
convert_table.py \
  "$P2_DIR/output/pathways_out/path_abun_unstrat.tsv.gz" \
  -c METACYC_TO_KEGG \
  -o "$P2_DIR/output/kegg_pathways_unstrat.tsv.gz" 2>/dev/null || \
  echo "[WARN] METACYC_TO_KEGG конвертация пропущена (опциональный шаг)"

# ── Копируем ключевые результаты ──────────────────────────────
echo "[INFO] Копируем результаты в $RESULTS_DIR..."
cp "$P2_DIR/output/pathways_out/path_abun_unstrat_descrip.tsv.gz" "$RESULTS_DIR/"
cp "$P2_DIR/output/EC_metagenome_out/pred_metagenome_unstrat_descrip.tsv.gz" "$RESULTS_DIR/"
cp "$P2_DIR/output/KO_metagenome_out/pred_metagenome_unstrat_descrip.tsv.gz" "$RESULTS_DIR/"
cp "$P2_DIR/output/pathways_out/path_abun_strat.tsv.gz" "$RESULTS_DIR/" 2>/dev/null || true
[ -f "$P2_DIR/output/kegg_pathways_unstrat.tsv.gz" ] && \
  cp "$P2_DIR/output/kegg_pathways_unstrat.tsv.gz" "$RESULTS_DIR/"

# NSTI качество
cp "$P2_DIR/output/intermediate/place_seqs/placed_seqs_nsti.tsv" \
   "$RESULTS_DIR/nsti_per_asv.tsv" 2>/dev/null || true

echo ""
echo "[OK] PICRUSt2 завершён."
echo "     Результаты в: $RESULTS_DIR/"
echo ""
echo "     Ключевые файлы:"
echo "       path_abun_unstrat_descrip.tsv.gz  ← MetaCyc пути с описаниями"
echo "       pred_metagenome_unstrat_descrip.tsv.gz (EC и KO)"
echo "       nsti_per_asv.tsv                  ← качество предсказания"
