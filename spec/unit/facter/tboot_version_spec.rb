require 'spec_helper'
require 'rspec/mocks'

describe 'tboot_version', type: :fact do
  context 'when rpm is installed' do
    before :each do
      Facter.clear
      Facter.clear_messages
      allow(Facter::Core::Execution).to receive(:which).with('rpm').and_return '/usr/bin/rpm'
      allow(Facter::Core::Execution).to receive(:execute).with('uname -m').and_return 'Linux'
    end

    tboot_installed = "Name        : tboot
Epoch       : 1
Version     : 1.9.6
Release     : 2.el7
Architecture: x86_64"

    tboot_notinstalled = 'package tboot is not installed'

    context 'tboot installed' do
      it 'returns the version' do
        allow(Facter::Core::Execution).to receive(:which).with('txt-stat').and_return '/sbin/txt-stat'
        allow(Facter::Core::Execution).to receive(:execute).with('rpm -qi tboot').and_return tboot_installed
        expect(Facter.fact(:tboot_version).value).to eq '1.9.6'
      end
    end

    context 'tboot not installed' do
      it 'returns the version' do
        allow(Facter::Core::Execution).to receive(:which).with('txt-stat').and_return nil
        allow(Facter::Core::Execution).to receive(:execute).with('rpm -qi tboot').and_return tboot_notinstalled
        expect(Facter.fact(:tboot_version).value).to eq nil
      end
    end
  end
end
