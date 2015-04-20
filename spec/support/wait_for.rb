require 'rspec/eventually'

class WaitFor
  def initialize(&block)
    @block = block
  end

  [:to, :to_not].each do |method|
    define_method method do |matcher|
      waiter = eventually(matcher)
      method == :to_not && waiter.not
      waiter.matches?(@block) || fail('wait_for never came true')
    end
  end

  private

  def eventually(matcher)
    Rspec::Eventually::Eventually.new(matcher).by_suppressing_errors
  end
end

def wait_for(&block)
  WaitFor.new(&block)
end

def wait_for_container(name)
  c = nil
  wait_for { (c = Docker::Container.get(name)).info['State']['Running'] }.to eq true
  c
end

def wait_for_containers(containers)
  containers.map { |n| wait_for_container n }
end
