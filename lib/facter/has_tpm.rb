# Detects whether or not the machine has a TPM based on the contents of
# /sys/class/misc/tpm* or /sys/class/tpm/tpm* on newer systems
Facter.add('has_tpm') do
  setcode do
    !(Dir.glob('/sys/class/misc/tpm*').empty? and Dir.glob('/sys/class/tpm/tpm*').empty?)
  end
end
