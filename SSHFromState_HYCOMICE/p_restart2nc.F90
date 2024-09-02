! File:          p_restart2nc.f90
!
! Created:       6 May 2008
! Corrected:     15 July 2019 
!
! Last modified: 6 May 2022 
!
! Author:        fanf, knutali, Pavel Sakov(*)
!                NERSC
!
!                * This code is derived (basically, stripped, beautified and
!                  enhanced to dump fields to a NetCDF file) by PS from 
!                  p_ssh_from_state.F90 created by fanf on 10/06/2004 and
!                  modified by knutali
!
! Modifications:
!    1)  Compile flag:  HYCOM_CICE: read the hycom statement from forecasted restart file and the ice
!    statement from the forecasted iced file at 9th May 2019 by Jiping           
!    involving more ice variables at 15th July 2019 by Jiping           
!    2) modified at 6th MAy 2022 for a simple way applied in hycom_cice
!

program p_restart2nc
  use mod_za
  use mod_xc
  use mod_read_rstab
  use mod_year_info
  use mod_sigma
  use m_parse_blkdat
  use nfw_mod
  use mod_ice_io
  use mod_read_icednc
  implicit none

  real, parameter :: ONEMETER  = 9806.0
  real, parameter :: UNDEF = -1.0e14

  integer, parameter :: NKOUT = 26
  real, parameter, dimension(NKOUT) :: POUT = (/5, 10, 20, 40, 60, 80, 100,&
       120, 140, 160, 180, 200, 250, 300, 350, 400, 450, 500, 600, 700, 800,&
       900, 1000, 1500, 2000, 3000/) * ONEMETER

  integer*4, external :: iargc
  character(len=80) :: fname, fbase, fnameice
  integer :: indxa, indxb

  type(year_info) :: rtdump
  integer :: nrmem
  integer :: idm_dummy, jdm_dummy, kdm

  integer, allocatable, dimension(:,:) ::  imask
  real, allocatable, dimension(:,:) :: depths, modlon, modlat
  real :: hmin, hmax
  real :: rdummy
  integer ::kapflg, thflag
  real :: thbase
  integer :: idummy,iostat,jj

  real(8), dimension(:,:), allocatable :: iofld
  real(4), dimension(:,:), allocatable :: iofld4
  real, allocatable, dimension(:,:) :: temp
  real, allocatable, dimension(:,:) :: ficem, hicem ,ticem,tsrfm,hsnwm
  real, allocatable, dimension(:,:) :: salt
  real, allocatable, dimension(:,:) :: u
  real, allocatable, dimension(:,:) :: v
  real, allocatable, dimension(:,:) :: th3d
  real, allocatable, dimension(:,:) :: dp
  real, allocatable, dimension(:,:) :: psikk
  real, allocatable, dimension(:,:) :: thkk
  real, allocatable, dimension(:,:) :: oneta
  real, allocatable, dimension(:,:) :: pbavg
  real, allocatable, dimension(:,:) :: ssh
  real, allocatable, dimension(:,:) :: sla
  real, allocatable, dimension(:,:) :: meanssh
  real, allocatable, dimension(:,:,:) :: p
  real, allocatable, dimension(:,:,:) :: montg
  real, allocatable, dimension(:,:,:) :: thstar
  real, allocatable, dimension(:,:,:) :: dp3d
  real, allocatable, dimension(:,:,:) :: temp3d
  real, allocatable, dimension(:,:,:) :: salt3d
  real, allocatable, dimension(:,:,:) :: u3d
  real, allocatable, dimension(:,:,:) :: v3d

  real, allocatable, dimension(:,:,:) :: temp_z
  real, allocatable, dimension(:,:,:) :: salt_z
  real, allocatable, dimension(:,:,:) :: u_z
  real, allocatable, dimension(:,:,:) :: v_z

  integer :: i, j, k

  character(len=80) :: fname_meanssh, fname_nc, fnewice 
  logical :: ex

  logical :: tbaric

  real :: tmpth3d, tmpkapf

  integer :: ncid
  integer :: dimids(3), k_id(1), kz_id(1)
  integer :: lon_id, lat_id, depth_id, ssh_id, meanssh_id
  integer :: sla_id, temp_id, salt_id, dp_id, u_id, v_id, p_id, ficem_id, hicem_id ,hsnwm_id
  integer :: temp_z_id, salt_z_id, u_z_id, v_z_id,ticem_id
  integer :: imem,ierr

  if (iargc() /= 1 .and. iargc() /= 2) then
     print *,'Usage: restart2nc <HYCOM restart filename>'
     print *,'Or. restart2nc <HYCOM restart filename> <new cice restart>'
     print *, 'The parameters are the input files'
     call exit(1)
  else
     call getarg(1, fname) 
     indxa = index(fname, '.a') - 1
     indxb = index(fname, '.b') - 1
     if (indxa <= 0 .and. indxb <= 0) then
        fbase = fname
     else
        fbase = fname(1 : max(indxa, indxb))
     end if
     !print *,trim(fbase)
     !read(fbase(indxa - 2:indxa),'(i3.3)') imem
     fnameice='ice_'//fbase(1:indxa)//'.nc'
     fname_nc = trim(fbase) // '.nc'
     if (iargc() == 2) then
        ! write out a new ice files
        call getarg(2, fnameice) 
        fname_nc = trim(fnameice)
     end if
  end if
  print *, 'We assume the ice state from', fnameice

  call xcspmd
  call zaiost

  ! Get # of layers from the header
  !
  call rst_read_header(fbase, rtdump, nrmem, idm_dummy, jdm_dummy, kdm)
  if (idm /= idm_dummy .or. jdm /= jdm_dummy ) then
     print *, 'Mismatch between restart grid size and depths grid size'
     stop '(ssh_from_state)'
  end if

  ! Read bathymetry and grid from regional.depths file
  !
  allocate(imask(idm, jdm))
  allocate(depths(idm, jdm))
  allocate(modlon(idm,jdm))
  allocate(modlat(idm,jdm))

  call zaiopf('regional.depth.a','old', 99)
  call zaiord(depths, imask, .false., hmin, hmax, 99)
  call zaiocl(99)
  call zaiopf('regional.grid.a', 'old', 99)
  call zaiord(modlon, imask, .false., hmin, hmax, 99)
  call zaiord(modlat, imask, .false., hmin, hmax, 99)
  call zaiocl(99)

  call parse_blkdat('kapref', 'integer', rdummy, kapflg)
  call parse_blkdat('thflag', 'integer', rdummy, thflag)
  call parse_blkdat('thbase', 'real', thbase, idummy)

  tbaric = kapflg == thflag
  !tbaric=kapflg==-1
  print *, 'blkdat.input: kapflg =', kapflg
  print *, 'blkdat.input: thflag =', thflag
  print *, 'blkdat.input: thbase =', thbase
  print *, 'blkdat.input: tbaric =', tbaric

  allocate(iofld(idm, jdm))
  allocate(iofld4(idm, jdm))
  allocate(ficem(idm, jdm))
  allocate(ticem(idm, jdm))
  allocate(tsrfm(idm, jdm))
  allocate(hicem(idm, jdm))
  allocate(hsnwm(idm, jdm))
  allocate(temp(idm, jdm))
  allocate(salt(idm, jdm))
  allocate(u(idm, jdm))
  allocate(v(idm, jdm))
  allocate(th3d(idm, jdm))
  allocate(dp(idm, jdm))
  allocate(psikk(idm, jdm))
  allocate(thkk(idm, jdm))
  allocate(oneta(idm, jdm))
  allocate(pbavg(idm, jdm))
  allocate(ssh(idm, jdm))
  allocate(sla(idm, jdm))
  allocate(meanssh(idm, jdm))
  allocate(p(idm, jdm, kdm + 1))
  allocate(salt3d(idm, jdm, kdm))
  allocate(montg(idm, jdm, kdm))
  allocate(thstar(idm, jdm, kdm))
  allocate(dp3d(idm, jdm, kdm))
  allocate(temp3d(idm, jdm, kdm))
  allocate(u3d(idm, jdm, kdm))
  allocate(v3d(idm, jdm, kdm))

  ! Get restart fields psikk and thkk
  call read_rstfield2d(fbase, 'psikk   ', psikk, idm, jdm, 0, UNDEF)
  call read_rstfield2d(fbase, 'thkk    ', thkk ,idm, jdm, 0, UNDEF)
  call read_rstfield2d(fbase, 'pbavg   ', pbavg, idm, jdm, 0, UNDEF)

