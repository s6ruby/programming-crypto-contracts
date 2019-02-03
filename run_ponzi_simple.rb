# encoding: utf-8

require 'universum'

require_relative './ponzi_simple'


###
# test contract

## setup test accounts with starter balance
Account[ '0x1111' ].balance = 0
Account[ '0xaaaa' ].balance = 1_000_000
Account[ '0xbbbb' ].balance = 1_200_000
Account[ '0xcccc' ].balance = 1_400_000

## pretty print (pp) all known accounts with balance
pp Uni.accounts

## genesis - create contract
ponzi = Uni.send_transaction( from: '0x1111', data: SimplePonzi ).contract
pp ponzi

Uni.send_transaction( from: '0xaaaa', to: ponzi, value: 1_000_000 )
pp ponzi

Uni.send_transaction( from: '0xbbbb', to: ponzi, value: 1_200_000 )
pp ponzi

Uni.send_transaction( from: '0xcccc', to: ponzi, value: 1_400_000 )
pp ponzi

## pretty print (pp) all known accounts with balance
pp Uni.accounts
