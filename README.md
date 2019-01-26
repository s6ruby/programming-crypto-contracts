
# Programming Crypto Blockchain Contracts Step-by-Step Book / Guide

_Let's Start with Ponzi & Pyramid Schemes. Run Your Own Lotteries, Gambling Casinos and more on the Blockchain World Computer..._



## Ponzis and Pyramids


### Simple Ponzi - Investment of a Lifetime!

Let's start with a simple ponzi scheme contract:

``` ruby
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

end # class SimplePonzi
```

(Source: [`ponzi_simple.rb`](ponzi_simple.rb))



What's a ponzi scheme?

> A Ponzi scheme (also a Ponzi game) is a form of fraud which lures investors and pays profits to earlier investors by using funds obtained from more recent investors. The victims are led to believe that the profits are coming from product sales or other means, and they remain unaware that other investors are the source of profits. A Ponzi scheme is able to maintain the illusion of a sustainable business as long as there continue to be new investors willing to contribute new funds, and as long as most of the investors do not demand full repayment and are willing to believe in the non-existent assets that they are purported to own.
The scheme is named after Charles Ponzi who became notorious for using the technique in the 1920s.
>
> -- [Ponzi Scheme @ Wikipedia](https://en.wikipedia.org/wiki/Ponzi_scheme)





Now in 2019 ponzi schemes are as popular as ever. For
modern Get-Rich-Quick "verifiable corrupt" ponzi schemes
running on the blockchain
browse the ["high-risk" category](https://dappradar.com/rankings/protocol/ethereum/category/high-risk) of contract scripts
running on Ethereum, for example.

Anyways, let's get back to the first simple ponzi contract script.
The idea is:

The money sent in by the latest investor
gets paid out to the previous investor and because every
new investment must be at least 10% larger than the last
investment - EVERY INVESTOR WINS! (*)

(*): Except the last "sucker" is HODLing the bag waiting for a greater fool.


Let's setup some test accounts with funny money:

``` ruby
## setup test accounts with starter balance
Account[ '0xaaaa' ].balance = 1_000_000
Account[ '0xbbbb' ].balance = 1_200_000
Account[ '0xcccc' ].balance = 1_400_000

## (pp) pretty print  all known accounts with balance
pp Uni.accounts      # Uni (short for) Universum
```

printing:

```
[#<Account @addr="0xaaaa", @balance=1000000>,
 #<Account @addr="0xbbbb", @balance=1200000>,
 #<Account @addr="0xcccc", @balance=1400000>]
```

Note: The contract scripts run on Universum - a 3rd generation blockchain / world computer. New to Universum? See the [Universum (World Computer) White Paper](https://github.com/openblockchains/universum/blob/master/WHITEPAPER.md)!



And let's invest:

``` ruby
ponzi = SimplePonzi.new

Uni.send_transaction( from: '0xaaaa', to: ponzi, value: 1_000_000 )
pp ponzi
#=> #<SimplePonzi @current_investment=1000000, @current_investor="0xaaaa">

Uni.send_transaction( from: '0xbbbb', to: ponzi, value: 1_200_000 )
pp ponzi
#=> #<SimplePonzi @current_investment=1200000, @current_investor="0xbbbb">

Uni.send_transaction( from: '0xcccc', to: ponzi, value: 1_400_000 )
pp ponzi
#=> #<SimplePonzi @current_investment=1400000, @current_investor="0xcccc">

## (pp) pretty print all known accounts with balance
pp Uni.accounts
```

Resulting in:

```
[#<Account @addr="0x0000", @balance=1000000>,
 #<Account @addr="0xaaaa", @balance=1200000>,
 #<Account @addr="0xbbbb", @balance=1400000>,
 #<Account @addr="0xcccc", @balance=0>]
```

The "Genesis" `0x0000` account made a 100% profit of 1_000_000.
The `0xaaaa` account made an investment of 1_000_000 and got 1_200_000. 200_000 profit! Yes, it works!
The `0xbbbb` account made an investment of 1_200_000 and got 1_400_000. 200_000 profit! Yes, it works!
The `0xcccc` account is still waiting for a greater fool and is HODLing the bag.
To the moon!


### Gradual Ponzi - May the Brave be Rewared with Riches!


Let's put together a more realistic ponzi
where investor get above-average returns gradually
as more investors join in:


``` ruby
class GradualPonzi < Contract

  MINIMUM_INVESTMENT = 1_000_000

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
```

(Source: [`ponzi_gradual.rb`](ponzi_gradual.rb))



The improved ponzi formula is:

The investment scheme has a 1_000_000 minimum
to keep out "free loaders"
and every new investment gets shared evenly
between all previous investors.
At any time investors can withdraw all profits made
BUT not the initial investment.


Let's setup some test accounts with funny money:

``` ruby
## setup test accounts with starter balance
Account[ '0xaaaa' ].balance = 1_000_000
Account[ '0xbbbb' ].balance = 1_000_000
Account[ '0xcccc' ].balance = 1_000_000
Account[ '0xdddd' ].balance = 1_000_000

## (pp) pretty print all known accounts with balance
pp Uni.accounts      # Uni (short for) Universum
```

printing:

```
[#<Account @addr="0xaaaa", @balance=1000000>,
 #<Account @addr="0xbbbb", @balance=1000000>,
 #<Account @addr="0xcccc", @balance=1000000>,
 #<Account @addr="0xdddd", @balance=1000000>]
```

And let's invest:

``` ruby
ponzi = GradualPonzi.new

Uni.send_transaction( from: '0xaaaa', to: ponzi, value: 1_000_000 )
pp ponzi
#=> #<GradualPonzi
#      @balances={"0x0000"=>1000000},
#      @investors=["0x0000", "0xaaaa"]>

Uni.send_transaction( from: '0xbbbb', to: ponzi, value: 1_000_000 )
pp ponzi
#=> #<GradualPonzi
#      @balances={"0x0000"=>1500000, "0xaaaa"=>500000},
#      @investors=["0x0000", "0xaaaa", "0xbbbb"]>

Uni.send_transaction( from: '0xcccc', to: ponzi, value: 1_000_000 )
pp ponzi
#=> #<GradualPonzi
#      @balances={"0x0000"=>1833333, "0xaaaa"=>833333, "0xbbbb"=>333333},
#      @investors=["0x0000", "0xaaaa", "0xbbbb", "0xcccc"]>

Uni.send_transaction( from: '0xdddd', to: ponzi, value: 1_000_000 )
pp ponzi
#=> #<GradualPonzi
#      @balances={"0x0000"=>2083333, "0xaaaa"=>1083333,
#                 "0xbbbb"=>583333,  "0xcccc"=>250000},
#      @investors=["0x0000", "0xaaaa", "0xbbbb", "0xcccc", "0xdddd"]>

## (pp) pretty print all known accounts with balance
pp Uni.accounts
```

Resulting in:

```
[#<Account @addr="0xaaaa", @balance=0>,
 #<Account @addr="0xbbbb", @balance=0>,
 #<Account @addr="0xcccc", @balance=0>,
 #<Account @addr="0xdddd", @balance=0>]
```

Note: All accounts have a balance of 0 because
the investment (and profits) are this time safely kept in the ponzi!

The "Genesis" `0x0000` account made a 100% profit of 2_083_333.
The `0xaaaa` account made an investment of 1_000_000 and got 1_083_333. 83_333 profit! Yes, it works!
The `0xbbbb` account made an investment of 1_000_000 and got 583_333 so far. HODL! HODL!
The `0xcccc` got 250_000 so far. HODL! HODL!
The `0xdddd` account is still waiting for greater fools and is HODLing the bag.
To the moon!


Let's withdraw and pocket the profits:

``` ruby
ponzi.send_transaction( :withdraw, from: '0xaaaa' )
pp ponzi
#=> #<GradualPonzi
#       @balances={"0x0000"=>2083333, "0xaaaa"=>0,
#                  "0xbbbb"=>583333,  "0xcccc"=>250000},
#       @investors=["0x0000", "0xaaaa", "0xbbbb", "0xcccc", "0xdddd"]>

## (pp) pretty print all known accounts with balance
pp Uni.accounts
```

resulting in:

```
[#<Account @addr="0xaaaa", @balance=1083333>,
 #<Account @addr="0xbbbb", @balance=0>,
 #<Account @addr="0xcccc", @balance=0>,
 #<Account @addr="0xdddd", @balance=0>]
```

Yes, it's real!
The `0xaaaa` account keeps getting more (and more) profits in the ponzi
(see the `@investors` list) and
got already ALL the investment back with 83_333 profits!



To be continued...
