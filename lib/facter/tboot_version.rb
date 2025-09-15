# Determine the verson of tboot installed
#
Facter.add('tboot_version') do
  confine do
    Facter::Core::Execution.which('rpm')
  end

  def parse_line(text, pattern)
    text.grep(pattern).first.split(':')[1].strip
  end

  setcode do
    if Facter::Core::Execution.which('txt-stat')
      rpminfo = Facter::Core::Execution.execute('rpm -qi tboot').split("\n")
      parse_line(rpminfo, %r{Version})
    end
  end
end
