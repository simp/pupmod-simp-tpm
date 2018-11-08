#!/usr/bin/env ruby

def tpm_takeownership
  system "stty -echo"

  print 'Enter owner password: '
  owner_pass = gets.chomp
  print "\nConfirm password: "
  owner_pass_confirm = gets.chomp

  if !owner_pass.eql? owner_pass_confirm
    puts "\nPasswords didn't match"
    return 255
  else
    puts
  end

  print 'Enter SRK password: '
  srk_pass = gets.chomp
  print "\nConfirm password: "
  srk_pass_confirm = gets.chomp

  if !srk_pass.eql? srk_pass_confirm
    puts "\nPasswords didn't match"
    return 255
  end

  system "stty echo"
  puts
  return 0
end

if ENV['MOCK_TIMEOUT'] == 'yes'
  sleep 30
  exit 255 # tpm_takeownership
else
  exit tpm_takeownership
end
