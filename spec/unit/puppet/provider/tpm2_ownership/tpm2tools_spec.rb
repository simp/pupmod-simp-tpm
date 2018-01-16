require 'spec_helper'
require 'json'

include Simp::RspecPuppetFacts

describe Puppet::Type.type(:tpm2_ownership).provider(:tpm2tools) do

  before :each do
    Puppet.stubs(:[]).with(:vardir).returns('/tmp/puppetvar')
    Facter.stubs(:value).with(:has_tpm).returns(true)
    Facter.stubs(:value).with(:tpm_version).returns('tpm2')
    Facter.stubs(:value).with(:kernel).returns('Linux')
#    FileUtils.stubs(:chown).with('root','root', '/tmp/simp').returns true
#    FileUtils.stubs(:chown).with('root','root', '/tmp/puppetvar/simp').returns true
  end

  describe 'dump_pass with local_dir set' do
    let(:resource) {
      Puppet::Type.type(:tpm2_ownership).new({
        :name            => 'tpm0',
        :owner_pass      => 'ownerpassword',
        :lock_pass       => 'lockpassword',
        :endorse_pass    => 'endorsepassword',
        :inhex           => true,
        :local           => true,
        :local_dir       => '/tmp',
        :provider        => 'tpm2tools'
      })
    }
    let(:provider) { resource.provider }

    let(:loc) { '/tmp' }
    after :each do
      file = "#{loc}/simp/#{resource[:name]}_data.json"
      FileUtils.rm(file) if File.exists? file
    end

    context 'dump_pass with local_dir set' do
      it 'should drop off the password file in local_dir' do
        expect(provider.dump_pass(resource[:name],resource[:local_dir])).to match(nil)
        expect(File.exists?("#{resource[:local_dir]}/simp/#{resource[:name]}_data.json")).to be_truthy
        expect(File.read("#{resource[:local_dir]}/simp/#{resource[:name]}_data.json")).to match(/{"owner_pass":"ownerpassword","lock_pass":"lockpassword","endorse_pass":"endorsepassword"}/)
      end
    end

    context 'gen_passwd_args with hex set' do
      it 'should add -X to the args' do
        expect(provider.gen_passwd_args).to eq(["-o ownerpassword", "-l lockpassword", "-e endorsepassword", "-X"])
      end
    end

  end

  describe 'with default local_dir and default password hex value' do

    let(:resource) {
      Puppet::Type.type(:tpm2_ownership).new({
        :name            => 'tpm0',
        :owner_pass      => 'ownerpassword',
        :lock_pass       => 'lockpassword',
        :endorse_pass    => 'endorsepassword',
        :local           => true,
        :provider        => 'tpm2tools'
      })
    }

    let(:provider) { resource.provider }

    context 'dump_pass with local_dir not set' do
      it 'should drop off the password file in Puppet[:vardir]' do
        expect(provider.dump_pass(resource[:name],resource[:local_dir])).to match(nil)
        expect(File.exists?("/tmp/puppetvar/simp/#{resource[:name]}_data.json")).to be_truthy
        expect(File.read("/tmp/puppetvar/simp/#{resource[:name]}_data.json")).to match(/{"owner_pass":"ownerpassword","lock_pass":"lockpassword","endorse_pass":"endorsepassword"}/)
      end
    end

    context 'gen_passwd_args with with default for hex password' do
      it 'should inot add -X to the args' do
        expect(provider.gen_passwd_args).to eq(["-o ownerpassword", "-l lockpassword", "-e endorsepassword"])
      end
    end

  end

  describe "Test tpm2_takeownership fails" do
    let(:resource)  { Puppet::Type.type(:tpm2_ownership).new({
      :name            => 'tpm0',
      :owner_pass      => 'ownerpassword',
      :lock_pass       => 'lockpassword',
      :endorse_pass    => 'endorsepassword',
      :provider        => 'tpm2tools',
      :local           => true,
      :local_dir       => '/tmp',
      })
    }

    let(:provider) { resource.provider }

    let(:loc) { '/tmp/tpm' }

    before :each do
      # Because there is no TPM during testing the commands all fail so for now we are faking
      # the output with script in the files directory.
      Puppet::Util.stubs(:which).with('tpm2_takeownership').returns('./spec/files/tpm2_takeownership')
      File.delete("#{loc}/tpm0/owned") if File.exists?("#{loc}/tpm0/owned")
      File.delete("#{resource[:local_dir]}/simp/#{resource[:name]}_data.json") if File.exists?("#{resource[:local_dir]}/simp/#{resource[:name]}_data.json")
    end

    it 'should not create the owned filed if it errors' do
      ENV['MOCK_ERROR'] = 'yes'
      provider.takeownership('tpm0', loc)
      expect(File.exists?("#{loc}/tpm0/owned")).to be_falsey
      expect(File.exists?("#{resource[:local_dir]}/simp/#{resource[:name]}_data.json")).to be_falsey
    end

    it 'should create the ownership file' do
      ENV['MOCK_ERROR'] = 'no'
      provider.takeownership('tpm0', loc)
      expect(File.exists?('/tmp/tpm/tpm0/owned')).to be_truthy
      expect(File.exists?("#{resource[:local_dir]}/simp/#{resource[:name]}_data.json")).to be_truthy
    end
  end
end
