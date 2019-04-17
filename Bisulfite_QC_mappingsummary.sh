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

  ####################
  ## mapping_summary
  ####################
  if [[ "$BISCUIT_QC_MAPPING" == true ]]; then
    >&2 echo "`date`---- BISCUIT_QC_MAPPING ----"
    echo -e "BISCUITqc Strand Table" >strand_table.txt
    biscuit cinread -p QPAIR,STRAND,BSSTRAND $BISCUIT_REFERENCE $input_bam | awk '{a[$1$2$3]+=1}END{for(strand in a) {print "strand\t"strand"\t"a[strand];}}' >>strand_table.txt

    echo -e "BISCUITqc Mapping Quality Table" >mapq_table.txt
    echo -e "MapQ\tCount" >>mapq_table.txt
    samtools view -F 0x100 -f 0x4 $input_bam | wc -l | cat <(echo -ne "unmapped\t") - >>mapq_table.txt
    samtools view -F 0x104 $input_bam | awk '{cnt[$5]+=1}END{for(mapq in cnt) {print mapq"\t"cnt[mapq];}}' | sort -k1,1n >>mapq_table.txt
  fi

}

input_vcf="<unset>"

function usage {
  >&2 echo "Usage: Bisulfite_QC_mappingsummary.sh input_vcf input_bam reference_genome QCannotation"
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
