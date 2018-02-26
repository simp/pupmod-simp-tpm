require 'spec_helper'

describe 'ima_security_attr', :type => :fact do

  before :each do
    Facter.clear
    Facter.clear_messages
    Facter.stubs(:value).with(:cmdline).returns({'ima_appraise_tcb' => "", 'foo' => 'bar' })
    Facter.stubs(:value).with(:puppet_vardir).returns('/tmp')
  end

  context 'The script is running' do
    before :each do
      Facter::Core::Execution.stubs(:execute).with('ps -ef').returns 'All kinds of junk and ima_security_attr_update.sh'
    end

    it 'should return updating' do
      expect(Facter.fact(:ima_security_attr).value).to eq 'active'
    end
  end

  context 'The script is not running' do
    before(:each) { Facter::Core::Execution.stubs(:execute).with('ps -ef').returns 'All kinds of junki\nAnd more junk\nbut not that which shall not be named'}

    context 'The relabel file is not present' do
      before(:each) { File.stubs(:exists?).with('/tmp/simp/.ima_relabel').returns(false) }

      it 'should return inactive' do
        expect(Facter.fact(:ima_security_attr).value).to eq 'inactive'
      end
    end

    context 'The relabel file is present' do
      before(:each) { File.stubs(:exists?).with('/tmp/simp/.ima_relabel').returns(true) }

      it 'should return inactive' do
        expect(Facter.fact(:ima_security_attr).value).to eq 'need_relabel'
      end
    end

  end
end
