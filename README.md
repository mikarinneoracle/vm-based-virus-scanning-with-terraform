## Instructions

### Create OL8 VM image

- Create VM with ssh access temporarily (can use Bastion service if preferred)
- Access VM over ssh
- Install UV scan
- Configure run command agent:

<pre>
echo "ocarun ALL=(ALL) NOPASSWD:ALL" > /tmp/101-oracle-cloud-agent-run-command
sudo cp /tmp/101-oracle-cloud-agent-run-command /etc/sudoers.d/
</pre>

- Add <code>/home/opc/scan.sh</code> (modify region and bucket names if necessary):

<pre>
rm -f /home/opc/report.txt
rm -rf /home/opc/scandir
mkdir /home/opc/scandir
oci os object bulk-download --bucket-name scanning --region eu-amsterdam-1 --download-dir /home/opc/scandir
/usr/local/uvscan/uvscan -v --unzip --analyze --summary --afc 512 --program --mime --recursive --threads=$(nproc) \
  --report=/home/opc/report.txt --rptall --rptcor --rpterr --rptobjects /home/opc/scandir
isInFile=$(cat /home/opc/report.txt | grep -c "Possibly Infected:.............     0")
if [ $isInFile -eq 0 ]; then
   echo "################# ALERT!!! Scanning found infected files ! #################"
   oci os object put --bucket-name scanning-alert-report --region eu-amsterdam-1 --file /home/opc/report.txt --force
else
   echo "################# Scanning found no infected files #################"
   oci os object bulk-delete --bucket-name scanned --region eu-amsterdam-1 --force
   oci os object put --bucket-name scanned --region eu-amsterdam-1 --file /home/opc/report.txt --force
   oci os object bulk-upload --bucket-name scanned --region eu-amsterdam-1 --src-dir /home/opc/scandir
fi
oci os object bulk-delete --bucket-name scanning --region eu-amsterdam-1 --force
</pre>

- Create VM image from the VM
- Copy <code>OCID</code> of the image
- Delete VM

### Create policies

### Create Stack

- Update VM image ocid and region

### Create Function

- Create Application <code>scanning</code>
- Configure <code>stack ocid</code>, <code>vm compartment ocid</code>, <code>command</code>
- In could shell:
- Create fn
- Edit/copy func.py, func.yaml
- fn -v deploy --app scanning

### Questions

- How to update the uvscan data file ? Create VM image again ? Automate ?
