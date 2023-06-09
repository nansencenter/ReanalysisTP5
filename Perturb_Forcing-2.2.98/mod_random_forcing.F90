module mod_random_forcing
! ----------------------------------------------------------------------------
! -- init_rand_update - Initializes the random module, reads infile2.in - sets
!                       array sizes of derived types and initializes variables
!                       ran1 and ran. Also sets random number seeed, and sets
!                       the FFT sizes in mod_pseudo
! -- rand_update      - main routine - updates the nondimensional perturbations
!                       contained in variable "ran", and applies the
!                       dimensionalized version of this to the different forcing
!                       fields contained in "forcing_fields". Note that this
!                       routine is (for now) applied only when hf forcing is
!                       enabled (a check is done against forcing update times
!                       "rdtime" given by mod_forcing_nersc and yrflag). Also, 
!                       synoptic flags from "mod_forcing_nersc" are not taken
!                       into account.
!
! + Various private routines:
! -- limits_randf     - reads infile2.in and sets forcing variances as well as
!                       spatial and temporal correlation lengths (private)
! -- set_random_seed2 - Sets the random number seed based on date and time
! -- ranfields          Produces a set of nondimensional perturbation fields in
!                       a forcing_fields type
! -- calc_forc_update   Creates a dimensional forcing_field type 
! -- assign_force       sets  forcing_field to a constant
! -- assign_vars        Sets variances to a constant
! -- ran_update_ran1    Updates nondimensional forcing_field "ran" using
!                       input variances and nondimensional stochastic forcing 
!                       "ran1" - produces a red timeseries specified by input
!                       "alpha"
! -- init_ran(ran)      Allocates variables in the forcing_fields type
! ----------------------------------------------------------------------------
! KAL - 1st offline version 20080830
! NB - to use this routine mod_grid must be initialized (get_grid), as well
!      as the mod_forcing module (init_forcing_nersc). This is needed to
!      allocate grid and forcing variables
! ----------------------------------------------------------------------------
   use mod_xc
   use mod_grid
   implicit none
   private

   logical, save :: randf ! Switches on/off random forcing
   real   , save :: rf_hradius  ! Horizontal decorr length for rand forc [m]
   real   , save :: rf_tradius  ! Temporal decorr length for rand forc
   real   , save :: rh          ! Horizontal decorr length for rand forc [grid cells]
   real   , save :: rv
   integer, save :: rf_prsflg=0 ! initial value


  ! Random forcing variables:
   type forcing_fields
      real,pointer :: slp    (:,:) !  Sea level pressure
      real,pointer ::  taux   (:,:) !  wind stress in x direction
      real,pointer ::  tauy   (:,:) !  wind stress in y direction
      real,pointer ::  wndspd (:,:) !  wind speed (tke source)
      real,pointer ::  airtmp (:,:) !  pseudo air temperature
      real,pointer ::  relhum (:,:) !  relative humidity
      real,pointer ::  clouds (:,:) !  cloud cover
      real,pointer ::  precip (:,:) !  precipitation
      real,pointer ::  sss    (:,:) !  SSS for relax 
      real,pointer ::  sst    (:,:) !  SST for relax 
      real,pointer ::  uwind  (:,:) !  u-component of wind
      real,pointer ::  vwind  (:,:) !  v-component of wind
      real,pointer ::  tauxice(:,:) !  ice stress on water in x dir
      real,pointer ::  tauyice(:,:) !  ice stress on water in y dir
!    added at 18Jan 2019 for era-i+all
      real,pointer ::  dswflx(:,:) ! downwelling shortwave flux 
      real,pointer ::  shwflx(:,:) ! net shortwave flux 
      real,pointer ::  radflx(:,:) ! net longwave radiation 
     
   end type forcing_fields

   type forcing_variances
      real slp
      real taux          
      real tauy
      real wndspd
      real uwind 
      real vwind
      real clouds
      real airtmp
      real precip
      real relhum
      real sss
      real sst
