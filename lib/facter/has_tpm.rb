Facter.add('has_tpm') do
  setcode do
    not Dir.glob('/sys/class/misc/tpm*').empty?
  end
end
