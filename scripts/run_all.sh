#!/usr/bin/env bash
# scripts/run_all.sh — запуск полного пайплайна одной командой
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/params.sh"

START_TIME=$(date +%s)
LOG_FILE="$PROJECT_DIR/pipeline_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$PROJECT_DIR"

echo "╔══════════════════════════════════════════════════╗"
echo "║  16S rRNA Pipeline — SRX14284601 / AR03-4        ║"
echo "║  Apple M4 Silicon  |  QIIME2 2024.10             ║"
echo "╚══════════════════════════════════════════════════╝"
echo "  Лог: $LOG_FILE"
echo ""

run_step() {
  local step="$1"
  local script="$2"
  echo "──────────────────────────────────────"
  echo "  ▶ $step"
  echo "──────────────────────────────────────"
  bash "$SCRIPT_DIR/$script" 2>&1 | tee -a "$LOG_FILE"
  echo "  ✅ $step — готово"
  echo ""
}

run_step "Шаг 1: Загрузка данных с NCBI SRA"     "01_download.sh"
run_step "Шаг 2: FastQC + Trimmomatic"            "02_qc.sh"
run_step "Шаг 3: QIIME2 импорт + cutadapt"        "03_qiime2_import.sh"
run_step "Шаг 4: DADA2 денойзинг → ASV"           "04_dada2.sh"
run_step "Шаг 5: Таксономия SILVA 138"            "05_taxonomy.sh"
run_step "Шаг 6: Филогения + Разнообразие"        "06_diversity.sh"
run_step "Шаг 7: PICRUSt2 функциональный анализ"  "07_picrust2.sh"

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
MINUTES=$(( ELAPSED / 60 ))
SECONDS=$(( ELAPSED % 60 ))

echo "╔══════════════════════════════════════════════════╗"
echo "║  ✅ Пайплайн завершён за ${MINUTES}м ${SECONDS}с"
echo "╠══════════════════════════════════════════════════╣"
echo "║  Ключевые результаты:"
echo "║"
echo "║  ТАКСОНОМИЯ:"
echo "║    $PROJECT_DIR/qiime2/taxa-barplot.qzv"
echo "║    $PROJECT_DIR/results/taxonomy/genus_table.tsv"
echo "║    $PROJECT_DIR/results/taxonomy/taxonomy.tsv"
echo "║"
echo "║  ФУНКЦИОНАЛЬНОСТЬ:"
echo "║    $PROJECT_DIR/results/picrust2/path_abun_unstrat_descrip.tsv.gz"
echo "║    $PROJECT_DIR/results/picrust2/pred_metagenome_unstrat_descrip.tsv.gz (EC)"
echo "║    $PROJECT_DIR/results/picrust2/pred_metagenome_unstrat_descrip.tsv.gz (KO)"
echo "║"
echo "║  РАЗНООБРАЗИЕ:"
echo "║    $PROJECT_DIR/qiime2/alpha-rarefaction.qzv"
echo "║    $PROJECT_DIR/qiime2/diversity/"
echo "║"
echo "║  Для просмотра .qzv: https://view.qiime2.org"
echo "╚══════════════════════════════════════════════════╝"
