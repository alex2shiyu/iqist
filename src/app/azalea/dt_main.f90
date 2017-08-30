
  program dt_main
     use mmpi, only : mp_init, mp_finalize
     use mmpi, only : mp_comm_rank, mp_comm_size
     use mmpi, only : mp_barrier

     use control, only : nprocs, myid, master

     implicit none

! initialize mpi envirnoment
# if defined (MPI)

! initialize the mpi execution environment
     call mp_init()

! determines the rank of the calling process in the communicator
     call mp_comm_rank(myid)

! determines the size of the group associated with a communicator
     call mp_comm_size(nprocs)

# endif  /* MPI */

     if ( myid == master ) then
         call dt_print_header()
     endif

     call dt_config()

     if ( myid == master ) then
         call dt_print_summary()
     endif

     call dt_setup_array()

     call dt_mesh_init()
     call dt_dmft_init()
     call dt_latt_init()
     call dt_dual_init()
     call dt_vert_init()

     call dt_run()

     call dt_final_array()

     if ( myid == master ) then
         call dt_print_footer()
     endif

! finalize mpi envirnoment
# if defined (MPI)

! blocks until all processes have reached this routine
     call mp_barrier()

! terminates mpi execution environment
     call mp_finalize()

# endif  /* MPI */

  end program dt_main