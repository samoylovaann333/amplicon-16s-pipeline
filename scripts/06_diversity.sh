#!/usr/bin/env bash
# scripts/06_diversity.sh — филогения + alpha/beta разнообразие
set -euo pipefail
source "$(dirname "$0")/../config/params.sh"
conda activate "$QIIME2_ENV"

echo "════════════════════════════════════════"
echo " 06 · Филогения + Разнообразие"
echo "════════════════════════════════════════"

Q2_DIR="$PROJECT_DIR/qiime2"
PHYLO_DIR="$Q2_DIR/phylogeny"
META="$PROJECT_DIR/metadata.tsv"
mkdir -p "$PHYLO_DIR"

# ── MAFFT выравнивание ───────────────────────────────────────
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

# ── Кривые рарефакции ─────────────────────────────────────────
echo "[INFO] Alpha-rarefaction curves..."
qiime diversity alpha-rarefaction \
  --i-table "$Q2_DIR/table-filtered.qza" \
  --i-phylogeny "$PHYLO_DIR/rooted-tree.qza" \
  --p-max-depth "$SAMPLING_DEPTH" \
  --p-steps 50 \
  --p-metrics faith_pd observed_features shannon \
  --o-visualization "$Q2_DIR/alpha-rarefaction.qzv"

# ── Core diversity metrics ────────────────────────────────────
echo "[INFO] Core diversity metrics (alpha + beta)..."
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny "$PHYLO_DIR/rooted-tree.qza" \
  --i-table "$Q2_DIR/table-filtered.qza" \
  --p-sampling-depth "$SAMPLING_DEPTH" \
  --m-metadata-file "$META" \
  --output-dir "$Q2_DIR/diversity/"

echo ""
echo "[OK] Разнообразие вычислено."
echo "     Файлы в: $Q2_DIR/diversity/"
echo "     Ключевые: faith_pd_vector.qza, shannon_vector.qza,"
echo "               unweighted_unifrac_emperor.qzv"
