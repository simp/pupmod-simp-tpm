require 'spec_helper_acceptance'
require 'json'

test_name 'tpm::ima class'

describe 'tpm::ima class' do
  hosts.each do |host|
    it 'should set a root password' do
      on(host, "sed -i 's/enforce_for_root//g' /etc/pam.d/*")
      on(host, 'echo "root:password" | chpasswd --crypt-method SHA256')
    end
  end

  context 'normal, loose rules' do
    hosts.each do |host|
      manifest = <<-EOF
        include 'tpm'
        class { 'tpm::ima':
          manage_policy => true
        }
      EOF

      it 'should run puppet' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'should run puppet idempotently' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end


      it 'should run puppet idempotently after a reboot' do
        # reboot to apply kernel_parameter settings
        host.reboot
        # the mount will need to be reset
        apply_manifest_on(host, manifest, catch_failures: true)

        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'should not lock up the filesystem' do
        on(host, "cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 1000 | head -n 10000 > /root/hugefile")
        on(host, 'head -15 /sys/kernel/security/ima/ascii_runtime_measurements')
        on(host, 'ls -la ~')
      end
    end
  end

  context 'stricter rules' do
    hosts.each do |host|
      manifest = <<-EOF
        include 'tpm'
        include 'tpm::ima'
        class { 'tpm::ima::policy':
          measure_root_read_files => true,
          measure_file_mmap       => true,
          measure_bprm_check      => true,
          measure_module_check    => true,
          appraise_fowner         => true,
        }
      EOF

      it 'should run puppet' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'should run puppet idempotently' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end


      it 'should run puppet idempotently after a reboot' do
        # reboot to apply kernel_parameter settings
        host.reboot
        # the mount will need to be reset
        apply_manifest_on(host, manifest, catch_failures: true)

        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'should not lock up the filesystem' do
        on(host, "cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 1000 | head -n 10000 > /root/hugefile")
        on(host, 'head -15 /sys/kernel/security/ima/ascii_runtime_measurements')
        on(host, 'ls -la ~')
      end
    end
  end

  context 'even more strict rules' do
    hosts.each do |host|
      manifest = <<-EOF
        include 'tpm'
        include 'tpm::ima'
        class { 'tpm::ima::policy':
          measure_root_read_files    => true,
          measure_file_mmap          => true,
          measure_bprm_check         => true,
          measure_module_check       => true,
          appraise_fowner            => true,
          dont_watch_rpm_var_cache_t => false,
          dont_watch_puppet_log_t    => false,
          dont_watch_lastlog_t       => false,
        }
      EOF

      it 'should run puppet' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'should run puppet idempotently' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end


      it 'should run puppet idempotently after a reboot' do
        # reboot to apply kernel_parameter settings
        host.reboot
        # the mount will need to be reset
        apply_manifest_on(host, manifest, catch_failures: true)

        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'may lock up the filesystem' do
        on(host, 'yum install -y tree')
        host.reboot
        on(host, 'head -15 /sys/kernel/security/ima/ascii_runtime_measurements')
        on(host, 'ls -la ~')
      end
    end
  end
end
