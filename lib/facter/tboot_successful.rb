# Detects whether or not the machine has booted into a trusted environment sucessfully
Facter.add('tboot_successful') do
  confine :has_tpm => true
  setcode do
    txt_stat = Facter::Core::Execution.execute('txt-stat')
    status = txt_stat.split("\n").grep(/TXT measured launch:/).first.split(':')[1].downcase.strip

    status == 'true' ? true : false
  end
end
