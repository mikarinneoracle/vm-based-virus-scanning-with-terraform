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

<b>In Cloud Shell</b>:
    
- Clone repo to localhost or Cloud Shell and cd to <code><a href="scanning">/scanning</a></code>
- Follow the instructions in the Application "Getting Started" to Function <code>scanning</code>
- Copy/paste <code>func.py</code>, <code>func.yaml</code>, <code>requirements.txt</code>
- Finally run (as part of the getting started):
<pre>
fn -v deploy --app scanning
</pre>
This will create and push the OCIR image and deploy the Function <code>scanning</code> to the Application

### Create Object Storage Bucket and Events using Terraform

<b>In could shell or locally</b>:

- Clone repo and cd to <code><a href="terraform">/terraform</a></code>
- Update <code><a href="terraform/vars.tf">vars.tf</a></code> <code>compartment</code> and <code>region</code> used 
- Run <code>terraform init</code> and <code>terraform apply</code> 

Running apply will create:

- Three Object Storage buckets <code>scanning</code>, <code>scanned</code>, <code>scanning_alert_report</code> 
- Event to kick-off the Function for environment creation using Resource Manager and then scanning using VM instance-agent and the scanning script
- Event to kick-off the Function for environment deletion using Resource Manager after the scanning is done
- To delete these resources run <code>terraform destroy</code> from Cloud Shell or locally

### Create Resource Manager Stack

<b>In localhost</b>:

- Clone repo and cd to <code><a href="resource_manager">/resource_manager</a></code> locally
- Update <code><a href="resource_manager/versions.tf">versions.tf</a></code> for <code>region</code> used
- Update <code><a href="resource_manager/vars.tf">vars.tf</a></code> for <code>VM image ocid</code>, <code>compartment</code> and <code>region/AD</code> used. <b>This can be also done in the next step in Resource Manager</b>.
- Create Resource Manager Stack using Cloud UI by drag-and-drop the folder <code>/resource_manager</code> from localhost

When Function is run using Resource Manager stack it creates (and then destroys once the scan is done)
- VCN with private subnet (no access from outside; add a Bastion Service if access is needed)
- VM instance to the VCN private subnet from the VM image created earlier
- Uses <code>instance-agent</code> to execute the uvscan shell script on the VM instance

### Configure Function

- Configure <code>STACK_OCID</code>, <code>COMPARTMENT_OCID</code>, <code>COMMAND</code> parameters for the Function tu run

VM Instance-Agent Run <code>COMMAND</code> (Can be <b>fixed</b> in the shell script instead for safety):
<pre>
sudo -u opc /home/opc/scan.sh
</pre>

### Questions / Considerations

- How to update the uvscan data file ? After update create VM image again ? Automate somehow ?
- To destroy the scanning VM env need to use another Event for the target buckets that will then
trigger another small function to use the Resource Manager Stack with destroy action after the
scanning is completed