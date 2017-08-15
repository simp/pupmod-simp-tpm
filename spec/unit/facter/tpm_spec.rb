require 'spec_helper'
require 'pry'

# if ENV['MOCK_FACTER'].to_s =~ /true/
module Facter
  class Fact
    def initialize()
      @confines = []
    end
    def confine(args = {})
      @confines << args
    end
    def setcode(&block)
      @code = yield
    end
    # def run()
    #   return @code.call()
    # end
  end
  def self.add(name, &block)
    $facts = {}
    obj = Facter::Fact.new()
    obj.instance_eval(&block)
    $facts[name] = obj
  end
end
load('lib/facter/tpm.rb')


describe 'tpm', :type => :fact do

  before :all do
    ENV['MOCK_FACTER'] = 'true'
  end
  after :all do
    ENV['MOCK_FACTER'] = nil
  end

  before :each do
    Facter.clear
    Facter.clear_messages
  end
  let(:obj) { $facts['tpm'] }

  # context 'has_tpm fact is false' do
  #   it 'should return nil' do
  #
  #     require 'pry';binding.pry
  #   end
  # end

  # context 'has_tpm fact is true, but tpm-tools package is not installed' do
  #   Facter.fact(:has_tpm).stubs(:value).returns(true)
  #   Facter::Core::Execution.stubs(:which).with('tpm_version').returns nil
  #   it 'should return nil' do
  #     expect(Facter.fact(:tboot).value).to eq nil
  #   end
  # end

  # context 'tpm is enabled and unowned' do
  #   before(:each) do
  #     Facter.fact(:has_tpm).stubs(:value).returns(true)
  #     Facter::Core::Execution.stubs(:which).with('txt-stat').returns nil
  #     Facter::Core::Execution.stubs(:which).with('tpm_version').returns true
  #   end
  #   it 'should be a structured fact with the prescribed structure' do
  #     fact = Facter.fact(:tboot).value
  #     expect(fact).to include('status','version','pubek','sys_path')
  #
  #   end
  # end

  ####### METHOD TESTING #########

  describe 'get_pubek_owned' do
    context 'with a well-known owner password' do
      it 'should return the results from the tpm_getpubek command' do
        out = File.read('spec/files/tpm/tpm_getpubek.txt')
        Facter::Core::Execution.stubs(:execute).with('tpm_getpubek -z', :timeout => 15).returns out
        expect(obj.get_pubek_owned('well-known')).to eq out
      end
    end
    context 'with a normal owner password' do
      it 'should interact with the tpm_getpubek command' do
        out = File.read('spec/files/tpm/tpm_getpubek.txt')
        expect(obj.get_pubek_owned('badpass', 'spec/files/tpm/mock_tpm_getpubek.rb')).to eq out
      end
    end
  end

  describe 'get_pubek_unowned' do
    it 'should return the results from the tpm_getpubek command' do
      out = File.read('spec/files/tpm/tpm_getpubek.txt')
      Facter::Core::Execution.stubs(:execute).with('tpm_getpubek', :timeout => 15).returns out
      expect(obj.get_pubek_unowned).to eq out
    end
  end

  describe 'tpm_version' do
    it 'should return the value of the command' do
      out = File.read('spec/files/tpm/tpm_version.txt')
      Facter::Core::Execution.stubs(:execute).with('tpm_version', :timeout => 15).returns out
      expect(obj.tpm_version).to eq out
    end
  end

  describe 'version' do
    context 'tpm_version exists' do
      before(:each) do
        obj.stubs(:tpm_version).returns File.read('spec/files/tpm/tpm_version.txt')
      end
      it 'should have _status with a positive message' do
        expect(obj.version).to include('_status' => 'tpm_version loaded correctly')
      end
      it 'should output as expected' do
        expect(obj.version).to include(
          "chip_version"      => "1.2.8.28",
          "spec_level"        => 2,
          "errata_revision"   => 3,
          "tpm_vendor_id"     => "STM",
          "tpm_version"       => 266240,
          "manufacturer_info" => "53544d20",
        )
      end
    end
    context 'tpm_version does not exist' do
      before(:each) do
        obj.stubs(:tpm_version).returns nil
      end
      it 'should output as expected' do
        expect(obj.version).to eq({"_status" => "Trousers is not running"})
      end
    end
  end

  describe 'status' do
    sysstub = Dir.glob('spec/files/tpm/device/*')
    before(:each) do
      Dir.stubs(:glob).with('/sys/class/tpm/tpm0/device/*').returns sysstub
    end
    it 'should ignore files in the ignore list' do
      expect(obj.status.keys).not_to include('pubek')
      expect(obj.status.keys).not_to include('cancel')
      expect(obj.status.keys).not_to include('options')
    end
    it 'should have structured values for pcrs' do
      expect(obj.status['pcrs']).not_to be nil
      expect(obj.status['pcrs'].keys).to include("pcr-00")
      expect(obj.status['pcrs'].keys).to include("pcr-20")
    end
    it 'should have structured values for caps' do
      expect(obj.status['caps']).not_to be nil
      expect(obj.status['caps']).to eq({
        "manufacturer"     => 1398033696,
        "tcg_version"      => 1.2,
        "firmware_version" => 8.28
      })
    end
    it 'should have simple keys for the rest of the file' do
      expect(obj.status.keys).to contain_exactly(
        'active', 'caps', 'durations', 'enabled',
        'id', 'owned', 'pcrs', 'resources',
        'temp_deactivated', 'timeouts', 'uevent',
      )
    end

  end

  describe 'pubek' do
    context 'tpm is not enabled' do
      let(:params) {{ 'enabled' => 0, 'owned' => 0 }}
      it 'should have a negavtive _status message' do
        expect(obj.pubek(params)['_status']).to eq 'error: tpm not enabled'
      end
    end

    context 'tpm is not owned' do
      before(:each) do
        obj.stubs(:get_pubek_unowned).returns File.read('spec/files/tpm/tpm_getpubek.txt')
      end
      let(:params) {{ 'enabled' => 1, 'owned' => 0 }}

      it 'should have a positive status message' do
        expect(obj.pubek(params)['_status']).to eq 'success: raw parsed'
      end
      it 'should have structured values' do
        expect(obj.pubek(params)).to include(
          "version"           => 266240,
          "usage"             => "0x0002 (Unknown)",
          "flags"             => "0x00000000 (!VOLATILE, !MIGRATABLE, !REDIRECTION)",
          "authusage"         => "0x00 (Never)",
          "algorithm"         => "0x00000020 (Unknown)",
          "encryption_scheme" => "0x00000012 (Unknown)",
          "signature_scheme"  => "0x00000010 (Unknown)",
          "public_key"        => "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
          "raw"               => "Public Endorsement Key:\n  Version:   01010000\n  Usage:     0x0002 (Unknown)\n  Flags:     0x00000000 (!VOLATILE, !MIGRATABLE, !REDIRECTION)\n  AuthUsage: 0x00 (Never)\n  Algorithm:         0x00000020 (Unknown)\n  Encryption Scheme: 0x00000012 (Unknown)\n  Signature Scheme:  0x00000010 (Unknown)\n  Public Key:\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n"
        )
      end
    end

    context 'tpm is owned' do
      before(:each) do
        obj.stubs(:get_pubek_owned).returns File.read('spec/files/tpm/tpm_getpubek.txt')
        File.stubs(:exists?).with('/dev/null/simp/tpm_ownership_owner_pass').returns true
        Facter::Core::Execution.stubs(:execute).with('cat /dev/null/simp/tpm_ownership_owner_pass 2> /dev/null').returns 'twentycharacters0000'
      end
      let(:params) {{ 'enabled' => 1, 'owned' => 1 }}

      it 'should have a positive status message' do
        expect(obj.pubek(params)['_status']).to eq 'success: raw parsed'
      end
      it 'should have structured values' do
        expect(obj.pubek(params)).to include(
          "version"           => 266240,
          "usage"             => "0x0002 (Unknown)",
          "flags"             => "0x00000000 (!VOLATILE, !MIGRATABLE, !REDIRECTION)",
          "authusage"         => "0x00 (Never)",
          "algorithm"         => "0x00000020 (Unknown)",
          "encryption_scheme" => "0x00000012 (Unknown)",
          "signature_scheme"  => "0x00000010 (Unknown)",
          "public_key"        => "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
          "raw"               => "Public Endorsement Key:\n  Version:   01010000\n  Usage:     0x0002 (Unknown)\n  Flags:     0x00000000 (!VOLATILE, !MIGRATABLE, !REDIRECTION)\n  AuthUsage: 0x00 (Never)\n  Algorithm:         0x00000020 (Unknown)\n  Encryption Scheme: 0x00000012 (Unknown)\n  Signature Scheme:  0x00000010 (Unknown)\n  Public Key:\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n"
        )
      end
    end
  end


end
