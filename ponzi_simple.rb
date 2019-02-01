# encoding: utf-8

##
# a simple ponzy (scheme) contract
#   last investor (or sucker) HODLing the bag
#
#  to run type:
#    $ ruby ./run_ponzi_simple.rb



class SimplePonzi < Contract

  def initialize
    @current_investor   = msg.sender   # type address - (hex) string starts with 0x
    @current_investment = 0            # type uint
  end

  def process    ## @payable default function
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
