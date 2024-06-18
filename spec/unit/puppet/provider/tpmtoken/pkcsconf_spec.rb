require 'spec_helper'
require 'json'

describe Puppet::Type.type(:tpmtoken).provider(:pkcsconf) do

  let(:resource) {
    Puppet::Type.type(:tpmtoken).new({
      :name     => 'IBM PKCS11 TPM Token',
      :so_pin   => '123456',
      :user_pin => '12345678',
      :provider => 'pkcsconf'
    })
  }
  let(:provider) { resource.provider }

  let(:pkcsconf_t_out) {
    File.read(File.expand_path('spec/files/pkcsconf_t.out'))
  }
  let(:pkcsconf_t_hash) {
    j = JSON.parse(
      File.read(File.expand_path('spec/files/pkcsconf_t_hash.json')),
      :symbolize_names => true
    )

    j.each do |r|
      r.map do |k,v|
        r.merge!( { k => v.to_sym } ) if v.eql? "present"
      end
    end
  }

  before(:each) do
    allow(provider).to receive(:pkcsconf).with(['-t']).and_return(pkcsconf_t_out)
    allow(provider.class).to receive(:pkcsconf).with(['-t']).and_return(pkcsconf_t_out)
    allow(provider).to receive(:new).and_return(pkcsconf_t_hash[0], pkcsconf_t_hash[1])
  end

  after :each do
    ENV['MOCK_TIMEOUT'] =  nil
  end

  # context 'default' do
  #   let(:resource) {
  #     Puppet::Type.type(:pkcs_slot).new({
  #       :name    => 'IBM PKCS11 TPM Token',
  #       :so_pin   => '123456',
  #       :user_pin => '12345678',
  #       :provider => 'pkcsconf'
  #     })
  #   }
  #
  # end

  describe 'instances' do
    it 'should take output from pkcsconf -t and turn it into a hash' do
      expect(provider.class.read_tokens).to eq(pkcsconf_t_hash)
    end
  end

  describe 'tpmtoken_init' do
    let(:stdin) {[
      [ /Enter new password:/i, resource[:so_pin]   ],
      [ /Confirm password/i,    resource[:so_pin]   ],
      [ /Enter new password:/i, resource[:user_pin] ],
      [ /Confirm password/i,    resource[:user_pin] ],
    ]}
    let(:mock_script) { File.expand_path('spec/files/mock_tpmtoken_init.rb') }

    it 'should interact with the script normally' do
      expect(provider.tpmtoken_init( stdin, mock_script )).to be_truthy
    end

    # it 'should interact with the script normally' do
    #   ENV['MOCK_TIMEOUT'] = 'yes'
    #   expect(provider.tpmtoken_init( stdin, mock_script )).to be_falsey
    # end

  end

end
