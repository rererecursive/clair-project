CfhighlanderTemplate do
  Name 'task-definition-clair'
  Description "task-definition-clair - #{component_version}"

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
  end


end
