require 'spec_helper'

describe 'tpm_version', :type => :fact do

  before :each do
    Facter.clear
    Facter.clear_messages
    Facter.fact(:has_tpm).stubs(:value).returns(true)
  end

  context 'the link exists' do
    before(:each) {
      Dir.stubs(:glob).with('/sys/class/tpm/tpm*').returns ['/tpm0']
      File.stubs(:symlink?).with('/tpm0').returns true
    }
    it 'should return tpm2 if MSFT is in the link name' do
      File.stubs(:readlink).with('/tpm0').returns '../xyz/MSFT00049/foo/bar'
      expect(Facter.fact(:tpm_version).value).to eq  'tpm2'
    end

    it 'should return tpm1 if link exists and no MSFT in name' do
      File.stubs(:readlink).with('/tpm0').returns '../xyz/foo/bar'
      expect(Facter.fact(:tpm_version).value).to eq  'tpm1'
    end
  end

  context 'the link file is not a link to the device' do
    before (:each) {
      Dir.stubs(:glob).with('/sys/class/tpm/tpm*').returns ['/tpm0']
      File.stubs(:symlink?).with('/tpm0').returns false
    }
    it 'should return unknown' do
      expect(Facter.fact(:tpm_version).value).to eq 'unknown'
    end
  end

  context 'There is nothing in the directory' do
    before (:each) {
      Dir.stubs(:glob).with('/sys/class/tpm/tpm*').returns []
    }
    it 'should return unknown' do
      expect(Facter.fact(:tpm_version).value).to eq 'unknown'
    end
  end

end
