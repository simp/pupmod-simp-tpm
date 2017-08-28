# TPM Utility Functions
#
module Facter
  module TPM
    class Util

      attr_accessor :result

      def initialize(sys_path)
        @sys_path = sys_path

        @result = {
          'sys_path' => sys_path,
          'version'  => version,
          'status'   => status
        }

        @result['pubek'] = pubek(@result['status'])
      end

      private

      # Get the pubek from tpm_getpubek when the TPM is owned
      # @param [String] the owner password of the TPM
      # @return [String] the output of the command, or nil if it times out
      #
      def get_pubek_owned(owner_pass, cmd = '/sbin/tpm_getpubek')
        require 'expect'
        require 'pty'

        out = ''

        begin
          if owner_pass == 'well-known'
            Puppet.debug('running tpm_getpubek using well-known option')
            out = Facter::Core::Execution.execute('tpm_getpubek -z', :timeout => 15)
          else
            Puppet.debug('running tpm_getpubek')
            ary = []
            PTY.spawn(cmd) do |r,w,pid|
              w.sync = true
              begin
                r.expect( /owner password/i, 15 ) { |s| w.puts owner_pass }
                r.each { |line| ary << line }
              rescue Errno::EIO
                # just until the end of the IO stream
              end
              Process.wait(pid)
            end
            out = ary.join("\n")
          end
        rescue Facter::Core::Execution::ExecutionFailure
          Puppet.debug('tpm_getpubek timed out!')
          out = nil
        end

        out
      end

      # Get the pubek from tpm_getpubek when the TPM isn't owned
      # @return [String] the output of the command, or nil if it times out
      #
      def get_pubek_unowned
        begin
          Puppet.debug('running tpm_getpubek')
          status = Facter::Core::Execution.execute('tpm_getpubek', :timeout => 15)
        rescue Facter::Core::Execution::ExecutionFailure
          Puppet.debug('tpm_getpubek timed out!')
          status = 'error: tpm_getpubek timed out'
        end

        status
      end

      # Get the output of tpm_version
      # @return [String] the output of the command, or nil if it times out
      #
      def tpm_version
        begin
          Puppet.debug('running tpm_version')
          status = Facter::Core::Execution.execute('tpm_version', :timeout => 15)
        rescue Facter::Core::Execution::ExecutionFailure
          Puppet.debug('tpm_version timed out!')
          status = nil
        end

        status
      end

      # @return [Hash] the yaml output from `tpm_version`
      #
      # The output of tpm_version just so happens to be valid yaml, and
      # it is parsed as such.
      #
      # Example output:
      #  ```
      #    TPM 1.2 Version Info:
      #    Chip Version:        1.2.18.60
      #    Spec Level:          2
      #    Errata Revision:     3
      #    TPM Vendor ID:       IBM
      #    TPM Version:         01010000
      #    Manufacturer Info:   49424d00
      #  ```
      #
      def version
        require 'yaml'

        output = Hash.new
        cmd_out = tpm_version

        if cmd_out == "" or cmd_out.nil?
          output['_status'] = 'Trousers is not running'
          return output
        else
          version = YAML.load(cmd_out)

          # Format keys in a way that Facter will like
          begin
            output = Hash[version.flatten[1].map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }]
          rescue NoMethodError
            version.delete_if { |k,y| k =~ /Version Info/ }
            output = Hash[version.map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }]
          end

          output['_status'] = 'tpm_version loaded correctly'
        end

        output
      end

      # @return [Hash] information about the TPM from /sys/class/tpm/tpm0/
      #
      def status
        require 'yaml'

        ignore_list = [ 'pubek','cancel','options' ]
        files = Dir.glob("#{@sys_path}/device/*")

        out = Hash.new

        files.each do |file|
          next if File.directory?(file)
          next if ignore_list.include? File.basename(file)

          raw = YAML.load_file(file)
          if raw.is_a? Hash
            out[File.basename(file)] = Hash[raw.map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }]
          else
            out[File.basename(file)] = raw
          end
        end

        out
      end

      # If the TPM is unowned, it can be retreived simply with the command. However,
      #   when the TPM is owned, the command asks for a password. We use an
      #   an interactive PTY to get around this restriction.
      #
      # @param [Boolean] whether or not the TPM is owned
      # @return [Hash] the TPM public key, including the raw key in `['raw']`
      #
      def pubek(status)
        pass_file = "#{Puppet[:vardir]}/simp/tpm_ownership_owner_pass"
        enabled   = status['enabled'] == 1
        owned     = status['owned'] == 1

        out = Hash.new
        raw = ''

        if !enabled
          out['_status'] = 'error: tpm not enabled'
          return out
        elsif !owned
          raw = get_pubek_unowned
          out['_status'] = 'success: tpm unowned'
        else
          if File.exists?(pass_file)
            owner_pass = Facter::Core::Execution.execute("cat #{pass_file} 2> /dev/null")
            if owner_pass.eql? ""
              out['_status'] = 'error: the password file is empty'
              return out
            else
              raw = get_pubek_owned(owner_pass)
              out['_status'] = 'success: raw pubek grabbed' unless raw.nil?
            end
          else
            out['_status'] = 'error: password file not found'
            return out
          end
        end

        if raw.nil? or raw == ""
          out['_status'] = 'error: trousers is not running, the tpm is not enabled, or the password in the password file is incorrect'
        else
          pubek = YAML.load(raw.gsub(/\t/,' '*4).split("\n").drop(1).join("\n"))
          pubek['Public Key'].to_s.gsub!(/ /, '')
          pubek['raw'] = raw
          out.merge!( Hash[pubek.map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }] )
          out['_status'] = 'success: raw parsed'
        end

        out
      end
    end
  end
end
