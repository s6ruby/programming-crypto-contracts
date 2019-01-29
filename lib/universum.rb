## stdlibs
require 'pp'    ## pretty print (pp)
require 'digest'


def sha256( str )
  Digest::SHA256.hexdigest( str )
end


def address( o )
  if o.is_a? Contract
    ##  fix/todo:  use/lookup proper addr from contract
    ## construct address for now from object_id
    "0x#{(o.object_id << 1).to_s(16)}"
  else
    raise "Type Conversion to Address Failed; Expected Contract got #{o.inspect}; Contract Halted (Stopped)"
  end
end





class String
  def send( value )
    ## check if self is an address
    if self.start_with?( '0x' )
      Account[self].send( value )
    else
      raise "(Auto-)Type Conversion from Address (Hex) String to Account Failed; Expected String Starting with 0x got #{self}; Contract Halted (Stopped)"
    end
  end

  def transfer( value )
    ## check if self is an address
    if self.start_with?( '0x' )
      Account[self].transfer( value )
    else
      raise "(Auto-)Type Conversion from Address (Hex) String to Account Failed; Expected String Starting with 0x got #{self}; Contract Halted (Stopped)"
    end
  end
end



class Account

  @@directory = {}
  def self.find_by_addr( key ) @@directory[ key ]; end

  def self.[]( key )
    o = find_by_addr( key )
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
    @@directory.values.sort { |l,r| l.addr <=> r.addr }   ## sort by hex addr string
  end


  ####
  #  account (builtin) services / transaction methods

  attr_reader   :addr
  attr_accessor :balance    ## note: for now allow write access too!!!

  def send( value )    # @payable
    ## todo/fix: assert value > 0
    @balance += value
  end

  def transfer( value )    # @payable
    ## todo/fix: assert value > 0
    ## todo/fix: add missing  -= part in transfer!!!!
    @balance += value
  end


private
  def initialize( addr, balance: 0 )
    @addr    = addr       # type address - (hex) string starts with 0x
    @balance = balance    # uint
  end

end # class Account



class Contract
  class Event; end   ## base class for events


  def self.handlers    ## use listeners/observers/subscribers/... - why? why not?
    @@handlers ||= []
  end


  def self.log( event )
    handlers.each { |h| h.handle( event ) }
  end

  def log( event ) self.class.log( event ); end


  def assert( cond )
    cond == true ? true : false
  end

  def require( cond )
    if cond == true
      ## do nothing
    else
      raise 'Contract Condition Failed; Contract Halted (Stopped)'
    end
  end

  ## todo/fix: return address - why? why not?
  def this() self; end

  def msg()   Universum.msg;   end
  def block() Universum.block; end
  def blockhash( number )
    ## todo/fix: only allow going back 255 blocks; check if number is in range!!!
    Universum.blockhash( number )
  end


  def destroy( owner )   ## todo/check: use a different name e.g. destruct/ delete - why? why not?
     ## selfdestruct function (for clean-up on blockchain)
     ## fix: does nothing for now - add some code (e.g. cleanup)
     ##  mark as destruct - why? why not?
  end

  def send_transaction( method, *args, **kwargs )
    if kwargs[:from]
      from = kwargs.delete( :from )
      Universum.msg = { sender: from }
    end

    ## todo/fix: check arity of method to call to pass along right params - quick and dirty hack/check for now used for kwargs
    if kwargs.empty?
      __send__( method, *args )   ## note: use __send__ (instead of send - might be overriden)
    else
      __send__( method, *args, **kwargs )   ## note: use __send__ (instead of send - might be overriden)
    end
      ## todo/fix: add send_tx alias - why? why not?
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

  def self.send_transaction( *args, data: [], from:, to:, value: 0 )
    if value > 0
      account = Account[from]
      account.balance -= value    ## move value to msg (todo/fix: restore if exception)
    end

    ## setup contract msg context
    self.msg = { sender: from, value: value }

    if args.size == 0  ## assume call (default method) for now
      to.call()
    else   ## assume method name
      m   = args[0]
      to.send( m, *data )
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

end  ## class Universum

Uni = Universum   ## add some convenience aliases (still undecided what's the most popular :-)
UNI = Universum
UN  = Universum
U   = Universum
