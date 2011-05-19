;
;
;
PRO HV_SECCHI_WRITE_COLORTABLE_PNG,dir = dir
;
  if not keyword_set(dir) then dir = ''
  inst = ['COR1','COR2','EUVI']
  meas = {cor1:[0],cor2:[0],euvi:[171,195,284,304]}

;  set_plot,'z'
  for i = 0,n_elements(inst)-1 do begin
     a = findgen(1,256)
     m = gt_tagval(meas,inst[i])
     for j = 0,n_elements(m)-1 do begin
        secchi_colors,inst[i],m[j],r,g,b
        write_png,dir + inst[i]+'_'+trim(m[j])+ '_colortable.png',a,r,g,b
     endfor
  endfor
  set_plot,'x'

  return
end
