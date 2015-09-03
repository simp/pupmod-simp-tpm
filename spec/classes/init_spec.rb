require 'spec_helper'

describe 'tpm' do

  let(:params) {{
    :use_ima => true,
    :use_tboot => true
  }}

  let(:facts) {{
    :cmdline => {'foo' => 'bar'},
    :operatingsystem => 'RedHat',
    :lsbmajdistrelease => '7'
  }}

  it { should compile.with_all_deps }
  it { should create_class('tpm') }
  it { should contain_class('tpm::ima') }
  it { should contain_class('tpm::tboot') }

end
