# Detects the size if the IMA log in bytes
Facter.add('ima_log_size') do
  setcode do
    f = "/sys/kernel/security/ima/ascii_runtime_measurements"

    if File.exists? f
      Facter::Core::Execution.execute("wc -c #{f}").to_i
    end
  end
end
