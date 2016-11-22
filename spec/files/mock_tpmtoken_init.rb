#!/usr/bin/env ruby

def tpmtoken_init
  system "stty -echo"

  puts 'A new TPM security officer password is needed. The password must be between 4 and 8 characters in length.'
  print 'Enter new password: '
  owner_pass = gets.chomp
  print "\nConfirm password: "
  owner_pass_confirm = gets.chomp

  if !owner_pass.eql? owner_pass_confirm
    puts "\nPasswords didn't match"
    return 1
  else
    puts
  end

  sleep 2

  puts 'A new TPM user password is needed. The password must be between 4 and 8 characters in length.'
  print 'Enter new password: '
  srk_pass = gets.chomp
  print "\nConfirm password: "
  srk_pass_confirm = gets.chomp

  if !srk_pass.eql? srk_pass_confirm
    puts "\nPasswords didn't match"
    return 1
  end

  sleep 2

  system "stty echo"
  puts
  return 0
end

if ENV['MOCK_TIMEOUT'] == 'yes'
  sleep 30
  tpmtoken_init
else
  tpmtoken_init
end