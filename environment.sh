#. environment.sh

echo -e "\e[0;32m"
echo -e "Start to install conda environment"
echo -e "\e[0m"

echo -e "\e[0;32m"
echo -e "Update conda"
echo -e "\e[0m"

#conda update -y -n base conda

start_time=$(date "+%Y-%m-%d %H:%M:%S")
#echo $start_time

echo -e "\e[0;32m"
echo -e "Start to install medaka"
echo -e "\e[0m"
#
#conda create -n ${vm_name} -c conda-forge -c bioconda medaka
conda create -n auto -y -c conda-forge -c bioconda medaka

echo -e "\e[0;32m"
echo -e "Start to install mash"
echo -e "\e[0m"
#
conda install -y -c conda-forge -c bioconda mash

echo -e "\e[0;32m"
echo -e "Start to install fastqc"
echo -e "\e[0m"
#
conda install -y -c bioconda fastqc

echo -e "\e[0;32m"
echo -e "Start to install abyss"
echo -e "\e[0m"
#
conda install -y -c bioconda abyss

echo -e "\e[0;32m"
echo -e "Start to install porechop"
echo -e "\e[0m"
#
conda install -y -c bioconda porechop

echo -e "\e[0;32m"
echo -e "Start to install flye"
echo -e "\e[0m"
#
conda install -y -c bioconda flye

echo -e "\e[0;32m"
echo -e "Start to install minimap2"
echo -e "\e[0m"
#
conda install -y -c bioconda minimap2

echo -e "\e[0;32m"
echo -e "Start to install racon"
echo -e "\e[0m"
#
conda install -y -c bioconda racon=1.4.13

echo -e "\e[0;32m"
echo -e "Start to install checkm"
echo -e "\e[0m"
#
conda install -y -c bioconda checkm-genome

echo -e "\e[0;32m"
echo -e "Start to install diamond"
echo -e "\e[0m"
#
conda install -y -c bioconda -c conda-forge diamond

echo -e "\e[0;32m"
echo -e "Start to install amrfider and update database"
echo -e "\e[0m"
#
conda install -y -c bioconda ncbi-amrfinderplus
amrfinder -u

echo -e "\e[0;32m"
echo -e "Start to install prokka"
echo -e "\e[0m"
#
conda install -y -c conda-forge -c bioconda prokka
#conda install -y -c bioconda perl-xml-simple

echo -e "\e[0;32m"
echo -e "List of tools version in the current environment" | tee -a tools_version.txt
echo -e "minimap2 version : $(minimap2 --version)" | tee -a tools_version.txt
echo -e "racon version : $(racon --version)" | tee -a tools_version.txt
echo -e "flye version : $(flye --version)" | tee -a tools_version.txt
echo -e "medaka version : $(medaka --version)" | tee -a tools_version.txt
echo -e "mash version : $(mash --version)" | tee -a tools_version.txt
echo -e "checkm version : $(checkm -h | sed -n '2p' | sed 's/^[ \t]*//g')" | tee -a tools_version.txt
echo -e "diamond version : $(diamond --version)" | tee -a tools_version.txt
echo -e "$(prokka --version)" | tee -a tools_version.txt
echo -e "amrfinder version : $(amrfinder --version)" | tee -a tools_version.txt
echo -e "\e[0m"

end_time=$(date "+%Y-%m-%d %H:%M:%S")
#echo $end_time
total_time=`echo $(($(date +%s -d "${end_time}") - $(date +%s -d "${start_time}"))) | awk '{t=split("60 s 60 m 24 h 999 d",a);for(n=1;n<t;n+=2){if($1==0)break;s=$1%a[n]a[n+1]s;$1=int($1/a[n])}print s}'`
echo -e "The environment script is from $start_time to $end_time "
echo -e "total time: $total_time"
echo -e "\e[0m"