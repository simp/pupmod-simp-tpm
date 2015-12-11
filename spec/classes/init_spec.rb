require 'spec_helper'

describe 'tpm' do

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:params) {{ :use_ima => true }}

      let(:facts) do
        os_facts.merge({
          :cmdline => {'foo' => 'bar'},
          :operatingsystem => 'RedHat',
          :lsbmajdistrelease => '7'
        })
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to create_class('tpm') }
      it { is_expected.to contain_class('tpm::ima') }
      it { is_expected.to contain_kernel_parameter('ima_audit').with_value('true') }
    end
  end
end
