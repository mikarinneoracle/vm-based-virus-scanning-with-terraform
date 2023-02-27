rm -f /home/opc/report.txt
rm -rf /home/opc/scandir
mkdir /home/opc/scandir
oci os object bulk-download --bucket-name scanning --region eu-amsterdam-1 --download-dir 
/home/opc/scandir
/usr/local/uvscan/uvscan -v --unzip --analyze --summary --afc 512 --program --mime --recursive 
--threads=$(nproc) \
    --report=/home/opc/report.txt --rptall --rptcor --rpterr --rptobjects /home/opc/scandir
oci os object bulk-delete --bucket-name scanning --region eu-amsterdam-1 --force
