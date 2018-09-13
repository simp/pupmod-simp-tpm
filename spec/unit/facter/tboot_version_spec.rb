require 'spec_helper'
require 'rspec/mocks'


describe 'tboot_version', :type => :fact do
  context "when rpm is installed" do
    before :each do
      Facter.clear
       Facter.clear_messages
       Facter::Core::Execution.stubs(:which).with('rpm').returns '/usr/bin/rpm'
       Facter::Core::Execution.stubs(:execute).with('uname -m').returns 'Linux'
    end

    tboot_installed   = "Name        : tboot
Epoch       : 1
Version     : 1.9.6
Release     : 2.el7
Architecture: x86_64"

    tboot_notinstalled =  "package tboot is not installed"

    context 'tboot installed' do

      it 'should return the version' do
        Facter::Core::Execution.stubs(:execute).with('rpm -qi tboot').returns tboot_installed
        expect(Facter.fact(:tboot_version).value).to eq "1.9.6"
      end
    end

    context 'tboot not installed' do

      it 'should return the version' do
        Facter::Core::Execution.stubs(:execute).with('rpm -qi tboot').returns tboot_notinstalled
        expect(Facter.fact(:tboot_version).value).to eq nil 
      end
    end
  end
end
