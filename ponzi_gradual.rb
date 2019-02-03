# encoding: utf-8

##
# a more realistic gradual ponzy (scheme) contract
#   last investors (or suckers) HODLing the bag
#
#  to run type:
#    $ ruby ./run_ponzi_gradual.rb




class GradualPonzi < Contract

  MINIMUM_INVESTMENT = 1_000_000

  def initialize
    @investors = []                                # type address[] - array of address
    @investors.push( msg.sender )

    @balances = Mapping.of( Address => Money )     # type mapping( address => unit )
  end


  def receive    # @payable default function
    assert( msg.value >= MINIMUM_INVESTMENT )

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
