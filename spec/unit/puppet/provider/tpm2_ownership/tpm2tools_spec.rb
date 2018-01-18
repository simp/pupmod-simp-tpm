require 'spec_helper'
require 'json'

include Simp::RspecPuppetFacts

describe Puppet::Type.type(:tpm2_ownership).provider(:tpm2tools) do

  before :each do
    Puppet.stubs(:[]).with(:vardir).returns('/tmp/puppetvar')
    Facter.stubs(:value).with(:has_tpm).returns(true)
    Facter.stubs(:value).with(:tpm_version).returns('tpm2')
    Facter.stubs(:value).with(:kernel).returns('Linux')
    FileUtils.stubs(:chown).with('root','root', '/tmp/simp/tpm0').returns true
    FileUtils.stubs(:chown).with('root','root', '/tmp/puppetvar/simp/tpm0').returns true
  end

  describe 'dump_pass and gen_password' do
    let(:provider) { resource.provider }

    context 'local_dir and inhex set' do
      let(:resource) {
        Puppet::Type.type(:tpm2_ownership).new({
          :name            => 'tpm0',
          :owner_pass      => 'ownerpassword',
          :lock_pass       => 'lockpassword',
          :endorse_pass    => 'endorsepassword',
          :inhex           => true,
          :local           => true,
          :local_dir       => '/tmp/local',
          :provider        => 'tpm2tools'
        })
      }

      # Password file should resolve to resource[:local_dir]/simp/resource[:name]/resource[:name]data.json
      let(:passwdfile) {'/tmp/local/simp/tpm0/tpm0data.json'}

      before :each do
        File.delete("#{passwdfile}") if File.exists?("#{passwdfile}")
        FileUtils.stubs(:chown).with('root','root', '/tmp/local/simp/tpm0').returns true
      end

      it 'should drop off the password file in local_dir' do
        expect(provider.dump_pass(resource[:name],resource[:local_dir])).to match(nil)
        expect(File.exists?("#{passwdfile}")).to be_truthy
        expect(File.read("#{passwdfile}")).to match(/{"owner_pass":"ownerpassword","lock_pass":"lockpassword","endorse_pass":"endorsepassword"}/)
      end

      it 'should add -X to the args' do
        expect(provider.gen_passwd_args).to eq(["-o ownerpassword", "-l lockpassword", "-e endorsepassword", "-X"])
      end
    end

    context 'with default values' do
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


      # Password file should resolve to Puppet[:vardir]/simp/resource[:name]/resource[:name]data.json
      let(:passwdfile) {'/tmp/puppetvar/simp/tpm0/tpm0data.json'}

      before :each do
        File.delete("#{passwdfile}") if File.exists?("#{passwdfile}")
      end

      it 'should drop off the password file in Puppet[:vardir]' do
        expect(provider.dump_pass(resource[:name],resource[:local_dir])).to match(nil)
        expect(File.exists?("#{passwdfile}")).to be_truthy
        expect(File.read("#{passwdfile}")).to match(/{"owner_pass":"ownerpassword","lock_pass":"lockpassword","endorse_pass":"endorsepassword"}/)
      end

      it 'should not add -X ' do
        expect(provider.gen_passwd_args).to eq(["-o ownerpassword", "-l lockpassword", "-e endorsepassword"])
      end
    end

  end

  describe "tpm2_takeownership" do
    let(:resource)  { Puppet::Type.type(:tpm2_ownership).new({
      :name            => 'tpm0',
      :owner_pass      => 'ownerpassword',
      :lock_pass       => 'lockpassword',
      :endorse_pass    => 'endorsepassword',
      :provider        => 'tpm2tools',
      :local           => true,
      })
    }

    let(:provider) { resource.provider }

    # Ownerfile should resolve to  Puppet[:vardir]/simp/resource[:name]/owned
    let(:ownerfile) {'/tmp/puppetvar/simp/tpm0/owned'}
    # Password file should resolve to Puppet[:vardir]/simp/resource[:name]/resource[:name]data.json
    let(:passwdfile) {'/tmp/puppetvar/simp/tpm0/tpm0data.json'}

    before :each do
      # Because there is no TPM during testing the commands all fail so for
      # now we are faking the output with script in the files directory.
      Puppet::Util.stubs(:which).with('tpm2_takeownership').returns('./spec/files/tpm2_takeownership')

      #clear out the files
      File.delete("#{ownerfile}") if File.exists?("#{ownerfile}")
      File.delete("#{passwdfile}") if File.exists?("#{passwdfile}")
    end

    context 'tpm2_takeownership errors' do
      ENV['MOCK_ERROR'] = 'yes'
      it 'should not create the owned filed ' do
        provider.takeownership(resource[:name])
        expect(File.exists?("#{ownerfile}")).to be_falsey
        expect(File.exists?("#{passwdfile}")).to be_falsey
      end
    end

    context 'tpm2_takeownership finishes' do
      it 'should create the owned file' do
        ENV['MOCK_ERROR'] = 'no'
        provider.takeownership(resource[:name])
        expect(File.exists?("#{ownerfile}")).to be_truthy
        expect(File.exists?("#{passwdfile}")).to be_truthy
      end
    end
  end

end
