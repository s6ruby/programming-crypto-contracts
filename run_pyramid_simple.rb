# encoding: utf-8

require 'universum'

require_relative './pyramid_simple'


###
# test contract

## setup test accounts with starter balance
Account[ '0x1111' ].balance = 1_000_000
Account[ '0xaa11' ].balance = 1_000_000
Account[ '0xaa22' ].balance = 1_000_000
Account[ '0xbb11' ].balance = 1_000_000
Account[ '0xbb22' ].balance = 1_000_000
Account[ '0xbb33' ].balance = 1_000_000
Account[ '0xbb44' ].balance = 1_000_000
Account[ '0xcc11' ].balance = 1_000_000
Account[ '0xcc22' ].balance = 1_000_000

## pretty print (pp) all known accounts with balance
pp Uni.accounts

## genesis - create contract
pyramid = Uni.send_transaction( from: '0x1111', value: 1_000_000, data: SimplePyramid ).contract
pp pyramid

## level 1
Uni.send_transaction( from: '0xaa11', to: pyramid, value: 1_000_000 )
pp pyramid
Uni.send_transaction( from: '0xaa22', to: pyramid, value: 1_000_000 )
pp pyramid

## level 2
Uni.send_transaction( from: '0xbb11', to: pyramid, value: 1_000_000 )
pp pyramid
Uni.send_transaction( from: '0xbb22', to: pyramid, value: 1_000_000 )
pp pyramid
Uni.send_transaction( from: '0xbb33', to: pyramid, value: 1_000_000 )
pp pyramid
Uni.send_transaction( from: '0xbb44', to: pyramid, value: 1_000_000 )
pp pyramid

# level 3
Uni.send_transaction( from: '0xcc11', to: pyramid, value: 1_000_000 )
pp pyramid
Uni.send_transaction( from: '0xcc22', to: pyramid, value: 1_000_000 )
pp pyramid

## pretty print (pp) all known accounts with balance
pp Uni.accounts

Uni.send_transaction( from: '0x1111', to: pyramid, data: [:withdraw] )
pp pyramid

## pretty print (pp) all known accounts with balance
pp Uni.accounts
