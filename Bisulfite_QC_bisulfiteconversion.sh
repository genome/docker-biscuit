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
  set -xe

  ##########################
  ## bisulfite conversion
  ##########################
  [[ ! -f "$input_vcf" ]] && BISCUIT_QC_BSCONV=false
  if [[ "$BISCUIT_QC_BSCONV" == true ]]; then
    >&2 echo "`date`---- BISCUIT_QC_BSCONV ----"
    echo -e "BISCUITqc Conversion Rate by Base Average Table" >totalBaseConversionRate.txt
    biscuit vcf2bed -et c $input_vcf | awk '{beta_sum[$6]+=$8; beta_cnt[$6]+=1;} END{print "CA\tCC\tCG\tCT"; print beta_sum["CA"]/beta_cnt["CA"]"\t"beta_sum["CC"]/beta_cnt["CC"]"\t"beta_sum["CG"]/beta_cnt["CG"]"\t"beta_sum["CT"]/beta_cnt["CT"];}' >>totalBaseConversionRate.txt

    echo -e "BISCUITqc Conversion Rate by Read Average Table" >totalReadConversionRate.txt
    samtools view -hq 40 $input_bam | biscuit bsconv -b $BISCUIT_REFERENCE - | awk '{for(i=1;i<=8;++i) a[i]+=$i;}END{print "CpA\tCpC\tCpG\tCpT"; print a[1]/(a[1]+a[2])"\t"a[3]/(a[3]+a[4])"\t"a[5]/(a[5]+a[6])"\t"a[7]/(a[7]+a[8]);}' >>totalReadConversionRate.txt

    echo -e "BISCUITqc CpH Retention by Read Position Table" >CpHRetentionByReadPos.txt
    echo -e "ReadInPair\tPosition\tConversion/Retention\tCount" >>CpHRetentionByReadPos.txt
    samtools view -hq 40 $input_bam | biscuit cinread $BISCUIT_REFERENCE - -t ch -p QPAIR,CQPOS,CRETENTION | sort | uniq -c | awk -F" " '$4!="N"{print $2"\t"$3"\t"$4"\t"$1}' | sort -k1,1 -k2,2n >>CpHRetentionByReadPos.txt

    echo -e "BISCUITqc CpG Retention by Read Position Table" >CpGRetentionByReadPos.txt
    echo -e "ReadInPair\tPosition\tConversion/Retention\tCount" >>CpGRetentionByReadPos.txt
    samtools view -hq 40 $input_bam | biscuit cinread $BISCUIT_REFERENCE - -t cg -p QPAIR,CQPOS,CRETENTION | sort | uniq -c | awk -F" " '$4!="N"{print $2"\t"$3"\t"$4"\t"$1}' | sort -k1,1 -k2,2n >>CpGRetentionByReadPos.txt
  fi

}

input_vcf="<unset>"

function usage {
  >&2 echo "Usage: Bisulfite_QC_bisulfiteconversion.sh input_vcf input_bam referecnce_genome setup_file"
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

source "$setup_file"

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
