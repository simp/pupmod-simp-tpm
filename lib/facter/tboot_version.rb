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
    rpminfo = Facter::Core::Execution.execute('rpm -qi tboot').split("\n")
    version = parse_line(rpminfo, /Version/)

    version
  end
end
