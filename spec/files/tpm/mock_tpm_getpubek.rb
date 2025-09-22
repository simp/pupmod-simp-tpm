#!/usr/bin/env ruby

def tpm_getpubek
  system 'stty -echo'

  print 'Enter owner password: '
  gets.chomp

  system 'stty echo'
  puts
  puts File.read('spec/files/tpm/tpm_getpubek.txt')
  0
end

if ENV['MOCK_TIMEOUT'] == 'yes'
  sleep 20
end
tpm_getpubek
