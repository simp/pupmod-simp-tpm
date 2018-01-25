# The tpm_ownership type allows you to take ownership of tpm0.
#
# @!puppet.type.param owner_auth TPM owner password. Required.
# @!puppet.type.param lock_auth TPM  lock out password. Required.
# @!puppet.type.param endorse_auth TPM endorsement hierachy password. Required.
#
# @!puppet.type.param in_hex If true, indicates the passwords are in Hex.
#
# @!puppet.type.param local If true, the provider will drop the 
#   passwords in a file in the puppet `$vardir`/simp/<tpmname>.
#
# @!puppet.type.param owned If true it will set the passwords on the TPM. Required
#
#
# @author SIMP Team <https://simp-project.com>
#
require 'puppet/parameter/boolean'

Puppet::Type.newtype(:tpm2_ownership) do
  @doc = "A type to manage ownership of a TPM 2.0.

  The current tpm2-tools version 1.1.0-7 does not have a feature to read the status
  of the tpm so the ownership of the  TPM is indicated by  a file called owned create in
  the /system/class/tpm/tpm0 directory called owned.

  Use this to set the passwords on a TPM to prevent unauthorized access.

  It can not at this time change the passwords or reset the passwords.

Example:

  include 'tpm'

  tpm2_ownership { 'tpm0':
    owned        => true,
    owner_auth   => 'badpass',
    lock_auth    => 'badpass',
    endorse_auth => 'badpass',
  }
"

  feature :take_ownership, "The ability to take ownership of a TPM"


  newparam(:owner_auth) do
    desc 'The owner password of the TPM'
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "owner_auth must be a String, not '#{value.class}'")
      end
    end
    defaultto ''
  end

  newparam(:lock_auth) do
    desc "The lock out password of the TPM"
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "lock_auth must be a String, not '#{value.class}'")
      end
    end
    defaultto ''
  end

  newparam(:endorse_auth) do
    desc "The endorse password of the TPM"
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "endorse_auth must be a String, not '#{value.class}'")
      end
    end
    defaultto ''
  end

  newparam(:name, :namevar => true) do
    desc 'The name of the tpm in /sys/class/tpm/ - usually tpm0, the default device.'
    defaultto 'tpm0'
  end

  newparam(:in_hex, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Whether or not the passwords are in hex"
    defaultto 'false'
  end

  newparam(:local, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Whether to save the passwords on the local system"
    defaultto 'false'
  end

# The following TCTI properties are common to most tpm2-tools commands. These are used in
#  Later versions of the tools and are not active yet.

  newparam(:tcti) do
    desc "The TCTI used for communication with the next component down the
              TSS stack"
    newvalues(:device,:socket)
    defaultto :socket
  end

  newparam(:devicefile) do
    desc "The TPM device file for use by the device TCTI"
    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        raise(Puppet::Error, "The device file must be an absolute path")
      end
    end
    defaultto '/dev/tpm0'
  end

  newparam(:socket_address) do
    desc "The domain name or IP address used by the socket TCTI"
    defaultto '127.0.0.1'
  end

  newparam(:socket_port) do
    desc "The port number used by the socket TCTI"
    validate do |value|
      unless value.is_a?(Integer)
        raise(Puppet::Error, "endorse_auth must be an Integer, not '#{value.class}'")
      end
    end
    defaultto 2323
  end

# End of TCTI Params

  newproperty(:owned) do
    desc 'Whether or not to set passwords on the TPM'
    newvalues(:true)
    validate do |value|
      unless value == true
        raise(Puppet::Error, "Owned must be set to true.  Clearing the TPM is not supported at this time.")
      end
    end
    defaultto :true
  end

  autorequire(:package) do
    [ 'tpm2-tss','tpm2-tools' ]
  end
  autorequire(:service) do
    [ 'resourcemgr' ]
  end

end
