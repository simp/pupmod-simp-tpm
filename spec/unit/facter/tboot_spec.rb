require 'spec_helper'

describe 'tboot', :type => :fact do

  before :each do
    Facter.clear
    Facter.clear_messages
  end

  normal_session   = File.read('spec/files/tboot/txt-stat_normal_session.txt')
  tboot_session    = File.read('spec/files/tboot/txt-stat_tboot_session.txt')
  measured_session = File.read('spec/files/tboot/txt-stat_measured_session.txt')

  context 'has_tpm fact is false' do
    before(:each) { allow(Facter.fact(:has_tpm)).to receive(:value).and_return(false) }

    it 'should return nil' do
      expect(Facter.fact(:tboot).value).to eq nil
    end
  end

  context 'has_tpm fact is true' do
    before(:each) do
      allow(Facter.fact(:has_tpm)).to receive(:value).and_return(true)
      allow(Facter::Core::Execution).to receive(:which).with('txt-stat').and_return nil
    end

    context 'tboot package is not installed' do

      it 'should return nil' do
        expect(Facter.fact(:tboot).value).to eq nil
      end
    end

    context 'tboot is installed' do
      before(:each) { allow(Facter::Core::Execution).to receive(:which).with('txt-stat').and_return '/usr/sbin/txt-stat' }

      context 'current session is normal' do
        it 'should return a structured fact with `tboot_session` and `measured_launch` returning false' do
          allow(Facter::Core::Execution).to receive(:execute).with('txt-stat').and_return normal_session
          expect(Facter.fact(:tboot).value).to be_a(Hash)
          expect(Facter.fact(:tboot).value).to include(
            'tboot_session'   => false,
            'measured_launch' => false
          )
        end
      end

      context 'current session is tboot with no policy' do
        it 'should return a structured fact with `tboot_session` returning true and `measured_launch` returning false' do
          allow(Facter::Core::Execution).to receive(:execute).with('txt-stat').and_return tboot_session
          expect(Facter.fact(:tboot).value).to be_a(Hash)
          expect(Facter.fact(:tboot).value).to include(
            'tboot_session'   => true,
            'measured_launch' => false
          )
        end
      end

      context 'current session is measured' do
        it 'should return a structured fact with `tboot_session` and `measured_launch` returning true' do
          allow(Facter::Core::Execution).to receive(:execute).with('txt-stat').and_return measured_session
          expect(Facter.fact(:tboot).value).to be_a(Hash)
          expect(Facter.fact(:tboot).value).to include(
            'tboot_session'   => true,
            'measured_launch' => true
          )
        end
      end
    end
  end

end
