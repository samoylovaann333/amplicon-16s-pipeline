# AMPLICON 16S rRNA Pipeline

Биоинформатический пайплайн для анализа ампликонного секвенирования 16S рРНК.
Разработан и протестирован на Apple M4 (macOS, osx-arm64).

## Образец

| Параметр | Значение |
|----------|---------|
| Sample ID | AR03-4 |
| Accession | SRX14284601 / SRR18136502 |
| Project | PRJNA810286 |
| Organism | Canis lupus familiaris |
| Condition | Atopic dermatitis (cAD) |
| Region | 16S V3–V4 (341F / 806R) |

## Установка

```bash
bash scripts/00_install.sh
```

Устанавливает: SRA Toolkit, FastQC, Trimmomatic, MultiQC, QIIME2 2026.4, PICRUSt2 2.6.3, SILVA 138.

## Запуск

```bash
bash scripts/run_all.sh
```

## Смена данных (config/params.sh)

```bash
ACCESSION="SRR18136502"              # заменить на свой SRR
SAMPLE_ID="AR03-4"                   # название образца
PROJECT_DIR="$HOME/SRX14284601"      # папка для результатов
PRIMER_F="CCTACGGGNGGCWGCAG"         # праймер 341F
PRIMER_R="GGACTACNVGGGTWTCTAAT"      # праймер 806R
TRUNC_LEN_F=260                      # усечение R1 (по FastQC)
TRUNC_LEN_R=220                      # усечение R2
SAMPLING_DEPTH=16000                 # глубина рарефакции
```

## Этапы

| Скрипт | Описание |
|--------|----------|
| 00_install.sh | Установка всех зависимостей |
| 01_download.sh | Загрузка NCBI SRA |
| 02_qc.sh | FastQC + Trimmomatic + MultiQC |
| 03_qiime2_import.sh | Импорт в QIIME2 + cutadapt |
| 04_dada2.sh | DADA2 денойзинг → ASV |
| 05_taxonomy.sh | Таксономия SILVA 138 vsearch |
| 06_diversity.sh | MAFFT + FastTree + alpha diversity |
| 07_picrust2.sh | PICRUSt2: MetaCyc, EC, KO |

## Требования

- macOS Apple Silicon (M1–M4)
- Homebrew + Miniforge3
