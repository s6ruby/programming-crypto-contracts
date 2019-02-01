# encoding: utf-8

require_relative './lib/universum'
require_relative './ponzi_gradual'


###
# test contract

## setup test accounts with starter balance
Account[ '0x1111' ].balance = 0
Account[ '0xaaaa' ].balance = 1_000_000
Account[ '0xbbbb' ].balance = 1_000_000
Account[ '0xcccc' ].balance = 1_000_000
Account[ '0xdddd' ].balance = 1_000_000

## pretty print (pp) all known accounts with balance
pp Uni.accounts


Uni.msg = { sender: '0x1111' }
ponzi = GradualPonzi.new
pp

Uni.send_transaction( from: '0xaaaa', to: ponzi, value: 1_000_000 )
pp ponzi

Uni.send_transaction( from: '0xbbbb', to: ponzi, value: 1_000_000 )
pp ponzi

Uni.send_transaction( from: '0xcccc', to: ponzi, value: 1_000_000 )
pp ponzi

Uni.send_transaction( from: '0xdddd', to: ponzi, value: 1_000_000 )
pp ponzi

## pretty print (pp) all known accounts with balance
pp Uni.accounts

Uni.send_transaction( from: '0xaaaa', to: ponzi, data: [:withdraw] )
pp ponzi

## pretty print (pp) all known accounts with balance
pp Uni.accounts
