import io
import json
import logging
import oci
import os
import collections

from fdk import response

def handler(ctx, data: io.BytesIO=None):
    signer = oci.auth.signers.get_resource_principals_signer()
    rm_client = oci.resource_manager.ResourceManagerClient(config={}, signer=signer)
    agent = oci.compute_instance_agent.ComputeInstanceAgentClient(config = {}, signer = signer)
    try:
        body = json.loads(data.getvalue())
        namespace = body["data"]["additionalDetails"]["namespace"]
        bucket = body["data"]["additionalDetails"]["bucketName"]
        object_name = body["data"]["resourceName"]
        logging.getLogger().info('Received file:  {}/{}'.format(bucket, object_name))
        
        args = collections.ChainMap(os.environ)
        stack_id = args.get("STACK_OCID")
        compartment_id = args.get("COMPARTMENT_OCID")
        command= args.get("COMMAND")
        
        if bucket == "scanning":
            
            logging.getLogger().info('Started applying stack {}'.format(stack_id))
            job_details=rm_client.create_job(
                create_job_details=oci.resource_manager.models.CreateJobDetails(
                    stack_id=stack_id,
                    job_operation_details=oci.resource_manager.models.CreateApplyJobOperationDetails(
                        operation="APPLY",
                        execution_plan_strategy="AUTO_APPROVED")))

            job_id = job_details.data.id
            job_response = rm_client.get_job(job_id)
            oci.wait_until(rm_client, job_response, 'lifecycle_state', 'SUCCEEDED')
            logging.getLogger().info('==> Finished applying stack {}, jobid {}'.format(stack_id, job_id))
            log = rm_client.get_job_logs_content(job_id)
            lines = log.data.split("\n")
            line_count = len(lines)
            ocid_line = lines[line_count - 2]
            el = ocid_line.split(' ')
            if len(el) > 1:
                ocid = el[len(el) - 1]
                compute_instance_id = ocid.replace('"', '')
                logging.getLogger().info('==> OCID {}'.format(compute_instance_id))
                target = oci.compute_instance_agent.models.InstanceAgentCommandTarget(instance_id = compute_instance_id)        
                content = oci.compute_instance_agent.models.InstanceAgentCommandContent(
                    source = oci.compute_instance_agent.models.InstanceAgentCommandSourceViaTextDetails(
                        source_type = oci.compute_instance_agent.models.InstanceAgentCommandSourceViaTextDetails.SOURCE_TYPE_TEXT,
                        text = command
                    ),
                    output = oci.compute_instance_agent.models.InstanceAgentCommandOutputViaTextDetails(
                        output_type = oci.compute_instance_agent.models.InstanceAgentCommandOutputViaTextDetails.OUTPUT_TYPE_TEXT
                    )
                )
                agentDetails = oci.compute_instance_agent.models.CreateInstanceAgentCommandDetails(compartment_id =                                                                                                  compartment_id, 
                                                                                                   content = content,
                                                                                                   display_name =  "scanning",
                                                                                                   execution_time_out_in_seconds = 300,
                                                                                                   target = target)
                res = agent.create_instance_agent_command(create_instance_agent_command_details = agentDetails)
                logging.getLogger().info('Agent create res: {}'.format(res.data))

        if bucket == "scanned" or bucket == "scanning-alert-report":

            if bucket == "scanning-alert-report":
                logging.getLogger().warn('Virus sacn alert! Found infected files at {}'.format(object_name))

            logging.getLogger().info('Started destroying stack {}'.format(stack_id))

            job_details=rm_client.create_job(
                create_job_details=oci.resource_manager.models.CreateJobDetails(
                    stack_id=stack_id,
                    job_operation_details=oci.resource_manager.models.CreateDestroyJobOperationDetails(
                        operation="DESTROY",
                        execution_plan_strategy="AUTO_APPROVED")))

            job_id = job_details.data.id
            job_response = rm_client.get_job(job_id)
            oci.wait_until(rm_client, job_response, 'lifecycle_state', 'SUCCEEDED')
            logging.getLogger().info('==> Finished destroying stack {}, jobid {}'.format(stack_id, job_id))
                
    except Exception as e:
        print('ERROR', flush=True)
        raise

    return response.Response(
        ctx, 
        response_data=json.dumps({"status": "Success"}),
        headers={"Content-Type": "application/json"}
    )

