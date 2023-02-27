import io
import json
import logging
import oci
import os
import collections

from fdk import response

def handler(ctx, data: io.BytesIO=None):
    signer = oci.auth.signers.get_resource_principals_signer()
    agent = oci.compute_instance_agent.ComputeInstanceAgentClient(config = {}, signer = signer)
    try:
        body = json.loads(data.getvalue())
        namespace = body["data"]["additionalDetails"]["namespace"]
        bucket = body["data"]["additionalDetails"]["bucketName"]
        object_name = body["data"]["resourceName"]
        print("Received file:  {}/{}".format(bucket, object_name), flush=True)

        # Store as config param
        # stack_id = args.get("STACK_OCID")

        args = collections.ChainMap(os.environ)
        compartment_id = args.get("COMPARTMENT_OCID")
        compute_instance_id = args.get("COMPUTE_INSTANCE_OCID")
        command= args.get("COMMAND")

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
        
        agentDetails = oci.compute_instance_agent.models.CreateInstanceAgentCommandDetails(compartment_id = compartment_id, 
                                                                                           content = content,
                                                                                           display_name =  "scanning",
                                                                                           execution_time_out_in_seconds = 300,
                                                                                           target = target)

        res = agent.create_instance_agent_command(create_instance_agent_command_details = agentDetails)
        # print("INFO - Agent create res: {}".format(res.data), flush=True)
        
    except Exception as e:
        print('ERROR', flush=True)
        raise

    return response.Response(
        ctx, 
        response_data=json.dumps({"status": "Success"}),
        headers={"Content-Type": "application/json"}
    )

