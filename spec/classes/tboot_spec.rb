require 'spec_helper'

describe 'tpm::tboot' do

  let(:facts) {{
    :operatingsystem => 'RedHat',
    :operatingsystemmajrelease => '7'
  }}

  it { should compile.with_all_deps }
  it { should create_class('tpm::tboot') }

  context 'enabling_tboot' do

    let(:facts) {{
      :cmdline => { 'foo' => 'bar' },
      :has_tpm => 'true',
      :operatingsystem => 'RedHat',
      :operatingsystemmajrelease => '7'
    }}

    it { should compile.with_all_deps }
    it { should contain_package('tboot') }

  end

  context 'disabling_tboot' do
    let(:params) {{ :enable => false }}

    it { should compile.with_all_deps }
    it { should contain_package('tboot').with_ensure('absent') }

  end
end
