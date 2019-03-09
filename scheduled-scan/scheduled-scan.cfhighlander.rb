CfhighlanderTemplate do

  Extends 'task-definition-clair'

  Name 'pipeline-scan'
  Description "pipeline-scan - #{component_version}"

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
    ComponentParam 'Stacks', '', isGlobal: true
    ComponentParam 'S3Bucket', 'source.ap-southeast-2.zac.base2services.com'
  end


end
