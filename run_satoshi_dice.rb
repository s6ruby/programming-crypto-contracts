# encoding: utf-8

require_relative './lib/universum'
require_relative './satoshi_dice'


## setup test accounts with starter balance
Account[ '0x1111' ].balance = 1_000
Account[ '0xaaaa' ].balance = 1_000
Account[ '0xbbbb' ].balance = 1_000
Account[ '0xcccc' ].balance = 1_000

## pretty print (pp) all known accounts with balance
pp Uni.accounts



Uni.msg = { sender: '0x1111' }
dice = SatoshiDice.new
pp dice

# Uni.this = dice   # current contract
# Uni.msg = { sender: '0x1111', value: 1_000 }
# dice.fund
Uni.send_transaction( from: '0x1111', to: dice, value: 1_000, data: [:fund] )
pp dice


# Uni.msg = { sender: '0xaaaa', value: 100 }
# dice.bet( 20_000 )
Uni.send_transaction( from: '0xaaaa', to: dice, value: 100, data: [:bet, 20_000] )
pp dice

# Uni.msg = { sender: '0xbbbb', value: 100 }
# dice.bet( 30_000 )
Uni.send_transaction( from: '0xbbbb', to: dice, value: 100, data: [:bet, 30_000] )
pp dice

## "mine" some blocks - block number (height) set to 3 and timestamp to Time.now
Uni.block = { timestamp: Time.now.to_i, number: 3 }


# Uni.msg = { sender: '0xaaaa' }
# dice.roll( 1 )
Uni.send_transaction( from: '0xaaaa', to: dice, data: [:roll, 1] )
pp dice

# Uni.msg = { sender: '0xbbbb' }
# dice.roll( 2 )
Uni.send_transaction( from: '0xbbbb', to: dice, data: [:roll, 2] )
pp dice

## pretty print (pp) all known accounts with balance
pp Uni.accounts
