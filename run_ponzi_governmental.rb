# encoding: utf-8

require 'universum'

require_relative './ponzi_governmental'


###
# test contract

## setup test accounts with starter balance
Account[ '0x1111' ].balance = 1_000_000
Account[ '0xaaaa' ].balance = 1_000_000
Account[ '0xbbbb' ].balance = 1_000_000
Account[ '0xcccc' ].balance = 1_000_000
Account[ '0xdddd' ].balance = 1_000_000
Account[ '0xeeee' ].balance = 1_000_000

## (pp) pretty print all known accounts with balance
pp Uni.accounts

## genesis - create contract
gov = Uni.send_transaction( from: '0x1111', value: 1_000_000, data: Governmental ).contract
pp gov

Uni.send_transaction( from: '0xaaaa', to: gov, value: 1_000_000 )
pp gov
Uni.send_transaction( from: '0xbbbb', to: gov, value: 1_000_000, data: [:lend_government_money, '0xaaaa'] )
pp gov
Uni.send_transaction( from: '0xcccc', to: gov, value: 1_000_000 )
pp gov
Uni.send_transaction( from: '0xdddd', to: gov, value: 1_000_000 )
pp gov

## (pp) pretty print all known accounts with balance
pp Uni.accounts

## mine - move block time ahead more than 12h (use 13h)
Uni.block = { number: 1, timestamp: Time.now.to_i + 60*60*13 }

## economy will collapse and new (ponzi) round starts
Uni.send_transaction( from: '0xeeee', to: gov, value: 1_000_000 )
pp gov

## (pp) pretty print all known accounts with balance
pp Uni.accounts
