# encoding: utf-8

##
# a simple ponzy (scheme) contract
#   last investor (or sucker) HODLing the bag
#
#  to run / test - use:
#    $ ruby ./ponzi_simple.rb


require_relative './lib/universum'


class SimplePonzi < Contract

  def initialize
    @current_investor   = '0x0000'   # type address - (hex) string starts with 0x
    @current_investment = 0          # type uint
  end


  def call    ## @payable @public  (default function)
    # note: new investments must be 10% greater than current
    minimum_investment = @current_investment * 11/10
    require( msg.value > minimum_investment )

    # record new investor
    previous_investor   = @current_investor
    @current_investor   = msg.sender
    @current_investment = msg.value

    # pay out previous investor
    previous_investor.send( msg.value )
  end

end # class SimplPonzi


###
# test contract

## setup test accounts with starter balance
Account[ '0xaaaa' ].balance = 1_000_000
Account[ '0xbbbb' ].balance = 1_200_000
Account[ '0xcccc' ].balance = 1_400_000

## dump (show) all known accounts with balance
pp Uni.accounts


ponzi = SimplePonzi.new

Uni.send_transaction( from: '0xaaaa', to: ponzi, value: 1_000_000 )
pp ponzi

Uni.send_transaction( from: '0xbbbb', to: ponzi, value: 1_200_000 )
pp ponzi

Uni.send_transaction( from: '0xcccc', to: ponzi, value: 1_400_000 )
pp ponzi

## dump (show) all known accounts with balance
pp Uni.accounts
