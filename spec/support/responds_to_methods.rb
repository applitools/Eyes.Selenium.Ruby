RSpec.shared_examples "responds to method" do |methods|
  methods.each do |m|
    it ":#{m}" do
      expect(subject).to respond_to m
    end
  end
end