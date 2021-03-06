;+
;HISTORY:
;	Written 1-Aug-96 by M.Morrison
;	 5-Aug-96 (MDM) - Added "disp_mdi_hr_fov" to disp_gen call
;	15-Aug-96 (MDM) - Scaled to gauss
;	19-Aug-96 (MDM) - Removed /5 logic (since mk_mdi_fits does it now)
;	21-Aug-96 (MDM) - Added call to mk_gif_mag_index
;	20-Jan-97 (MDM) - Changed output directory from
;			  /soho-archive/public/data/summary/mdi  (to)
;			  /soho-archive/public/data/summary/gif/YYMMDD
;	11-Jun-97 (MDM) - Modified to mask out the part of the data which
;			  is off the limb (but within the crop radius)
;	25-Jul-97 (MDM) - Added creation of the continuum GIF images
;			- Changed headers
;	10-Nov-97 (JFC) - Added a couple of lines to adjust the scaling of the
;			  conitnuum images to distinguish umbrae and penumbrae
;			  while we are entering the active cycle
;       12-Feb-99 (RIB) - Set the output directory to /md86/gif; changed the
;                         continuum color table to "3" (red-temperature)
;	04-Aug-99 (CED) - Changed output directory to $MDI_GIF_DIR
;      4-Jan-2000 (RIB) - Changed rebinning of continuum flatfield to match
;			  incoming fits file
;     26-Jan-2001 (RIB) - Changed flatfield file to flat_jan2001.fits
;     07-Jul-2003 (RIB) - Inserted check of CROT = 180 while SOHO is rolled
;     25-Mar-2005 (SEG) - Changing flat field file to flat_mar2005.fits, see
;			  flat_README for more details.
;     11-Jul-2007 (SEG) - Made some temporary changes due to network switch of
;			  SOHO-archive 09 July 2007.  Reading .fts files from
;			  /sas12/temp instead of archive.  Igram and doppl images
;			  on archive cannot be read from our machines for some reason.
;     16-Nov-2007 (SEG) - Undoing change above now that we are on soho-archive network
;			  and mditlm is doing the fits
;     10-Dec-2008 (SEG) - Changing the flat field fits file to flat_Dec2008.fits
;     19-Sep-2009 (SEG) - soho-arch is down, so saving fits on sas and making gifs from them
;     21-Sep-2009 (SEG) - Will always read fits files from mdisas (now saved to mdisas and soho-archive
;			  in go_fits_sci160k.pro) in the event that we cannot access soho-arch.
;     04-Dec-2009 (SEG) - Updating the flat_field file from flat_Dec2008.fits to flat_Dec2009.fits
;-

if (n_elements(sttim) eq 0) then sttim = anytim2ints(ut_time(), offset=-2*86400)
if (n_elements(entim) eq 0) then entim = ut_time()
;; ------ temporyary fix for network switch problems where igram and doppl cannot be read from soho-archive 11-Jul-2007 (SEG) 
;;dir = '/soho-archive/private/data/planning/mdi' ;;--- 11-Jul-2007 (SEG)
dir = '/sas12/temp' ;------16-nov-2007 (SEG) On the new network, not saving fits to sas4/temp anymore 
		    ;------19-Sep-2009 (SEG) Added this back in since soho-arch down for maintainence, will keep so that
		    ;                        if soho-arch goes down, we will always have fits and gifs.  Soho-arch will get
		    ;                        fits according to go_fits_sci160k.pro

;; outdir2 = '/soho-archive/public/data/summary/gif' -- 11-Jul-2007 (SEG) 
;;outdir2 = '/sas12/temp' -- 11-Jul-2007 (SEG)

;ff_file = '/mdisw/dbase/cal/files/flat_005.fits'
;ff_file = '/mdisw/dbase/cal/files/flat_jan2001.fits'
;ff_file = '/mdisw/dbase/cal/files/flat_mar2005.fits'
;ff_file = '/mdisw/dbase/cal/files/flat_Dec2008.fits'
ff_file = '/mdisw/dbase/cal/files/flat_Dec2009.fits'

if (n_elements(types) eq 0) then types = ['maglc', 'igram']
for itype=0,n_elements(types)-1 do begin
  type = types(itype)
  ff = file_list(dir, '*' + type + '*', file=file)
  timarr = anytim2ints(fid2ex( strmid(file, 16, 11)))
  ss = sel_timrange(timarr, sttim, entim, /between)
  if (ss(0) ne -1) then begin
    for i=0,n_elements(ss)-1 do begin
	infil = ff(ss(i))
	break_file, infil, dsk_log, dir00, filnam
	img = rfits(infil, h=h)
	case type of
	   'maglc': begin
		ss2 = circle_mask(img, sxpar(h,'CRPIX1'), sxpar(h,'CRPIX2'), 'GE', sxpar(h,'RADIUS') )
		if (ss2(0) ne -1) then img(ss2)=-3000
		dpc_str = string(sxpar(h, 'dpc'), format='(z8.8)')
		img = img*0.352*8.	;data is 8 m/sec
		smin = -250.
		smax = 250.
		axis1 = 'Gauss'
		fmt='(f7.2)'
		outdir = getenv('MDI_GIF_DIR')+'/mag'
		tit = 'SOHO/MDI Magnetogram'
		loadct = 0
	   end
	   'igram': begin
		naxis=sxpar(h,'naxis1')
		xyz=[sxpar(h,'crpix1'), sxpar(h,'crpix2'), sxpar(h,'radius')]
		img=(img/10.)^2.
		if (n_elements(ff_img) eq 0) then begin
		    ff_img = rfits(ff_file)
		    ff_img = rebin(ff_img, naxis, naxis)
		end
		img = img * ff_img
		darklimb_correct, img, img3, limbxyr=xyz, lambda=6767
		img = temporary(img3)
		smin = 5000.
		smax = 13000.
		gamma=1.8	
		;img(*,505:*) = 0	;mask out garbage at the top
		axis1 = ''
		fmt='(f7.1)'
		outdir = getenv('MDI_GIF_DIR')+'/igram'
		tit = 'SOHO/MDI Continuum'
		loadct = 3
	   end
	endcase
	
	stit = strmid(sxpar(h, 'DATEOBS'),0,17)
	if (strpos(infil, '_fd_') ne -1) then cmds = 'disp_mdi_hr_fov, 0, 100, scale=0.5' $
					 else cmds = ''
	if (sxpar(h, 'CROT') eq 180) then begin
	  img = rotate(img,2)
	  if (strpos(infil, '_fd_') ne -1) then cmds = 'disp_mdi_hr_fov, -8, 38, scale=0.5'
	end

	outfil = concat_dir(outdir, filnam + '.gif')
	disp_gen, 1, img, tit, stit, smin=smin, smax=smax, /std_foot, $
		fmt=fmt, /compass, gif=outfil, cmds=cmds, axis1=axis1, $
                loadct=loadct

	;;outdir2b = concat_dir(outdir2, strmid(ex2fid(anytim2ex(stit)), 0, 6)) - (SEG) 11-Jul-2007
	if (keyword_set(outdir2)) then spawn, ['cp', '-p', outfil, outdir2b], /noshell
    end
  end
end

mk_gif_mag_index
end