#if defined(HYCOM_CICE)
  call read_iced_nc(fnameice,ficem,hicem,hsnwm,idm,jdm,5,UNDEF)
#endif

  p(:,:,:) = 0.0

  do k = 1, kdm
     call read_rstfield2d(fbase, 'saln    ', salt , idm, jdm, k, UNDEF)
     call read_rstfield2d(fbase, 'temp    ', temp , idm, jdm, k, UNDEF)
     call read_rstfield2d(fbase, 'dp      ', dp   , idm, jdm, k, UNDEF)
     call read_rstfield2d(fbase, 'u       ', u    , idm, jdm, k, UNDEF)
     call read_rstfield2d(fbase, 'v       ', v    , idm, jdm, k, UNDEF)

     salt3d(:, :, k) = salt
     temp3d(:, :, k) = temp
     dp3d(:, :, k) = dp
     u3d(:, :, k) = u
     v3d(:, :, k) = v

     ! use upper interface pressure in converting sigma to sigma-star.
     ! this is to avoid density variations in layers intersected by bottom
     ! NB - KAL - thstar/th3d are densities with thbase = 0.0
     !
     do j = 1, jdm
        do i = 1, idm
           if (depths(i, j) > 0.1 .and. depths(i, j) < 1.0e29) then
              ! sig-option time
              if (thflag == 0) then 
                 tmpth3d = sig0(temp(i, j), salt(i, j))
                 tmpkapf = kappaf0(temp(i, j), salt(i,j), p(i, j, k))
              elseif (thflag == 2) then 
                 tmpth3d = sig2(temp(i, j), salt(i, j))
                 tmpkapf = kappaf2(temp(i, j), salt(i, j), p(i, j, k))
              elseif (thflag == 4) then 
                 tmpth3d = sig4(temp(i, j), salt(i, j))
                 tmpkapf = kappaf4(temp(i, j), salt(i, j), p( i, j, k))
              else
                 print *, 'ERROR: unknown thflag "', thflag, '"'
                 stop
              end if

              th3d(i, j) = tmpth3d
              if (tbaric) then
                 thstar(i, j, k) = th3d(i, j) + tmpkapf
              else
                 thstar(i, j, k) = th3d(i, j)
              end if
              p(i, j, k + 1) = p(i, j, k) + dp(i, j)
           end if
        end do ! i
     end do ! j
  end do ! k

  do j = 1, jdm
     do i = 1, idm
        if (depths(i, j) > 0.1 .and. depths(i, j) < 1.0e29) then
           oneta(i, j) = 1.0 + pbavg(i, j) / p(i, j, kdm + 1)
           montg(i, j, kdm) = psikk(i, j)&
                + (p(i, j, kdm + 1) * (thkk(i, j) + thbase - thstar(i, j, kdm))&
                - pbavg(i, j) * (thstar(i, j, kdm))) * thref ** 2
        end if
     end do
  end do

  ! m_prime in remaining layers:
  !
  do k = kdm - 1, 1, -1
     do j = 1, jdm
        do i = 1, idm
           if (depths(i, j) > 0.1 .and. depths(i, j) < 1.0e29) then
              montg(i, j, k) = montg(i, j, k + 1) + p(i, j, k + 1)&
                   * oneta(i, j)&
                   * (thstar(i, j, k + 1) - thstar(i, j, k)) * thref ** 2
           end if
        end do
     end do
  end do

  ! SSH
  !
  do j = 1, jdm
     do i = 1, idm
        if (depths(i, j) > 0.1 .and. depths(i, j) < 1.0e29) then
           ssh(i, j) = (montg(i, j, 1) / thref + pbavg(i, j)) / ONEMETER 
        end if
     end do
  end do

  ! try to get mean ssh
  fname_meanssh='meanssh.uf'
  
  inquire(exist = ex, file = trim(fname_meanssh))
  if(ex) then
     print *, 'found "', trim(fname_meanssh), '" -- calculating sla'
     open(10, file = trim(fname_meanssh), status = 'old', form = 'unformatted')
     read(10) iofld
     close(10)
     meanssh = iofld
     print *, 'range(mean SSH) =', minval(iofld), ',', maxval(iofld)
     
     sla = ssh - meanssh
  else
     print *,'did not find "', fname_meanssh, '" -- setting sla to zero'
     sla = 0.0
     meanssh = 0.0
  end if

  print 9000, int(POUT / ONEMETER)
  print *, 'interpolating 3D fields to fixed Z levels...'
  allocate(temp_z(idm, jdm, NKOUT));
  allocate(salt_z(idm, jdm, NKOUT));
  allocate(u_z(idm, jdm, NKOUT));
  allocate(v_z(idm, jdm, NKOUT));
  do j = 1, jdm
     do i = 1, idm
        call interpolate_vertically(kdm, p(i, j, 2 : kdm + 1),&
             temp3d(i, j, :), NKOUT, POUT, temp_z(i, j, :))
     end do
  end do
  do j = 1, jdm
     do i = 1, idm
        call interpolate_vertically(kdm, p(i, j, 2 : kdm + 1),&
             salt3d(i, j, :), NKOUT, POUT, salt_z(i, j, :))
     end do
  end do
  do j = 1, jdm
     do i = 1, idm
        call interpolate_vertically(kdm, p(i, j, 2 : kdm + 1),&
             u3d(i, j, :), NKOUT, POUT, u_z(i, j, :))
     end do
  end do
  do j = 1, jdm
     do i = 1, idm
        call interpolate_vertically(kdm, p(i, j, 2 : kdm + 1),&
             v3d(i, j, :), NKOUT, POUT, v_z(i, j, :))
     end do
  end do
  !Taking away the power 30 value
  where(depths < 0.1 .or. depths > 1.0e29) 
     ssh=nf_fill_float
     sla=nf_fill_float
     meanssh=nf_fill_float
     depths=nf_fill_float
  end where
  dp3d = dp3d / ONEMETER
  p = p / ONEMETER
  where (p == 0.0 ) p = nf_fill_float
  where (dp3d == 0.0 .or. dp3d > 1.0e20) 
     dp3d = nf_fill_float
     temp3d=nf_fill_float
     salt3d=nf_fill_float
     u3d=nf_fill_float
     v3d=nf_fill_float
 end where


  fname_nc = trim(fbase) // '.nc'
  print *, 'dumping fields to NetCDF file "', trim(fname_nc), '"...'

  call nfw_create(fname_nc, nf_write, ncid)
  call nfw_def_dim(fname_nc, ncid, 'i', idm, dimids(1))
  call nfw_def_dim(fname_nc, ncid, 'j', jdm, dimids(2))
  call nfw_def_dim(fname_nc, ncid, 'k', kdm, dimids(3))
  call nfw_def_dim(fname_nc, ncid, 'kz', NKOUT, kz_id(1))
      
  call nfw_def_var(fname_nc, ncid, 'lon', nf_double, 2, dimids, lon_id)
  call nfw_def_var(fname_nc, ncid, 'lat', nf_double, 2, dimids, lat_id)
  call nfw_def_var(fname_nc, ncid, 'depth', nf_double, 2, dimids, depth_id)
  call nfw_def_var(fname_nc, ncid, 'ssh', nf_double, 2, dimids, ssh_id)
  call nfw_def_var(fname_nc, ncid, 'meanssh', nf_double, 2, dimids, meanssh_id)
  call nfw_def_var(fname_nc, ncid, 'sla', nf_double, 2, dimids, sla_id)
  call nfw_def_var(fname_nc, ncid, 'ficem', nf_double, 2, dimids, ficem_id)
  call nfw_def_var(fname_nc, ncid, 'hicem', nf_double, 2, dimids, hicem_id)
  call nfw_def_var(fname_nc, ncid, 'hsnwm', nf_double, 2, dimids, hsnwm_id)
