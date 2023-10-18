# Detects whether or not the machine has a TPM
Facter.add('has_tpm') do
  setcode do
    File.exist?('/dev/tpm0')
  end
end
