require 'spec_helper'
require 'json'

describe Puppet::Type.type(:tpm2_ownership).provider(:tpm2tools) do

  let(:provider) { resource.provider }


  let(:resource) {
    Puppet::Type.type(:tpm2_ownership).new({
      :name         => 'tpm0',
      :owner_pass   => 'badpass',
      :lock_pass    => 'badpass',
      :endorse_pass => 'badpass',
      :provider     => 'tpm2tools'
    })
  }


  before :each do
    Puppet.stubs(:[]).with(:vardir).returns('/tmp/puppetvar')
    Facter.stubs(:value).with(:has_tpm).returns(true)
    Facter.stubs(:value).with(:tpm_version).returns('tpm2')
    Facter.stubs(:value).with(:kernel).returns('Linux')
    FileUtils.stubs(:chown).with('root','root', '/tmp/simp').returns true
    FileUtils.stubs(:chown).with('root','root', '/tmp/puppetvar/simp').returns true
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

  describe "provider class" do
    resource = Puppet::Type::tpm2_takeownership.new(
      :name            => 'tpm0',
      :owner_pass      => 'ownerpassword',
      :lock_pass       => 'lockpassword',
      :endorse_pass    => 'endorsepassword',
      :provider        => 'tpm2tools'
    )
    Dir.stubs(:glob).with('/sys/class/tpm/*').returns ['tpm0']
    File.stubs(:exists?).with('/sys/class/tpm/tpm0/owned').returns false



end
