require 'spec_helper'

describe Puppet::Type.type(:tpm_ownership) do
  before :each do
    allow(Facter).to receive(:value).with(:has_tpm).and_return(false)
  end

  context 'should require a boolean for advanced_facts' do
    it 'is given a boolean' do
      expect {
        Puppet::Type.type(:tpm_ownership).new(
          name: 'tpm0',
          owner_pass: 'badpass',
          srk_pass: 'badpass',
          advanced_facts: true,
        )
      }.not_to raise_error
    end
    it 'is given a string that is not a boolean' do
      expect {
        Puppet::Type.type(:tpm_ownership).new(
          name: 'tpm0',
          owner_pass: 'badpass',
          srk_pass: 'badpass',
          advanced_facts: 'not a boolean',
        )
      }.to raise_error
    end
  end

  [:owner_pass, :srk_pass].each do |param|
    it "requires a string for #{param}" do
      expect {
        Puppet::Type.type(:tpm_ownership).new(
          :name => 'tpm0',
          param => ['array', 'should', 'fail'],
        )
      }.to raise_error(%r{#{param} must be a String})
    end
  end
end
