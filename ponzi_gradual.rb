# encoding: utf-8

##
# a more realistic gradual ponzy (scheme) contract
#   last investors (or suckers) HODLing the bag
#
#  to run / test - use:
#    $ ruby ./ponzi_v2.rb


require_relative './lib/universum'


class GradualPonzi < Contract

  MINIMUM_INVESTMENT = 1_000_000  # unit   # use 1e15 - why? why not?

  def initialize
    @investors = []    # type address[] - array of address
    @investors.push( msg.sender )

    @balances = Hash.new(0)   ## type mapping( address => unit )
  end


  def call    ## @payable @public  (default function)
    require( msg.value >= MINIMUM_INVESTMENT )

    investor_share = msg.value / @investors.size
    @investors.each do |investor|
      @balances[investor] += investor_share
    end

    @investors.push( msg.sender )
  end


  def withdraw
    payout = @balances[msg.sender]
    @balances[msg.sender] = 0
    msg.sender.transfer( payout )
  end


end # class GradualPonzi


###
# test contract

## setup test accounts with starter balance
Account[ '0xaaaa' ].balance = 1_000_000
Account[ '0xbbbb' ].balance = 1_000_000
Account[ '0xcccc' ].balance = 1_000_000
Account[ '0xdddd' ].balance = 1_000_000

## dump (show) all known accounts with balance
pp Uni.accounts


ponzi = GradualPonzi.new

Uni.send_transaction( from: '0xaaaa', to: ponzi, value: 1_000_000 )
pp ponzi

Uni.send_transaction( from: '0xbbbb', to: ponzi, value: 1_000_000 )
pp ponzi

Uni.send_transaction( from: '0xcccc', to: ponzi, value: 1_000_000 )
pp ponzi

Uni.send_transaction( from: '0xdddd', to: ponzi, value: 1_000_000 )
pp ponzi

## dump (show) all known accounts with balance
pp Uni.accounts

ponzi.send_transaction( :withdraw, from: '0xaaaa' )
pp ponzi

## dump (show) all known accounts with balance
pp Uni.accounts
