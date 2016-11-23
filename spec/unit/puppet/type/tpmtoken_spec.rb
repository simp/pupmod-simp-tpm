require 'spec_helper'

describe Puppet::Type.type(:tpmtoken) do

  [:so_pin, :user_pin].each do |param|

    it "should accept #{param} with 8 characters" do
      expect {
        Puppet::Type.type(:tpmtoken).new(
          :name => 'IBM PKCS11 TPM Token',
          param => '1234'
        )
      }.not_to raise_error
    end

    it "should accept #{param} with 4 characters" do
      expect {
        Puppet::Type.type(:tpmtoken).new(
          :name => 'IBM PKCS11 TPM Token',
          param => '12345678'
        )
      }.not_to raise_error
    end

    it "should fail #{param} with less than 4 characters" do
      expect {
        Puppet::Type.type(:tpmtoken).new(
          :name => 'IBM PKCS11 TPM Token',
          param => '123'
        )
      }.to raise_error(Puppet::ResourceError)
    end

    it "should fail #{param} with more than 8 characters" do
      expect {
        Puppet::Type.type(:tpmtoken).new(
          :name => 'IBM PKCS11 TPM Token',
          param => '123456789'
        )
      }.to raise_error(Puppet::ResourceError)
    end
  end

end