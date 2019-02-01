# encoding: utf-8

##
#  satoshi dice gambling - up to 65 000x returns on your bet!
#
#  to run type:
#    $ ruby ./run_satoshi_dice.rb


class SatoshiDice < Contract

  ## type struct - address user; uint block; uint cap; uint amount;
  Bet = Struct.new( :user, :block, :cap, :amount )

  ## Fee (Casino House Edge) is 1.9%, that is, 19 / 1000
  FEE_NUMERATOR   = 19
  FEE_DENOMINATOR = 1000


  MAXIMUM_CAP = 2**16   # 65_536 = 2^16 = 2 byte/16 bit
  MAXIMUM_BET = 100_000_000
  MINIMUM_BET = 100

  BetPlaced = Event.create( :id, :user, :cap, :amount )  ## type uint id, address user, uint cap, uint amount
  Roll      = Event.create( :id, :rolled )               ## type uint id, uint rolled


  def initialize
    @owner   = msg.sender
    @counter = 0
    @bets    = Mapping.of( Integer => Bet )              ## type mapping( uint => Bet )
  end

  def bet( cap )
     require( cap >= 1 && cap <= MAXIMUM_CAP )
     require( msg.value >= MINIMUM_BET && msg.value <= MAXIMUM_BET )

     @counter += 1
     @bets[@counter] = Bet.new( msg.sender, block.number+3, cap, msg.value )
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
    end

    log Roll.new( id, rolled )
    @bets.delete( id )
  end

  def fund    # @payable
  end

  def kill
    require( msg.sender == @owner )
    selfdestruct( @owner )
  end
end
