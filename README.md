## Instructions

### Create OL8 VM image

- Create VM with ssh access temporarily (can use Bastion service if preferred)
- Access VM over ssh
- Install UV scan
- Add <code>/home/opc/<a href="scan.sh">scan.sh</a></code> (modify region and bucket names if necessary):

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

#### Create Dynamic Groups for Policies

- scanning_fn

<pre>
ALL {resource.type = 'fnfunc', resource.compartment.id = 'ocid1.compartment.oc1..aaaaaaaawccfklp2wj4c5ymigrkjfdhcbcm3u5ripl2whnznhmvgiqdatqgq'}
</pre>

- scanning_agent

<pre>
ANY {instance.compartment.id = 'ocid1.compartment.oc1..aaaaaaaawccfklp2wj4c5ymigrkjfdhcbcm3u5ripl2whnznhmvgiqdatqgq'}
</pre>


### Create policies

- scanning_fn

<pre>
Allow dynamic-group scanning_fn to manage instance-agent-command-family in compartment mika.rinne
Allow dynamic-group scanning_fn to manage all-resources in compartment mika.rinne
</pre>

- scanning_agent

<pre>
Allow dynamic-group scanning_agent to use instance-agent-command-execution-family in compartment mika.rinne where request.instance.id=target.instance.id
Allow dynamic-group scanning_agent to manage objects in compartment mika.rinne where all {target.bucket.name = 'scanning'}
Allow dynamic-group scanning_agent to use instance-agent-command-execution-family in compartment mika.rinne
</pre>

### Create Function

- Create Application <code>scanning</code>
- In could shell:
- Create fn
- Edit/copy func.py, func.yaml
- fn -v deploy --app scanning

### Create Stack

- Update Terraform <code><a href="terraform/vars.tf">vars.tf</a></code> for <code>VM image ocid</code>, <code>compartment</code> and <code>region/AD</code>. <b>This can be also done in the next step in Resource Manager</b>.

- Create Resource Manager Stack using Cloud UI

When run using TF stack creates/destroys
- VCN with private subnet
- Object Storage buckets <code>scanning</code> with emit events set to true, <code>scanned</code>, <code>scanning-alert-report</code>
- VM to private subnet from the VM image created earlier
- Event for scanning bucket writes (create, update) to call the Function

### Configure Function

- Configure <code>stack ocid</code>, <code>vm compartment ocid</code>, <code>command</code>

### Questions

- How to update the uvscan data file ? Create VM image again ? Automate ?
