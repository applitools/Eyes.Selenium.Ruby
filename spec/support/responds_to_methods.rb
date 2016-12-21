RSpec.shared_examples 'responds to method' do |methods|
  methods.each do |m|
    it ":#{m}" do
      expect(subject).to respond_to m
    end
  end
end

RSpec.shared_examples 'has private method' do |methods|
  methods.each do |m|
    it ":#{m}" do
      expect(subject.private_methods).to include m
    end
  end
end

RSpec.shared_examples 'has abstract method' do |methods|
  methods.each do |m|
    it ":#{m}" do
      expect { subject.send(m) }.to raise_error(Applitools::AbstractMethodCalled)
    end
  end
end