#if defined(HYCOM_CICE)
  print *, 'skipping tsrfm, sicem, tsnom ticem at current ..'
#endif
  call nfw_def_var(fname_nc, ncid, 'temp', nf_float, 3, dimids, temp_id)
  call nfw_def_var(fname_nc, ncid, 'salt', nf_float, 3, dimids, salt_id)
  call nfw_def_var(fname_nc, ncid, 'dp', nf_float, 3, dimids, dp_id)
  call nfw_def_var(fname_nc, ncid, 'u', nf_float, 3, dimids, u_id)
  call nfw_def_var(fname_nc, ncid, 'v', nf_float, 3, dimids, v_id)
  call nfw_def_var(fname_nc, ncid, 'p', nf_float, 3, dimids, p_id)
  dimids(3) = kz_id(1)
  call nfw_def_var(fname_nc, ncid, 'temp_z', nf_float, 3, dimids, temp_z_id)
  call nfw_def_var(fname_nc, ncid, 'salt_z', nf_float, 3, dimids, salt_z_id)
  call nfw_def_var(fname_nc, ncid, 'u_z', nf_float, 3, dimids, u_z_id)
  call nfw_def_var(fname_nc, ncid, 'v_z', nf_float, 3, dimids, v_z_id)
  call nfw_enddef(fname_nc, ncid)

  call nfw_put_var_double(fname_nc, ncid, lon_id, modlon)
  call nfw_put_var_double(fname_nc, ncid, lat_id, modlat)
  call nfw_put_var_double(fname_nc, ncid, depth_id, depths)
  call nfw_put_var_double(fname_nc, ncid, ssh_id, ssh)
  call nfw_put_var_double(fname_nc, ncid, meanssh_id, meanssh)
  call nfw_put_var_double(fname_nc, ncid, sla_id, sla)
  call nfw_put_var_double(fname_nc, ncid, ficem_id, ficem)
  call nfw_put_var_double(fname_nc, ncid, hicem_id, hicem)
  call nfw_put_var_double(fname_nc, ncid, hsnwm_id, hsnwm)
