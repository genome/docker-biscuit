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

  ##########################
  ## base coverage
  ##########################
  if [[ "$BISCUIT_QC_BASECOV" == true ]]; then
    >&2 echo "`date`---- BISCUIT_QC_BASECOV ----"
    bedtools genomecov -bga -split -ibam $input_bam -g ${BISCUIT_REFERENCE}.fai | LC_ALL=C sort -k1,1 -k2,2n >bga.bed

    echo -e "BISCUITqc Depth Distribution (All)" >covdist_table.txt
    echo -e "depth\tcount" >>covdist_table.txt
    awk '{cnt[$4]+=$3-$2}END{for(cov in cnt) {print int(cov)"\t"int(cnt[cov]);}}' bga.bed | sort -k1,1n >>covdist_table.txt
  fi

  ##########################
  ## duplicate_coverage
  ##########################
  [[ ! -f "bga.bed" ]] && BISCUIT_QC_DUPLICATE=false
  if [[ "$BISCUIT_QC_DUPLICATE" == true ]]; then
    >&2 echo "`date`---- BISCUIT_QC_DUPLICATE ----"
    # duplicate
    samtools view -f 0x400 -b $input_bam | bedtools genomecov -ibam stdin -g $BISCUIT_REFERENCE.fai -bga -split | LC_ALL=C sort -k1,1 -k2,2n >bga_dup.bed

    # duplication rate
    echo -e "BISCUITqc Read Duplication Table" >dup_report.txt
    echo -ne "#bases covered by all reads: " >>dup_report.txt
    awk 'BEGIN{a=0}$4>0{a+=$3-$2}END{print a}' bga.bed >>dup_report.txt
    echo -ne "#bases covered by duplicate reads: " >>dup_report.txt
    awk 'BEGIN{a=0}$4>0{a+=$3-$2}END{print a}' bga_dup.bed >>dup_report.txt

    if [[ -f "$BISCUIT_TOPGC_BED" && -f "$BISCUIT_BOTGC_BED" ]]; then
      # high GC content
      echo -ne "#high-GC bases covered by all reads: " >>dup_report.txt
      bedtools intersect -a bga.bed -b $BISCUIT_TOPGC_BED -sorted | awk 'BEGIN{a=0}$4>0{a+=$3-$2}END{print a}' >>dup_report.txt
      echo -ne "#high-GC bases covered by duplicate reads: " >>dup_report.txt
      bedtools intersect -a bga_dup.bed -b $BISCUIT_TOPGC_BED -sorted | awk 'BEGIN{a=0}$4>0{a+=$3-$2}END{print a}' >>dup_report.txt

      # low GC content
      echo -ne "#low-GC bases covered by all reads: " >>dup_report.txt
      bedtools intersect -a bga.bed -b $BISCUIT_BOTGC_BED -sorted | awk 'BEGIN{a=0}$4>0{a+=$3-$2}END{print a}' >>dup_report.txt
      echo -ne "#low-GC bases covered by duplicate reads: " >>dup_report.txt
      bedtools intersect -a bga_dup.bed -b $BISCUIT_BOTGC_BED -sorted | awk 'BEGIN{a=0}$4>0{a+=$3-$2}END{print a}' >>dup_report.txt
    fi
  fi

  ##########################
  ## cpg coverage
  ##########################

  [[ ! -f "$BISCUIT_CPGBED" ]] && BISCUIT_QC_CPGCOV=false
  [[ ! -f "bga.bed" ]] && BISCUIT_QC_CPGCOV=false
  if [[ "$BISCUIT_QC_CPGCOV" == true ]]; then
    >&2 echo "`date`---- BISCUIT_QC_CPGCOV ----"
    bedtools intersect -a $BISCUIT_CPGBED -b bga.bed -wo -sorted | bedtools groupby -g 1-3 -c 7 -o min >cpg.bed

    echo -e "BISCUITqc CpG Depth Distribution (All)" >covdist_cpg_table.txt
    echo -e "depth\tcount" >>covdist_cpg_table.txt
    awk '{cnt[$4]+=1}END{for(cov in cnt) {print int(cov)"\t"int(cnt[cov]);}}' cpg.bed | sort -k1,1n >>covdist_cpg_table.txt
  fi

  ##########################
  ## cpg distribution
  ##########################
  [[ ! -f "cpg.bed" ]] && BISCUIT_QC_CPGDIST=false
  [[ ! -f "$BISCUIT_EXON" ]] && BISCUIT_QC_CPGDIST=false
  [[ ! -f "$BISCUIT_RMSK" ]] && BISCUIT_QC_CPGDIST=false
  [[ ! -f "$BISCUIT_GENE" ]] && BISCUIT_QC_CPGDIST=false
  [[ ! -f "$BISCUIT_CGIBED" ]] && BISCUIT_QC_CPGDIST=false
  if [[ "$BISCUIT_QC_CPGDIST" == true ]]; then
    >&2 echo "`date`---- BISCUIT_QC_CPGDIST ----"
    # whole genome
    echo -e "BISCUITqc CpG Distribution Table" >cpg_dist_table.txt
    awk '$4>0{a+=1}END{printf("\t%d\n",a)}' cpg.bed >>cpg_dist_table.txt

    # exon
    bedtools intersect -a cpg.bed -b <(bedtools merge -i $BISCUIT_EXON) -sorted | awk '$4>0{a+=1}END{printf("\t%d\n",a)}'  >>cpg_dist_table.txt

    # repeat
    bedtools intersect -a cpg.bed -b <(bedtools merge -i $BISCUIT_RMSK) -sorted | awk '$4>0{a+=1}END{printf("\t%d\n",a)}'  >>cpg_dist_table.txt

    # gene
    bedtools intersect -a cpg.bed -b <(bedtools merge -i $BISCUIT_GENE) -sorted | awk '$4>0{a+=1}END{printf("\t%d\n",a)}'  >>cpg_dist_table.txt

    # CGI
    bedtools intersect -a cpg.bed -b <(bedtools merge -i $BISCUIT_CGIBED) -sorted | awk '$4>0{a+=1}END{printf("\t%d\n",a)}'  >>cpg_dist_table.txt

    >&2 echo "`date`---- BISCUIT_QC_CGICOV ----"
  fi
}

input_vcf="<unset>"

function usage {
  >&2 echo "Usage: Bisulfite_QC_Coveragestats.sh input_vcf input_bam reference_genome QCannotation"
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
