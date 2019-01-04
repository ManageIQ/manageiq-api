RSpec.describe Api::ErrorSerializer do
  let(:message_without_sql_select) { "Error" }
  let(:message_with_sql_select) { "#{message_without_sql_select} SELECT  \"users\".* FROM \"users\"" }
  let(:error) { double("error", :message => message_with_sql_select, :backtrace => []) }
  let(:kind) { "kind" }

  describe ".serialize" do
    it "returns a message with the SQL SELECT by default" do
      actual = described_class.new(kind, error).serialize

      expect(actual[:error][:message]).to eq(message_with_sql_select)
    end

    it "returns a message without the SQL SELECT when requested" do
      actual = described_class.new(kind, error).serialize(true)

      expect(actual[:error][:message]).to eq(message_without_sql_select)
    end
  end
end