#if defined(HYCOM_CICE)
  print *, 'skipping tsrfm, sicem, tsnom ticem at current ..'
  !call nfw_put_var_double(fname_nc, ncid, ticem_id, ticem)
  !call nfw_put_var_double(fname_nc, ncid, tsrfm_id, tsrfm)
#endif
  call nfw_put_var_double(fname_nc, ncid, p_id, p(:, :, 2 : kdm + 1))
  call nfw_put_var_double(fname_nc, ncid, temp_id, temp3d)
  call nfw_put_var_double(fname_nc, ncid, salt_id, salt3d)
  call nfw_put_var_double(fname_nc, ncid, u_id, u3d)
  call nfw_put_var_double(fname_nc, ncid, v_id, v3d)
  call nfw_put_var_double(fname_nc, ncid, dp_id, dp3d)
  call nfw_put_var_double(fname_nc, ncid, p_id, p(:, :, 2 : kdm + 1))
  call nfw_put_var_double(fname_nc, ncid, temp_z_id, temp_z)
  call nfw_put_var_double(fname_nc, ncid, salt_z_id, salt_z)
  call nfw_put_var_double(fname_nc, ncid, u_z_id, u_z)
  call nfw_put_var_double(fname_nc, ncid, v_z_id, v_z)
  call nfw_close(fname_nc, ncid)

  9000 format(' Z levels used in interpolation: ', 26(I0, ' '), 'm')
