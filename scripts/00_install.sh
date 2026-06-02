#!/usr/bin/env bash
# scripts/00_install.sh — установка всех зависимостей (Apple M4 / osx-arm64)
set -euo pipefail
source "$(dirname "$0")/../config/params.sh"

echo "════════════════════════════════════════"
echo " 00 · Установка зависимостей"
echo "════════════════════════════════════════"

# ── Homebrew ──────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "[INFO] Устанавливаем Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "[INFO] Устанавливаем SRA-Toolkit, FastQC, Trimmomatic..."
brew install sratoolkit fastqc trimmomatic

# ── MultiQC ───────────────────────────────────────────────────
echo "[INFO] Устанавливаем MultiQC..."
pip3 install multiqc --quiet

# ── Miniforge (conda для arm64) ───────────────────────────────
if ! command -v conda &>/dev/null; then
  echo "[INFO] Устанавливаем Miniforge3 (arm64)..."
  curl -fsSL https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh \
    -o /tmp/Miniforge3.sh
  bash /tmp/Miniforge3.sh -b -p "$HOME/miniforge3"
  eval "$("$HOME/miniforge3/bin/conda" shell.bash hook)"
  conda init bash zsh
fi

# ── QIIME2 env ────────────────────────────────────────────────
# QIIME2 2026.4 поставляется только для osx-64; на Apple Silicon (M1-M4)
# conda создаёт окружение под Rosetta 2 (прозрачно для пользователя).
# Используется минимальный набор плагинов для 16S-пайплайна — без deblur
# (deblur требует sortmerna==2.0, удалённого из всех каналов).
if ! conda env list | grep -q "$QIIME2_ENV"; then
  echo "[INFO] Создаём QIIME2 2026.4 environment (osx-64 via Rosetta 2)..."
  cat > /tmp/qiime2-minimal.yml << 'EOF'
channels:
  - https://packages.qiime2.org/qiime2/2026.4/qiime2/released
  - conda-forge
  - bioconda
  - defaults
dependencies:
  - python=3.12
  - qiime2=2026.4.0
  - q2cli=2026.4.0
  - q2templates=2026.4.0
  - q2-demux=2026.4.0
  - q2-cutadapt=2026.4.0
  - q2-dada2=2026.4.0
  - q2-feature-classifier=2026.4.0
  - q2-feature-table=2026.4.0
  - q2-taxa=2026.4.0
  - q2-alignment=2026.4.0
  - q2-phylogeny=2026.4.0
  - q2-diversity=2026.4.0
  - q2-diversity-lib=2026.4.0
  - q2-metadata=2026.4.0
  - q2-types=2026.4.0
  - q2-vsearch=2026.4.0
  - biom-format
EOF
  CONDA_SUBDIR=osx-64 mamba env create -n "$QIIME2_ENV" \
    --file /tmp/qiime2-minimal.yml \
    --channel-priority flexible
  conda run -n "$QIIME2_ENV" conda config --env --set subdir osx-64
  echo "[OK] QIIME2 установлен: $QIIME2_ENV"
else
  echo "[SKIP] QIIME2 env уже существует: $QIIME2_ENV"
fi

# ── PICRUSt2 env ──────────────────────────────────────────────
# PICRUSt2 conda-пакет требует hmmer<=3.2.1 и r-castor, которых нет в bioconda.
# Устанавливаем бинарные зависимости через conda (hmmer 3.4, epa-ng, gappa),
# а сам picrust2 Python-пакет — через pip с GitHub.
if ! conda env list | grep -q "^picrust2"; then
  echo "[INFO] Создаём PICRUSt2 environment (conda + pip)..."
  conda create -n picrust2 -c bioconda -c conda-forge \
    python=3.9 hmmer=3.4 epa-ng gappa muscle mafft glpk -y
  conda run -n picrust2 pip install ete3
  conda run -n picrust2 pip install \
    "git+https://github.com/picrust/picrust2.git@v2.6.3#egg=picrust2"
  conda run -n picrust2 Rscript -e "install.packages('castor', repos='https://cloud.r-project.org', quiet=TRUE)"
  # Копируем референсные файлы из sparse clone
  PICRUST2_PKG=$(conda run -n picrust2 python -c "import picrust2, os; print(os.path.dirname(picrust2.__file__))")
  git lfs install 2>/dev/null || true
  mkdir -p /tmp/picrust2_ref_clone && cd /tmp/picrust2_ref_clone
  git init && git remote add origin https://github.com/picrust/picrust2.git
  git config core.sparseCheckout true
  echo "picrust2/default_files/" > .git/info/sparse-checkout
  git fetch --depth=1 origin v2.6.3 && git checkout FETCH_HEAD
  cp -r picrust2/default_files "$PICRUST2_PKG/"
  cd - && rm -rf /tmp/picrust2_ref_clone
  echo "[OK] PICRUSt2 установлен"
else
  echo "[SKIP] PICRUSt2 env уже существует"
fi

# ── Скачать референсные последовательности и таксономию SILVA 138 ────
mkdir -p "$(dirname "$CLASSIFIER_PATH")"
if [ ! -f "$CLASSIFIER_PATH" ]; then
  echo "[INFO] Скачиваем SILVA 138 референсные последовательности V3-V4 (~100 MB)..."
  curl -fL "$CLASSIFIER_URL" -o "$CLASSIFIER_PATH"
  echo "[OK] Последовательности сохранены: $CLASSIFIER_PATH"
else
  echo "[SKIP] Референсные последовательности уже есть: $CLASSIFIER_PATH"
fi
if [ ! -f "$TAXONOMY_PATH" ]; then
  echo "[INFO] Скачиваем SILVA 138 таксономию V3-V4 (~5 MB)..."
  curl -fL "$TAXONOMY_URL" -o "$TAXONOMY_PATH"
  echo "[OK] Таксономия сохранена: $TAXONOMY_PATH"
else
  echo "[SKIP] Таксономия уже есть: $TAXONOMY_PATH"
fi

echo ""
echo "✅ Все зависимости установлены."
echo "   Следующий шаг: bash scripts/run_all.sh"
