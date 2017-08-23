describe Api::MetricRollupsService do
  before do
    allow(Settings.api).to receive(:metrics_default_limit).and_return(1000)
  end

  it 'validates that all of the parameters are present' do
    expect do
      described_class.query_metric_rollups({})
    end.to raise_error(Api::BadRequestError, a_string_including('Must specify'))
  end

  it 'validates the capture interval' do
    expect do
      described_class.query_metric_rollups(:resource_type    => 'Service',
                                           :start_date       => Time.zone.today.to_s,
                                           :capture_interval => 'bad_interval')
    end.to raise_error(Api::BadRequestError, a_string_including('Capture interval must be one of '))
  end
end
