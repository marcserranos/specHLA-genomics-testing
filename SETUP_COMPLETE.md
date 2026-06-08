# SpecHLA Setup Complete ✓

## Your Installation

**Location:** `/Users/marcserrano/WORK/STANFORD/specHLA-genomics-testing/spechla_vanilla/SpecHLA`

**Environment:** `spechla_env` (conda, isolated Python 3.11)

**Status:** Ready to use

---

## What Was Done

1. ✅ **Cloned SpecHLA** from GitHub (fresh, unmodified source)
2. ✅ **Created conda environment** with modern, macOS-compatible packages
3. ✅ **Built bowtie2 indexes** (HLA reference database indexed and ready)
4. ✅ **Verified example data** (5 test FASTQ files available)

## Workarounds Applied

| Issue | Solution | Why |
|-------|----------|-----|
| Old `environment.yml` | Rewrote with modern versions | Original had Linux packages and unavailable old versions |
| BLAT/BLAST unavailable | Removed (optional tools) | Not available for ARM Mac; core HLA typing doesn't require them |

**Everything else is vanilla SpecHLA as distributed by the authors.**

---

## Quick Start: Run Your First Test

### 1. Open Terminal
Press `⌘ + Space`, type "Terminal", press Enter.

### 2. Copy-Paste This Entire Block
```bash
cd /Users/marcserrano/WORK/STANFORD/specHLA-genomics-testing/spechla_vanilla/SpecHLA

source /opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh

conda activate ./spechla_env

bash script/long_read_typing.py -r example/pacbio/HG00733_pacbio.subsample.fastq.gz -n HG00733_pacbio_test -o output/
```

### 3. Wait for Results
The test should complete in 2-5 minutes. When done, you'll see:
```
output/HG00733_pacbio_test/hla.result.txt
```

### 4. View Results
```bash
cat output/HG00733_pacbio_test/hla.result.txt
```

---

## Understanding the Conda Environment

**Every time you open a new Terminal:**

```bash
# 1. Activate conda (one-time per session)
source /opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh

# 2. Activate the SpecHLA environment
conda activate /Users/marcserrano/WORK/STANFORD/specHLA-genomics-testing/spechla_vanilla/SpecHLA/spechla_env

# Now you can run SpecHLA commands
bash script/whole/SpecHLA.sh -h
```

You'll see `(spechla_env)` in your prompt when active.

---

## Running Different Tests

### Long-read only (PacBio)
```bash
bash script/long_read_typing.py -r example/pacbio/HG00733_pacbio.subsample.fastq.gz -n HG00733_test -o output/
```

### Short-read only (Illumina paired-end)
```bash
bash script/whole/SpecHLA.sh -n HG00733_short_reads \
  -1 example/whole/HG00733.final_extract_1.fq.gz \
  -2 example/whole/HG00733.final_extract_2.fq.gz \
  -o output/
```

### Exon-level typing (for WES/RNASeq)
```bash
bash script/whole/SpecHLA.sh -n NA06985_exon \
  -1 example/exon/NA06985_1.filter.fastq.gz \
  -2 example/exon/NA06985_2.filter.fastq.gz \
  -u 1 -o output/
```

---

## What the Results Mean

After a run, you'll find in `output/<sample_name>/`:

| File | Content |
|------|---------|
| `hla.result.txt` | **Main output**: HLA allele calls (e.g., `A*30:02:01:01`) |
| `hla.result.details.txt` | Detailed alleles with scores |
| `hla.allele.*.HLA_*.fasta` | Actual HLA sequences found |

Example result line:
```
HG00733_pacbio_test  A*30:02:01:01  A*30:12:02  -  -  -  -  ...
```

This means:
- Gene HLA-A: allele 1 is `A*30:02:01:01`, allele 2 is `A*30:12:02`
- Gene HLA-B, C: No call (`-`) due to low depth in subsampled data

---

## Troubleshooting

### Command not found (e.g., `bowtie2-build: command not found`)
**You forgot to activate the conda environment.** Run:
```bash
source /opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh
conda activate ./spechla_env
```

### `script/long_read_typing.py: No such file or directory`
**You're not in the SpecHLA directory.** Run:
```bash
cd /Users/marcserrano/WORK/STANFORD/specHLA-genomics-testing/spechla_vanilla/SpecHLA
```

### Out of disk space
Run:
```bash
conda clean --all -y
```

---

## Next Steps

1. **Run the long-read test above** to verify everything works
2. **Try the short-read test** (longer, ~10 min)
3. **Scale to your own data** once you understand the workflow

Good luck! 🧬
