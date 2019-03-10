CloudFormation do

  container_definitions =  [
    {
      Name: 'clair',
      Image: '400480216381.dkr.ecr.ap-southeast-2.amazonaws.com/coreos-clair:latest',
      Cpu: 1024,
      Memory: 2048,
      Essential: true,
      Environment: [
        {
          Name: 'DB_HOST',
          Value: 'localhost'
        }
      ],
      LogConfiguration: {
        LogDriver: 'awslogs',
        Options: {
          'awslogs-group' => Ref("LogGroup"),
          "awslogs-region" => Ref("AWS::Region"),
          "awslogs-stream-prefix" => component_name
        }
      }
    },
    {
      Name: 'postgres',
      Image: 'postgres:11.2',
      Essential: true,
      Environment: [
        {
          Name: 'POSTGRES_PASSWORD',
          Value: 'password'
        }
      ],
      Cpu: 1024,
      Memory: 2048,
      LogConfiguration: {
        LogDriver: 'awslogs',
        Options: {
          'awslogs-group' => Ref("LogGroup"),
          "awslogs-region" => Ref("AWS::Region"),
          "awslogs-stream-prefix" => 'postgres'
        }
      }
    }
  ]

  if defined? include_klar and include_klar
    container_definitions << {
      Name: 'klar',
      Image: '400480216381.dkr.ecr.ap-southeast-2.amazonaws.com/klar:latest',
      Essential: true,
      Environment: [
        {
          Name: 'IMAGE',
          Value: ''
        }
      ],
      Cpu: 512,
      Memory: 1024,
      LogConfiguration: {
        LogDriver: 'awslogs',
        Options: {
          'awslogs-group' => Ref("LogGroup"),
          "awslogs-region" => Ref("AWS::Region"),
          "awslogs-stream-prefix" => 'klar'
        }
      }
    }
  end

  Resource("TaskDefinition") {
    Type 'AWS::ECS::TaskDefinition'
    Property('Cpu', 2048)
    Property('Memory', '4GB')
    Property('NetworkMode', 'awsvpc')
    Property('RequiresCompatibilities', ['FARGATE'])
    Property('TaskRoleArn', Ref('TaskRole'))
    Property('ExecutionRoleArn', Ref('ExecutionRole'))
    Property('ContainerDefinitions', container_definitions)
  }

  Resource('LogGroup') {
    Type 'AWS::Logs::LogGroup'
    Property('LogGroupName', "clair-security-scans-#{component_name}")
    Property('RetentionInDays', 14)
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
