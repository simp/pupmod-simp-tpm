require 'spec_helper'

describe 'tpm' do

  let(:params) {{
    :use_ima => true
  }}

  let(:facts) {{
    :cmdline => {'foo' => 'bar'},
    :operatingsystem => 'RedHat',
    :lsbmajdistrelease => '7'
  }}

  it { should compile.with_all_deps }
  it { should create_class('tpm') }
  it { should contain_class('tpm::ima') }

end
