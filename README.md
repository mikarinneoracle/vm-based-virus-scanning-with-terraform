## Instructions

### Create OL8 VM image

- Using Cloud UI create a VM with ssh access temporarily (can use Bastion service if preferred)
- Access VM over ssh
- Install UV scan
- Add <code>/home/opc/<a href="scan.sh">scan.sh</a></code> (modify <code>region</code> if necessary):

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

### Create Object Storage Bucket and Event using Terraform

<b>In could shell</b>:
- Copy repo and cd to <code><a href="terraform">/terraform</a></code> locally (Can use git clone)
- Update <code><a href="terraform/vars.tf">vars.tf</a></code> <code>compartment</code> and <code>region</code> used 
- Run <code>terraform init</code> and <code>terarform apply</code> 

### Create Dynamic Groups for Policies

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

### Create OCIR for Function

- Create Container registry <code>scanning</code> for the Funtion created in the next step

### Create Function

- Create Application <code>scanning</code>

<p>
<b>In could shell</b>:
- Copy repo and cd to <code><a href="scanning">/scanning</a></code> locally (Can use git clone; was done earlier)
- run:
<pre>
fn -v deploy --app scanning
</pre>

### Create Stack

<b>In localhost</b>:
- Copy repo and cd to <code><a href="resource_manager">/resource_manager</a></code> locally (Can use git clone)
- Update <code><a href="resource_manager/versions.tf">versions.tf</a></code> for <code>region</code> used
- Update <code><a href="resource_manager/vars.tf">vars.tf</a></code> for <code>VM image ocid</code>, <code>compartment</code> and <code>region/AD</code> used. <b>This can be also done in the next step in Resource Manager</b>.
- Create Resource Manager Stack using Cloud UI by drag-and-drop the folder <code>/resource_manager</code> from localhost

When Function is run using Resource Manager stack it creates (and optionally destroys)
- VCN with private subnet (no access from outside; add a Bastion Service if access is needed)
- VM instance to the VCN private subnet from the VM image created earlier
- Uses <code>instance-agent</code> to execute the uvscall shell script on the VM instance

### Configure Function

- Configure <code>STACK_OCID</code>, <code>COMPARTMENT_OCID</code>, <code>COMMAND</code> parameters for the Function

Command code (Can be <b>fixed</b> in the shell script instead for safety):
<pre>
sudo -u opc /home/opc/scan.sh
</pre>

### Questions

- How to update the uvscan data file ? After update create VM image again ? Automate somehow ?
