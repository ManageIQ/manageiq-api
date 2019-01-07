RSpec.describe Api::ErrorSerializer do
  let(:non_sql_message) { "Not a PostgreSQL error" }
  let(:non_sql_error) { double("non sql error", :message => non_sql_message, :backtrace => []) }

  let(:pg_message_header) { "PG::Error" }

  let(:pg_select_error) { "#{pg_message_header} SeLeCt  \"users\".* FROM \"users\"" }
  let(:select_error) { double("select error", :message => pg_select_error, :backtrace => []) }

  let(:pg_update_error) { "#{pg_message_header} UpDate  \"users\".* FROM \"users\"" }
  let(:update_error) { double("update error", :message => pg_update_error, :backtrace => []) }

  let(:pg_insert_error) { "#{pg_message_header} Insert  \"users\".* FROM \"users\"" }
  let(:insert_error) { double("insert error", :message => pg_insert_error, :backtrace => []) }

  let(:delete_error) { double("delete error", :message => pg_delete_error, :backtrace => []) }
  let(:pg_delete_error) { "#{pg_message_header} dEleTe  \"users\".* FROM \"users\"" }

  let(:kind) { "kind" }

  describe ".serialize" do
    it "returns the original message when not a PG error" do
      actual = described_class.new(kind, non_sql_error).serialize

      expect(actual[:error][:message]).to eq(non_sql_message)
    end

    it "returns a message with the SQL statement by default" do
      actual = described_class.new(kind, select_error).serialize

      expect(actual[:error][:message]).to eq(pg_select_error)
    end

    it "returns a message without the SQL SELECT statement when requested" do
      actual = described_class.new(kind, select_error).serialize(true)

      expect(actual[:error][:message]).to eq(pg_message_header)
    end

    it "returns a message without the SQL UPDATE statement when requested" do
      actual = described_class.new(kind, update_error).serialize(true)

      expect(actual[:error][:message]).to eq(pg_message_header)
    end

    it "returns a message without the SQL INSERT statement when requested" do
      actual = described_class.new(kind, insert_error).serialize(true)

      expect(actual[:error][:message]).to eq(pg_message_header)
    end

    it "returns a message without the SQL DELETE statement when requested" do
      actual = described_class.new(kind, delete_error).serialize(true)

      expect(actual[:error][:message]).to eq(pg_message_header)
    end
  end
end
