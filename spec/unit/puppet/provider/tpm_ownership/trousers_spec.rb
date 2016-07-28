require 'spec_helper'
require 'json'
require 'pry'

describe Puppet::Type.type(:tpm_ownership).provider(:trousers) do

  let(:provider) { resource.provider }

  let(:tpm_fact) {
    # JSON.load(File.read(File.expand_path('spec/files/tpm_fact.json'), File.dirname(__FILE__)))
    JSON.load(File.read(File.expand_path('spec/files/tpm_fact.json')))
  }

  before :each do
    Puppet.initialize_settings
    Puppet.stubs(:[]).with(:vardir).returns('/tmp')

    FileUtils.stubs(:mkdir).returns(true)
    FileUtils.stubs(:chown).returns(true)

    Facter.stubs(:value).with(:has_tpm).returns(true)
    Facter.stubs(:value).with(:tpm).returns(tpm_fact)
    Facter.stubs(:value).with(:kernel).returns(true)
  end

  context 'with just passwords' do
    let(:resource) {
      Puppet::Type.type(:tpm_ownership).new({
        :name       => 'tpm0',
        :owner_pass => 'badpass',
        :srk_pass   => 'badpass2',
        :provider   => 'trousers'
      })
    }

    describe 'dump_owner_pass' do
      let(:resource) {
        Puppet::Type.type(:tpm_ownership).new({
          :name            => 'tpm0',
          :owner_pass      => 'badpass',
          :srk_pass        => 'badpass2',
          'advanced_facts' => true,
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

    describe 'exists?' do
      it 'detect TPM is unowned' do
        expect(provider.exists?).to be_falsey
      end
    end

    describe 'create' do

      let(:tpm_ownership_stdout) {
%q{Enter owner password:
Confirm password:
Enter SRK password:
Confirm password:
}
      }

      let(:tpm_ownership_stdin) {
%q{badpass
badpass
badpass
badpass
}
      }

      it 'runs tpm_takeownership with expected output' do
        skip('TODO')
        # stdin = StringIO.new(tpm_ownership_stdin)
        # stdout = StringIO.new(tpm_ownership_stdout)


      end
    end

    describe 'destroy' do
      it 'should log alert and not do anything' do
        expect(provider.destroy).to be_instance_of(Puppet::Util::Log)
      end
    end

    #test each of
    # ensure => present but doesn't exists
    # ensure => absent but exists
    # etc

  end

end
