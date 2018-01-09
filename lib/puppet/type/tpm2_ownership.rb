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

Puppet::Type.newtype(:tpm2_ownership) do
  @doc = "A type to manage ownership of a TPM 2.0.

  The current tpm2-tools version 1.1.0-7 does not have a feature to read the status
  of the tpm so the ownership of the  TPM is indicated by files kept in the
  ${vardir}/simp directory.

  It can not at this time change the passwords or reset the passwords.


Example:

  include 'tpm'

  tpm2_ownership { 'tpm0':
    owned        => true,
    owner_pass   => 'badpass',
    lock_pass    => 'badpass',
    endorse_pass => 'badpass',
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
    defaultto ''
  end

  newparam(:lock_pass) do
    desc "The lock out password of the TPM"
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "lock_pass must be a String, not '#{value.class}'")
      end
    end
    defaultto ''
  end

  newparam(:endorse_pass) do
    desc "The endorse password of the TPM"
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "endorse_pass must be a String, not '#{value.class}'")
      end
    end
    defaultto ''
  end

  newparam(:name, :namevar => true) do
    desc 'The name of the tpm in /sys/class/tpm/ - usually tpm0, the default device.'
    defaultto 'tpm0'
  end

  newparam(:inhex, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Wether or not the passwords are in hex"
    defaultto 'false'
  end

# The following TCTI properties are common to most  tpm2-tools commands

  newparam(:tcti) do
    desc "the  TCTI used for communication with the next component down the
              TSS stack"
    newvalues(:device,:socket)
    defaultto :socket
  end

  newparam(:devicefile) do
    desc "the  TPM  device file for use by the device TCTI"
    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        raise(Puppet::Error, "The device file must be an absolute path")
      end
    end
    defaultto '/dev/tpm0'
  end

  newparam(:socket_address) do
    desc "the domain name or IP  address  used  by  the  socket  TCTI. "
    defaultto '127.0.01'
  end

  newparam(:socket_port) do
    desc "the port number used by the socket TCTI"
    validate do |value|
      unless value.is_a?(Integer)
        raise(Puppet::Error, "endorse_pass must be an Integer, not '#{value.class}'")
      end
    end
    defaultto 2323
  end

# End of TCTI Params

  newproperty(:owned) do
    desc 'Ownership status of the TPM'
    newvalues(:true, :false)
    defaultto :true
  end

  autorequire(:package) do
    [ 'tpm2-tss','tpm2-tools' ]
  end
# note: note autorequiring the service because in version 2.0 the service is not
# required in kernel 4.X and later.
#
end
