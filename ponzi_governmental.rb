# encoding: utf-8

##
# a "real world" ponzi (scheme) contract
#   see http://governmental.github.io/GovernMental
#   last investor wins the jackpot!
#
#  for live installation on ethereum with code (in solidity)
#   see  https://etherscan.io/address/0xF45717552f12Ef7cb65e95476F217Ea008167Ae3#code
#
#  to run type:
#    $ ruby ./run_ponzi_governmental.rb

##
# note: comments are the "original" anti-government rant comments
#   from the solidity source code


class Governmental < Contract

  MINIMUM_INVESTMENT = 1_000_000 

  TWELVE_HOURS       = 43_200        ## in seconds e.g. 12h*60min*60secs


  def initialize
    ## The corrupt elite establishes a new government
    ## this is the commitment of the corrupt Elite - everything that can not be saved from a crash
    @profit_from_crash       = msg.value        ## type uint public
    @corrupt_elite           = msg.sender       ## type address public
    @last_time_of_new_credit = block.timestamp  ## type uint public

    @creditor_addresses = []                    ## type address[] public
    @creditor_amounts   = []                    ## type uint[] public
    @buddies = Mapping.of( Address => Integer ) ## type mapping (address => uint) buddies

    @round = 0                                  ## type uint8 public
    @last_creditor_paid_out = 0                 ## type uint32 public

    ## todo/fix: add/sub value "by hand" from/to balance for now in constructor (make auto-matic!!!)
    _add( msg.value )
    msg.sender._sub( msg.value )
  end


  def lend_government_money( buddy )
    amount = msg.value

    ## check if the system already broke down. If for 12h no new creditor gives new credit to the system it will brake down.
    ## 12h are on average = 12h*60min*60secs/12.5 = 3456 blocks
    if @last_time_of_new_credit + TWELVE_HOURS < block.timestamp
      ## Return money to sender
      msg.sender.send( amount )
      ## Sends all contract money to the last creditor
      @creditor_addresses[ @creditor_addresses.length-1].send( @profit_from_crash )
      @corrupt_elite.send( balance )
      ## Reset contract state
      @last_creditor_paid_out = 0
      @last_time_of_new_credit = block.timestamp
      @profit_from_crash = 0
      @creditor_addresses = []
      @creditor_amounts   = []
      @round += 1
      return false
    else
      ## the system needs to collect at least 1% of the profit from a crash to stay alive
      if amount >= MINIMUM_INVESTMENT
        ## the System has received fresh money, it will survive at leat 12h more
        @last_time_of_new_credit = block.timestamp;
        ## register the new creditor and his amount with 10% interest rate
        @creditor_addresses.push( msg.sender )
        @creditor_amounts.push( amount * 110 / 100 )

        ## now the money is distributed

        ## first the corrupt elite grabs 5% - thieves!
        @corrupt_elite.send( amount * 5/100 )

        ## 5% are going into the economy (they will increase the value for the person seeing the crash comming)
        if @profit_from_crash < 10_000 * MINIMUM_INVESTMENT
          @profit_from_crash += amount * 5/100
        end

        ## if you have a buddy in the government (and he is in the creditor list) he can get 5% of your credits.
        ## Make a deal with him.
        if @buddies[buddy] >= amount
          buddy.send( amount * 5/100 )
        end

        @buddies[ msg.sender ] += amount * 110 / 100

        ## 90% of the money will be used to pay out old creditors
        if @creditor_amounts[ @last_creditor_paid_out] <= balance - @profit_from_crash
          @creditor_addresses[ @last_creditor_paid_out ].send( @creditor_amounts[@last_creditor_paid_out] )

          @buddies[ @creditor_addresses[ @last_creditor_paid_out ]] = 0
          @last_creditor_paid_out += 1
        end
        return true
      else
        msg.sender.send( amount )
        return false
      end
    end
  end # method lend_government_money


  def process
    lend_government_money( '0x0000' )   ## sorry - no buddy (e.g. '0x0000') in government gets 5% "referral" fee
  end


  def total_debt    ## returns type uint debt
    debt = 0
    (@last_creditor_paid_out...@creditor_amounts.length).each do |i|
      debt += @creditor_amounts[i]
    end
    debt
  end

  def total_paid_out   ## returns type uint payout
    payout = 0
    (0...@last_creditor_paid_out).each do |i|
      payout += @creditor_amounts[i]
    end
    payout
  end

  ## better don't do it (unless you are the corrupt elite and you want to establish trust in the system)
  def invest_in_the_system
    @profit_from_crash += msg.value
  end

  ## From time to time the corrupt elite inherits it's power to the next generation
  def inherit_to_next_generation( next_generation )
    if msg.sender == @corrupt_elite
      @corrupt_elite = next_generation
    end
  end
end   # class Governmental
