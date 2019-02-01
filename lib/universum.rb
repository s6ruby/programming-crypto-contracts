## stdlibs
require 'pp'    ## pretty print (pp)
require 'digest'


def sha256( str )
  Digest::SHA256.hexdigest( str )
end



module Address
  def address
    if @address
      @address
    else
      if is_a? Contract
         ##  fix/todo:  use/lookup proper addr from contract
         ## construct address for now from object_id
         "0x#{(object_id << 1).to_s(16)}"
      else  ## assume Account
         '0x0000'
      end
    end
  end # method address

  def transfer( value )  ## @payable @public
    ## todo/fix: throw exception if insufficient funds
    send( value )   # returns true/false
  end

  def send( value )  ## @payable @public
    ## todo/fix: assert value > 0
    ## todo/fix: add missing  -= part in transfer!!!!

    ## use this (current contract) for debit (-) ammount
    this._sub( value )    # sub(tract) / debit from the sender (current contract)
    _add( value )         # add / credit to the recipient
  end

  def balance
    @balance ||= 0   ## return 0 if undefined
  end

  ### private (internal use only) methods - PLEASE do NOT use (use transfer/send)
  def _sub( value )
    @balance ||= 0   ## return 0 if undefined
    @balance -= value
  end

  def _add( value )
    @balance ||= 0   ## return 0 if undefined
    @balance += value
  end
end  # class Address


class Bool; end   ## add dummy bool class for mapping


class Mapping
  def self.of( *args )
     ## e.g. gets passed in [{Address=>Integer}]
     ##  check for Integer - use Hash.new(0)
     ##  check for Bool    - use Hash.new(False)
     if args[0].is_a? Hash
       arg = args[0].to_a   ## convert to array (for easier access)
       if arg[0][1] == Integer
         Hash.new( 0 )     ## if key missing returns 0 and NOT nil (the default)
       elsif arg[0][1] == Bool
         Hash.new( false )
       elsif arg[0][1] == Address
         Hash.new( '0x0000' )
       else   ## assume "standard" defaults
         Hash.new
       end
     else
       Hash.new    ## that is, "plain" {} with all "standard" defaults
     end
  end
end

class Array
  def self.of( *args )
     Array.new    ## that is, "plain" [] with all "standard" defaults
  end
end


class String
  def transfer( value )
    ## check if self is an address
    if self.start_with?( '0x' )
      Account[self].transfer( value )
    else
      raise "(Auto-)Type Conversion from Address (Hex) String to Account Failed; Expected String Starting with 0x got #{self}; Contract Halted (Stopped)"
    end
  end

  def send( value )
    ## check if self is an address
    if self.start_with?( '0x' )
      Account[self].send( value )
    else
      raise "(Auto-)Type Conversion from Address (Hex) String to Account Failed; Expected String Starting with 0x got #{self}; Contract Halted (Stopped)"
    end
  end

  def _sub( value )
    ## check if self is an address
    if self.start_with?( '0x' )
      Account[self]._sub( value )
    else
      raise "(Auto-)Type Conversion from Address (Hex) String to Account Failed; Expected String Starting with 0x got #{self}; Contract Halted (Stopped)"
    end
  end
end



class Account

  @@directory = {}
  def self.find_by_address( key ) @@directory[ key ]; end

  def self.[]( key )
    o = find_by_address( key )
    if o
      o
    else
      o = new( key )
      ## note: auto-register (new) address in (yellow page) directory
      @@directory[ key ] = o
      o
    end
  end

  def self.all
    ## todo/fix: do NOT sort - to keep "stable" order
    ##   - check if values is insertion order
    @@directory.values.sort { |l,r| l.address <=> r.address }   ## sort by hex addr string
  end


  ####
  #  account (builtin) services / transaction methods
  include Address    ## includes address + send/transfer/balance

  ## note: for now allow write access too!!!
  def balance=( value )
    @balance = value
  end

  ## note: needed by transfer/send
  def this()       Universum.this;         end   ## returns current contract

private
  def initialize( address, balance: 0 )
    @address = address    # type address - (hex) string starts with 0x
    @balance = balance    # uint
  end

end # class Account



## base class for events
class Event
  ## return a new Struct-like read-only class

  ##
  ##  todo/fix: make it work with self.new (for convenience) too!!!!
  ##    - check source of Struct.new - why? why not? possible?
  def self.create( *fields )
    klass = Class.new( Event ) do
      define_method( :initialize ) do |*args|
        fields.zip( args ).each do |field, arg|
          instance_variable_set( "@#{field}", arg )
        end
      end

      fields.each do |field|
        define_method( field ) do
          instance_variable_get( "@#{field}" )
        end
      end
    end
    klass
  end
end  # class Event




