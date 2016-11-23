# Ininitalize and manage certs in the TPM PKCS #11 interface
#
# @author Nick Miller <nick.miller@onyxpoint.com>
#
Puppet::Type.newtype(:tpmtoken) do
  @doc = "THis type will manage the PKCS #11 interface provided by opencryptoki,
and backed my the TPM.

Example:
  include 'tpm'

  tpmtoken { 'tpmtok':
    ensure   => present,
    so_pin   => '87654321',
    user_pin => '87654321'
  }"

  ensurable

  newparam(:label, :namevar => true) do
    desc 'The tag of the slot, to be used during initialization'
  end

  # newparam(:slot) do
  #   desc 'The slot in the PKCS #11 interface you would like to manage'
  #   defaultto 0
  # end

  newparam(:so_pin) do
    desc 'Security Officer (SO) PIN for the interface'
    validate do |value|
      if value.length < 4 or value.length > 8
        fail("Pin needs to be between 4 and 8 characters")
      end
    end
  end

  newparam(:user_pin) do
    desc 'User PIN for the interface'
    validate do |value|
      if value.length < 4 or value.length > 8
        fail("Pin needs to be between 4 and 8 characters")
      end
    end
  end

  autorequire(:package) do
    [ 'opencryptoki','opencryptoki-tpmtok','tpm-tools-pkcs11' ]
  end
  autorequire(:service) do
    'pkcsslotd'
  end

end
