RSpec.describe Api::Filter do
  describe ".parse" do
    it "supports attribute equality test using double quotes" do
      filters = ['name="bb"']

      actual = described_class.parse(filters, Vm)

      expected = {"=" => {"field" => "Vm-name", "value" => "bb"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports attribute equality test using single quotes" do
      filters = ["name='aa'"]

      actual = described_class.parse(filters, Vm)

      expected = {"=" => {"field" => "Vm-name", "value" => "aa"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports attribute pattern matching via %" do
      filters = ["name='aa%'"]

      actual = described_class.parse(filters, Vm)

      expected = {"REGULAR EXPRESSION MATCHES" => {"field" => "Vm-name", "value" => "/\\Aaa.*\\z/"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports attribute pattern matching via *" do
      filters = ["name='aa*'"]

      actual = described_class.parse(filters, Vm)

      expected = {"REGULAR EXPRESSION MATCHES" => {"field" => "Vm-name", "value" => "/\\Aaa.*\\z/"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports inequality test via !=" do
      filters = ["name!='b%'"]

      actual = described_class.parse(filters, Vm)

      expected = {"REGULAR EXPRESSION DOES NOT MATCH" => {"field" => "Vm-name", "value" => "/\\Ab.*\\z/"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports multiple possible values using arrays with =" do
      filters  = ["name=[foo,bar,baz]"]
      actual   = described_class.parse(filters, Vm)
      expected = {
        "OR" => [
          {"=" => {"field" => "Vm-name", "value" => "foo"}},
          {"=" => {"field" => "Vm-name", "value" => "bar"}},
          {"=" => {"field" => "Vm-name", "value" => "baz"}}
        ]
      }

      expect(actual.exp).to eq(expected)
    end

    it "supports NULL/nil equality test via =" do
      filters = ["retired=NULL"]

      actual = described_class.parse(filters, Vm)

      expected = {"IS NULL" => {"field" => "Vm-retired", "value" => nil}}
      expect(actual.exp).to eq(expected)
    end

    it "supports NULL/nil inequality test via !=" do
      filters = ["retired!=nil"]

      actual = described_class.parse(filters, Vm)

      expected = {"IS NOT NULL" => {"field" => "Vm-retired", "value" => nil}}
      expect(actual.exp).to eq(expected)
    end

    it "supports numerical less than comparison via <" do
      filters = ["id < 1000000000123"]

      actual = described_class.parse(filters, Vm)

      expected = {"<" => {"field" => "Vm-id", "value" => "1000000000123"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports numerical less than or equal comparison via <=" do
      filters = ["id <= 1000000000123"]

      actual = described_class.parse(filters, Vm)

      expected = {"<=" => {"field" => "Vm-id", "value" => "1000000000123"}}
      expect(actual.exp).to eq(expected)
    end

    it "support greater than numerical comparison via >" do
      filters = ["id > 1000000000123"]

      actual = described_class.parse(filters, Vm)

      expected = {">" => {"field" => "Vm-id", "value" => "1000000000123"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports greater or equal than numerical comparison via >=" do
      filters = ["id >= 1000000000123"]

      actual = described_class.parse(filters, Vm)

      expected = {">=" => {"field" => "Vm-id", "value" => "1000000000123"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports compound logical OR comparisons" do
      filters = ["id = 1000000000123", "or id > 1000000000456"]

      actual = described_class.parse(filters, Vm)

      expected = {
        "OR" => [
          {"=" => {"field" => "Vm-id", "value" => "1000000000123"}},
          {">" => {"field" => "Vm-id", "value" => "1000000000456"}}
        ]
      }
      expect(actual.exp).to eq(expected)
    end

    it "supports multiple logical AND comparisons" do
      filters = ["id = 1000000000123", "name = foo"]

      actual = described_class.parse(filters, Vm)

      expected = {
        "AND" => [
          {"=" => {"field" => "Vm-id", "value" => "1000000000123"}},
          {"=" => {"field" => "Vm-name", "value" => "foo"}}
        ]
      }
      expect(actual.exp).to eq(expected)
    end

    it "supports multiple comparisons with both AND and OR" do
      filters = ["id = 1000000000123", "name = foo", "or id > 1000000000456"]

      actual = described_class.parse(filters, Vm)

      expected = {
        "OR" => [
          {
            "AND" => [
              {"=" => {"field" => "Vm-id", "value" => "1000000000123"}},
              {"=" => {"field" => "Vm-name", "value" => "foo"}}
            ]
          },
          {">" => {"field" => "Vm-id", "value" => "1000000000456"}}
        ]
      }
      expect(actual.exp).to eq(expected)
    end

    it "supports filtering by attributes of associations" do
      filters = ["host.name='foo'"]

      actual = described_class.parse(filters, Vm)

      expected = {"=" => {"field" => "Vm.host-name", "value" => "foo"}}
      expect(actual.exp).to eq(expected)
    end

    it "does not support filtering by attributes of associations' associations" do
      filters = ["host.hardware.memory_mb>1024"]

      expect do
        described_class.parse(filters, Vm)
      end.to raise_error(Api::BadRequestError,
                         "Filtering of attributes with more than one association away is not supported")
    end

    it "supports filtering by virtual string attributes" do
      filters = ["host_name='aa'"]

      actual = described_class.parse(filters, Vm)

      expected = {"=" => {"field" => "Vm-host_name", "value" => "aa"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports filtering by string set attributes, e.g.: ipaddresses" do
      filters = ["ipaddresses='192.0.2.0'"]

      actual = described_class.parse(filters, Vm)

      expected = {"includes all" => {"field" => "Vm-ipaddresses", "value" => "192.0.2.0"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports flexible filtering by virtual string attributes" do
      filters = ["host_name='a%'"]

      actual = described_class.parse(filters, Vm)

      expected = {"REGULAR EXPRESSION MATCHES" => {"field" => "Vm-host_name", "value" => "/\\Aa.*\\z/"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports filtering by virtual boolean attributes" do
      filters = ["archived=true"]

      actual = described_class.parse(filters, Vm)

      expected = {"=" => {"field" => "Vm-archived", "value" => "true"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports filtering by comparison of virtual integer attributes" do
      filters = ["num_cpu > 4"]

      actual = described_class.parse(filters, Vm)

      expected = {">" => {"field" => "Vm-num_cpu", "value" => "4"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports = with dates mixed with virtual attributes" do
      filters = ["retires_on = 2016-01-02", "vendor_display = VMware"]

      actual = described_class.parse(filters, Vm)

      expected = {
        "AND" => [
          {"IS" => {"field" => "Vm-retires_on", "value" => "2016-01-02"}},
          {"=" => {"field" => "Vm-vendor_display", "value" => "VMware"}}
        ]
      }
      expect(actual.exp).to eq(expected)
    end

    it "supports > with dates mixed with virtual attributes" do
      filters = ["retires_on > 2016-01-01", "vendor_display = VMware"]

      actual = described_class.parse(filters, Vm)

      expected = {
        "AND" => [
          {"AFTER" => {"field" => "Vm-retires_on", "value" => "2016-01-01"}},
          {"=" => {"field" => "Vm-vendor_display", "value" => "VMware"}}
        ]
      }
      expect(actual.exp).to eq(expected)
    end

    it "supports > with datetimes mixed with virtual attributes" do
      filters = ["last_scan_on > 2016-01-01T07:59:59Z", "vendor_display = VMware"]

      actual = described_class.parse(filters, Vm)

      expected = {
        "AND" => [
          {"AFTER" => {"field" => "Vm-last_scan_on", "value" => "2016-01-01T07:59:59Z"}},
          {"=" => {"field" => "Vm-vendor_display", "value" => "VMware"}}
        ]
      }
      expect(actual.exp).to eq(expected)
    end

    it "supports < with dates mixed with virtual attributes" do
      filters = ["retires_on < 2016-01-03", "vendor_display = VMware"]

      actual = described_class.parse(filters, Vm)

      expected = {
        "AND" => [
          {"BEFORE" => {"field" => "Vm-retires_on", "value" => "2016-01-03"}},
          {"=" => {"field" => "Vm-vendor_display", "value" => "VMware"}}
        ]
      }
      expect(actual.exp).to eq(expected)
    end

    it "supports < with datetimes mixed with virtual attributes" do
      filters = ["last_scan_on < 2016-01-01T08:00:00Z", "vendor_display = VMware"]

      actual = described_class.parse(filters, Vm)

      expected = {
        "AND" => [
          {"BEFORE" => {"field" => "Vm-last_scan_on", "value" => "2016-01-01T08:00:00Z"}},
          {"=" => {"field" => "Vm-vendor_display", "value" => "VMware"}}
        ]
      }
      expect(actual.exp).to eq(expected)
    end

    it "does not support filtering with <= with datetimes" do
      filters = ["retires_on <= 2016-01-03"]

      expect do
        described_class.parse(filters, Vm)
      end.to raise_error(Api::BadRequestError, "Unsupported operator for datetime: <=")
    end

    it "does not support filtering with >= with datetimes" do
      filters = ["retires_on >= 2016-01-03"]

      expect do
        described_class.parse(filters, Vm)
      end.to raise_error(Api::BadRequestError, "Unsupported operator for datetime: >=")
    end

    it "does not support filtering with != with datetimes" do
      filters = ["retires_on != 2016-01-03"]

      expect do
        described_class.parse(filters, Vm)
      end.to raise_error(Api::BadRequestError, "Unsupported operator for datetime: !=")
    end

    it "will handle poorly formed datetimes in the filter" do
      filters = ["retires_on > foobar"]

      expect do
        described_class.parse(filters, Vm)
      end.to raise_error(Api::BadRequestError, "Bad format for datetime: foobar")
    end

    it "does not support filtering vms as a subcollection" do
      filters = ["name=foo"]

      actual = described_class.parse(filters, Vm)

      expected = {"=" => {"field" => "Vm-name", "value" => "foo"}}
      expect(actual.exp).to eq(expected)
    end

    it "can do fuzzy matching on strings with forward slashes" do
      filters = ["name='*/foo'"]

      actual = described_class.parse(filters, Vm)

      expected = {"REGULAR EXPRESSION MATCHES" => {"field" => "Vm-name", "value" => "/\\A.*/foo\\z/"}}
      expect(actual.exp).to eq(expected)
    end

    it "can handle operator characters on the right hand side" do
      filters = ["name=Vms with free space > 50 percent"]

      actual = described_class.parse(filters, MiqReport)

      expected = {"=" => {"field" => "MiqReport-name", "value" => "Vms with free space > 50 percent"}}
      expect(actual.exp).to eq(expected)
    end

    it "can handle exact strings" do
      filters = ["name=='  foo.*bar%f '"]

      actual = described_class.parse(filters, MiqReport)

      expected = {"=" => {"field" => "MiqReport-name", "value" => "  foo.*bar%f "}}
      expect(actual.exp).to eq(expected)
    end

    it "can handle exact string nonequality" do
      filters = ["name !== '  foo.*bar%f ' "]

      actual = described_class.parse(filters, MiqReport)

      expected = {"!=" => {"field" => "MiqReport-name", "value" => "  foo.*bar%f "}}
      expect(actual.exp).to eq(expected)
    end

    it "can handle regexes" do
      filters = ["name =~ /foo/i"]

      actual = described_class.parse(filters, MiqReport)

      expected = {"REGULAR EXPRESSION MATCHES" => {"field" => "MiqReport-name", "value" => "/foo/i"}}
      expect(actual.exp).to eq(expected)
    end

    it "can handle negative regexes" do
      filters = ["name !~ /foo/i"]

      actual = described_class.parse(filters, MiqReport)

      expected = {"REGULAR EXPRESSION DOES NOT MATCH" => {"field" => "MiqReport-name", "value" => "/foo/i"}}
      expect(actual.exp).to eq(expected)
    end

    it "supports filtering with operators in the strings" do
      filters = ["host.name='foo='"]

      actual = described_class.parse(filters, Vm)

      expected = {"=" => {"field" => "Vm.host-name", "value" => "foo="}}
      expect(actual.exp).to eq(expected)
    end

    it "supports filtering with multiple operators in the strings" do
      filters = ["host.name<'<=foo=>'"]

      actual = described_class.parse(filters, Vm)

      expected = {"<" => {"field" => "Vm.host-name", "value" => "<=foo=>"}}
      expect(actual.exp).to eq(expected)
    end
  end
end
