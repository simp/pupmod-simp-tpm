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
    before(:each) { Facter.fact(:has_tpm).stubs(:value).returns(false) }

    it 'should return nil' do
      expect(Facter.fact(:tboot).value).to eq nil
    end
  end

  context 'has_tpm fact is true' do
    before(:each) { Facter.fact(:has_tpm).stubs(:value).returns(true) }

    context 'tboot package is not installed' do
      Facter::Core::Execution.stubs(:which).with('txt-stat').returns nil

      it 'should return nil' do
        expect(Facter.fact(:tboot).value).to eq nil
      end
    end

    context 'tboot is installed' do
      before(:each) { Facter::Core::Execution.stubs(:which).with('txt-stat').returns '/usr/sbin/txt-stat' }

      context 'current session is normal' do
        it 'should return a structured fact with `tboot_session` and `measured_launch` returning false' do
          Facter::Core::Execution.stubs(:execute).with('txt-stat').returns normal_session
          expect(Facter.fact(:tboot).value).to be_a(Hash)
          expect(Facter.fact(:tboot).value).to include(
            'tboot_session'   => false,
            'measured_launch' => false
          )
        end
      end

      context 'current session is tboot with no policy' do
        it 'should return a structured fact with `tboot_session` returning true and `measured_launch` returning false' do
          Facter::Core::Execution.stubs(:execute).with('txt-stat').returns tboot_session
          expect(Facter.fact(:tboot).value).to be_a(Hash)
          expect(Facter.fact(:tboot).value).to include(
            'tboot_session'   => true,
            'measured_launch' => false
          )
        end
      end

      context 'current session is measured' do
        it 'should return a structured fact with `tboot_session` and `measured_launch` returning true' do
          Facter::Core::Execution.stubs(:execute).with('txt-stat').returns measured_session
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
