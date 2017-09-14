# The tpm_ownership type allows you to take ownership of tpm0.
#
# @!puppet.type.param owner_pass TPM owner password. Required.
#
# @!puppet.type.param srk_pass TPM SRK password. Defaults to empty string.
#
# @!puppet.type.param advanced_facts If true, the provider will drop the owner
#   password in a file in the puppet `$vardir` to be used in the `tpm` fact
#   from this module.
#
# @author Nick Miller <nick.miller@onyxpoint.com>
#
require 'puppet/parameter/boolean'

Puppet::Type.newtype(:tpm_ownership) do
  @doc = "A type to manage ownership of a TPM. `owner_pass` is required, while
`srk-pass` is only necessary if you aren't using Trusted Boot or the PKCS#11
interface. The SRK password must be  to be null in order to use those features.

If you need to use a 'well-known' password, make the password equal to the
string 'well-known'. The provider will then use the `-z` or `-y` option when
taking ownership of the TPM with `tpm_takeownership`.

Example:

  include 'tpm'

  tpm_ownership { 'tpm0':
    owned      => true,
    owner_pass => 'badpass',
  }
"

  feature :take_ownership, "The ability to take ownership of a TPM"


  newparam(:owner_pass) do
    desc 'The owner password of the TPM'
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "owner_pass must be a String, not '#{value.class}'")
      end
    end
  end

  newparam(:srk_pass) do
    desc 'The Storage Root Key(SRK) password of the TPM'
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "srk_pass must be a String, not '#{value.class}'")
      end
    end
    defaultto 'well-known'
  end

  newparam(:name, :namevar => true) do
    desc 'The name of the resource - usually tpm0, the default device.'
    defaultto 'tpm0'
  end

  newparam(:advanced_facts, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Enabling the advanced facts will write your owner password to a file on the
      system, only readable by the root user. It will be used to query the
      TPM using trousers."
    defaultto 'false'
  end


  newproperty(:owned) do
    desc 'Ownership status of the TPM'
    newvalues(:true,:false)
  end


  autorequire(:package) do
    [ 'trousers','tpm-tools' ]
  end
  autorequire(:service) do
    'tcsd'
  end

end
