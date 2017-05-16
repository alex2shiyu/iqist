!!!-----------------------------------------------------------------------
!!! project : manjushaka
!!! program : ctqmc_print_header
!!!           ctqmc_print_footer
!!!           ctqmc_print_summary
!!!           ctqmc_print_control
!!!           ctqmc_print_runtime
!!!           ctqmc_print_it_info
!!! source  : ctqmc_print.f90
!!! type    : subroutines
!!! author  : li huang (email:lihuang.dmft@gmail.com)
!!! history : 09/15/2009 by li huang (created)
!!!           05/16/2017 by li huang (last modified)
!!! purpose : provide printing infrastructure for hybridization expansion
!!!           version continuous time quantum Monte Carlo (CTQMC) quantum
!!!           impurity solver and dynamical mean field theory (DMFT) self
!!!           -consistent engine.
!!! status  : unstable
!!! comment :
!!!-----------------------------------------------------------------------

!!
!! @sub ctqmc_print_header
!!
!! print the startup information for continuous time quantum Monte Carlo
!! quantum impurity solver plus dynamical mean field theory engine
!!
  subroutine ctqmc_print_header()
     use constants, only : mystd

     use version, only : FULL_VER
     use version, only : AUTH_VER
     use version, only : MAIL_VER
     use version, only : GPL3_VER

     use control, only : cname
     use control, only : nprocs

     implicit none

! local variables
! string for current date and time
     character (len = 20) :: date_time_string

! obtain current date and time
     call s_time_builder(date_time_string)

# if defined (MPI)

     write(mystd,'(2X,a)') cname//' (parallelized edition)'

# else   /* MPI */

     write(mystd,'(2X,a)') cname//' (sequential edition)'

# endif  /* MPI */

     write(mystd,'(2X,a)') 'A Modern Continuous Time Quantum Monte Carlo Impurity Solver'
     write(mystd,*)

     write(mystd,'(2X,a)') 'Version: '//FULL_VER//' (built at '//__TIME__//" "//__DATE__//')'
     write(mystd,'(2X,a)') 'Develop: '//AUTH_VER
     write(mystd,'(2X,a)') 'Support: '//MAIL_VER
     write(mystd,'(2X,a)') 'License: '//GPL3_VER
     write(mystd,*)

     write(mystd,'(2X,a)') 'start running at '//date_time_string

# if defined (MPI)

     write(mystd,'(2X,a,i4)') 'currently using cpu cores:', nprocs

# else   /* MPI */

     write(mystd,'(2X,a,i4)') 'currently using cpu cores:', 1

# endif  /* MPI */

     return
  end subroutine ctqmc_print_header

!!
!! @sub ctqmc_print_footer
!!
!! print the ending information for continuous time quantum Monte Carlo
!! quantum impurity solver plus dynamical mean field theory engine
!!
  subroutine ctqmc_print_footer()
     use constants, only : dp, mystd

     use control, only : cname

     implicit none

! local variables
! string for current date and time
     character (len = 20) :: date_time_string

! used to record the time usage information
     real(dp) :: tot_time

! obtain time usage information
     call cpu_time(tot_time)

! obtain current date and time
     call s_time_builder(date_time_string)

     write(mystd,'(2X,a,f10.2,a)') cname//' >>> total time spent:', tot_time, 's'
     write(mystd,*)

     write(mystd,'(2X,a)') cname//' >>> I am tired and want to go to bed. Bye!'
     write(mystd,'(2X,a)') cname//' >>> happy ending at '//date_time_string

     return
  end subroutine ctqmc_print_footer

