describe :placeholders do
  include_examples :placeholders, ManageIQ::Api::Engine.root.join('locale').to_s
end