class Contract
  ####
  #  account (builtin) services / transaction methods
  include Address    ## includes address + send/transfer/balance


  def process    ## @payable default fallback
  end


  def assert( cond )
    if cond == true
      ## do nothing
    else
      raise 'Contract Assertion Failed; Contract Halted (Stopped)'
    end
  end

  def require( cond )
    if cond == true
      ## do nothing
    else
      raise 'Contract Require Condition Failed; Contract Halted (Stopped)'
    end
  end

  def this()       Universum.this;         end   ## returns current contract
  def log( event ) Universum.log( event ); end
  def msg()        Universum.msg;          end
  def block()      Universum.block;        end
  def blockhash( number )
    ## todo/fix: only allow going back 255 blocks; check if number is in range!!!
    Universum.blockhash( number )
  end

private
  def selfdestruct( owner )   ## todo/check: use a different name e.g. destruct/ delete - why? why not?
    ## selfdestruct function (for clean-up on blockchain)
    owner.send( @balance )    ## send back all funds owned/hold by contract

     ## fix: does nothing for now - add some code (e.g. cleanup)
     ##  mark as destruct - why? why not?
  end

end  # class Contract



## blockchain message (msg) context
##   includes:  sender (address)
##  todo: allow writable attribues e.g. sender - why? why not?
class Msg
  attr_reader :sender, :value

  def initialize( sender: '0x0000', value: 0 )
    @sender = sender
    @value  = value
  end
end  # class Msg



class Block
  attr_reader :timestamp, :number

  def initialize( timestamp: Time.now.to_i, number: 0 )
    @timestamp = timestamp   # unix epoch time (in seconds since 1970)
    @number    = number      # block height (start with 0 - genesis block)
  end
end  # class Block




class Universum   ## Uni short for Universum
  ## convenience helpers


  def self.send_transaction( from:, to:, value: 0, data: [] )
    ## transaction counter 1,2,3,etc. (sometimes called nounce too)
    @@counter ||= 0
    @@counter += 1       ## start with 0 or 1 (for now starting with 1 - why? why not?)

    if value > 0
      account = Account[from]

      ## move value to msg (todo/fix: restore if exception)
      account._sub( value )  # (sub)tract / debit from the sender (account)
      to._add( value )       # add / credit to the recipient
    end


    ## setup contract msg context
    self.msg = { sender: from, value: value }

    self.this = to    ## assumes for now that to is always a contract (and NOT an account)!!!

    ## for debug add transaction (tx) args (e.g. from, value, etc.)
    tx_args_debug = { from: from }
    tx_args_debug[ :value ] = value    if value > 0

    ## use our "own" pretty print / inspect (to string) format
    tx_args_debug_str = tx_args_debug.reduce( [] ) { |ary,(k,v)| ary; ary << "#{k}: #{v.inspect}" }.join( ', ' )


    if data.empty?  ## assume process (default method) for now
      puts "** tx ##{@@counter} (block ##{block.number}): #{tx_args_debug_str} => to: #{to.class.name} default function"
      to.process()
    else   ## assume method name
      m    = data[0]       ## method name / signature
      args = data[1..-1]   ## arguments

      ## convert all args to string (with inspect) for debugging
      ##   check if pretty_inspect adds trailing newline? why? why not? possible?
      args_debug = args.reduce( [] ) { |ary,arg| ary; ary << arg.inspect }.join( ', ' )
      puts "** tx ##{@@counter} (block ##{block.number}): #{tx_args_debug_str} => to: #{to.class.name} #{m}( #{args_debug} )"

      to.__send__( m, *args )    ## note: use __send__ to avoid clash with send( value ) for sending payments!!!
    end
  end


  def self.accounts
    accounts = Account.all
  end


  def self.msg
    @@msg ||= Msg.new
  end

  def self.msg=( value )
    if value.is_a? Hash
      kwargs = value
      @@msg = Msg.new( kwargs )
    else   ## assume Msg class/type
      @@msg = value
    end
  end


  def self.blockhash( number )
    ## for now return "dummy" blockhash
    sha256( "blockhash #{number}" )
  end

  def self.block
    @@block ||= Block.new
  end

  def self.block=( value )
    if value.is_a? Hash
      kwargs = value
      @@block = Block.new( kwargs )
    else   ## assume Block class/type
      @@block = value
    end
  end

  def self.this    ## returns current contract
    @@this
  end

  def self.this=(value)
    ## todo/fix: check that value is a contract
    @@this = value
  end


  def self.handlers    ## use listeners/observers/subscribers/... - why? why not?
    @@handlers ||= []
  end

  def self.log( event )
    handlers.each { |h| h.call( event ) }
  end
end  ## class Universum


Uni = Universum   ## add some convenience aliases (still undecided what's the most popular :-)
UNI = Universum
UN  = Universum
U   = Universum


## (auto-)add (debug) log handler for now - pretty print (pp) events to console
Uni.handlers << (->(event) { puts "** event: #{event.pretty_inspect}" })
