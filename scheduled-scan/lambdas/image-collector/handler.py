#!/usr/bin/python3
import boto3
import json
import os

"""
Iterate over a stack name and collect all of container images that are used in all task definitions.

Required environment variables:
    ACCOUNT_ID              The AWS account ID that this Lambda function resides in
    TASK_DEFINITION_ARN     The task definition for the Clair container bundle
    ECS_CLUSTER             The ECS cluster to execute the above task on
    VPC                     f
    SUBNETS                 f
    SECURITY_GROUPS         f

Required parameters:
    StackName               The name of the CloudFormation stack to search for container images
    AccountId               The AWS account ID in which to to search the above stack
"""

def lambda_handler(event, context):
    print("Received event: %s" % (event))

    account_id = os.environ['ACCOUNT_ID']
    ecs_cluster = os.environ['ECS_CLUSTER']
    task_definition_arn = os.environ['TASK_DEFINITION_ARN']

    stack_name = event['StackName']
    target_account_id = event['AccountId']

    if account_id != target_account_id:
        sts = boto3.client('sts')
        creds = client.assume_role(
            RoleArn='arn:aws:sts::%s:role/ciinabox' % (target_account_id),
            RoleSessionName='scheduled-scan'
        )['Credentials']

        clientCloudFormation = boto3.client('cloudformation',
            aws_access_key_id=creds['AccessKeyId'],
            aws_secret_access_key=creds['SecretAccessKey']
        )
        clientECS = boto3.client('ecs',
            aws_access_key_id=creds['AccessKeyId'],
            aws_secret_access_key=creds['SecretAccessKey']
        )
    else:
        clientCloudFormation = boto3.client('cloudformation')
        clientECS = boto3.client('ecs')

    all_image_ids = collect_container_images(stack_name, clientCloudFormation, clientECS)
    all_image_ids = list(set(all_image_ids)).sort()    # Remove duplicates
    print("%d images were collected." % len(all_image_ids))

    # Now call RunTask() against Clair for each collected image.
    print("Preparing to launch ECS task: '%s' ..." % task_definition_arn)

    for image in all_image_ids:
        print("Starting task with image: %s ..." % image)

        clientECS.run_task(
            cluster=ecs_cluster,
            taskDefinition=task_definition_arn,
            startedBy=('lambda-%s' % context.aws_request_id),
            vpcConfiguration
        )

def collect_container_images(stack_name, clientCloudFormation, clientECS):
    image_ids = []

    print("Searching for container images in stack: %s ..." % stack_name)
    result = client.describe_stack_resources(StackName=stack_name)

    for resource in result.StackResources:
        if resource['ResourceType'] == 'AWS::ECS::TaskDefinition':
            resource_id = resource['PhysicalResourceId']
            task_definition = clientECS.describe_task_definition(TaskDefinition=resource_id)['taskDefinition']

            print("Task definition: %s" % (task_definition))

            for container_definitions in task_definition['containerDefinitions']:

                image_ids.append(container_definitions['image'])
                print("\tImage: %s" % (image))

        elif resource['ResourceType'] == 'AWS::CloudFormation::Stack':
            image_ids = image_ids + collect_container_images(resource['PhysicalResourceId'], clientCloudFormation, clientECS)

    return image_ids


'''
event = {
    'TargetFunctionArn': 'test',
    'Argument': '1234:prod1,prod2 4321:dev1 3333:ops',
    'AccountId': '1234'
}
lambda_handler(event, {})
'''