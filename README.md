# 16S rRNA Amplicon Analysis — SRX14284601

**Образец:** AR03-4 | Gut microbiome | Canine Atopic Dermatitis  
**Проект:** PRJNA810286 — Seoul National University  
**Платформа:** Apple M4 Silicon (macOS Sequoia 15.3)  
**Инструменты:** QIIME2 2026.4 · PICRUSt2 2.6.3 · SILVA 138

---

## Структура репозитория

```
SRX14284601-pipeline/
├── README.md
├── envs/
│   ├── qiime2-env.yml          # conda env для QIIME2
│   └── picrust2-env.yml        # conda env для PICRUSt2
├── config/
│   └── params.sh               # все параметры в одном месте
├── scripts/
│   ├── 00_install.sh           # установка всех зависимостей
│   ├── 01_download.sh          # скачивание данных с NCBI SRA
│   ├── 02_qc.sh                # FastQC + MultiQC + Trimmomatic
│   ├── 03_qiime2_import.sh     # импорт в QIIME2 + cutadapt
│   ├── 04_dada2.sh             # DADA2 денойзинг → ASV
│   ├── 05_taxonomy.sh          # классификация SILVA 138
│   ├── 06_diversity.sh         # alpha/beta разнообразие
│   ├── 07_picrust2.sh          # функциональный анализ PICRUSt2
│   └── run_all.sh              # запуск всего пайплайна одной командой
└── results/                    # сюда попадут выходные файлы
```

---

## Быстрый старт (Apple M4)

```bash
# 1. Клонировать репозиторий
git clone https://github.com/YOUR_USERNAME/SRX14284601-pipeline.git
cd SRX14284601-pipeline

# 2. Установить зависимости (один раз)
bash scripts/00_install.sh

# 3. Запустить весь пайплайн
bash scripts/run_all.sh
```

Результаты появятся в папке `results/` примерно через **10–15 минут**.

---

## Выходные файлы

| Файл | Описание |
|------|----------|
| `results/qiime2/taxonomy.qzv` | Таксономия (просмотр: view.qiime2.org) |
| `results/qiime2/taxa-barplot.qzv` | Интерактивный бар-плот |
| `results/qiime2/dada2-stats.qzv` | Статистика денойзинга |
| `results/export/genus_table.tsv` | Таблица родов (TSV) |
| `results/picrust2/path_abun_unstrat.tsv.gz` | MetaCyc пути |
| `results/picrust2/KO_metagenome_unstrat.tsv.gz` | KEGG Orthology |
| `results/qiime2/diversity/` | Alpha/Beta метрики |

Для просмотра `.qzv` файлов: **https://view.qiime2.org** (перетащить файл в браузер)
