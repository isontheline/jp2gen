;
; Parse an input CCSDS time into its parts
;
FUNCTION HV_PARSE_CCSDS,a
  b = {yy:strmid(a,0,4),$
       mm:strmid(a,5,2),$
       dd:strmid(a,8,2),$
       hh:strmid(a,11,2),$
       mmm:strmid(a,14,2),$
       ss:strmid(a,17,2),$
       milli:strmid(a,20,3)}
return,b
end
