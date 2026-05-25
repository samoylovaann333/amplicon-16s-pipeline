#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# config/params.sh — все параметры пайплайна в одном месте
# ─────────────────────────────────────────────────────────────

# Образец
ACCESSION="SRR18136502"
SAMPLE_ID="AR03-4"
PROJECT_DIR="$HOME/SRX14284601"

# Праймеры 16S V3-V4
PRIMER_F="GTGYCAGCMGCCGCGGTAA"    # 515F
PRIMER_R="GGACTACNVGGGTWTCTAAT"   # 806R

# Параметры DADA2 (усечение по качеству из FastQC)
TRUNC_LEN_F=260
TRUNC_LEN_R=220
TRIM_LEFT_F=0
TRIM_LEFT_R=0

# Глубина рарефакции (устанавливается после DADA2)
SAMPLING_DEPTH=46000

# Потоки (M4: 8 performance + efficiency cores)
THREADS=8

# Среды conda
QIIME2_ENV="qiime2-2024.10"
PICRUST2_ENV="picrust2"

# Классификатор SILVA 138 (V3-V4, 515F/806R)
CLASSIFIER_URL="https://data.qiime2.org/2024.10/common/silva-138-99-seqs-515-806.qza"
CLASSIFIER_PATH="$PROJECT_DIR/classifiers/silva-138-classifier-V3V4.qza"

# Уровень уверенности классификатора
CLASSIFIER_CONFIDENCE=0.7

# Химерный метод DADA2
CHIMERA_METHOD="consensus"

# PICRUSt2
PICRUST2_NSTI_CUTOFF=0.2
