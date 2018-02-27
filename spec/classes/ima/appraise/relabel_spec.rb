require 'spec_helper'


describe 'tpm::ima::appraise::relabel' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let (:default_facts) do
        os_facts.merge({
          :cmdline => { 'ima_appraise' => 'fix' }
        })
      end

      context 'with relabel true' do
        let (:params) {{
          relabel_file: '/tmp/stuff',
          scriptdir: '/myscripts'
        }}

        context 'with ima_security_attr active' do
          let (:facts) do
            default_facts.merge({
              :ima_security_attr => 'active'
            })
          end

          it { is_expected.to contain_notify('IMA updates running')}
        end

        context 'with ima_security_attr inactive' do
          let (:facts) do
            default_facts.merge({
              :ima_security_attr => 'inactive'
            })
          end

          it { is_expected.to contain_class('tpm::ima::appraise::enforcemode')}
        end

        context 'with ima_security_attr relabel' do
          let (:facts) do
            default_facts.merge({
              :ima_security_attr => 'relabel'
            })
          end

          it { is_expected.to contain_notify('IMA updates started')}
          it { is_expected.to contain_exec('ima_security_attr_update').with({
            'command'    => '/myscripts/ima_security_attr_update.sh /tmp/stuff &',
          })}
        end
      end
    end
  end
end