!    added at 18Jan 2019 for era-i+all
      real shwflx
      real radflx
   end type forcing_variances


   ! Variable containing forcing variances
   type(forcing_variances), save :: vars

   ! Variable containing random forcing
   type(forcing_fields)   , save :: ran , ran1


   interface assignment(=)
      module procedure assign_force
      module procedure assign_vars
   end interface

   interface sqrt
      module procedure var_sqrt
   end interface
   
   public :: randf, init_rand_update, rand_update

contains


      subroutine init_rand_update()
      use mod_xc
      use mod_pseudo
      use mod_forcing_nersc
      implicit none
      real :: dx

      call limits_randf()
      dx=scpx(idm/2,jdm/2)
      if (mnproc==1) print *,'typical model grid scale ', dx
      rh=rf_hradius/dx     ! Decorrelation length is rh grid cells
      rv=rf_tradius        ! Temporal decorrelation scale (days)
      call init_ran(ran)
      call init_ran(ran1)
      ran=0.
      ran1=0.
      ! Init fft dimensions in mod_pseudo
      call initfftdim(idm,jdm)
      ! Init 
      call set_random_seed2
      call ranfields(ran,rh)
      call limits_randf()
      !print *,minval(ran%airtmp)
      !print *,maxval(ran%airtmp)
      !print *,'(stop in init_rand_update)'
      !stop 'in init_rand_update'
      end subroutine

      subroutine set_random_seed2
      ! Sets a random seed based on the wall clock time
      use mod_xc
      implicit none 

      integer , dimension(8)::val
      integer cnt
      integer sze
      integer, allocatable, dimension(:):: pt  ! keeps random seed

      call DATE_AND_TIME(values=val)
      call RANDOM_SEED(size=sze)
      allocate( pt(sze))
      call RANDOM_SEED         ! Init - assumes seed is set in some way based on clock, date etc. (not specified in f ortran standard)
      call RANDOM_SEED(GET=pt) ! Retrieve initialized seed
      pt = pt * (val(8)-500)  ! val(8) is milliseconds - this randomizes stuff if random_seed is nut updated often e nough
      call RANDOM_SEED(put=pt)
      deallocate( pt)
      end subroutine set_random_seed2


      subroutine limits_randf()
      use mod_forcing_nersc
      use m_parse_blkdat
      implicit none
      real, parameter :: version2=2.0    ! version of limits routine

      logical :: ex
      integer :: seed
      real    :: fversion

      inquire(file='infile2.in',exist=ex)
      if (.not.ex) then
         if (mnproc==1) write(lp,*) 'ERROR: infile2.in does not exist'
         call xcstop('(limits)')
         stop '(limits)'
      endif

      open(99,file='infile2.in',status='old',action='read')
      call blkinr(fversion, 'fversn','(a6," =",f10.4," ")')
      if (abs(version2-fversion)>1e-4) then
         if (mnproc==1) write(lp,*)  &
            'Wrong version of input file infile2.in'
         if (mnproc==1) write(lp,*) 'Expected version is',version2
         if (mnproc==1) write(lp,*) 'file     version is',fversion
         call xcstop('(limits)')
         stop '(limits)'
      endif
      call blkinl(randf        ,'randf ')
      call blkini(seed         ,'seed  ')
      call blkinr(vars%slp     ,'vslp  ','(a6," =",g10.1," Pa**2")')
      call blkinr(vars%taux    ,'vtaux ','(a6," =",g10.4," N**2m**-4")')
      call blkinr(vars%tauy    ,'vtauy ','(a6," =",g10.4," N**2m**-4")')
      call blkinr(vars%wndspd  ,'wndspd ','(a6," =",g10.4," m**2s**-2")')
      call blkinr(vars%uwind  ,'uwind ','(a6," =",g10.4," m**2s**-2")')
      call blkinr(vars%vwind  ,'vwind ','(a6," =",g10.4," m**2s**-2")')
      call blkinr(vars%clouds  ,'vcloud','(a6," =",g10.4," []")')
      call blkinr(vars%airtmp  ,'vtair ','(a6," =",g10.4," C**2")')
      call blkinr(vars%precip  ,'vprcp ','(a6," =",g10.4," ")')
      call blkinr(vars%relhum  ,'vrlhum','(a6," =",g10.4," []")')
      call blkinr(vars%shwflx  ,'vshwf ','(a6," =",g10.4," W**2m**-4")')
      call blkinr(vars%radflx  ,'vradf ','(a6," =",g10.4," W**2m**-4")')
      call blkinr(rf_hradius   ,'scorr ','(a6," =",g10.4," m")')
      call blkinr(rf_tradius   ,'tcorr ','(a6," =",g10.4," days")')
      call blkini(rf_prsflg    ,'prsflg')

      if (rf_prsflg>2 .or. rf_prsflg<0) then
         if (mnproc==1) then
            write(lp,*) 'Pressure flag must be between 0 and 2'
         end if
         call xcstop('(limits:limits_randf)')
         stop '(limits:limits_randf)'
      end if
      close(99)
      end subroutine limits_randf


