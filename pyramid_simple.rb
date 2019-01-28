# encoding: utf-8

##
# a simple pyramid (scheme) contract
#   last investors (or suckers) HODLing the bag
#
#  to run / test - use:
#    $ ruby ./pyramid_simple.rb


require_relative './lib/universum'


class SimplePyramid < Contract

  MINIMUM_INVESTMENT = 1_000_000  # unit   # use 1e15 - why? why not?

  def initialize
    require( msg.value >= MINIMUM_INVESTMENT )

    @depth       = 1   # current depth / pyramid level
    @next_payout = 3   # start first payout with 3 investors (1 / 2,3) on depth+1 (e.g. 2nd) level

    @investors = []    # type address[] - array of address
    @investors.push( msg.sender )

    @balances = Hash.new(0)  # hash mapping with default value 0
    @balances[ address(this) ] = msg.value
  end

  def call   # @payable @public
    require( msg.value >= MINIMUM_INVESTMENT )
    @balances[ address(this) ] += msg.value

    @investors.push( msg.sender )

    if( @investors.size == @next_payout )
      # payout previous layer in pyramid
      ## e.g. with depth=1 (investors=3 e.g. 1+2)  - 2**1=2 // 2**0=1
      ##       - end_index:    1 = 3 - 2
      ##       - start_index:  0 = 1 - 1
      ##      with depth=2 (investors=7 e.g. 1+2+4)  - 2**2=4 // 2**1=2
      ##       - end_index:    3 = 7 - 4
      ##       - start_index:  1 = 3 - 2
      ##      with depth=3 (inverstors=15 e.g. 1+2+4+8) - 2**3=8 // 2**2=4
      ##       - end_index:    7 = 15 - 8
      ##       - start_index:  3  = 7 - 4
      ##  ...
      end_index   = @investors.size - 2**@depth
      start_index = end_index - 2**(@depth-1)

      puts "depth: #{@depth}, investors: #{@investors.size}, start_index: #{start_index}, end_index: #{end_index}"

      # note: use ... (three dots) NOT .. (two dots) to exclude end index
      (start_index...end_index).each do |index|
        @balances[ @investors[index] ] += MINIMUM_INVESTMENT
        puts "payout investment for ##{index+1} - yes, it works!"
      end

      ## share remaining balance among all
      paid  = MINIMUM_INVESTMENT * 2**(@depth-1)
      share = (@balances[ address(this) ] - paid) / @investors.size
      puts "paid out: #{paid}, remaining share / investor: #{share}"

      @investors.each do |investor|
        @balances[investor] += share
      end

      ## update pyramid state
      @balances[ address(this) ] = 0
      @depth += 1
      @next_payout += 2**@depth
    end
  end

  def withdraw
    payout = @balances[msg.sender]
    @balances[msg.sender] = 0
    msg.sender.transfer( payout )
  end

end  # class SimplePyramid



###
# test contract

## setup test accounts with starter balance
Account[ '0xaa11' ].balance = 1_000_000
Account[ '0xaa22' ].balance = 1_000_000
Account[ '0xbb11' ].balance = 1_000_000
Account[ '0xbb22' ].balance = 1_000_000
Account[ '0xbb33' ].balance = 1_000_000
Account[ '0xbb44' ].balance = 1_000_000
Account[ '0xcc11' ].balance = 1_000_000
Account[ '0xcc22' ].balance = 1_000_000

## dump (show) all known accounts with balance
pp Uni.accounts

## genesis (founder)
Uni.msg = { sender: '0x0000', value: 1_000_000 }
pyramid = SimplePyramid.new
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

## dump (show) all known accounts with balance
pp Uni.accounts

pyramid.send_transaction( :withdraw, from: '0x0000' )
pp pyramid

## dump (show) all known accounts with balance
pp Uni.accounts
