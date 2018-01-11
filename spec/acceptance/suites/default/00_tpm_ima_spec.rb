require 'spec_helper_acceptance'
require 'json'

# module Beaker
#   class SshConnection
#     CATCHABLE_EXCEPTIONS = RETRYABLE_EXCEPTIONS
#     RETRYABLE_EXCEPTIONS = []
#   end
# end

def try_to_ssh(host, user, opts)
  begin
    out = Net::SSH.start(host.connection.ip, user, opts).exec!('ls')
  rescue Net::SSH::ConnectionTimeout
    out = 'connection timeout'
  end
  out
end

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
        include 'tpm::ima'
        include 'tpm::ima::policy'
        # class { 'tpm::ima::policy':
        #   set_with_service => false,
        #   set_with_puppet  => false
        # }
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

      it 'locks up the filesystem after a reboot and new policy is applied' do
        # save ssh configuration, it should be the same post-reboot
        ssh_user = host.connection.instance_variable_get(:@user)
        ssh_opts = host[:ssh]
        host.connection.ssh_connection_preference = [:ip]
        expect(on(host, 'ls')).to be_truthy

        # test the saved config
        test = try_to_ssh(host, ssh_user, ssh_opts)
        expect(test).not_to match 'connection timeout'

        host.reboot

        # class BigTimeoutError < Timeout::Error; end

        sleep 30

        # require 'pry';binding.pry

        expect(on(host, 'ls')).to raise_error(/Cannot connect to/)

        # use the saved config, but expect it to fail
        test2 = try_to_ssh(host, ssh_user, ssh_opts)
        expect(test2).to match 'connection timeout'
      end
    end
  end
end
