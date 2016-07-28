require 'spec_helper'

describe Puppet::Type.type(:tpm_ownership) do

  before :each do
    Facter.stubs(:value).with(:has_tpm).returns(false)

  end

  it 'should fail to run on a host without a TPM' do
    expect {
      Puppet::Type.type(:tpm_ownership).new(
        :name           => 'tpm0',
        :owner_pass     => 'badpass',
        :srk_pass       => 'badpass',
      ).pre_run_check
    }.to raise_error(/Host doesn't have a TPM/)
  end

  it 'should fail to run with an invalid TPM device name' do
    expect {
      Puppet::Type.type(:tpm_ownership).new(
        :name  => 'tpm1',
        :owner_pass     => 'badpass',
        :srk_pass       => 'badpass',
      )
    }.to raise_error(/tpm1 is not a valid TPM device/)
  end

  context 'should require a boolean for advanced_facts' do
    it 'is given a boolean' do
      expect {
        Puppet::Type.type(:tpm_ownership).new(
          :name           => 'tpm0',
          :owner_pass     => 'badpass',
          :srk_pass       => 'badpass',
          :advanced_facts => true
        )
      }.to_not raise_error
    end
    it 'is given a string that is not a boolean' do
      expect {
        Puppet::Type.type(:tpm_ownership).new(
          :name           => 'tpm0',
          :owner_pass     => 'badpass',
          :srk_pass       => 'badpass',
          :advanced_facts => 'not a boolean'
        )
      }.to raise_error
    end
  end

  [:owner_pass, :srk_pass].each do |param|
    it "should fail to run with only the #{param} field" do
      # skip("TODO: Figure out how to require the #{param} parameter")
      expect {
       Puppet::Type.type(:tpm_ownership).new(
         :name => 'tpm0',
         param => 'badpass'
       )
     }.to raise_error(Puppet::ResourceError)
    end

    it 'should require a string for both passwords' do
      expect {
        Puppet::Type.type(:tpm_ownership).new(
          :name => 'tpm0',
          param => ['array','should','fail']
        )
      }.to raise_error(/must be a String/)
    end
  end
end
