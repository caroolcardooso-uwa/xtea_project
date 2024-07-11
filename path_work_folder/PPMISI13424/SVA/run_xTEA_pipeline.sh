#!/bin/bash

#SBATCH --job-name=xtea_test
#SBATCH --nodes=1
#SBATCH --partition=work
#SBATCH --account=pawsey0360
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=50G
#SBATCH --time=24:00:00
#SBATCH --output=PPMISI13424_%j.out


source /software/projects/pawsey0360/cdoamaral/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/pawsey0360/cdoamaral/conda_envs/xtea_env_37

PREFIX=/scratch/pawsey0360/cdoamaral/xtea_project/path_work_folder/PPMISI13424/SVA/
############
############

ANNOTATION=/scratch/pawsey0360/cdoamaral/xtea_project/reference_files/rep_libs/SVA/hg38/hg38_SVA.out
ANNOTATION1=/scratch/pawsey0360/cdoamaral/xtea_project/reference_files/rep_libs/SVA/hg38/hg38_SVA.out
REF=/scratch/pawsey0360/cdoamaral/xtea_project/reference_files/hg38.fa
GENE=/scratch/pawsey0360/cdoamaral/xtea_project/reference_files/gencode.v38.annotation.gff3
BLACK_LIST=null
L1_COPY_WITH_FLANK=/scratch/pawsey0360/cdoamaral/xtea_project/reference_files/rep_libs/SVA/hg38/hg38_SVA_copies_with_flank.fa
SF_FLANK=/scratch/pawsey0360/cdoamaral/xtea_project/reference_files/rep_libs/SVA/hg38/hg38_FL_SVA_flanks_3k.fa
L1_CNS=/scratch/pawsey0360/cdoamaral/xtea_project/reference_files/rep_libs/consensus/SVA.fa
XTEA_PATH=/scratch/pawsey0360/cdoamaral/xtea_project/xTea/xTea/xtea/
BAM_LIST=${PREFIX}"bam_list.txt"
BAM1=${PREFIX}"10X_phased_possorted_bam.bam"
BARCODE_BAM=${PREFIX}"10X_barcode_indexed.sorted.bam"
TMP=${PREFIX}"tmp/"
TMP_CLIP=${PREFIX}"tmp/clip/"
TMP_CNS=${PREFIX}"tmp/cns/"
TMP_TNSD=${PREFIX}"tmp/transduction/"
############
############
python ${XTEA_PATH}"x_TEA_main.py" -C --sva -i ${BAM_LIST} --lc 3 --rc 3 --cr 1  -r ${L1_COPY_WITH_FLANK}  -a ${ANNOTATION} --cns ${L1_CNS} --ref ${REF} -p ${TMP} -o ${PREFIX}"candidate_list_from_clip.txt"  -n 1 --cp ./path_work_folder/PPMISI13424/pub_clip/
python ${XTEA_PATH}"x_TEA_main.py"  -D --sva -i ${PREFIX}"candidate_list_from_clip.txt" --nd 5 --ref ${REF} -a ${ANNOTATION} -b ${BAM_LIST} -p ${TMP} -o ${PREFIX}"candidate_list_from_disc.txt" -n 1
python ${XTEA_PATH}"x_TEA_main.py" -N --sva --cr 3 --nd 5 -b ${BAM_LIST} -p ${TMP_CNS} --fflank ${SF_FLANK} --flklen 3000 -n 1 -i ${PREFIX}"candidate_list_from_disc.txt" -r ${L1_CNS} --ref ${REF} -a ${ANNOTATION} -o ${PREFIX}"candidate_disc_filtered_cns.txt"
python ${XTEA_PATH}"x_TEA_main.py" --transduction --cr 3 --nd 5 -b ${BAM_LIST} -p ${TMP_TNSD} --fflank ${SF_FLANK} --flklen 3000 -n 1 -i ${PREFIX}"candidate_disc_filtered_cns.txt" -r ${L1_CNS} --ref ${REF} --input2 ${PREFIX}"candidate_list_from_disc.txt.clip_sites_raw_disc.txt" --rtype 4 -a ${ANNOTATION1}    -o ${PREFIX}"candidate_disc_filtered_cns2.txt"
python ${XTEA_PATH}"x_TEA_main.py" --sibling --cr 3 --nd 5 -b ${BAM_LIST} -p ${TMP_TNSD} --fflank "" --flklen 3000 -n 1 -i ${PREFIX}"candidate_disc_filtered_cns2.txt" -r ${L1_CNS} --ref ${REF} --input2 ${PREFIX}"candidate_list_from_disc.txt.clip_sites_raw_disc.txt" --rtype 4 -a ${ANNOTATION1} --blacklist ${BLACK_LIST}    -o ${PREFIX}"candidate_sibling_transduction2.txt"
python ${XTEA_PATH}"x_TEA_main.py" --postF --rtype 4 -p ${TMP_CNS} -n 1 -i ${PREFIX}"candidate_disc_filtered_cns2.txt" -a ${ANNOTATION1}  -o ${PREFIX}"candidate_disc_filtered_cns_post_filtering.txt"
python ${XTEA_PATH}"x_TEA_main.py" --postF --rtype 4 -p ${TMP_CNS} -n 1 -i ${PREFIX}"candidate_disc_filtered_cns2.txt.high_confident" -a ${ANNOTATION1} --blacklist ${BLACK_LIST}  -o ${PREFIX}"candidate_disc_filtered_cns.txt.high_confident.post_filtering.txt"
python ${XTEA_PATH}"x_TEA_main.py" --gene -a ${GENE} -i ${PREFIX}"candidate_disc_filtered_cns.txt.high_confident.post_filtering.txt"  -n 1 -o ${PREFIX}"candidate_disc_filtered_cns.txt.high_confident.post_filtering_with_gene.txt"
python ${XTEA_PATH}"x_TEA_main.py" --gntp_classify -i ${PREFIX}"candidate_disc_filtered_cns.txt.high_confident.post_filtering_with_gene.txt"  -n 1 --model ${XTEA_PATH}"genotyping/trained_model_ssc_py2_random_forest_two_category.pkl"  -o ${PREFIX}"candidate_disc_filtered_cns.txt.high_confident.post_filtering_with_gene_gntp.txt"
python ${XTEA_PATH}"x_TEA_main.py" --gVCF -i ${PREFIX}"candidate_disc_filtered_cns.txt.high_confident.post_filtering_with_gene_gntp.txt"  -o ${PREFIX} -b ${BAM_LIST} --ref ${REF} --rtype 4


