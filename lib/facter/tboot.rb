# Hash of TXT and tboot related things
#
# txt['tboot_session'] Whether or not the current boot is using the tboot kernel
# txt['measured_launch'] Whether or not the current boot is in a measured launch environment
# txt['errorcode'] tboot error code, also available using the `parse_err` command
# txt['pubkey'] not sure what this is for
#
Facter.add('tboot') do
  confine has_tpm: true
  confine do
    Facter::Core::Execution.which('txt-stat')
  end

  def parse_line(text, pattern)
    text.grep(pattern).first.split(':')[1].downcase.strip
  end

  setcode do
    txt_stat = Facter::Core::Execution.execute('txt-stat').split("\n")

    pubkey_index = txt_stat.find_index("\tPUBLIC.KEY:")
    pubkey_raw = txt_stat[pubkey_index + 1..pubkey_index + 2]

    ret = {}
    ret['tboot_session']   = txt_stat.length > 60
    ret['measured_launch'] = (parse_line(txt_stat, %r{TXT measured launch}) == 'true') ? true : false
    ret['errorcode']       = parse_line(txt_stat, %r{ERRORCODE})
    ret['pubkey']          = pubkey_raw.each { |l| l.strip! }.join(' ').delete(' ')
    ret
  end
end
