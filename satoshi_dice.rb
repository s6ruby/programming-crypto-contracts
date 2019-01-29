# encoding: utf-8

##
#  satoshi dice gambling - up to 65 000x returns on your bet!
#
#  to run type:
#    $ ruby ./satoshi_dice.rb


require_relative './lib/universum'




class SatoshiDice < Contract

  ## type struct - address user; uint block; uint cap; uint amount;
  Bet = Struct.new( :user, :block, :cap, :amount )

  ## Fee is 1 / 100
  FEE_NUMERATOR = 1
  FEE_DENOMINATOR = 100

  MAXIMUM_CAP = 2**16   # 65_536 = 2^16 = 2 byte/16 bit
  MAXIMUM_BET = 100_000_000
  MINIMUM_BET = 100

  class BetPlaced < Event
    ## type uint id, address user, uint cap, uint amount
    def initialize( id, user, cap, amount )
      @id, @user, @cap, @amount = id, user, cap, amount
    end
  end

  class Roll < Event
    ## type uint id, uint rolled
    def initialize( id, rolled )
      @id, @rolled = id, rolled
    end
  end


  def initialize
    @owner   = msg.sender
    @counter = 0
    @bets    = {}   ## type mapping(uint => Bet)

    @balance = 0   ## keep track of contract balance "by hand" for now (todo/fix: make it "automatic/builtin")
  end

  def bet( cap )
     require( cap >= 1 && cap <= MAXIMUM_CAP )
     require( msg.value >= MINIMUM_BET && msg.value <= MAXIMUM_BET )

     @counter += 1
     @bets[@counter] = Bet.new( msg.sender, block.number+3, cap, msg.value )
     @balance += msg.value   ## fix/todo: track remaining balance "by hand" for now
     log BetPlaced.new( @counter, msg.sender, cap, msg.value )
  end

  def roll( id )
    bet = @bets[id]

    require( msg.sender == bet.user )
    require( block.number >= bet.block )
    require( block.number <= bet.block + 255 )

    ## "provable" fair - random number depends on
    ##  - blockhash (of block in the future - t+3)
    ##  - nonce (that is, bet counter id)
    hex = sha256( "#{blockhash( bet.block )} #{id}" )
    ## get first 2 bytes (4 chars in hex string) and convert to integer number
    ##   results in a number between 0 and 65_535
    rolled = hex[0,4].to_i(16)
    puts "rolled: #{rolled} - hex: #{hex[0,4]}"

    if rolled < bet.cap
       payout = bet.amount * MAXIMUM_CAP / bet.cap
       fee = payout * FEE_NUMERATOR / FEE_DENOMINATOR
       payout -= fee
       puts "bingo! payout: #{payout}, fee: #{fee}"

       msg.sender.transfer( payout )
       @balance -= payout   ## fix/todo: track remaining balance "by hand" for now
    end

    log Roll.new( id, rolled )
    @bets.delete( id )
  end

  def fund
    @balance += msg.value  ## fix/todo: track remaining balance "by hand" for now
  end

  def kill
    require( msg.sender == @owner )
    selfdestruct( @owner )
  end
end



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

# Uni.msg = { sender: '0x1111', value: 1_000 }
# dice.fund
Uni.send_transaction( :fund, from: '0x1111', to: dice, value: 1_000 )
pp dice


# Uni.msg = { sender: '0xaaaa', value: 100 }
# dice.bet( 20_000 )
Uni.send_transaction( :bet, data: [20_000], from: '0xaaaa', to: dice, value: 100 )
pp dice

# Uni.msg = { sender: '0xbbbb', value: 100 }
# dice.bet( 30_000 )
Uni.send_transaction( :bet, data: [30_000], from: '0xbbbb', to: dice, value: 100 )
pp dice

## "mine" some blocks - block number (height) set to 3 and timestamp to Time.now
Uni.block = { timestamp: Time.now.to_i, number: 3 }


# Uni.msg = { sender: '0xaaaa' }
# dice.roll( 1 )
Uni.send_transaction( :roll, data: [1], from: '0xaaaa', to: dice )
pp dice

# Uni.msg = { sender: '0xbbbb' }
# dice.roll( 2 )
Uni.send_transaction( :roll, data: [2], from: '0xbbbb', to: dice )
pp dice

## pretty print (pp) all known accounts with balance
pp Uni.accounts
