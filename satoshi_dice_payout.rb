


## Fee is 1 / 100  (that is 0.01 or 1%)
FEE_NUMERATOR   = 1
FEE_DENOMINATOR = 100

MAXIMUM_CAP = 2**16   # 65_536 = 2^16 = 2 byte/16 bit


(1..MAXIMUM_CAP).each do |bet|
  if bet > 200 && bet < 65530
    next unless bet % 100 == 0
  end

  print "%5d" % bet

  payout  = MAXIMUM_CAP / bet.to_f
  fee     = payout * FEE_NUMERATOR / FEE_DENOMINATOR.to_f
  payout -= fee
  print " - %f x " % payout
  print " (%f %%) " % (bet*100 / MAXIMUM_CAP.to_f )
  print " (+ #{FEE_NUMERATOR}/#{FEE_DENOMINATOR} fee %f) " % fee

  print "\n"

end
