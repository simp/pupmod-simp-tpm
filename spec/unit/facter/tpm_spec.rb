require 'spec_helper'
require 'pry'

describe 'tpm', type: :fact do
  before :each do
    Facter.clear
    Facter.clear_messages
  end

  context 'has_tpm fact is false' do
    it 'returns nil' do
      allow(Facter.fact(:has_tpm)).to receive(:value).and_return(false)
      expect(Facter.fact(:tpm).value).to eq nil
    end
  end

  context 'has_tpm fact is true, but tpm-tools package is not installed' do
    it 'returns nil' do
      allow(Facter.fact(:has_tpm)).to receive(:value).and_return(true)
      allow(Facter::Core::Execution).to receive(:which).with('tpm_version').and_return nil
      expect(Facter.fact(:tpm).value).to eq nil
    end
  end

  context 'tpm is enabled and unowned' do
    before(:each) do
      allow(Facter.fact(:has_tpm)).to receive(:value).and_return(true)
      allow(Facter::Core::Execution).to receive(:which).with('txt-stat').and_return nil

      # Just need something that actually exists on the current FS
      allow(Facter::Core::Execution).to receive(:which).with('tpm_version').and_return Dir.pwd
    end

    it 'is a structured fact with the prescribed structure' do
      require 'facter/tpm/util'

      fact = Facter::TPM::Util.new('spec/files/tpm')
      allow(Facter::TPM::Util).to receive(:new).with('/sys/class/tpm/tpm0').and_return fact
      expect(Facter.fact(:tpm).value).to include('status', 'version', 'pubek', 'sys_path')
    end
  end

  require 'facter/tpm/util'

  describe Facter::TPM::Util do
    before(:each) do
      allow(Facter::Core::Execution).to receive(:execute).with('tpm_version', timeout: 15).and_return File.read('spec/files/tpm/tpm_version.txt')
    end

    let(:tpm_fact) { described_class.new('spec/files/tpm') }

    describe '.get_pubek_owned' do
      context 'with a well-known owner password' do
        it 'returns the results from the tpm_getpubek command' do
          out = File.read('spec/files/tpm/tpm_getpubek.txt')
          allow(Facter::Core::Execution).to receive(:execute).with('tpm_getpubek -z', timeout: 15).and_return out

          expect(tpm_fact.send(:get_pubek_owned, 'well-known')).to eq out
        end
      end

      # context 'with a normal owner password' do
      #   it 'should interact with the tpm_getpubek command' do
      #     out = File.read('spec/files/tpm/tpm_getpubek.txt')
      #     expect(tpm_fact.send(:get_pubek_owned, 'badpass', 'spec/files/tpm/mock_tpm_getpubek.rb')).to eq out
      #   end
      # end
    end

    describe '.get_pubek_unowned' do
      it 'returns the results from the tpm_getpubek command' do
        out = File.read('spec/files/tpm/tpm_getpubek.txt')
        allow(Facter::Core::Execution).to receive(:execute).with('tpm_getpubek', timeout: 15).and_return out
        expect(tpm_fact.send(:get_pubek_unowned)).to eq out
      end
    end

    describe '.tpm_version' do
      it 'returns the value of the command' do
        out = File.read('spec/files/tpm/tpm_version.txt')
        allow(Facter::Core::Execution).to receive(:execute).with('tpm_version', timeout: 15).and_return out
        expect(tpm_fact.send(:tpm_version)).to eq out
      end
    end

    describe '.version' do
      context 'tpm_version exists' do
        before(:each) do
          allow(tpm_fact).to receive(:tpm_version).and_return File.read('spec/files/tpm/tpm_version.txt')
        end
        it 'has _status with a positive message' do
          expect(tpm_fact.send(:version)).to include('_status' => 'tpm_version loaded correctly')
        end
        it 'outputs as expected' do
          expect(tpm_fact.send(:version)).to include(
            'chip_version'      => '1.2.8.28',
            'spec_level'        => 2,
            'errata_revision'   => 3,
            'tpm_vendor_id'     => 'STM',
            'tpm_version'       => 266_240,
            'manufacturer_info' => '53544d20',
          )
        end
      end
      context '.tpm_version does not exist' do
        before(:each) do
          allow(tpm_fact).to receive(:tpm_version).and_return nil
        end
        it 'outputs as expected' do
          expect(tpm_fact.send(:version)).to eq({ '_status' => 'Trousers is not running' })
        end
      end
    end

    describe '.status' do
      it 'ignores files in the ignore list' do
        expect(tpm_fact.send(:status).keys).not_to include('pubek')
        expect(tpm_fact.send(:status).keys).not_to include('cancel')
        expect(tpm_fact.send(:status).keys).not_to include('options')
      end
      it 'has structured values for pcrs' do
        expect(tpm_fact.send(:status)['pcrs']).not_to be nil
        expect(tpm_fact.send(:status)['pcrs'].keys).to include('pcr-00')
        expect(tpm_fact.send(:status)['pcrs'].keys).to include('pcr-20')
      end
      it 'has structured values for caps' do
        expect(tpm_fact.send(:status)['caps']).not_to be nil
        expect(tpm_fact.send(:status)['caps']).to eq(
          'manufacturer'     => 1_398_033_696,
          'tcg_version'      => 1.2,
          'firmware_version' => 8.28,
        )
      end
      it 'has simple keys for the rest of the file' do
        expect(tpm_fact.send(:status).keys).to contain_exactly(
          'active', 'caps', 'durations', 'enabled',
          'id', 'owned', 'pcrs', 'resources',
          'temp_deactivated', 'timeouts', 'uevent'
        )
      end
    end

    describe '.pubek' do
      context 'tpm is not enabled' do
        let(:params) { { 'enabled' => 0, 'owned' => 0 } }

        it 'has a negative _status message' do
          expect(tpm_fact.send(:pubek, params)['_status']).to eq 'error: tpm not enabled'
        end
      end

      context 'tpm is not owned' do
        before(:each) do
          allow(tpm_fact).to receive(:get_pubek_unowned).and_return File.read('spec/files/tpm/tpm_getpubek.txt')
        end
        let(:params) { { 'enabled' => 1, 'owned' => 0 } }

        it 'has a positive status message' do
          expect(tpm_fact.send(:pubek, params)['_status']).to eq 'success: raw parsed'
        end
        it 'has structured values' do
          expect(tpm_fact.send(:pubek, params)).to include(
            'version'           => 266_240,
            'usage'             => '0x0002 (Unknown)',
            'flags'             => '0x00000000 (!VOLATILE, !MIGRATABLE, !REDIRECTION)',
            'authusage'         => '0x00 (Never)',
            'algorithm'         => '0x00000020 (Unknown)',
            'encryption_scheme' => '0x00000012 (Unknown)',
            'signature_scheme'  => '0x00000010 (Unknown)',
            # rubocop:disable Layout/LineLength
            'public_key'        => '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
            'raw'               => "Public Endorsement Key:\n  Version:   01010000\n  Usage:     0x0002 (Unknown)\n  Flags:     0x00000000 (!VOLATILE, !MIGRATABLE, !REDIRECTION)\n  AuthUsage: 0x00 (Never)\n  Algorithm:         0x00000020 (Unknown)\n  Encryption Scheme: 0x00000012 (Unknown)\n  Signature Scheme:  0x00000010 (Unknown)\n  Public Key:\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n",
            # rubocop:enable Layout/LineLength
          )
        end
      end

      context 'tpm is owned' do
        before(:each) do
          allow(tpm_fact).to receive(:get_pubek_owned).and_return File.read('spec/files/tpm/tpm_getpubek.txt')
          allow(File).to receive(:exist?).with('/dev/null/simp/tpm_ownership_owner_pass').and_return true
          allow(Facter::Core::Execution).to receive(:execute).with('cat /dev/null/simp/tpm_ownership_owner_pass 2> /dev/null').and_return 'twentycharacters0000'
        end
        let(:params) { { 'enabled' => 1, 'owned' => 1 } }

        it 'has a positive status message' do
          expect(tpm_fact.send(:pubek, params)['_status']).to eq 'success: raw parsed'
        end
        it 'has structured values' do
          expect(tpm_fact.send(:pubek, params)).to include(
            'version'           => 266_240,
            'usage'             => '0x0002 (Unknown)',
            'flags'             => '0x00000000 (!VOLATILE, !MIGRATABLE, !REDIRECTION)',
            'authusage'         => '0x00 (Never)',
            'algorithm'         => '0x00000020 (Unknown)',
            'encryption_scheme' => '0x00000012 (Unknown)',
            'signature_scheme'  => '0x00000010 (Unknown)',
            # rubocop:disable Layout/LineLength
            'public_key'        => '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
            'raw'               => "Public Endorsement Key:\n  Version:   01010000\n  Usage:     0x0002 (Unknown)\n  Flags:     0x00000000 (!VOLATILE, !MIGRATABLE, !REDIRECTION)\n  AuthUsage: 0x00 (Never)\n  Algorithm:         0x00000020 (Unknown)\n  Encryption Scheme: 0x00000012 (Unknown)\n  Signature Scheme:  0x00000010 (Unknown)\n  Public Key:\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n\t00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000\n",
            # rubocop:enable Layout/LineLength
          )
        end
      end
    end
  end
end
