# encoding: utf-8

require 'universum'

require_relative './satoshi_dice'


## setup test accounts with starter balance
Account[ '0x1111' ].balance = 1_000
Account[ '0xaaaa' ].balance = 1_000
Account[ '0xbbbb' ].balance = 1_000
Account[ '0xcccc' ].balance = 1_000

## pretty print (pp) all known accounts with balance
pp Uni.accounts


## genesis - create contract
dice = Uni.send_transaction( from: '0x1111', data: SatoshiDice ).contract
pp dice

Uni.send_transaction( from: '0x1111', to: dice, value: 1_000, data: [:fund] )
pp dice

Uni.send_transaction( from: '0xaaaa', to: dice, value: 100, data: [:bet, 20_000] )
pp dice

Uni.send_transaction( from: '0xbbbb', to: dice, value: 100, data: [:bet, 30_000] )
pp dice

## "mine" some blocks - block number (height) set to 3 and timestamp to Time.now
Uni.block = { timestamp: Time.now.to_i, number: 3 }

Uni.send_transaction( from: '0xaaaa', to: dice, data: [:roll, 1] )
pp dice

Uni.send_transaction( from: '0xbbbb', to: dice, data: [:roll, 2] )
pp dice

## pretty print (pp) all known accounts with balance
pp Uni.accounts
