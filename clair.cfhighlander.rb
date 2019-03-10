CfhighlanderTemplate do
  Name 'clair'
  Description "clair"

  Component name: 'pipeline-scan', template: 'pipeline-scan'
  Component name: 'scheduled-scan', template: 'scheduled-scan'
  Component name: 'alarms', template: 'alarms' do
  	parameter name: 'SNS', value: 'scheduledscan.SNSTopic'
  end
end
