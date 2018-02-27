# A structured fact to tell if IMA expects the files system to be relabeled, is
# in the process of relabeling, or does not need relabeling.
#
# This checks for the existence of a file set by the ``tpm::ima::appraise``
# class and also checks if the script from the same module is running.
#
# return values:
#
# * 'active' if it determines the script is running
# * 'need_relabel' if the file to indicate that a relabel is required exists
# * 'inactive' if the file to indicate a relabel file does not exist
#
Facter.add('ima_security_attr') do
  confine do
    Facter.value(:cmdline).has_key?('ima_appraise_tcb')
  end

  setcode do
    vardir = Facter.value(:puppet_vardir)

  # Check if the script to update the attributes is still running
    isrunning = Facter::Core::Execution.execute('ps -ef')
    if isrunning['ima_security_attr_update.sh'].nil?
      relabel_file = "#{vardir}/simp/.ima_relabel"
      if File.exists?("#{relabel_file}")
        status = 'need_relabel'
      else
        status = 'inactive'
      end
    else
      status = 'active'
    end

    status
  end
end
