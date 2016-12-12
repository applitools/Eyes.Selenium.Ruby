RSpec.shared_examples 'proxy method' do |receiver, methods|
  methods.each do |m|
    it "responds to #{m}" do
      expect(subject).to respond_to(m)
    end
    it "#{m} to #{receiver}" do
      expect(receiver).to receive(m).at_least 1
      subject.send m, nil
    end
  end
end
