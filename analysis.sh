
file_name=$( echo $1 | sed 's/.fastq//g')
threads=$2

activate="/bip7_disk/yuchun110/Minconda3/bin/activate"
#deactivate="/bip7_disk/yuchun110/Minconda3/bin/deactivate"

#porechop
source ${activate} porechop
porechop -i ${file_name}.fastq -o ${file_name}_porechop.fastq -t ${threads}
conda deactivate


#flye
source ${activate} flye
flye --nano-raw ${file_name}_porechop.fastq -o ${file_name}_porechop_assembly --genome-size 5m --thread ${threads} --iterations 0
conda deactivate

cp ./${file_name}_porechop_assembly/assembly.fasta ./

#minimap & racon
source ${activate} minimap_racon

../../minimap_racon/minimap2/minimap2 -t ${threads} -a -2 --sam-hit-only --secondary=no -Q -x map-ont assembly.fasta ${file_name}_porechop.fastq  > ${file_name}_mini1_racon0.sam

racon -t ${threads} -m 8 -x -6 -g -8 -w 500 ${file_name}_porechop.fastq ${file_name}_mini1_racon0.sam assembly.fasta > ${file_name}_racon1.fasta

../../minimap_racon/minimap2/minimap2 -t ${threads} -a -2 --sam-hit-only --secondary=no -Q -x map-ont ${file_name}_racon1.fasta ${file_name}_porechop.fastq  > ${file_name}_mini2_racon1.sam

racon -t ${threads} -m 8 -x -6 -g -8 -w 500 ${file_name}_porechop.fastq ${file_name}_mini2_racon1.sam ${file_name}_racon1.fasta > ${file_name}_racon2.fasta

../../minimap_racon/minimap2/minimap2 -t ${threads} -a -2 --sam-hit-only --secondary=no -Q -x map-ont ${file_name}_racon2.fasta ${file_name}_porechop.fastq  > ${file_name}_mini3_racon2.sam

racon -t ${threads} -m 8 -x -6 -g -8 -w 500 ${file_name}_porechop.fastq ${file_name}_mini3_racon2.sam ${file_name}_racon2.fasta > ${file_name}_racon3.fasta

../../minimap_racon/minimap2/minimap2 -t ${threads} -a -2 --sam-hit-only --secondary=no -Q -x map-ont ${file_name}_racon3.fasta ${file_name}_porechop.fastq  > ${file_name}_mini4_racon3.sam

racon -t ${threads} -m 8 -x -6 -g -8 -w 500 ${file_name}_porechop.fastq ${file_name}_mini4_racon3.sam ${file_name}_racon3.fasta > ${file_name}_racon4.fasta

conda deactivate

#medaka
source ${activate} medaka
medaka_consensus -i ${file_name}_porechop.fastq -d ${file_name}_racon4.fasta -o ${file_name}_racon4_medaka_prom -t ${threads} -m r941_prom_high_g303
conda deactivate

echo $'\n\nAfter medaka polish:\n' >> ${file_name}_all_info.txt
abyss-fac -t0 ${file_name}_racon4_medaka_prom/consensus.fasta >> ${file_name}_all_info.txt

#mash&homopolish
source ${activate} homopolish
python3 /bip7_disk/jhihyang_108/auto_assembly/detection.py  ${file_name}_racon4_medaka_prom/consensus.fasta ${threads} ${file_name}_mash_output/

mkdir ${file_name}_homopolish
cd ${file_name}_homopolish
python3 /bip7_disk/jhihyang_108/homopolish_CDS_combination/homopolish/old_version/main.py ../${file_name}_racon4_medaka_prom/consensus.fasta /bip7_disk/jhihyang_108/homopolish_CDS_combination/homopolish/old_version/svm_v1.pkl ${threads}
cd ..
conda deactivate


source ${activate} yuchun
checkm lineage_wf -t ${threads} -x fasta ${file_name}_homopolish/ ${file_name}_CheckM
echo $'\n\nCheckM Standard Output:\n' >> ${file_name}_all_info.txt
checkm qa ${file_name}_CheckM/lineage.ms ${file_name}_CheckM/ >> ${file_name}_all_info.txt
echo $'\nCheckM ALL Output:\n' >> ${file_name}_all_info.txt
checkm qa -o 3 ${file_name}_CheckM/lineage.ms ${file_name}_CheckM/ >> ${file_name}_all_info.txt
echo $'\n\n' >> ${file_name}_all_info.txt
conda deactivate


#prodigal&diamond
source ${activate} prodigal
mkdir ${file_name}_prodigal
prodigal -i ${file_name}_homopolish/final.fasta -o ${file_name}_prodigal/${file_name}.fasta -a ${file_name}_prodigal/${file_name}_proteins.fasta
mkdir ${file_name}_prodigal_diamond
/bip7_disk/yuchun110/diamond/diamond blastp -d /big7_disk/guocheng107/Zymo/card_db.dmnd -q ${file_name}_prodigal/${file_name}_proteins.fasta  -k 1 --more-sensitive -f 6 qseqid salltitles pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen full_qseq full_sseq -o ${file_name}_prodigal_diamond/${file_name}_prodigal_diamond.tsv  --query-cover 96
conda deactivate

#prokka
source ${activate} prokka
prokka ${file_name}_homopolish/final.fasta --outdir ${file_name}_prokka/
conda deactivate

#amrfinder
source ${activate} amrfinder
mkdir ${file_name}_amrfinder
/bip7_disk/yuchun110/amrfinder/amr-amrfinder_v3.10.23/amrfinder -p ${file_name}_prodigal/${file_name}_proteins.fasta -o ${file_name}_amrfinder/${file_name}_amrfinder.tsv --threads ${threads}
conda deactivate


