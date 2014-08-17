!!!-----------------------------------------------------------------------
!!! project : azalea
!!! program : ctqmc_save_status
!!!           ctqmc_retrieve_status
!!! source  : ctqmc_status.f90
!!! type    : subroutine
!!! author  : li huang (email:huangli712@gmail.com)
!!! history : 09/23/2009 by li huang
!!!           02/21/2010 by li huang
!!!           08/15/2014 by li huang
!!! purpose : save or retrieve the data structures of the perturbation
!!!           expansion series to or from the well-formatted status file
!!!           for hybridization expansion version continuous time quantum
!!!           Monte Carlo (CTQMC) quantum impurity solver, respectively.
!!!           it can be used to save the computational time to achieve the
!!!           equilibrium state
!!! status  : unstable
!!! comment :
!!!-----------------------------------------------------------------------

!!>>> ctqmc_save_status: save the current perturbation expansion series
!!>>> information for the continuous time quantum Monte Carlo quantum
!!>>> impurity solver
  subroutine ctqmc_save_status()
     use constants, only : dp, mytmp
     use control, only : norbs
     use context, only : stts, rank, index_s, index_e, time_s, time_e

     implicit none

! local variables
! loop index over orbitals
     integer :: i

! loop index over segments
     integer :: j

! string for current date and time
     character (len = 20) :: date_time_string

! obtain current date and time
     call s_time_builder(date_time_string)

! open status file: solver.status.dat
     open(mytmp, file='solver.status.dat', form='formatted', status='unknown')

! write the header message
     write(mytmp,'(a)') '>> WARNING: DO NOT MODIFY THIS FILE MANUALLY'
     write(mytmp,'(a)') '>> it is used to store current status of ctqmc quantum impurity solver'
     write(mytmp,'(a)') '>> generated by AZALEA code at '//date_time_string
     write(mytmp,'(a)') '>> any problem, please contact me: huangli712@gmail.com'

! dump the segments
     do i=1,norbs
         write(mytmp,'(a,i4)') '# flavor     :', i
         write(mytmp,'(a,i4)') '# status     :', stts(i)

! write out start point values for segments (create  operators)
         write(mytmp,'(a,i4)') '# time_s data:', rank(i)
         do j=1,rank(i)
             write(mytmp,'(2i4,f12.6)') i, j, time_s( index_s(j, i), i )
         enddo ! over j={1,rank(i)} loop

! write out end   point values for segments (destroy operators)
         write(mytmp,'(a,i4)') '# time_e data:', rank(i)
         do j=1,rank(i)
             write(mytmp,'(2i4,f12.6)') i, j, time_e( index_e(j, i), i )
         enddo ! over j={1,rank(i)} loop

         write(mytmp,*) ! write empty lines
         write(mytmp,*)
     enddo ! over i={1,norbs} loop

! close the file handler
     close(mytmp)

     return
  end subroutine ctqmc_save_status

!!>>> ctqmc_retrieve_status: retrieve the perturbation expansion series
!!>>> information to initialize the continuous time quantum Monte Carlo
!!>>> quantum impurity solver
  subroutine ctqmc_retrieve_status()
     use constants, only : dp, zero, mytmp
     use control, only : mkink, norbs, beta, myid, master
     use context, only : ckink, cstat, stts, rank

     use mmpi

     implicit none

! local variables
! loop index
     integer  :: i
     integer  :: j

! dummy integer variables
     integer  :: i1
     integer  :: j1

! used to check whether the input file (solver.status.dat) exists
     logical  :: exists

! dummy character variables
     character(14) :: chr

! determinant ratio for insert segments
     real(dp) :: deter_ratio

! dummy variables, used to store imaginary time points
     real(dp) :: tau_s(mkink,norbs)
     real(dp) :: tau_e(mkink,norbs)

! initialize variables
     exists = .false.

     tau_s = zero
     tau_e = zero

