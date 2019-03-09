CloudFormation do

  Resource('Schedule') {
    Type 'AWS::Events::Rule'
    Property('Description', 'Scan container images with Clair')
    Property('ScheduleExpression', 'rate(12 hours)')
    Property('State', 'ENABLED')
    Property('Targets', [
      {
        Arn: FnGetAtt('FunctionStackCollector', 'Arn'),
        Id: 'target'
      }
    ])
  }

  Resource("MetricFilter") {
    Type 'AWS::Logs::MetricFilter'
    Property('LogGroupName', Ref('LogGroup'))
    Property('FilterPattern', '{}')
    Property('MetricTransformations', [
      {
        MetricName: metric_name,
        MetricNamespace: metric_namespace,
        MetricValue: 1
      }
    ])
  }

  Resource("Alarm") {
    Type 'AWS::CloudWatch::Alarm'
    Property('ActionsEnabled', true)
    Property('AlarmActions', [ Ref('Topic') ])
    Property('AlarmDescription', 'Number of vulnerable container images')
    Property('ComparisonOperator', 'GreaterThanOrEqualToThreshold')
    Property('DatapointsToAlarm', 1)
    Property('EvaluationPeriods', 1)
    Property('MetricName', metric_name)
    Property('Namespace', metric_namespace)
    Property('Period', 60)
    Property('Statistic', 'Sum')
    Property('Threshold', 1)
    Property('TreatMissingData', 'notBreaching')
  }

  Resource('Topic') {
    Type 'AWS::SNS::Topic'
    Property('DisplayName', 'TriggerFunctionLogsToSNS')
    Property('Subscription', [
      {
        Protocol: 'lambda',
        Endpoint: FnGetAtt('FunctionLogsToSNS', 'Arn')
      }
    ])
  }

  Resource('Cluster') {
    Type 'AWS::ECS::Cluster'
    Property('ClusterName', 'Clair')
  }

  # Keep
  Resource('FunctionStackCollector') {
    Type 'AWS::Lambda::Function'
    Property('Code', {
      S3Bucket: Ref('S3Bucket'),
      S3Key: 'lambdas/stack-collector/handler.zip'
    })
    Property('Environment', {
      Variables: {
        'ACCOUNT_ID' => Ref('AWS::AccountId'),
        'TARGET_FUNCTION_ARN' => FnGetAtt('FunctionImageCollector', 'Arn'),
        'STACKS' => Ref('Stacks')
      }
    })
    Property('Handler', 'handler.lambda_handler')
    Property('MemorySize', 128)
    Property('Role', FnGetAtt('Role', 'Arn'))   # TODO
    Property('Runtime', 'python3.6')
    Property('Timeout', 10)
  }

  Resource('PermissionStackCollector') {
    Type 'AWS::Lambda::Permission'
    Property('Action', 'lambda:InvokeFunction')
    Property('Principal', 'events.amazonaws.com')
    Property('FunctionName', Ref('FunctionLogsToSNS'))
    Property('SourceArn', Ref('Topic'))
  }

  Resource('Role') {
    Type 'AWS::IAM::Role'
    Property('AssumeRolePolicyDocument', {
      Statement: [
        Effect: 'Allow',
        Principal: { Service: ['lambda.amazonaws.com'] },
        Action: ['sts:AssumeRole']
      ]
    })
    Property('Path', '/')
    Property('Policies', [
      {
        PolicyName: 'ossec-alerts',
        PolicyDocument:
        {
          Statement:
          [
            {
              Effect: 'Allow',
              Action:
              [
                "logs:*",
                "ses:*",
                "sns:*"
              ],
              Resource: ['*']
            }
          ]
        }
      }
    ])
    Property('ManagedPolicyArns', [
      "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    ])
  }

  # Keep
  Resource('FunctionImageCollector') {
    Type 'AWS::Lambda::Function'
    Property('Code', {
      S3Bucket: Ref('S3Bucket'),
      S3Key: 'lambdas/image-collector/handler.zip'
    })
    Property('Environment', {
      Variables: {
        'ACCOUNT_ID' => Ref('AWS::AccountId'),
        'TASK_DEFINITION_ARN' => Ref('TaskDefinition'),
        'ECS_CLUSTER' => Ref('Cluster')
      }
    })
    Property('Handler', 'handler.lambda_handler')
    Property('MemorySize', 128)
    Property('Role', FnGetAtt('Role', 'Arn'))   # TODO
    Property('Runtime', 'python3.6')
    Property('Timeout', 60)
  }

  Resource('FunctionLogsToSNS') {
    Type 'AWS::Lambda::Function'
    Property('Code', {
      S3Bucket: Ref('S3Bucket'),
      S3Key: 'lambdas/logs-to-sns/handler.zip'
    })
    Property('Environment', {
      Variables: {
        'NOTIFY_SNS' => Ref('Topic')
      }
    })
    Property('Handler', 'index.handler')
    Property('MemorySize', 128)
    Property('Role', FnGetAtt('Role', 'Arn'))
    Property('Runtime', 'nodejs8.10')
    Property('Timeout', 3)
    Property('TracingConfig', {
      Mode: 'PassThrough'
    })
  }

  Resource('Permission') {
    Type 'AWS::Lambda::Permission'
    Property('Action', 'lambda:InvokeFunction')
    Property('Principal', 'sns.amazonaws.com')
    Property('FunctionName', Ref('FunctionLogsToSNS'))
    Property('SourceArn', Ref('Topic'))
  }

  Resource('Role') {
    Type 'AWS::IAM::Role'
    Property('AssumeRolePolicyDocument', {
      Statement: [
        Effect: 'Allow',
        Principal: { Service: ['lambda.amazonaws.com'] },
        Action: ['sts:AssumeRole']
      ]
    })
    Property('Path', '/')
    Property('Policies', [
      {
        PolicyName: 'clair',
        PolicyDocument:
        {
          Statement:
          [
            {
              Effect: 'Allow',
              Action:
              [
                "logs:*",
                "ses:*",
                "sns:*"
              ],
              Resource: ['*']
            }
          ]
        }
      }
    ])
    Property('ManagedPolicyArns', [
      "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    ])
  }

end
