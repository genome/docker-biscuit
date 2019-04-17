#!/usr/bin/env bash
## make sure the following is in PATH
## biscuit samtools, bedtools, awk

function biscuitQC

{
  ## simple test to make sure all is available
  if [[ `which biscuit 2>&1 >/dev/null` ]]; then echo "biscuit does not exist in PATH"; exit 1; fi
  if [[ `which samtools 2>&1 >/dev/null` ]]; then echo "samtools does not exist in PATH"; exit 1; fi
  if [[ `which bedtools 2>&1 >/dev/null` ]]; then echo "bedtools does not exist in PATH"; exit 1; fi
  if [[ `which awk 2>&1 >/dev/null` ]]; then echo "awk does not exist in PATH"; exit 1; fi
  for var in BISCUIT_CPGBED BISCUIT_CGIBED BISCUIT_RMSK BISCUIT_EXON BISCUIT_GENE BISCUIT_TOPGC_BED BISCUIT_BOTGC_BED input_bam input_vcf; do
    if [[ ${!var} != "<unset>" && ! -f ${!var} ]]; then
      >&2 echo "$var: ${!var} does not exist."
      exit 1;
    fi
  done

  echo "Running."
  set -xeou pipefail

  ###################################
  ## CpG retention distribution
  ###################################
  [[ ! -f "$input_vcf" ]] && BISCUIT_QC_BETAS=false
  if [[ "$BISCUIT_QC_BETAS" == true ]]; then
    echo -e "BISCUITqc Retention Distribution Table" >CpGRetentionDist.txt
    echo -e "RetentionFraction\tCount" >>CpGRetentionDist.txt
    biscuit vcf2bed -t cg $input_vcf | awk '$5>=3{a[sprintf("%3.0f", $4*100)]+=1}END{for (beta in a) print beta"\t"a[beta];}' | sort -k1,1n >>CpGRetentionDist.txt
  fi
}

input_vcf="<unset>"

function usage {
  >&2 echo "Usage: Bisulfite_QC_CpGretentiondistribution.sh input_vcf input_bam reference_genome QCannotation"
  exit 1;
}

[[ "$#" -lt 4 ]] && usage;
setup_file="${@: -1}"
set -- "${@:1:$(($#-1))}"
BISCUIT_REFERENCE="${@: -1}"
set -- "${@:1:$(($#-1))}"
input_bam="${@: -1}"
set -- "${@:1:$(($#-1))}"
input_vcf="${@: -1}"
set -- "${@:1:$(($#-1))}"

if [[ ! -f "$setup_file" ]]; then
  echo "Setup file missing: $setup_file.";
  exit 1;
fi

if [[ ! -f "${BISCUIT_REFERENCE}.fai" ]]; then
  >&2 echo "Cannot locate fai-indexed reference: ${BISCUIT_REFERENCE}.fai"
  >&2 echo "Please make sure the directory containing the Reference genome file has the fai file.";
  exit 1;
fi

BISCUIT_CPGBED="$setup_file/cpg.bed.gz"
## CpG islands
BISCUIT_CGIBED="$setup_file/cgi.bed.gz"
## repeat masker bed file
BISCUIT_RMSK="$setup_file/rmsk.bed.gz"
## merged exon bed file
BISCUIT_EXON="$setup_file/exon.bed.gz"
## genes
BISCUIT_GENE="$setup_file/genes.bed.gz"
## locations for the top 100bp bins in GC content
BISCUIT_TOPGC_BED="$setup_file/windows100bp.gc_content.top10p.bed.gz"
## locations for the bottom 100bp bins in GC content
BISCUIT_BOTGC_BED="$setup_file/windows100bp.gc_content.bot10p.bed.gz"

>&2 echo "## Running BISCUIT QC script with following configuration ##"
>&2 echo "=============="
>&2 echo "input bam:   $input_bam"
>&2 echo "input vcf:   $input_vcf"
>&2 echo "REFERENCE:   $BISCUIT_REFERENCE"
>&2 echo "CPGBED:      $BISCUIT_CPGBED"
>&2 echo "CGIBED:      $BISCUIT_CGIBED"
>&2 echo "RMSK:        $BISCUIT_RMSK"
>&2 echo "EXON:        $BISCUIT_EXON"
>&2 echo "GENE:        $BISCUIT_GENE"
>&2 echo "TOPGC_BED:   $BISCUIT_TOPGC_BED"
>&2 echo "BOTGC_BED:   $BISCUIT_BOTGC_BED"
>&2 echo "=============="
biscuitQC
>&2 echo -e "\nDone."