!!
!! @sub ctqmc_print_summary
!!
!! print the running parameters, only for reference
!!
  subroutine ctqmc_print_summary()
     use constants, only : mystd

     use control ! ALL

     implicit none

     write(mystd,'(2X,a)') 'configuration parameters for global control'
     write(mystd,'(2X,a)') '----------------------------------------------------'
     write(mystd,'(4X,a,i10,  a4,a10)') 'isscf  /', isscf , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'isscr  /', isscr , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'isbnd  /', isbnd , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'isspn  /', isspn , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'isopt  /', isopt , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'iscut  /', iscut , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'isbin  /', isbin , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'iswor  /', iswor , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'isort  /', isort , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'isobs  /', isobs , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'issus  /', issus , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'isvrt  /', isvrt , '/', 'integer'

     write(mystd,'(2X,a)') 'configuration parameters for self-consistent engine'
     write(mystd,'(2X,a)') '----------------------------------------------------'
     write(mystd,'(4X,a,i10,  a4,a10)') 'niter  /', niter , '/', 'integer'
     write(mystd,'(4X,a,f10.5,a4,a10)') 'alpha  /', alpha , '/', ' double'

     write(mystd,'(2X,a)') 'configuration parameters for quantum impurity model'
     write(mystd,'(2X,a)') '----------------------------------------------------'
     write(mystd,'(4X,a,i10,  a4,a10)') 'nband  /', nband , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'nspin  /', nspin , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'norbs  /', norbs , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'ncfgs  /', ncfgs , '/', 'integer'
     write(mystd,'(4X,a,f10.5,a4,a10)') 'Uc     /', Uc    , '/', ' double'
     write(mystd,'(4X,a,f10.5,a4,a10)') 'Jz     /', Jz    , '/', ' double'
     write(mystd,'(4X,a,f10.5,a4,a10)') 'lc     /', lc    , '/', ' double'
     write(mystd,'(4X,a,f10.5,a4,a10)') 'wc     /', wc    , '/', ' double'
     write(mystd,'(4X,a,f10.5,a4,a10)') 'mune   /', mune  , '/', ' double'
     write(mystd,'(4X,a,f10.5,a4,a10)') 'beta   /', beta  , '/', ' double'
     write(mystd,'(4X,a,f10.5,a4,a10)') 'part   /', part  , '/', ' double'

     write(mystd,'(2X,a)') 'configuration parameters for quantum impurity solver'
     write(mystd,'(2X,a)') '----------------------------------------------------'
     write(mystd,'(4X,a,i10,  a4,a10)') 'lemax  /', lemax , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'legrd  /', legrd , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'mkink  /', mkink , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'mfreq  /', mfreq , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'nffrq  /', nffrq , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'nbfrq  /', nbfrq , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'nfreq  /', nfreq , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'ntime  /', ntime , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'npart  /', npart , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'nflip  /', nflip , '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'ntherm /', ntherm, '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'nsweep /', nsweep, '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'nclean /', nclean, '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'nwrite /', nwrite, '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'nmonte /', nmonte, '/', 'integer'
     write(mystd,'(4X,a,i10,  a4,a10)') 'ncarlo /', ncarlo, '/', 'integer'

     write(mystd,'(2(4X,a,i10))')   'ifast :', ifast  , 'itrun :', itrun 

     write(mystd,'(2(4X,a,i10))')   'npart :', npart  , 'nflip :', nflip

     write(mystd,*)

     return
  end subroutine ctqmc_print_summary

!!>>> ctqmc_print_runtime: print the runtime information, including physical
!!>>> observables and statistic data, only for reference
  subroutine ctqmc_print_runtime(iter, cstep)
     use constants, only : dp, one, half, mystd

     use control, only : cname
     use control, only : nsweep, nmonte
     use context, only : cnegs, caves
     use context, only : insert_tcount, insert_accept, insert_reject
     use context, only : remove_tcount, remove_accept, remove_reject
     use context, only : lshift_tcount, lshift_accept, lshift_reject
     use context, only : rshift_tcount, rshift_accept, rshift_reject
     use context, only : reflip_tcount, reflip_accept, reflip_reject
     use context, only : paux

     implicit none

! external arguments
! current self-consistent iteration number
     integer, intent(in) :: iter

! current QMC sweeping steps
     integer, intent(in) :: cstep

! local variables
! real(dp) dummy variables
     real(dp) :: raux

! about iteration number
     write(mystd,'(2X,a,i3,2(a,i10))') cname//' >>> iter:', iter, ' sweep:', cstep, ' of ', nsweep

