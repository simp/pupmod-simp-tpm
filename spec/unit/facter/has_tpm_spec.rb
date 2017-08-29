require 'spec_helper'

describe 'has_tpm', :type => :fact do

  before :each do
    Facter.clear
    Facter.clear_messages
  end

  context 'the required file is not present' do
    it 'should return nil' do
      File.stubs(:exists?).with('/dev/tpm0').returns false
      expect(Facter.fact(:has_tpm).value).to eq false
    end
  end

  context 'the required file is present' do
    it 'should return true' do
      File.stubs(:exists?).with('/dev/tpm0').returns true
      expect(Facter.fact(:has_tpm).value).to eq true
    end
  end

end
