# The tpm_ownership type allows you to take ownership of tpm0.
#
# @!puppet.type.param owner_pass TPM owner password. Required.
# @!puppet.type.param lock_pass TPM  lock out password. Required.
# @!puppet.type.param endorse_pass TPM endorsement hierachy password. Required.
#
# @!puppet.type.param inhex If true, indicates the passwords are in Hex.
#
# @!puppet.type.param local If true, the provider will drop the owner
#   password in a file in the puppet `$vardir` to be used in the `tpm` fact
#   from this module.
# @!puppet.type.param local_dir If local is true, this will override the default
#   directory the passwords are stored in.
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

  newparam(:local, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Wether to save the passwords on the local system"
    defaultto 'false'
  end

  newparam(:local_dir) do
    desc "Directory to save passwords locally"
    validate do |value|
      unless Puppet::Util.absolute_path?(value) or value == 'vardir'
        raise(Puppet::Error, " local_dir must be an absolute path or the word vardir to indicate
              that vardir set in the puppet configuration should be used.")
      end
    end
    defaultto 'vardir'
  end

# The following TCTI properties are common to most  tpm2-tools commands.  These are used in
#  Later versions of the tools and are not active yet.

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
    desc 'Wether or not to set passwords on the TPM'
    newvalues(:true, :false)
    defaultto :true
  end

  autorequire(:package) do
    [ 'tpm2-tss','tpm2-tools' ]
  end
  autorequire(:service) do
    [ 'resourcemgr' ]
  end

end