! --- This routine updates the random forcing component, according to 
! --- a simple correlation progression with target variance specified 
! --- By forcing_variances. At the end of the routine, if applicable,
! --- the random forcing is added to the forcing fields.
   

      subroutine rand_update()
      use mod_grid
      use mod_parameters
      use mod_forcing_nersc
      implicit none

      ! rt       -- Information on time (mod_year_info)
      ! ran      -- Nondimensional random perturbations
      ! vars     -- Variances of fields ( Real pert = ran * vars)
      ! lrestart -- Special actions are taken if this is a restart

      !type(forcing_fields)    , intent(inout) :: ran 
      !type(forcing_variances) , intent(in)    :: vars

      integer :: ix,jy
      real :: alpha, autocorr, nsteps, wspd

      logical, save :: first=.true.
      integer, save :: ccount=1

      real, dimension(idm,jdm) :: modlon, modlat

      logical, parameter :: randf_test=.true.
      logical, save :: lfirst=.true.
      real, parameter :: rhoa = 1.2 , cdfac = 0.0012

      real :: cd_new,w4,wfact,wndfac, fcor
      real, dimension(1-nbdy:idm+nbdy,1-nbdy:jdm+nbdy) :: dpresx,dpresy
      real :: ucor, vcor, ueq,veq,wcor
      real :: wprsfac, minscpx, maxscpx

      real, parameter :: radtodeg=57.2957795
      real, parameter :: wlat=15.
      integer i,j

      ! Scale for slp (hPa) in TP4, otherwise equals 1.0 in TP5 (Pa)
      real, parameter :: Sslp=100.      

      yrflag=3
      if (yrflag/=3) then 
         write(lp,*) 'Random forcing only for yrflag=3'
         write(lp,'(2g14.4)') rdtime,yrflag
         stop '(rand_update)'
      else if (rdtime<1./24.) then 
         write(lp,*) 'rdtime to small', rdtime
         stop '(rand_update)'
      end if


      ! Autocorrelation between two times "tcorr"
      !KAL - quite high? - autocorr = 0.95
      autocorr = 0.75

      ! Number of "forcing" steps rdtime between autocorrelation
      ! decay. Autocorrelation time is tcorr
      nsteps = rv/rdtime

      ! This alpha will guarantee autocorrelation "autocorr"
      ! over the time "rv" 
      ! rv -> infinity , nsteps -> infinity, alpha -> 1 
      ! rv -> 0        , nsteps -> 0       , alpha -> 0 (when 1>autocorr>0)
      alpha=autocorr**(1/nsteps)

      !write(lp,*) 'Rand_update -- Random forcing field update' 


      ! Add new random forcing field to the newly read
      ! fields from ecmwf or ncep (:,:,4)
      !ran1=sqrt(vars)*ran
      call calc_forc_update(ran1,ran,sqrt(vars))



      if (rf_prsflg .eq. 1 .or. rf_prsflg .eq.2 ) then
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! rf_prsflag=1 : wind perturbations calculated from slp, using coriolis
!                parameter at 40 deg N
! rf_prsflag=2 : wind perturbations calculated from slp, using coriolis
!                parameter at 40 deg N, but limited by the setting of
!                windspeed, to account for the horizontal scale of pert.
!                As far as the wind is concerned, this is the same as 
!                reducing pressure perturbations
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


      ! grid size min max
      minscpx=minval(scpx)
      maxscpx=maxval(scpx)
      wprsfac=1.
      ! flag used in prsflg=2
      if (rf_prsflg==2) then

         fcor=2*sin(40./radtodeg)*2*pi/86400; ! Constant 

         ! typical pressure gradient  change it from default mBar in TP4 to Pa
         wprsfac=Sslp*sqrt(vars%slp)/(rh*minscpx)

         ! results in this typical wind magnitude
         wprsfac=wprsfac/fcor

         ! but should give wind according to vars%wndspd
         ! this is a correction factor for that
         wprsfac=sqrt(vars%wndspd)/wprsfac

      end if



      dpresx=0.
      dpresy=0.
