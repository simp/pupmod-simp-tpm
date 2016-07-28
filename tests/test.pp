#
# class test {
#   include tpm
#
#   tpm_ownership { 'tpm0':
#     ensure     => present,
#     owner_pass => 'badpass2',
#     srk_pass   => 'badpass3'
#   }
# }
#
# include test

# include tpm::ownership

# class { 'tpm::ownership' :
#   advanced_facts => true
# }

include tpm