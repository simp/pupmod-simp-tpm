require 'spec_helper'
require 'pry'

describe 'tpm', :type => :fact do
  before :each do
    Facter.clear
    Facter.clear_messages
  end

  context 'has_tpm fact is false' do
    it 'should return nil' do
      Facter.fact(:has_tpm).stubs(:value).returns(false)
      expect(Facter.fact(:tpm).value).to eq nil
    end
  end

  context 'has_tpm fact is true, but tpm-tools package is not installed' do
    it 'should return nil' do
      Facter.fact(:has_tpm).stubs(:value).returns(true)
      Facter::Core::Execution.stubs(:which).with('tpm_version').returns nil
      expect(Facter.fact(:tpm).value).to eq nil
    end
  end

  context 'tpm is enabled and unowned' do
    before(:each) do
      Facter.fact(:has_tpm).stubs(:value).returns(true)
      Facter::Core::Execution.stubs(:which).with('txt-stat').returns nil

      # Just need something that actually exists on the current FS
      Facter::Core::Execution.stubs(:which).with('tpm_version').returns Dir.pwd
    end

    it 'should be a structured fact with the prescribed structure' do
      require 'facter/tpm/util'

      fact = Facter::TPM::Util.new('spec/files/tpm')
      Facter::TPM::Util.stubs(:new).with('/sys/class/tpm/tpm0').returns fact
      expect(Facter.fact(:tpm).value).to include('status','version','pubek','sys_path')
    end
  end

  require 'facter/tpm/util'

  describe Facter::TPM::Util do

    before(:each) do
      Facter::Core::Execution.stubs(:execute).with('tpm_version', :timeout => 15).returns File.read('spec/files/tpm/tpm_version.txt')


      @tpm_fact = Facter::TPM::Util.new('spec/files/tpm')
    end

    describe '.get_pubek_owned' do
      context 'with a well-known owner password' do
        it 'should return the results from the tpm_getpubek command' do
          out = File.read('spec/files/tpm/tpm_getpubek.txt')
          Facter::Core::Execution.stubs(:execute).with('tpm_getpubek -z', :timeout => 15).returns out

          expect(@tpm_fact.send(:get_pubek_owned, 'well-known')).to eq out
        end
      end

      # context 'with a normal owner password' do
      #   it 'should interact with the tpm_getpubek command' do
      #     out = File.read('spec/files/tpm/tpm_getpubek.txt')
      #     expect(@tpm_fact.send(:get_pubek_owned, 'badpass', 'spec/files/tpm/mock_tpm_getpubek.rb')).to eq out
      #   end
      # end
    end

    describe '.get_pubek_unowned' do
      it 'should return the results from the tpm_getpubek command' do
        out = File.read('spec/files/tpm/tpm_getpubek.txt')
        Facter::Core::Execution.stubs(:execute).with('tpm_getpubek', :timeout => 15).returns out
        expect(@tpm_fact.send(:get_pubek_unowned)).to eq out
      end
    end

    describe '.tpm_version' do
      it 'should return the value of the command' do
        out = File.read('spec/files/tpm/tpm_version.txt')
        Facter::Core::Execution.stubs(:execute).with('tpm_version', :timeout => 15).returns out
        expect(@tpm_fact.send(:tpm_version)).to eq out
      end
    end

    describe '.version' do
      context 'tpm_version exists' do
        before(:each) do
          @tpm_fact.stubs(:tpm_version).returns File.read('spec/files/tpm/tpm_version.txt')
        end
        it 'should have _status with a positive message' do
          expect(@tpm_fact.send(:version)).to include('_status' => 'tpm_version loaded correctly')
        end
        it 'should output as expected' do
          expect(@tpm_fact.send(:version)).to include(
            "chip_version"      => "1.2.8.28",
            "spec_level"        => 2,
            "errata_revision"   => 3,
            "tpm_vendor_id"     => "STM",
            "tpm_version"       => 266240,
            "manufacturer_info" => "53544d20",
          )
        end
      end
      context '.tpm_version does not exist' do
        before(:each) do
          @tpm_fact.stubs(:tpm_version).returns nil
        end
        it 'should output as expected' do
          expect(@tpm_fact.send(:version)).to eq({"_status" => "Trousers is not running"})
        end
      end
    end

    describe '.status' do
      it 'should ignore files in the ignore list' do
        expect(@tpm_fact.send(:status).keys).not_to include('pubek')
        expect(@tpm_fact.send(:status).keys).not_to include('cancel')
        expect(@tpm_fact.send(:status).keys).not_to include('options')
      end
      it 'should have structured values for pcrs' do
        expect(@tpm_fact.send(:status)['pcrs']).not_to be nil
        expect(@tpm_fact.send(:status)['pcrs'].keys).to include("pcr-00")
        expect(@tpm_fact.send(:status)['pcrs'].keys).to include("pcr-20")
      end
      it 'should have structured values for caps' do
        expect(@tpm_fact.send(:status)['caps']).not_to be nil
        expect(@tpm_fact.send(:status)['caps']).to eq({
          "manufacturer"     => 1398033696,
          "tcg_version"      => 1.2,
          "firmware_version" => 8.28
        })
      end
      it 'should have simple keys for the rest of the file' do
        expect(@tpm_fact.send(:status).keys).to contain_exactly(
          'active', 'caps', 'durations', 'enabled',
          'id', 'owned', 'pcrs', 'resources',
          'temp_deactivated', 'timeouts', 'uevent',
        )
      end
    end

    describe '.pubek' do
      context 'tpm is not enabled' do
        let(:params) {{ 'enabled' => 0, 'owned' => 0 }}
        it 'should have a negative _status message' do
          expect(@tpm_fact.send(:pubek, params)['_status']).to eq 'error: tpm not enabled'
        end
      end

      context 'tpm is not owned' do
        before(:each) do
          @tpm_fact.stubs(:get_pubek_unowned).returns File.read('spec/files/tpm/tpm_getpubek.txt')
        end
        let(:params) {{ 'enabled' => 1, 'owned' => 0 }}

        it 'should have a positive status message' do
          expect(@tpm_fact.send(:pubek, params)['_status']).to eq 'success: raw parsed'
        end
        it 'should have structured values' do
          expect(@tpm_fact.send(:pubek, params)).to include(
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
          @tpm_fact.stubs(:get_pubek_owned).returns File.read('spec/files/tpm/tpm_getpubek.txt')
          File.stubs(:exists?).with('/dev/null/simp/tpm_ownership_owner_pass').returns true
          Facter::Core::Execution.stubs(:execute).with('cat /dev/null/simp/tpm_ownership_owner_pass 2> /dev/null').returns 'twentycharacters0000'
        end
        let(:params) {{ 'enabled' => 1, 'owned' => 1 }}

        it 'should have a positive status message' do
          expect(@tpm_fact.send(:pubek, params)['_status']).to eq 'success: raw parsed'
        end
        it 'should have structured values' do
          expect(@tpm_fact.send(:pubek, params)).to include(
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
end
