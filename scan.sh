export OCI_CLI_AUTH=instance_principal
rm -f /home/opc/report.txt
rm -rf /home/opc/scandir
mkdir /home/opc/scandir
# Using namespace is optional in oci cli commands below
namespace=$(oci os ns get | jq .data | tr -d '"')
oci os object bulk-download --bucket-name scanning --region eu-amsterdam-1 --download-dir /home/opc/scandir --namespace $namespace
/usr/local/uvscan/uvscan -v --unzip --analyze --summary --afc 512 --program --mime --recursive --threads=$(nproc) \
  --report=/home/opc/report.txt --rptall --rptcor --rpterr --rptobjects /home/opc/scandir
isInFile=$(cat /home/opc/report.txt | grep -c "Possibly Infected:.............     0")
if [ $isInFile -eq 0 ]; then
   echo "################# ALERT!!! Scanning found infected files ! #################"
   oci os object put --bucket-name scanning-alert-report --region eu-amsterdam-1 --file /home/opc/report.txt --force --namespace $namespace
else
   echo "################# Scanning found no infected files #################"
   oci os object bulk-delete --bucket-name scanned --region eu-amsterdam-1 --force --namespace $namespace
   oci os object put --bucket-name scanned --region eu-amsterdam-1 --file /home/opc/report.txt --force --namespace $namespace
   #oci os object bulk-upload --bucket-name scanned --region eu-amsterdam-1 --src-dir /home/opc/scandir --namespace $namespace 
   ls /home/opc/scandir > /home/opc/scanned.out
   while read file; do
    echo "uploading $file to scanned files"
    oci os object put --bucket-name scanned --region eu-amsterdam-1 --file /home/opc/scandir/$file --force --namespace $namespace
   done </home/opc/scanned.out
   rm -f /home/opc/scanned.out
fi
oci os object bulk-delete --bucket-name scanning --region eu-amsterdam-1 --force --namespace $namespace