!$OMP PARALLEL DO PRIVATE (ix,jy)
!$OMP&SCHEDULE(STATIC,jblk)
      do jy=1,jdm
      do ix=1,idm
         ! print *,ix,jy

         ! Pressure gradient. Coversion from mBar to Pa
         ! Note that this is in u-point, but is used for a v-point
         ! later 
         ! change it from default mBar in TP4 to Pa at 19Jan 2019
         if (iu(ix,jy)==1)  then
            !dpresx(ix,jy) = &
            !   100.*(ran1%slp(ix,jy) - ran1%slp(ix-1,jy))/ &
            !   scpx(ix,jy)
            dpresx(ix,jy) = Sslp*(ran1%slp(ix,jy) - ran1%slp(ix-1,jy))/ &
                             scpx(ix,jy)
            dpresx(ix,jy)=dpresx(ix,jy)*wprsfac
         else
            dpresx(ix,jy)=0. ! should be extrapolated
         end if

         ! Note that this is in v-point, but is used for a u-point
         ! later
         ! change it from default mBar in TP4 to Pa at 19Jan 2019
         if (iv(ix,jy)==1)  then
         !   dpresy(ix,jy) = &
         !      100.*(ran1%slp(ix,jy) - ran1%slp(ix,jy-1))/ &
         !      scpy(ix,jy)
            dpresy(ix,jy) = Sslp*(ran1%slp(ix,jy) - ran1%slp(ix,jy-1))/ &
                             scpy(ix,jy)
            dpresy(ix,jy)=dpresy(ix,jy)*wprsfac
         else
         dpresy(ix,jy)=0. ! should be extrapolated
         end if
      end do
      end do
!$OMP END PARALLEL DO




!$OMP PARALLEL DO PRIVATE (ix,jy,fcor,ucor,vcor, & 
!$OMP&                  ueq,veq,wcor)      &       
!$OMP&SCHEDULE(STATIC,jblk)
      do jy=1,jdm
      do ix=1,idm

         ! Coriolis balance (at 40 deg)
         !fcor=2*sin(max(abs(plat(ix,jy)),20.)/radtodeg)*2*pi/86400;
         fcor=2*sin(40./radtodeg)*2*pi/86400; ! Constant 
         fcor=fcor*sign(1.,plat(ix,jy))*rhoa
         vcor= dpresx(ix,jy) / (fcor)
         ucor=-dpresy(ix,jy) / (fcor)


         ! In the equatorial band u,v are aligned with the
         ! pressure gradients. Here we use the coriolis
         ! factor above to set it up (to limit the speeds)
         ueq=-dpresx(ix,jy) / abs(fcor)
         veq=-dpresy(ix,jy) / abs(fcor)

         ! Weighting between coriiolis/equator solution
         wcor=sin( &
            min(abs(plat(ix,jy)),wlat) / wlat &
            *pi*0.5)


         synuwind(ix,jy) = synuwind(ix,jy)+wcor*ucor + (1.-wcor)*ueq
         synvwind(ix,jy) = synvwind(ix,jy)+wcor*vcor + (1.-wcor)*veq

         synwndspd(ix,jy) = sqrt(  &
              synuwind(ix,jy)**2 + synvwind(ix,jy)**2)

         ! The rest use uncorrelated fields
         synairtmp(ix,jy) = synairtmp(ix,jy)+ran1%airtmp(ix,jy)
         synrelhum(ix,jy) = synrelhum(ix,jy)+ran1%relhum(ix,jy)
         synslp   (ix,jy) = synslp   (ix,jy)+ran1%slp   (ix,jy)
         !synprecip(ix,jy) = synprecip(ix,jy)+ran1%precip(ix,jy)
         !synprecip(ix,jy) = max(synprecip(ix,jy),0.0)
         ! replaced with lognormal precip by Jiping 
         synprecip(ix,jy) = synprecip(ix,jy)*exp(ran1%precip(ix,jy) &
                           -0.5*vars%precip**2)  
         synrelhum(ix,jy) = min(max(synrelhum(ix,jy),0.0),1.0)
         synwndspd(ix,jy) = max(synwndspd(ix,jy),0.0)
         !    added at 18Jan 2019 for era-i+all
