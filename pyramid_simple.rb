# encoding: utf-8

##
# a simple pyramid (scheme) contract
#   last investors (or suckers) HODLing the bag
#
#  to run type:
#    $ ruby ./run_pyramid_simple.rb



class SimplePyramid < Contract

  MINIMUM_INVESTMENT = 1_000_000  # unit   # use 1e15 - why? why not?

  def initialize
    require( msg.value >= MINIMUM_INVESTMENT )

    @depth       = 1   # current depth / pyramid level
    @next_payout = 3   # start first payout with 3 investors (1 / 2,3) on depth+1 (e.g. 2nd) level

    @investors = []    # type address[] - array of address
    @investors << msg.sender

    @balances = Hash.new(0)  # hash mapping with default value 0
    @balances[ address ] = msg.value
  end

  def process   # @payable
    require( msg.value >= MINIMUM_INVESTMENT )
    @balances[ address ] += msg.value

    @investors << msg.sender

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
      share = (@balances[ address ] - paid) / @investors.size
      puts "paid out: #{paid}, remaining share / investor: #{share}"

      @investors.each do |investor|
        @balances[investor] += share
      end

      ## update pyramid state
      @balances[ address ] = 0
      @depth += 1
      @next_payout += 2**@depth
    end
  end

  def withdraw
    payout = @balances[ msg.sender ]
    @balances[ msg.sender ] = 0
    msg.sender.transfer( payout )
  end

end  # class SimplePyramid
