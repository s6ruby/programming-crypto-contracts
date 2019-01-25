## stdlibs
require 'pp'    ## pretty print (pp)





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

  def msg() self.class.msg; end


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


  def destroy( owner )   ## todo/check: use a different name e.g. destruct/ delete - why? why not?
     ## selfdestruct function (for clean-up on blockchain)
     ## fix: does nothing for now - add some code (e.g. cleanup)
     ##  mark as destruct - why? why not?
  end

  def send_transaction( method, *args, **kwargs )
    if kwargs[:from]
      from = kwargs.delete( :from )
      self.class.msg = { sender: from }
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




class Universum   ## Uni short for Universum
  ## convenience helpers

  def self.send_transaction( from:, to:, value: )
    account = Account[from]
    account.balance -= value    ## move value to msg (todo/fix: restore if exception)

    ## setup contract msg context
    Contract.msg = { sender: from, value: value }

    to.call()   ## assume call (default method) for now
  end


  def self.accounts
    accounts = Account.all
  end
end  ## class Universum

Uni = Universum   ## add some convenience aliases (still undecided what's the most popular :-)
UNI = Universum
UN  = Universum
U   = Universum
