# The tpm_ownership type allows you to take ownership of tpm0.
#
# @!puppet.type.param owner_pass TPM owner password. Required.
#
# @!puppet.type.param srk_pass TPM SRK password. Required.
#
# @!puppet.type.param device TPM device identifier. Defaults to tpm0. Checks to
#   make sure the device exists at /dev/*<id>*
#
# @!puppet.type.param advanced_facts If true, the provider will drop the owner
#   password in a file in the puppet `$vardir` to be used in some facts.
#
# @author Nick Miller <nick.miller@onyxpoint.com>
#
require 'puppet/parameter/boolean'

Puppet::Type.newtype(:tpm_ownership) do
  @doc = <<-EOM
    A type to manage ownership of a TPM. `owner_pass` and `srk_pass` are required.

    Example:

    ```ruby
    include 'tpm'

    tpm_ownership { 'tpm0':
      ensure     => present,
      owner_pass => 'badpass',
      srk_pass   => 'badpass2'
    }
    ```
  EOM

  feature :take_ownership, "The ability to take ownership of a TPM"

  ensurable

  def pre_run_check
    if !Facter.value(:has_tpm)
      raise Puppet::Error, "Host doesn't have a TPM"
    end
  end

  newparam(:owner_pass) do
    desc 'The owner password of the TPM'
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "$owner_pass must be a String, not '#{value.class}'")
      end
    end
  end

  newparam(:srk_pass) do
    desc 'The SRK password of the TPM'
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "$owner_pass must be a String, not '#{value.class}'")
      end
    end
  end

  newparam(:device, :namevar => true) do
    desc 'The tpm device to manage'

    validate do |value|
      unless !Dir.glob("/dev/#{value}").empty?
        raise ArgumentError, "%s is not a valid TPM device" % value
      end
    end

    defaultto 'tpm0'
  end

  newparam(:advanced_facts, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Enabling the advanced facts will write your owner password to a file on the
      system, only readable by the root user. It will be used to query the
      TPM using trousers."
    defaultto 'false'
  end

  autorequire(:package) do
    [ 'trousers','tpm-tools' ]
  end
  autorequire(:service) do
    'tcsd'
  end

  validate do
    if self[:owner_pass].nil? or self[:srk_pass].nil?
      fail('Both passwords are required to use this type')
    end
  end

end