!         syndswflx(ix,jy) = syndswflx(ix,jy)*(1 + sign(  &
!                     min(1.,abs(ran1%shwflx(ix,jy)))*sqrt(vars%shwflx), &
!                       ran1%shwflx(ix,jy)))

         syndswflx(ix,jy) = syndswflx(ix,jy)*exp(ran1%shwflx(ix,jy) &
                            -0.5*vars%shwflx**2)

!         synradflx(ix,jy) = synradflx(ix,jy)*(1 + sign(  &
!                     min(1.,abs(ran1%radflx(ix,jy)))*sqrt(vars%radflx), &
!                       ran1%radflx(ix,jy)))

         synradflx(ix,jy) = synradflx(ix,jy)*exp(ran1%radflx(ix,jy) &
                           -0.5*vars%radflx**2)

      end do
      end do
!$OMP END PARALLEL DO




         ! Drag
!$OMP PARALLEL DO PRIVATE (ix,jy,wndfac,cd_new,w4,wfact) 
!$OMP&SCHEDULE(STATIC,jblk)
      do jy=1,jdm
      do ix=1,idm
         wndfac=(1.+sign(1.,synwndspd(ix,jy)-11.))*.5
         cd_new=(0.49+0.065*synwndspd(ix,jy))*1.0e-3*wndfac+cdfac*(1.-wndfac)

         w4    =.25*( &
            synvwind(ix-1,jy+1)+synvwind(ix,jy+1)+  &
            synvwind(ix-1,jy  )+synvwind(ix,jy  )) 
         wfact=sqrt( synuwind(ix,jy)*synuwind(ix,jy)+w4*w4)* airdns*cd_new
         syntaux(ix,jy)=synuwind(ix,jy)*wfact

         w4   =.25*( &
            synuwind(ix  ,jy-1)+synuwind(ix+1,jy-1)+ &
            synuwind(ix+1,jy  )+synuwind(ix  ,jy  ))
         wfact=sqrt( &
               synvwind(ix,jy)*synvwind(ix,jy)+w4*w4)* airdns*cd_new
         syntauy(ix,jy)=synvwind(ix,jy)*wfact
      end do
      end do
!$OMP END PARALLEL DO



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! rf_prsflag=0 : wind and slp are uncorrelated
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      else  ! rf_prsflg .eq. 0



!!$OMP PARALLEL DO PRIVATE (ix,jy,wspd) SCHEDULE(STATIC,jblk)
      do jy=2,jdm-1
      do ix=2,idm-1
      !if (ip(ix,jy)==1) then
         syntaux  (ix,jy) = syntaux  (ix,jy) + ran1%taux(ix,jy)
         syntauy  (ix,jy) = syntauy  (ix,jy) + ran1%tauy(ix,jy)

         ! KAL -- winds are nonlinear functions of tau and mainly
         ! KAL -- used for sea ice
         wspd = sqrt(syntaux(ix,jy)**2 + syntauy(ix,jy)**2)
         wspd = max(sqrt(wspd / (cdfac*rhoa)),0.1)
         synuwind(ix,jy) = syntaux (ix,jy) / (wspd*cdfac*rhoa)
         synvwind(ix,jy) = syntauy (ix,jy) / (wspd*cdfac*rhoa)



         synairtmp(ix,jy) = synairtmp(ix,jy)+ran1%airtmp(ix,jy)
         synwndspd(ix,jy) = synwndspd(ix,jy)+ran1%wndspd(ix,jy)
         synrelhum(ix,jy) = synrelhum(ix,jy)+ran1%relhum(ix,jy)
         !synprecip(ix,jy) = synprecip(ix,jy)+ran1%precip(ix,jy)
         !synprecip(ix,jy) = max(synprecip(ix,jy),0.0)
         ! replaced with lognormal precip by Jiping 
         synprecip(ix,jy) = synprecip(ix,jy)*exp(ran1%precip(ix,jy)  &
                           -0.5*vars%precip**2)  
         synrelhum(ix,jy) = min(max(synrelhum(ix,jy),0.0),1.0)
         synwndspd(ix,jy) = max(synwndspd(ix,jy),0.0)

