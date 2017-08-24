describe Api::MetricRollupsService do
  context ".new" do
    it 'validates that all of the parameters are present' do
      expect do
        described_class.new({})
      end.to raise_error(Api::BadRequestError, a_string_including('Must specify'))
    end

    it 'validates the capture interval' do
      expect do
        described_class.new(:resource_type    => 'Service',
                            :start_date       => Time.zone.today.to_s,
                            :capture_interval => 'bad_interval')
      end.to raise_error(Api::BadRequestError, a_string_including('Capture interval must be one of '))
    end
  end
end
