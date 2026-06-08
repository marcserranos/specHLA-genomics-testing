# SpecHLA Docker Configuration - Detailed Summary

## Current State: LONG-READ ONLY ✅ (SHORT-READ PENDING)

---

## Deltas from Vanilla Installation

### 1. **Docker Container (Not Vanilla)**
**Delta:** Using Docker instead of native macOS install  
**Reason:** macOS has architecture/binary compatibility issues with pre-compiled x86-64 tools in SpecHLA repo. Docker provides Linux environment where everything works.  
**Trade-off:** Adds container abstraction, but guarantees reproducibility.

---

### 2. **environment_docker.yml (Modified from Vanilla)**

#### Removed from Vanilla:
- BLAT (v. 36x2) - Not available for Linux in conda
- ScanIndel v1.3 - Not in bioconda
- Fermikit-0.13 - Complex to build, rarely used
- SpecHap building (from index.sh) - Causes libblis/BLAS conflicts in long-read-only mode
- Individual library pinning (e.g., _libgcc_mutex, kernel-headers, etc.) - Linux-specific old versions

#### Kept from Vanilla (updated versions):
- Python 3.11 (was 3.8) - Modern stable version
- samtools ≥1.17 (was 1.3.1) - Far newer, backwards compatible
- bcftools ≥1.18 (was 1.9) - Modern version
- bwa ≥0.7.17 (exact) - For short-read
- bowtie2 ≥2.5.0 (was 2.3.4.1) - Modern, backwards compatible
- minimap2 ≥2.24 (was 2.17) - For long-read alignment
- longshot ≥0.4.1 (exact) - For phasing
- bedtools ≥2.30 (was 2.26.0) - Modern
- blast ≥2.12.0 (exact) - For annotation
- freebayes ≥1.3 (was 1.2.0) - For variant calling
- numpy, scipy, pandas, pysam, biopython, pulp, perl - All modern versions

---

### 3. **Pre-compiled Binaries (Removed)**
**Delta:** Deleted `bin/*` folder contents  
**Reason:** Contains x86-64 pre-compiled executables that cause Rosetta emulation errors on Docker  
**Result:** Use conda-installed tools instead (cleaner, architecture-native)

---

### 4. **index.sh (Skipped for Long-Read Mode)**
**Delta:** Not running `bash index.sh` in Docker build  
**Reason:** README says: "If you only need long-read mode, there is no need for index.sh"  
**Impact:** Short-read requires bowtie2 indexes (index.sh creates these) - STILL NEEDED

---

## What's Missing for Short-Read

### The Problem:
`bash index.sh` needs:
- cmake 3.16.3+ ✓ (Docker has 3.31.6)
- GCC 9.4.0+ ✓ (Docker has 14.2.0)
- arpack, lapack, blas for SpecHap compilation
- Creates bowtie2 indexes: `db/ref/*.bt2` files

### Why It Failed Before:
- BLAS library (libblis) configuration errors in Docker
- Likely cause: conflicting BLAS implementations (openblas vs blis)
- Solution: Need to either fix BLAS configuration or use a different approach

---

## Strategy to Fix Short-Read

### Option A: Multi-Stage Docker Build (Recommended)
1. **Build stage:** Include arpack/lapack/blas, run index.sh, create indexes
2. **Runtime stage:** Copy only the index files and compiled scripts (no BLAS libs)
3. **Result:** Clean runtime environment, indexes pre-built

### Option B: Index Pre-Building (Fastest)
1. Build indexes locally on Linux VM or use pre-built ones
2. Copy them into Docker image
3. Skip index.sh entirely

### Option C: Fix BLAS Configuration
1. Specify `BLAS_LIBRARIES` explicitly in CMake
2. Use only libopenblas, not blis
3. Run index.sh successfully

---

## Next Step
Implement one of the above options to get short-read working while maintaining clean long-read.

