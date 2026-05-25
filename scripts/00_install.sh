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
if ! conda env list | grep -q "$QIIME2_ENV"; then
  echo "[INFO] Создаём QIIME2 environment (osx-arm64)..."
  wget -qO /tmp/qiime2.yml \
    "https://data.qiime2.org/distro/core/qiime2-core-2024.10-py310-osx-conda.yml"
  conda env create -n "$QIIME2_ENV" --file /tmp/qiime2.yml
  echo "[OK] QIIME2 установлен: $QIIME2_ENV"
else
  echo "[SKIP] QIIME2 env уже существует: $QIIME2_ENV"
fi

# ── PICRUSt2 env ──────────────────────────────────────────────
if ! conda env list | grep -q "^picrust2"; then
  echo "[INFO] Создаём PICRUSt2 environment..."
  conda create -n picrust2 -c bioconda -c conda-forge \
    picrust2=2.5.3 -y
  echo "[OK] PICRUSt2 установлен"
else
  echo "[SKIP] PICRUSt2 env уже существует"
fi

# ── Скачать классификатор SILVA 138 ───────────────────────────
mkdir -p "$(dirname "$CLASSIFIER_PATH")"
if [ ! -f "$CLASSIFIER_PATH" ]; then
  echo "[INFO] Скачиваем SILVA 138 классификатор (~286 MB)..."
  wget -qc "$CLASSIFIER_URL" -O "$CLASSIFIER_PATH"
  echo "[OK] Классификатор сохранён: $CLASSIFIER_PATH"
else
  echo "[SKIP] Классификатор уже есть: $CLASSIFIER_PATH"
fi

echo ""
echo "✅ Все зависимости установлены."
echo "   Следующий шаг: bash scripts/run_all.sh"
