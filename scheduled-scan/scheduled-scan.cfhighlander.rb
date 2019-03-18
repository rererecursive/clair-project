CfhighlanderTemplate do

  Name 'scheduled-scan'
  Description "scheduled-scan - #{component_version}"

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
    ComponentParam 'Stacks', '', isGlobal: true
    ComponentParam 'SNSCrit', "" # TODO
    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'
    ComponentParam 'SecurityGroupIds', type: 'List<AWS::EC2::SecurityGroup::Id>'
    ComponentParam 'SubnetIds', type: 'List<AWS::EC2::Subnet::Id>'
  end

  LambdaFunctions 'lambdas'

end