! about auxiliary physical observables
     raux = real(caves) / nmonte
     write(mystd,'(4X,a)')        'auxiliary system observables:'
     write(mystd,'(2(4X,a,f10.5))') 'etot :', paux(1) / raux, 'epot :', paux(2) / raux
     write(mystd,'(2(4X,a,f10.5))') 'ekin :', paux(3) / raux, '<Sz> :', paux(4) / raux
     write(mystd,'(2(4X,a,f10.5))') '<N1> :', paux(5) / raux, '<N2> :', paux(6) / raux
     write(mystd,'(2(4X,a,e10.5))') '<K2> :', paux(7) / raux, '<K3> :', paux(8) / raux
     write(mystd,'(1(4X,a,e10.5))') '<K4> :', paux(9) / raux

! about insert action
     if ( insert_tcount <= half ) insert_tcount = -one ! if insert is disable
     write(mystd,'(4X,a)')        'insert kink statistics:'
     write(mystd,'(4X,a,3i10)')   'count:', int( insert_tcount ), int( insert_accept ), int( insert_reject )
     write(mystd,'(4X,a,3f10.5)') 'ratio:', one, insert_accept / insert_tcount, insert_reject / insert_tcount

! about remove action
     if ( remove_tcount <= half ) remove_tcount = -one ! if remove is disable
     write(mystd,'(4X,a)')        'remove kink statistics:'
     write(mystd,'(4X,a,3i10)')   'count:', int( remove_tcount ), int( remove_accept ), int( remove_reject )
     write(mystd,'(4X,a,3f10.5)') 'ratio:', one, remove_accept / remove_tcount, remove_reject / remove_tcount

! about lshift action
     if ( lshift_tcount <= half ) lshift_tcount = -one ! if lshift is disable
     write(mystd,'(4X,a)')        'lshift kink statistics:'
     write(mystd,'(4X,a,3i10)')   'count:', int( lshift_tcount ), int( lshift_accept ), int( lshift_reject )
     write(mystd,'(4X,a,3f10.5)') 'ratio:', one, lshift_accept / lshift_tcount, lshift_reject / lshift_tcount

! about rshift action
     if ( rshift_tcount <= half ) rshift_tcount = -one ! if rshift is disable
     write(mystd,'(4X,a)')        'rshift kink statistics:'
     write(mystd,'(4X,a,3i10)')   'count:', int( rshift_tcount ), int( rshift_accept ), int( rshift_reject )
     write(mystd,'(4X,a,3f10.5)') 'ratio:', one, rshift_accept / rshift_tcount, rshift_reject / rshift_tcount

! about reflip action
     if ( reflip_tcount <= half ) reflip_tcount = -one ! if reflip is disable
     write(mystd,'(4X,a)')        'global flip statistics:'
     write(mystd,'(4X,a,3i10)')   'count:', int( reflip_tcount ), int( reflip_accept ), int( reflip_reject )
     write(mystd,'(4X,a,3f10.5)') 'ratio:', one, reflip_accept / reflip_tcount, reflip_reject / reflip_tcount

! about negative sign
     write(mystd,'(4X,a,i10)')    'negative sign counter:', cnegs
     write(mystd,'(4X,a,f10.5)')  'averaged sign sampler:', caves / real(cstep)

     return
  end subroutine ctqmc_print_runtime

!!>>> ctqmc_print_it_info: print the iteration information to the screen
  subroutine ctqmc_print_it_info(iter)
     use constants, only : mystd

     use control, only : cname

     implicit none

! external arguments
! current iteration number
     integer, intent(in) :: iter

! according to the value of iter, we can judge whether the impurity solver
! is in the binning mode.
     if ( iter /= 999 ) then
         write(mystd,'(2X,a,i3,a)') cname//' >>> DMFT iter:', iter, ' <<< SELFING'
     else
         write(mystd,'(2X,a,i3,a)') cname//' >>> DMFT iter:', iter, ' <<< BINNING'
     endif ! back if ( iter /= 999 ) block

     return
  end subroutine ctqmc_print_it_info
