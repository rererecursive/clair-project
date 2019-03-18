CloudFormation do

  Resource("TaskDefinition") {
    Type 'AWS::ECS::TaskDefinition'
    Property('Cpu', 2048)
    Property('Memory', '4GB')
    Property('NetworkMode', 'awsvpc')
    Property('RequiresCompatibilities', ['FARGATE'])
    Property('TaskRoleArn', Ref('TaskRole'))
    Property('ExecutionRoleArn', Ref('ExecutionRole'))
    Property('ContainerDefinitions', [
      {
        Name: 'clair',
        Image: 'base2/clair',
        Cpu: 2048,
        Memory: 4096,
        Essential: true,
        LogConfiguration: {
          LogDriver: 'awslogs',
          Options: {
            'awslogs-group' => Ref("LogGroup"),
            "awslogs-region" => Ref("AWS::Region"),
            "awslogs-stream-prefix" => component_name
          }
        }
      }
    ])
  }

  Resource('LogGroup') {
    Type 'AWS::Logs::LogGroup'
    Property('LogGroupName', "clair-security-scans")
    Property('RetentionInDays', 90)
  }

  Resource('ExecutionRole') {
    Type 'AWS::IAM::Role'
    Property('AssumeRolePolicyDocument', {
      Statement: [
        Effect: 'Allow',
        Principal: {
          Service: ['ecs-tasks.amazonaws.com']
        },
        Action: ['sts:AssumeRole']
      ]
    })
    Property('Path', '/')
    Property('Policies', [
      {
        PolicyName: 'ecr-and-logs',
        PolicyDocument:
        {
          Statement:
          [
            {
              Effect: 'Allow',
              Action:
              [
              "ecr:GetAuthorizationToken",
              "ecr:BatchGetImage",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchCheckLayerAvailability",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
              ],
              Resource: ['*']
            }
          ]
        }
      }
    ])
  }

  Resource('TaskRole') {
    Type 'AWS::IAM::Role'
    Property('AssumeRolePolicyDocument', {
      Statement: [
        Effect: 'Allow',
        Principal: {
          Service: ['ecs-tasks.amazonaws.com']
        },
        Action: ['sts:AssumeRole']
      ]
    })
  }

  Resource('Cluster') {
    Type 'AWS::ECS::Cluster'
    Property('ClusterName', 'Clair')
  }

end
