require 'spec_helper'

describe 'ima_log_size', :type => :fact do

  before :each do
    Facter.clear
    Facter.clear_messages
  end

  context 'the required file is not present' do
    it 'should return nil' do
      File.stubs(:exists?).with('/sys/kernel/security/ima/ascii_runtime_measurements').returns false
      expect(Facter.fact(:ima_log_size).value).to eq nil
    end
  end

  context 'the required file is present' do
    it 'should read the contents of the file as an integer' do
      File.stubs(:exists?).with('/sys/kernel/security/ima/ascii_runtime_measurements').returns true
      Facter::Core::Execution.stubs(:execute).with('wc -c /sys/kernel/security/ima/ascii_runtime_measurements').returns '1337'

      expect(Facter.fact(:ima_log_size).value).to eq 1337
    end
  end

end