! inquire file status: solver.status.dat, only master node can do it
     if ( myid == master ) then
         inquire (file = 'solver.status.dat', exist = exists)
     endif ! back if ( myid == master ) block

! broadcast exists from master node to all children nodes
# if defined (MPI)

! broadcast data
     call mp_bcast( exists, master )

! block until all processes have reached here
     call mp_barrier()

# endif  /* MPI */

! if solver.status.dat does not exist, return parent subroutine immediately
     if ( exists .eqv. .false. ) RETURN

! read solver.status.dat, only master node can do it
     if ( myid == master ) then

! open the status file
         open(mytmp, file='solver.status.dat', form='formatted', status='unknown')

! skip comment lines
         read(mytmp,*)
         read(mytmp,*)
         read(mytmp,*)
         read(mytmp,*)

! read in key data
         do i=1,norbs
             read(mytmp, '(a14,i4)') chr, i1
             read(mytmp, '(a14,i4)') chr, cstat

             read(mytmp, '(a14,i4)') chr, ckink
             do j=1,ckink
                 read(mytmp,*) i1, j1, tau_s(j, i)
             enddo ! over j={1,ckink} loop

             read(mytmp, '(a14,i4)') chr, ckink
             do j=1,ckink
                 read(mytmp,*) i1, j1, tau_e(j, i)
             enddo ! over j={1,ckink} loop

             read(mytmp,*) ! skip two lines
             read(mytmp,*)

             stts(i) = cstat
             rank(i) = ckink
         enddo ! over i={1,norbs} loop

! close the status file
         close(mytmp)

     endif ! back if ( myid == master ) block

! broadcast rank, stts, tau_s, and tau_e from master node to all children nodes
# if defined (MPI)

! broadcast data
     call mp_bcast( rank,  master )
     call mp_bcast( stts,  master )

! block until all processes have reached here
     call mp_barrier()

! broadcast data
     call mp_bcast( tau_s, master )
     call mp_bcast( tau_e, master )

! block until all processes have reached here
     call mp_barrier()

# endif  /* MPI */

! check the validity of tau_s
     if ( maxval(tau_s) > beta ) then
         call s_print_error('ctqmc_retrieve_status','the retrieved tau_s data are not correct')
     endif ! back if ( maxval(tau_s) > beta ) block

! check the validity of tau_e
     if ( maxval(tau_e) > beta ) then
         call s_print_error('ctqmc_retrieve_status','the retrieved tau_e data are not correct')
     endif ! back if ( maxval(tau_e) > beta ) block

! restore all the segments or anti-segments
     do i=1,norbs

! segment scheme
         if ( stts(i) == 1 ) then
             do j=1,rank(i)
                 ckink = j - 1 ! update ckink simultaneously
                 call cat_insert_detrat(i, tau_s(j, i), tau_e(j, i), deter_ratio)
                 call cat_insert_matrix(i, j, j, tau_s(j, i), tau_e(j, i), deter_ratio)
             enddo ! over j={1,rank(i)} loop
         endif ! back if ( stts(i) == 1 ) block

! anti-segment scheme
         if ( stts(i) == 2 ) then
             do j=1,rank(i)-1
                 ckink = j - 1 ! update ckink simultaneously
                 call cat_insert_detrat(i, tau_s(j, i), tau_e(j+1, i), deter_ratio)
                 call cat_insert_matrix(i, j, j, tau_s(j, i), tau_e(j+1, i), deter_ratio)
             enddo ! over j={1,rank(i)-1} loop
             ckink = rank(i) - 1
             call cat_insert_detrat(i, tau_s(ckink+1, i), tau_e(1, i), deter_ratio)
             call cat_insert_matrix(i, ckink+1, 1, tau_s(ckink+1, i), tau_e(1, i), deter_ratio)
         endif ! back if ( stts(i) == 1 ) block

     enddo ! over i={1,norbs} loop

     return
  end subroutine ctqmc_retrieve_status