end program p_restart2nc


subroutine interpolate_vertically(nkin, pin, fin, nkout, pout, fout)
  use nfw_mod
  implicit none

  real, parameter :: ONEMETER  = 9806.0

  integer, intent(in) :: nkin
  real, intent(in) :: pin(nkin)
  real, intent(in) :: fin(nkin)
  integer, intent(in) :: nkout
  real, intent(in) :: pout(nkout)
  real, intent(inout) :: fout(nkout)

  real :: sumabs
  integer :: k, kin1, kin2, kout

  sumabs = 0.0
  do k = 1, nkin
     sumabs = sumabs + abs(pin(k))
  end do

  if (sumabs == 0.0) then
     fout = nf_fill_float
     return
  end if

  kin1 = 1
  kin2 = 1
  kout = 1
  do while (kout <= nkout)
     do while (kin1 + 1 <= nkin .and. pin(kin1 + 1) < pout(kout))
        kin1 = kin1 + 1
     end do
     do while (kin2 + 1 <= nkin .and. pin(kin2)  < pout(kout))
        kin2 = kin2 + 1
     end do

     if (kin2 == 1) then
        fout(kout) = fin(1)
     else if (kin1 == nkin) then
        fout(kout) = fin(nkin)
     else if (abs(pin(kin2) - pin(kin1)) < 0.1 * ONEMETER) then
        fout(kout) = (fin(kin1) + fin(kin2)) / 2.0
     else
        fout(kout) = (fin(kin1) * (pin(kin2) - pout(kout))&
             + fin(kin2) * (pout(kout) - pin(kin1))) / (pin(kin2) - pin(kin1))
     end if

     kout = kout + 1
  end do
end subroutine interpolate_vertically
