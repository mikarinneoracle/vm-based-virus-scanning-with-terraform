## Instructions

### Create OL8 VM image

- Create VM with ssh access temporarily (can use Bastion service if preferred)
- Access VM over ssh
- Install UV scan
- Configure run command agent

<pre>
echo "ocarun ALL=(ALL) NOPASSWD:ALL" > /tmp/101-oracle-cloud-agent-run-command
sudo cp /tmp/101-oracle-cloud-agent-run-command /etc/sudoers.d/
</pre>

- Add <code>/home/opc/scan.sh</code> (modify region and bucket names if necessary):

<pre>
rm -f /home/opc/report.txt
rm -rf /home/opc/scandir
mkdir /home/opc/scandir
oci os object bulk-download --bucket-name scanning --region eu-amsterdam-1 --download-dir 
/home/opc/scandir
/usr/local/uvscan/uvscan -v --unzip --analyze --summary --afc 512 --program --mime --recursive 
--threads=$(nproc) \
    --report=/home/opc/report.txt --rptall --rptcor --rpterr --rptobjects /home/opc/scandir
oci os object bulk-delete --bucket-name scanning --region eu-amsterdam-1 --force
</pre>

- Create VM image from the VM
- Copy OCID of the image
- Delete VM

