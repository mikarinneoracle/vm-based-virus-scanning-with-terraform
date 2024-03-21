## Instructions

### Create OL8 VM image

- Using Cloud UI create a VM with ssh access temporarily (can use Bastion service if preferred)
- Install oci cli (will be authorized as instance-principal)
- Install UV scan. I downloaded Command Line Scanner for Linux-64bit free trial from https://www.trellix.com/en-us/downloads/trials.html?selectedTab=endpointprotection and then using <code>scp</code> copied the file to the
VM instance using Internet connection over ssh, e.g.:

<pre>
 scp cls-l64-703-e.tar.gz opc@141.144.201.144:/tmp
</pre>

- Access VM over ssh and add <code>/home/opc/<a href="scan.sh">scan.sh</a></code> (modify <code>region</code> if necessary):

<pre>
export OCI_CLI_AUTH=instance_principal
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

- Also dowloaded the uvscan datafile and then moved it to it's place (in uvscan):

<pre>
wget https://update.nai.com/products/commonupdater/current/vscandat1000/dat/0000/avvdat-10629.zip 
</pre>

- Using Cloud UI create a VM image from the VM
- Copy <code>OCID</code> of the created VM image for the step <a href="#create-resource-manager-stack">Create Resource Manager Stack</a>
- Delete VM

### Create Dynamic Groups for Policies

- scanning_fn

<pre>
ALL {resource.type = 'fnfunc', resource.compartment.id = 'ocid1.compartment.oc1..u5ripl2whnznhmvgiqdatqgq'}
</pre>

- scanning_agent

<pre>
ANY {instance.compartment.id = 'ocid1.compartment.oc1..u5ripl2whnznhmvgiqdatqgq'}
</pre>


### Create policies

- scanning_fn

This should be enough:
<pre>
Allow dynamic-group scanning_fn to manage instance-agent-command-family in compartment &lt;YOUR COMPARTMENT&gt;
</pre>

However, I used policy for broader access to make it work:
<pre>
Allow dynamic-group scanning_fn to manage all-resources in compartment &lt;YOUR COMPARTMENT&gt;
</pre>

- scanning_agent

<pre>
Allow dynamic-group scanning_agent to use instance-agent-command-execution-family in compartment &lt;YOUR COMPARTMENT&gt; where request.instance.id=target.instance.id
Allow dynamic-group scanning_agent to manage objects in compartment &lt;YOUR COMPARTMENT&gt; where all {target.bucket.name = 'scanning'}
Allow dynamic-group scanning_agent to use instance-agent-command-execution-family in compartment &lt;YOUR COMPARTMENT&gt;
</pre>

### Create OCIR for Function

- In Cloud UI create Container registry <code>scanning</code> for the Function created in the next step

### Create Function

- In Cloud UI create Application <code>scanning</code>
- Enable logging

<b>In Cloud Shell / Cloud Code Editor</b>:
    
- Clone repo to localhost or Cloud Shell and cd to <code><a href="scanning">/scanning</a></code>
- Follow the instructions in the Application "Getting Started" to Function <code>scanning</code>
- Copy/paste <code>func.py</code>, <code>func.yaml</code>, <code>requirements.txt</code>
- Finally run (as part of the getting started):
<pre>
fn -v deploy --app scanning
</pre>
This will create and push the OCIR image and deploy the Function <code>scanning</code> to the Application

### Create Object Storage Bucket and Events using Terraform

<b>In could shell or localhost</b>:

- Clone repo and cd to <code><a href="terraform">/terraform</a></code>
- Update <code><a href="terraform/vars.tf">vars.tf</a></code> <code>compartment</code> and <code>region</code> used 
- Run <code>terraform init</code> and <code>terraform apply</code> 

Running apply will create:

- Three Object Storage buckets <code>scanning</code>, <code>scanned</code>, <code>scanning-alert-report</code> 
- Event to kick-off the Function for environment creation using Resource Manager and then scanning using VM instance-agent and the scanning script
- Event to kick-off the Function for environment deletion using Resource Manager after the scanning is done
- To delete these resources run <code>terraform destroy</code> from Cloud Shell or locally

### Create Resource Manager Stack

<b>In localhost</b>:

- Clone repo and cd to <code><a href="resource_manager">/resource_manager</a></code> locally
- Update <code><a href="resource_manager/versions.tf">versions.tf</a></code> for <code>region</code> used
- Update <code><a href="resource_manager/vars.tf">vars.tf</a></code> for <code>VM image ocid</code>, <code>compartment</code> and <code>region/AD</code> used. <b>This can be also done in the next step in Resource Manager</b>.
- Create Resource Manager Stack using Cloud UI by drag-and-drop the folder <code>/resource_manager</code> from localhost
- Copy <code>OCID</code> of the Stack for the next step <a href="#configure-function">Configure Function</a>

When Function is run using Resource Manager stack it creates (and then destroys once the scan is done)
- VCN with private subnet (no access from outside; add a Bastion Service if access is needed)
- VM instance to the VCN private subnet from the VM image created earlier
- Uses <code>instance-agent</code> to execute the uvscan shell script on the VM instance


### Configure Function

- Configure <code>STACK_OCID</code>, <code>COMPARTMENT_OCID</code>, <code>COMMAND</code> parameters for the Function tu run

VM Instance-Agent Run <code>COMMAND</code>:
<pre>
sudo -u opc /home/opc/scan.sh
</pre>

### Upload a .zip file

- Use oci cli

<pre>
oci os object put --bucket-name scanning --region eu-amsterdam-1 --file test.zip
</pre>

- To use curl first create a <code>PAR</code> (preauthenticated request) for the bucket <code>scanning</code> with <code>permit object writes</code> using Cloud UI and then use curl command (example):

<pre>
curl -T test.zip https://objectstorage.eu-amsterdam-1.oraclecloud.com/p/0ZBlo1e.....caMjhEfRsjcg5/n/frsxwtjslf35/b/scanning/o/
</pre>
