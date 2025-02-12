










! --- generate monthly forcing fields
! --- Now also High-frequency forcing


! --- When this routine is finished, The following fields should be 
! --- prepared with these variable names and units. Note that the fields
! --- are either read all at once (climatology), or sequentially in HYCOM
! --- (synoptic forcing).
! --- -------------------------------------------------------------
! --- Field description:     Variable name:     Unit:
! --- ------------------     --------------     -----              
! --- Atmosphere temp        airtmp             Celsius
! --- Relative humidity      relhum             [] (Fraction)
! --- Precipitation          precip             m/s (water equivalent)
! --- Total Cloud Cover      cloud              [] (fraction)
! --- Wind speed             wndspd             m/s
! --- U Wind component       uwnd               m/s (component on grid)
! --- V Wind component       uwnd               m/s (component on grid
! --- U Drag component       taux               N/m^2
! --- V Drag component       tauy               N/m^2
! --- SLP                    slp                mBar
!
! --- TP5 forcing - synoptic added in 2019----
! --- Atmosphere temp        airtmp             Celsius
! --- SLP                    mlsprs             Pa 
! --- Precipitation          precip             m/s (water equivalent)
! --- Downwelling longwave   radflx             W/m^2     % onely era-i 
! --- Downwelling shortwave  shwflx             W/m^2     %
! --- vapmixing              vapmix             kg kg^-1
! --- ewd wind               wndewd             m/s
! --- nwd wind               wndnwd             m/s
! --- net longwave           radflx             W/m^2    % era-i+all
! --- net shortwave          nswflx             W/m^2
! --- -------------------------------------------------------------

      program force_perturb
      use mod_xc
      use mod_za
      use mod_grid
      use mod_forcing_nersc
      use mod_random_forcing
      implicit none

      integer,parameter :: ioff=30 ! offset for input  files
      integer,parameter :: ooff=0  ! offset for output files
      integer ::  ios,off,k
      real    :: span
      real*8  :: dtime
      character(len=*), parameter ::  &
         catm='Atm. forcing', &
         cwnd='Wind forcing', &
         prfx='tst.' 

      call xcspmd()
      call zaiost()
      call get_grid()           ! inits various stuff (grid, etc) 
      call init_forcing_nersc() ! Inits flags, constants and allocatable fields
      call init_rand_update()   ! initializes random forcing and allocates vars

      if (.not.randf) then
         print *,'randf option switched off in infile2.in '
         call exit(0)
      end if

      ! Open forcing files for reading
      call opnfrcrd(904+ioff,'airtmp')
      call opnfrcrd(906+ioff,'precip')
      call opnfrcrd(908+ioff,'radflx')
      call opnfrcrd(909+ioff,'shwflx')
      call opnfrcrd(unit_uwind +ioff,'wndewd')
      call opnfrcrd(unit_vwind +ioff,'wndnwd')
      call opnfrcrd(unit_slp   +ioff,'mslprs')

      ! Open forcing files for writing - treat all perturbations as synoptic
      call opnfrcwr(904+ooff,'airtmp',.true.,catm, &
                    'airtmp [degree_Celsius]',prefix=prfx)
      call opnfrcwr(906+ooff,'precip',.true.,catm, &
                    'precip [m/s]',prefix=prfx)
      call opnfrcwr(909+ooff,'shwflx',.true.,catm, &
                    'shwflx [W m**-2]',prefix=prfx)
      call opnfrcwr(908+ooff,'radflx',.true.,catm, &
                    'radflx [W m**-2]',prefix=prfx)
      call opnfrcwr(unit_uwind +ooff,'wndewd', .true.,cwnd, &
                    'wndewd [m s**-1]',prefix=prfx)
      call opnfrcwr(unit_vwind +ooff,'wndnwd', .true.,cwnd, &
                    'wndnwd [m s**-1]',prefix=prfx)
      call opnfrcwr(unit_slp  +ooff,'mslprs',   .true.,catm, &
                    'mslprs [Pa]',prefix=prfx)

      ios=0
      do while(ios==0)
         ! Read input fields into syn fields
         call readfrcitem(904        +ioff,synairtmp,dtime,span,ios)
         call readfrcitem(906        +ioff,synprecip,dtime,span,ios)
         call readfrcitem(909        +ioff,syndswflx,dtime,span,ios)
         call readfrcitem(908        +ioff,synradflx,dtime,span,ios)
         call readfrcitem(unit_uwind +ioff,synuwind ,dtime,span,ios)
         call readfrcitem(unit_vwind +ioff,synvwind ,dtime,span,ios)
         call readfrcitem(unit_slp   +ioff,synslp   ,dtime,span,ios)

         rdtime= span

         if (ios==0) then
            if ( mod(int(dtime/rdtime),20)==0) then
               write(lp,*)
               print *,'Random forcing update - dtime=',dtime
            else
               write(lp,'(a1)',advance='no')  '.'
               call flush(lp)
            end if

            call rand_update()

            ! Dump to new forcing fields
            call writeforc(synairtmp,904+ooff,        &
                          'airtmp',.true.,dtime)
            call writeforc(synprecip,906+ooff,        &
                          'precip',.true.,dtime)
            call writeforc(syndswflx,909+ooff,        &
                          'shwflx',.true.,dtime)
            call writeforc(synradflx,908+ooff,        &
                          'radflx',.true.,dtime)
            call writeforc(synuwind ,unit_uwind +ooff,&
                          'wndewd',.true.,dtime)
            call writeforc(synvwind ,unit_vwind +ooff,&
                          'wndnwd',.true.,dtime)
            call writeforc(synslp   ,unit_slp   +ooff,&
                          'mslprs',.true.,dtime)
         end if
      end do


      do k=1,2
         if (k==1) then
            off=ioff
         else
            off=ooff
         end if
         close(904+off) ; call zaiocl(904+off)
         close(906+off) ; call zaiocl(906+off)
         close(908+off) ; call zaiocl(908+off)
         close(909+off) ; call zaiocl(909+off)
         close(unit_uwind +off) ; call zaiocl(unit_uwind +off)
         close(unit_vwind +off) ; call zaiocl(unit_vwind +off)
         close(unit_slp   +off) ; call zaiocl(unit_slp   +off)
      end do


      contains 
      subroutine readfrcitem(iunit,fld,dtime,span,ios)
      implicit none
      real   , intent(out) :: fld(idm,jdm),span
      real*8 , intent(out) :: dtime
      integer, intent(out) :: ios
      integer, intent(in)  :: iunit

      real :: hmin,hminb,hmax,hmaxb
      character(len=80) :: cline
      integer :: i

      read(iunit,'(a80)',iostat=ios) cline

      if (ios/=0) return
      call zaiord(fld,ip,.false.,hmin,hmax,iunit)
      i = index(cline,'=')
      read (cline(i+1:),*) dtime,span, hminb,hmaxb
      if (abs(hmin-hminb).gt.abs(hminb)*1.e-4 .or. &
          abs(hmax-hmaxb).gt.abs(hmaxb)*1.e-4     ) then
          write(lp,'(/ a / a,1p3e14.6 / a,1p3e14.6 /)') &
            'error - .a and .b files not consistent:', &
            '.a,.b min = ',hmin,hminb,hmin-hminb, &
            '.a,.b max = ',hmax,hmaxb,hmax-hmaxb
         print *,'unit=',iunit
         print *,'(p_force_perturb:readfrcitem)'
         call exit(1)
      end if

      if (span/=0.25) then
         print *,'unsupported span ',span
         call exit(1)
      end if
      end subroutine


      end program
