require 'spec_helper'
require 'json'

describe Puppet::Type.type(:tpm_ownership).provider(:trousers) do

  let(:provider) { resource.provider }

  let(:tpm_fact) {
    # JSON.load(File.read(File.expand_path('spec/files/tpm_fact.json'), File.dirname(__FILE__)))
    JSON.load(File.read(File.expand_path('spec/files/tpm_fact.json')))
  }

  let(:resource) {
    Puppet::Type.type(:tpm_ownership).new({
      :name       => 'tpm0',
      :owner_pass => 'badpass',
      :srk_pass   => 'badpass2',
      :provider   => 'trousers'
    })
  }


  before :each do
    Puppet.stubs(:[]).with(:vardir).returns('/tmp')

    FileUtils.stubs(:mkdir).returns(true)
    FileUtils.stubs(:chown).returns(true)

    Facter.stubs(:value).with(:has_tpm).returns(true)
    Facter.stubs(:value).with(:tpm).returns(tpm_fact)
    # Facter.stubs(:[]).with(:tpm).with(value).returns(tpm_fact)
    Facter.stubs(:value).with(:kernel).returns(true)
  end

  after :each do
    ENV['MOCK_TIMEOUT'] =  nil
  end


  describe 'dump_owner_pass' do
    let(:resource) {
      Puppet::Type.type(:tpm_ownership).new({
        :name            => 'tpm0',
        :owner_pass      => 'badpass',
        :srk_pass        => 'badpass2',
        :advanced_facts  => true,
        :provider        => 'trousers'
      })
    }

    context 'with advanced_facts => true' do
      it 'should drop off the password file' do
        loc = '/tmp'
        expect(provider.dump_owner_pass(loc)).to match(/badpass/)
        expect(File.exists?("#{loc}/simp/tpm_ownership_owner_pass")).to be_truthy
      end
    end
    context 'with advanced_facts => false' do
      it 'should not do a thing' do

      end
    end
  end

  describe 'tpm_takeownership' do
    let(:stdin) {[
      [ /owner password/i,   resource[:owner_pass] ],
      [ /Confirm password/i, resource[:owner_pass] ],
      [ /SRK password/i,     resource[:srk_pass]   ],
      [ /Confirm password/i, resource[:srk_pass]   ],
    ]}
    let(:mock_script) { File.expand_path('spec/files/mock_tpm_takeownership.rb') }

    it 'interact with the test script normally' do
      expect(provider.tpm_takeownership( stdin, mock_script )).to be_truthy
    end

    it 'errors when it times out' do
      ENV['MOCK_TIMEOUT'] = 'yes'
      expect(provider.tpm_takeownership( stdin, mock_script )).to be_falsey
    end
  end

  describe 'generate_args' do
    context 'both passwords specified' do
      let(:resource) {
        Puppet::Type.type(:tpm_ownership).new({
          :name       => 'tpm0',
          :owner_pass => 'badpass',
          :srk_pass   => 'badpass2',
          :provider   => 'trousers'
        })
      }
      it 'should generate patterns for owner and srk passwords' do
        # require 'pry';binding.pry
        stdin, cmd = provider.generate_args

        expect(stdin).to eq([
          [ /owner password/i,   'badpass'  ],
          [ /Confirm password/i, 'badpass'  ],
          [ /SRK password/i,     'badpass2' ],
          [ /Confirm password/i, 'badpass2' ],
        ])
        expect(cmd).to eq('tpm_takeownership')
      end
    end

    context 'well-known owner password' do
      let(:resource) {
        Puppet::Type.type(:tpm_ownership).new({
          :name       => 'tpm0',
          :owner_pass => 'well-known',
          :srk_pass   => 'badpass2',
          :provider   => 'trousers'
        })
      }
      it 'should generate patterns for only SRK pass and a proper cmd' do
        stdin, cmd = provider.generate_args

        expect(stdin).to eq([
          [ /SRK password/i,     'badpass2' ],
          [ /Confirm password/i, 'badpass2' ],
        ])
        expect(cmd).to eq('tpm_takeownership -y')
      end
    end

    context 'well-known SRK password' do
      let(:resource) {
        Puppet::Type.type(:tpm_ownership).new({
          :name       => 'tpm0',
          :owner_pass => 'badpass',
          :srk_pass   => 'well-known',
          :provider   => 'trousers'
        })
      }
      it 'should generate patterns for only owner pass and a proper cmd' do
        stdin, cmd = provider.generate_args

        expect(stdin).to eq([
          [ /owner password/i,   'badpass'  ],
          [ /Confirm password/i, 'badpass'  ],
        ])
        expect(cmd).to eq('tpm_takeownership -z')
      end
    end

    context 'both well-known passwords' do
      let(:resource) {
        Puppet::Type.type(:tpm_ownership).new({
          :name       => 'tpm0',
          :owner_pass => 'well-known',
          :srk_pass   => 'well-known',
          :provider   => 'trousers'
        })
      }
      it 'should generate no patterns and a proper cmd' do
        stdin, cmd = provider.generate_args

        expect(stdin).to eq([])
        expect(cmd).to eq('tpm_takeownership -y -z')
      end
    end
  end

  describe 'exists?' do
    it 'detect TPM is unowned' do
      expect(provider.exists?).to be_falsey
    end
  end

  # describe 'create' do
  #
  # end

  describe 'destroy' do
    it 'should log alert and not do anything' do
      expect(provider.destroy).to be_instance_of(Puppet::Util::Log)
    end
  end

end
