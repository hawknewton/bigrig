describe 'wait for' do
  it 'should wait for stuff' do
    value = 0
    Thread.new do
      sleep 1
      value = 1
    end
    wait_for { value }.to_not eq 0
  end
end
