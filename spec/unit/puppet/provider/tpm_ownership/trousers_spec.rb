require 'spec_helper'
require 'json'

describe Puppet::Type.type(:tpm_ownership).provider(:trousers) do

  let(:provider) { resource.provider }

  let(:tpm_fact) {
    JSON.load(File.read(File.expand_path('spec/files/tpm_fact.json')))
  }

  let(:resource) {
    Puppet::Type.type(:tpm_ownership).new({
      :name       => 'tpm0',
      :owner_pass => 'twentycharacters0000',
      :srk_pass   => 'twentycharacters1111',
      :provider   => 'trousers'
    })
  }


  before :each do
    Puppet.stubs(:[]).with(:vardir).returns('/tmp')
    Facter.stubs(:value).with(:has_tpm).returns(true)
    Facter.stubs(:value).with(:tpm).returns(tpm_fact)
    Facter.stubs(:value).with(:kernel).returns('Linux')
    FileUtils.stubs(:chown).with('root','root', '/tmp/simp').returns true
  end

  after :each do
    ENV['MOCK_TIMEOUT'] = nil
  end


  describe 'dump_owner_pass' do
    let(:resource) {
      Puppet::Type.type(:tpm_ownership).new({
        :name            => 'tpm0',
        :owner_pass      => 'twentycharacters0000',
        :srk_pass        => 'twentycharacters1111',
        :advanced_facts  => true,
        :provider        => 'trousers'
      })
    }
    let(:loc) { '/tmp' }
    after :each do
      file = "#{loc}/simp/tpm_ownership_owner_pass"
      FileUtils.rm(file) if File.exists? file
    end

    context 'with advanced_facts => false' do
      it 'should not do a thing' do
        expect(File.exists?("#{loc}/simp/tpm_ownership_owner_pass")).to be_falsey
      end
    end
    context 'with advanced_facts => true' do
      it 'should drop off the password file' do
        expect(provider.dump_owner_pass(loc)).to match(/twentycharacters0000/)
        expect(File.exists?("#{loc}/simp/tpm_ownership_owner_pass")).to be_truthy
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
          :owner_pass => 'twentycharacters0000',
          :srk_pass   => 'twentycharacters1111',
          :provider   => 'trousers'
        })
      }
      it 'should generate patterns for owner and srk passwords' do
        stdin, cmd = provider.generate_args

        expect(stdin).to eq([
          [ /owner password/i,   'twentycharacters0000'  ],
          [ /Confirm password/i, 'twentycharacters0000'  ],
          [ /SRK password/i,     'twentycharacters1111' ],
          [ /Confirm password/i, 'twentycharacters1111' ],
        ])
        expect(cmd).to eq('tpm_takeownership')
      end
    end

    context 'well-known owner password' do
      let(:resource) {
        Puppet::Type.type(:tpm_ownership).new({
          :name       => 'tpm0',
          :owner_pass => 'well-known',
          :srk_pass   => 'twentycharacters1111',
          :provider   => 'trousers'
        })
      }
      it 'should generate patterns for only SRK pass and a proper cmd' do
        stdin, cmd = provider.generate_args

        expect(stdin).to eq([
          [ /SRK password/i,     'twentycharacters1111' ],
          [ /Confirm password/i, 'twentycharacters1111' ],
        ])
        expect(cmd).to eq('tpm_takeownership -y')
      end
    end

    context 'well-known SRK password' do
      let(:resource) {
        Puppet::Type.type(:tpm_ownership).new({
          :name       => 'tpm0',
          :owner_pass => 'twentycharacters0000',
          :srk_pass   => 'well-known',
          :provider   => 'trousers'
        })
      }
      it 'should generate patterns for only owner pass and a proper cmd' do
        stdin, cmd = provider.generate_args

        expect(stdin).to eq([
          [ /owner password/i,   'twentycharacters0000'  ],
          [ /Confirm password/i, 'twentycharacters0000'  ],
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

  describe 'read_sys' do
    it 'should construct an instances hash from /sys/class/tpm' do
      mock_sys = 'spec/files/tpm/'
      expected = [{
        :name  => 'tpm',
        :owned => :true,
      }]
      expect(provider.class.read_sys(mock_sys)).to eq(expected)
    end
  end
end
