# encoding: utf-8

##
# a "real world" ponzi (scheme) contract
#   see http://governmental.github.io/GovernMental
#   last investor wins the jackpot!
#
#  for live installation on ethereum with code (in solidity)
#   see  https://etherscan.io/address/0xF45717552f12Ef7cb65e95476F217Ea008167Ae3#code
#
#  to run / test - use:
#    $ ruby ./ponzi_governmental.rb

##
# note: comments are the "original" anti-government rant comments
#   from the solidity source code


require_relative './lib/universum'



class Governmental < Contract

  MINIMUM_INVESTMENT = 1_000_000   # unit   # use 1e15 - why? why not?

  TWELVE_HOURS = 43_200    ## in seconds e.g. 12*60*60


  def initialize
    ## The corrupt elite establishes a new government
    ## this is the commitment of the corrupt Elite - everything that can not be saved from a crash
    @profit_from_crash       = msg.value        ## type uint public
    @corrupt_elite           = msg.sender       ## type address public
    @last_time_of_new_credit = block.timestamp  ## type uint public

    @creditor_addresses = []    ## type address[] public
    @creditor_amounts   = []    ## type uint[] public
    @buddies = Hash.new(0)      ## type mapping (address => uint) buddies

    @round = 0                   ## type uint8 public
    @last_creditor_paid_out = 0  ## type uint32 public

    @balance = 0   ## keep track of contract balance "by hand" for now (todo/fix: make it "automatic/builtin")
  end


  def lend_government_money( buddy )
    amount = msg.value

    ## check if the system already broke down. If for 12h no new creditor gives new credit to the system it will brake down.
    ## 12h are on average = 60*60*12/12.5 = 3456
    if @last_time_of_new_credit + TWELVE_HOURS < block.timestamp
      ## Return money to sender
      msg.sender.send( amount )
      ## Sends all contract money to the last creditor
      @creditor_addresses[ @creditor_addresses.length-1].send( @profit_from_crash )
      @balance -= @profit_from_crash   ## fix/todo: track remaining balance "by hand" for now
      @corrupt_elite.send( @balance )
      ## Reset contract state
      @last_creditor_paid_out = 0
      @last_time_of_new_credit = block.timestamp
      @profit_from_crash = 0
      @balance = 0                    ## fix/todo: track remaining balance "by hand" for now
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
        paid_out = 0                ## fix/todo: track remaining balance "by hand" for now

        ## first the corrupt elite grabs 5% - thieves!
        @corrupt_elite.send( amount * 5/100 )
        paid_out += amount * 5/100   ## fix/todo: track remaining balance "by hand" for now

        ## 5% are going into the economy (they will increase the value for the person seeing the crash comming)
        if @profit_from_crash < 10_000 * MINIMUM_INVESTMENT
          @profit_from_crash += amount * 5/100
        end

        ## if you have a buddy in the government (and he is in the creditor list) he can get 5% of your credits.
        ## Make a deal with him.
        if @buddies[buddy] >= amount
          buddy.send( amount * 5/100 )
          paid_out += amount * 5/100   ## fix/todo: track remaining balance "by hand" for now
        end

        @buddies[ msg.sender ] += amount * 110 / 100

        ## 90% of the money will be used to pay out old creditors
        if @creditor_amounts[ @last_creditor_paid_out] <= (@balance + amount - paid_out) - @profit_from_crash
          @creditor_addresses[ @last_creditor_paid_out ].send( @creditor_amounts[@last_creditor_paid_out] )

          paid_out += @creditor_amounts[@last_creditor_paid_out]   ## fix/todo: track remaining balance "by hand" for now

          @buddies[ @creditor_addresses[ @last_creditor_paid_out ]] = 0
          @last_creditor_paid_out += 1
        end

        ## fix/todo: update balance and track remaining balance "by hand" for now
        if paid_out >= 0
          @balance += amount - paid_out
        else ## note: if negative more paid out than in msg.value (reduce balance)
          @balance -= paid_out.abs    # abs (= absolute value, that is, always with minus e.g. turn -12 into 12)
        end

        return true
      else
        msg.sender.send( amount )
        return false
      end
    end
  end # method lend_government_money


  def call
    lend_government_money( 0 )   ## sorry - no buddy (e.g. 0) in government gets 5% "referral" fee
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
      @corrupt_elite = @next_generation
    end
  end
end   # class Governmental




###
# test contract

## setup test accounts with starter balance
Account[ '0xaaaa' ].balance = 1_000_000
Account[ '0xbbbb' ].balance = 1_000_000
Account[ '0xcccc' ].balance = 1_000_000
Account[ '0xdddd' ].balance = 1_000_000
Account[ '0xeeee' ].balance = 1_000_000

## (pp) pretty print all known accounts with balance
pp Uni.accounts

## genesis (founder)
Uni.msg = { sender: '0x0000', value: 1_000_000 }
gov = Governmental.new
pp gov

Uni.send_transaction( from: '0xaaaa', to: gov, value: 1_000_000 )
pp gov
Uni.send_transaction( from: '0xbbbb', to: gov, value: 1_000_000 )
pp gov
Uni.send_transaction( from: '0xcccc', to: gov, value: 1_000_000 )
pp gov
Uni.send_transaction( from: '0xdddd', to: gov, value: 1_000_000 )
pp gov
Uni.send_transaction( from: '0xeeee', to: gov, value: 1_000_000 )
pp gov

## (pp) pretty print all known accounts with balance
pp Uni.accounts

puts "totals:"
puts "  debt (remaining): #{gov.total_debt}"
puts "  paid out: #{gov.total_paid_out}"
