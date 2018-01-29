require 'spec_helper'

describe Puppet::Type.type(:tpm2_ownership) do

  before :each do
    Facter.stubs(:value).with(:has_tpm).returns(false)
  end

  context 'should require a boolean for in_hex' do
    it 'is given a boolean' do
      expect {
        Puppet::Type.type(:tpm2_ownership).new(
          :name       => 'tpm0',
          :owner_auth => 'badpass',
          :in_hex     => true
        )
      }.to_not raise_error
    end
    it 'is given a string that is not a boolean' do
      expect {
        Puppet::Type.type(:tpm_ownership).new(
          :name       => 'tpm0',
          :owner_auth => 'badpass',
          :in_hex     => 'not a boolean'
        )
      }.to raise_error
    end
  end

  [:owner_auth, :lock_auth, :endorse_auth].each do |param|
    it "should require a string for #{param}" do
      expect {
        Puppet::Type.type(:tpm2_ownership).new(
          :name => 'tpm0',
          param => ['array','should','fail']
        )
      }.to raise_error(/#{param.to_s} must be a String/)
    end
  end
end