!    added at 18Jan 2019 for era-i+all
         syndswflx(ix,jy) = syndswflx(ix,jy)*(1 + sign(  &
                     min(1.,abs(ran1%shwflx(ix,jy)))*sqrt(vars%shwflx), &
                       ran1%shwflx(ix,jy)))
         synshwflx(ix,jy) = synshwflx(ix,jy)*(1 + sign(  &
                     min(1.,abs(ran1%shwflx(ix,jy)))*sqrt(vars%shwflx), &
                       ran1%shwflx(ix,jy)))

         synradflx(ix,jy) = synradflx(ix,jy)*(1 + sign(  &
                     min(1.,abs(ran1%radflx(ix,jy)))*sqrt(vars%radflx), &
                       ran1%radflx(ix,jy)))
      !end if
      end do
      end do


      end if ! rf_prsflg
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! end if rf_prsflag=0 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


      ! ran1 is new random forcing. ran is nondimensional
      ! "Brownian increment".
      call ranfields(ran1,rh)

      !ran= alpha*ran + sqrt(1-alpha*alpha)* ran 
      call ran_update_ran1(ran,ran1,alpha)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Diagnostics section -- Spatial field dumped on first run
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      if (lfirst) then
         ! Test for ranfld .... only done for first pass
         lfirst=.false.
         if (mnproc==1) then
            open(10,file='ranfld.dat',status='replace')
            do jy=1,jdm
            do ix=1,idm
               write(10,'(2i5,6e14.3)') ix,jy,  &
               modlon(ix,jy),modlat(ix,jy),depths(ix,jy), &
               synairtmp(ix,jy), syntaux(ix,jy),synuwind(ix,jy)
            end do
            end do
            close(10)
         end if
      end if
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Diagnostics section -- time series at test point
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      if (randf_test) then
         open(10,file='rantest.dat',status='unknown', position='append')
         write(10,'(i6,6f14.3)') ccount, &
             ran%taux  (50,80)*sqrt(vars%taux),  &
             ran%tauy  (50,80)*sqrt(vars%tauy), &
             ran%airtmp(50,80)*sqrt(vars%airtmp), &
             ran%relhum(50,80), &
             ran%uwind(50,80), &
             ran%vwind(50,80)
         close(10)
      end if
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! End Diagnostics section 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      ccount=ccount+1
      end subroutine rand_update



      subroutine ranfields(ranfld,scorr)
      use mod_pseudo
      use mod_forcing_nersc
      implicit none

      type(forcing_fields)    , intent(inout) :: ranfld 
      real,                     intent(in)    :: scorr 

      ranfld=0.
      call pseudo2D(ranfld%slp,idm,jdm,1,scorr,fnx,fny)
      call pseudo2D(ranfld%taux,idm,jdm,1,scorr,fnx,fny)
      call pseudo2D(ranfld%tauy,idm,jdm,1,scorr,fnx,fny)
      call pseudo2D(ranfld%wndspd,idm,jdm,1,scorr,fnx,fny)
      call pseudo2D(ranfld%airtmp,idm,jdm,1,scorr,fnx,fny)
      call pseudo2D(ranfld%relhum,idm,jdm,1,scorr,fnx,fny)
      call pseudo2D(ranfld%clouds,idm,jdm,1,scorr,fnx,fny)
      call pseudo2D(ranfld%precip,idm,jdm,1,scorr,fnx,fny)
      call pseudo2D(ranfld%uwind,idm,jdm,1,scorr,fnx,fny)
      call pseudo2D(ranfld%vwind,idm,jdm,1,scorr,fnx,fny)
      call pseudo2D(ranfld%shwflx,idm,jdm,1,scorr,fnx,fny)
      call pseudo2D(ranfld%radflx,idm,jdm,1,scorr,fnx,fny)
      end subroutine ranfields



   subroutine calc_forc_update(A,B,C)
      type(forcing_fields), intent(inout) :: A
      type(forcing_fields), intent(in   ) :: B
      type(forcing_variances), intent(in) :: C
      integer :: i,j
      do j=1,jdm
      do i=1,idm
         A%slp   (i,j)=C%slp    * B%slp   (i,j)
         A%taux  (i,j)=C%taux   * B%taux  (i,j)
         A%tauy  (i,j)=C%tauy   * B%tauy  (i,j)
         A%wndspd(i,j)=C%wndspd * B%wndspd(i,j)
         A%airtmp(i,j)=C%airtmp * B%airtmp(i,j)
         A%relhum(i,j)=C%relhum * B%relhum(i,j)
         A%clouds(i,j)=C%clouds * B%clouds(i,j)
         A%precip(i,j)=C%precip * B%precip(i,j)
         A%sss   (i,j)=C%sss    * B%sss   (i,j)
         A%sst   (i,j)=C%sst    * B%sst   (i,j)
         A%uwind (i,j)=C%uwind  * B%uwind (i,j)
         A%vwind (i,j)=C%vwind  * B%vwind (i,j)
         A%dswflx(i,j)=C%shwflx * B%dswflx(i,j)
         A%shwflx(i,j)=C%shwflx * B%shwflx(i,j)
         A%radflx(i,j)=C%radflx * B%radflx(i,j)
      end do
      end do
   end subroutine calc_forc_update

   function var_sqrt(A)
      type(forcing_variances) var_sqrt
      type(forcing_variances), intent(in) :: A

      var_sqrt%slp   = sqrt(A%slp   )
      var_sqrt%taux  = sqrt(A%taux  )
      var_sqrt%tauy  = sqrt(A%tauy  )
      var_sqrt%wndspd= sqrt(A%wndspd)
      var_sqrt%airtmp= sqrt(A%airtmp)
      var_sqrt%relhum= sqrt(A%relhum)
      var_sqrt%clouds= sqrt(A%clouds)
      var_sqrt%precip= sqrt(A%precip)
      var_sqrt%sss   = sqrt(A%sss   )
      var_sqrt%sst   = sqrt(A%sst   )
      var_sqrt%uwind = sqrt(A%uwind )
      var_sqrt%vwind = sqrt(A%vwind )
      var_sqrt%shwflx= sqrt(A%shwflx)
      var_sqrt%radflx= sqrt(A%radflx)
   end function var_sqrt

   subroutine assign_force(A,r)
      type(forcing_fields), intent(out) :: A
      real, intent(in) :: r

      integer :: i,j

      do j=1,jdm
      do i=1,idm
         A%slp    (i,j) = r
         A%taux   (i,j) = r
         A%tauy   (i,j) = r
         A%wndspd (i,j) = r
         A%airtmp (i,j) = r
         A%relhum (i,j) = r
         A%clouds (i,j) = r
         A%precip (i,j) = r
         A%sss    (i,j) = r
         A%sst    (i,j) = r
         A%uwind  (i,j) = r
         A%vwind  (i,j) = r
         A%dswflx (i,j) = r
         A%shwflx (i,j) = r
         A%radflx (i,j) = r
         A%tauxice(i,j) = r
         A%tauyice(i,j) = r
      end do
      end do
   end subroutine assign_force


   subroutine assign_vars(A,r)
      type(forcing_variances), intent(out) :: A
      real, intent(in) :: r
      A%slp    = r
      A%taux   = r
      A%tauy   = r
      A%wndspd = r
      A%airtmp = r
      A%relhum = r
      A%clouds = r
      A%precip = r
      A%sss    = r
      A%sst    = r
      A%uwind  = r
      A%vwind  = r
      A%shwflx = r
      A%radflx = r
   end subroutine assign_vars


   subroutine ran_update_ran1(ran,ran1,alpha)
      type(forcing_fields), intent(inout) :: ran
      type(forcing_fields), intent(   in) :: ran1
      real                , intent(   in) :: alpha
       
      integer :: ix,jy

      do jy=1,jdm
      do ix=1,idm
         ran%slp   (ix,jy)=alpha*ran%slp   (ix,jy) + sqrt(1-alpha*alpha)*ran1%slp   (ix,jy)
         ran%taux  (ix,jy)=alpha*ran%taux  (ix,jy) + sqrt(1-alpha*alpha)*ran1%taux  (ix,jy)
         ran%tauy  (ix,jy)=alpha*ran%tauy  (ix,jy) + sqrt(1-alpha*alpha)*ran1%tauy  (ix,jy)
         ran%wndspd(ix,jy)=alpha*ran%wndspd(ix,jy) + sqrt(1-alpha*alpha)*ran1%wndspd(ix,jy)
         ran%airtmp(ix,jy)=alpha*ran%airtmp(ix,jy) + sqrt(1-alpha*alpha)*ran1%airtmp(ix,jy)
         ran%relhum(ix,jy)=alpha*ran%relhum(ix,jy) + sqrt(1-alpha*alpha)*ran1%relhum(ix,jy)
         ran%clouds(ix,jy)=alpha*ran%clouds(ix,jy) + sqrt(1-alpha*alpha)*ran1%clouds(ix,jy)
         ran%precip(ix,jy)=alpha*ran%precip(ix,jy) + sqrt(1-alpha*alpha)*ran1%precip(ix,jy)
         ran%sss   (ix,jy)=alpha*ran%sss   (ix,jy) + sqrt(1-alpha*alpha)*ran1%sss   (ix,jy)
         ran%sst   (ix,jy)=alpha*ran%sst   (ix,jy) + sqrt(1-alpha*alpha)*ran1%sst   (ix,jy)
         ran%uwind (ix,jy)=alpha*ran%uwind (ix,jy) + sqrt(1-alpha*alpha)*ran1%uwind (ix,jy)
         ran%vwind (ix,jy)=alpha*ran%vwind (ix,jy) + sqrt(1-alpha*alpha)*ran1%vwind (ix,jy)
         ran%dswflx(ix,jy)=alpha*ran%dswflx(ix,jy) + sqrt(1-alpha*alpha)*ran1%dswflx(ix,jy)
         ran%shwflx(ix,jy)=alpha*ran%shwflx(ix,jy) + sqrt(1-alpha*alpha)*ran1%shwflx(ix,jy)
         ran%radflx(ix,jy)=alpha*ran%radflx(ix,jy) + sqrt(1-alpha*alpha)*ran1%radflx(ix,jy)
      end do
      end do
   end subroutine


   subroutine init_ran(ran)
   implicit none
      type(forcing_fields), intent(inout) :: ran
      allocate(ran%slp    (idm,jdm))
      allocate(ran%taux   (idm,jdm))
      allocate(ran%tauy   (idm,jdm))
      allocate(ran%wndspd (idm,jdm))
      allocate(ran%airtmp (idm,jdm))
      allocate(ran%relhum (idm,jdm))
      allocate(ran%clouds (idm,jdm))
      allocate(ran%precip (idm,jdm))
      allocate(ran%sss    (idm,jdm))
      allocate(ran%sst    (idm,jdm))
      allocate(ran%uwind  (idm,jdm))
      allocate(ran%vwind  (idm,jdm))
      allocate(ran%dswflx (idm,jdm))
      allocate(ran%shwflx (idm,jdm))
      allocate(ran%radflx (idm,jdm))
      allocate(ran%tauxice(idm,jdm))
      allocate(ran%tauyice(idm,jdm))
   end subroutine
  
  

end module mod_random_forcing
