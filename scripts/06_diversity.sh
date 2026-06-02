#!/usr/bin/env bash
# scripts/06_diversity.sh — филогения + alpha/beta разнообразие
set -euo pipefail
source "$(dirname "$0")/../config/params.sh"
set +u
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$QIIME2_ENV"
set -u

echo "════════════════════════════════════════"
echo " 06 · Филогения + Разнообразие"
echo "════════════════════════════════════════"

Q2_DIR="$PROJECT_DIR/qiime2"
PHYLO_DIR="$Q2_DIR/phylogeny"
META="$PROJECT_DIR/metadata.tsv"
mkdir -p "$PHYLO_DIR"

# ── MAFFT выравнивание ───────────────────────────────────────
if [ -f "$PHYLO_DIR/rooted-tree.qza" ]; then
  echo "[SKIP] Филогенетическое дерево уже построено"
else

echo "[INFO] MAFFT: множественное выравнивание ASV..."
qiime alignment mafft \
  --i-sequences "$Q2_DIR/rep-seqs.qza" \
  --p-n-threads "$THREADS" \
  --o-alignment "$PHYLO_DIR/aligned-rep-seqs.qza"

qiime alignment mask \
  --i-alignment "$PHYLO_DIR/aligned-rep-seqs.qza" \
  --o-masked-alignment "$PHYLO_DIR/masked-aligned-rep-seqs.qza"

# ── FastTree2 ─────────────────────────────────────────────────
echo "[INFO] FastTree2: построение филогенетического дерева..."
qiime phylogeny fasttree \
  --i-alignment "$PHYLO_DIR/masked-aligned-rep-seqs.qza" \
  --p-n-threads "$THREADS" \
  --o-tree "$PHYLO_DIR/unrooted-tree.qza"

qiime phylogeny midpoint-root \
  --i-tree "$PHYLO_DIR/unrooted-tree.qza" \
  --o-rooted-tree "$PHYLO_DIR/rooted-tree.qza"

fi  # end skip guard

# ── Кривые рарефакции ─────────────────────────────────────────
if [ -f "$Q2_DIR/alpha-rarefaction.qzv" ]; then
  echo "[SKIP] Alpha-rarefaction уже выполнена"
else
echo "[INFO] Alpha-rarefaction curves..."
qiime diversity alpha-rarefaction \
  --i-table "$Q2_DIR/table-filtered.qza" \
  --i-phylogeny "$PHYLO_DIR/rooted-tree.qza" \
  --p-max-depth "$SAMPLING_DEPTH" \
  --p-steps 50 \
  --p-metrics faith_pd observed_features shannon \
  --o-visualization "$Q2_DIR/alpha-rarefaction.qzv"
fi  # end skip guard

# ── Alpha diversity (один образец — beta diversity недоступна) ───────────────
echo "[INFO] Alpha diversity metrics..."
mkdir -p "$Q2_DIR/diversity"

qiime diversity alpha-phylogenetic \
  --i-phylogeny "$PHYLO_DIR/rooted-tree.qza" \
  --i-table "$Q2_DIR/table-filtered.qza" \
  --p-metric faith_pd \
  --o-alpha-diversity "$Q2_DIR/diversity/faith_pd_vector.qza"

qiime diversity alpha \
  --i-table "$Q2_DIR/table-filtered.qza" \
  --p-metric shannon \
  --o-alpha-diversity "$Q2_DIR/diversity/shannon_vector.qza"

qiime diversity alpha \
  --i-table "$Q2_DIR/table-filtered.qza" \
  --p-metric observed_features \
  --o-alpha-diversity "$Q2_DIR/diversity/observed_features_vector.qza"

qiime diversity alpha \
  --i-table "$Q2_DIR/table-filtered.qza" \
  --p-metric chao1 \
  --o-alpha-diversity "$Q2_DIR/diversity/chao1_vector.qza"

# Экспорт alpha-метрик в TSV
qiime tools export --input-path "$Q2_DIR/diversity/faith_pd_vector.qza" \
  --output-path "$Q2_DIR/diversity/faith_pd/"
qiime tools export --input-path "$Q2_DIR/diversity/shannon_vector.qza" \
  --output-path "$Q2_DIR/diversity/shannon/"
qiime tools export --input-path "$Q2_DIR/diversity/observed_features_vector.qza" \
  --output-path "$Q2_DIR/diversity/observed_features/"

echo ""
echo "[OK] Разнообразие вычислено (один образец — только alpha diversity)."
echo "     Файлы в: $Q2_DIR/diversity/"
echo "     Ключевые: faith_pd_vector.qza, shannon_vector.qza, observed_features_vector.qza"
