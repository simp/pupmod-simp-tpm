require 'spec_helper'

describe 'tpm', :type => :fact do

  before :each do
    Facter.clear
    Facter.clear_messages
  end

  it 'is not tested yet' do
    skip('test this?')
  end

end