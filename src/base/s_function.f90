!!!-----------------------------------------------------------------------
!!! project : CSSL (Common Service Subroutines Library)
!!! program : s_leg_basis
!!!           s_che_basis
!!!           s_svd_basis
!!!           s_svd_point
!!!           s_sph_jn
!!!           s_sph_jn_core
!!!           s_sph_jn_order
!!!           s_bezier
!!!           s_safe_exp
!!!           s_f_kernel
!!!           s_b_kernel
!!! source  : s_function.f90
!!! type    : subroutines & functions
!!! author  : li huang (email:lihuang.dmft@gmail.com)
!!! history : 07/10/2014 by li huang (created)
!!!           08/17/2017 by li huang (last modified)
!!! purpose : these subroutines are used to generate some auxiliary
!!!           functions, such as the Legendre orthogonal polynomial and
!!!           Chebyshev orthogonal polynomial, Bessel function, etc.
!!! status  : unstable
!!! comment :
!!!-----------------------------------------------------------------------

!!
!!
!! Introduction
!! ============
!!
!! 1. orthogonal polynomial basis
!! ------------------------------
!!
!! subroutine s_leg_basis(...)
!! subroutine s_che_basis(...)
!! subroutine s_svd_basis(...)
!! subroutine s_svd_point(...)
!!
!! 2. spheric Bessel function
!! --------------------------
!!
!! subroutine s_sph_jn(...)
!!
!! 3. bernstein polynomial
!! -----------------------
!!
!! subroutine s_bezier(...)
!!
!! 4. some helper functions for s_svd_basis
!! ----------------------------------------
!!
!! function s_safe_exp(...)
!! function s_f_kernel(...)
!! function s_b_kernel(...)
!!

!!========================================================================
!!>>> orthogonal polynomial basis                                      <<<
!!========================================================================

!!
!! @sub s_leg_basis
!!
!! build legendre orthogonal polynomial in [-1,1] interval
!!
  subroutine s_leg_basis(lemax, legrd, lmesh, rep_l)
     use constants, only : dp
     use constants, only : one

     implicit none

! external arguments
! maximum order for legendre orthogonal polynomial
     integer, intent(in)   :: lemax

! number of mesh points for legendre orthogonal polynomial
     integer, intent(in)   :: legrd

! mesh for legendre orthogonal polynomial in [-1,1]
     real(dp), intent(in)  :: lmesh(legrd)

! legendre orthogonal polynomial defined on [-1,1]
     real(dp), intent(out) :: rep_l(legrd,lemax)

! local variables
! loop index
     integer :: i
     integer :: j
     integer :: k

! check lemax
     if ( lemax <= 2 ) then
         call s_print_error('s_leg_basis','lemax must be larger than 2')
     endif ! back if ( lemax <= 2 ) block

! the legendre orthogonal polynomials obey the three term recurrence
! relation known as Bonnet’s recursion formula:
!     $P_0(x) = 1$
!     $P_1(x) = x$
!     $(n+1) P_{n+1}(x) = (2n+1) P_n(x) - n P_{n-1}(x)$
     do i=1,legrd
         rep_l(i,1) = one
         rep_l(i,2) = lmesh(i)
         do j=3,lemax
             k = j - 1
             rep_l(i,j) = ( real(2*k-1) * lmesh(i) * rep_l(i,j-1) - real(k-1) * rep_l(i,j-2) ) / real(k)
         enddo ! over j={3,lemax} loop
     enddo ! over i={1,legrd} loop

     return
  end subroutine s_leg_basis

!!
!! @sub s_che_basis
!!
!! build the second kind chebyshev orthogonal polynomial in [-1,1] interval
!!
  subroutine s_che_basis(chmax, chgrd, cmesh, rep_c)
     use constants, only : dp
     use constants, only : one, two

     implicit none

! external arguments
! maximum order for chebyshev orthogonal polynomial
     integer, intent(in)   :: chmax

! number of mesh points for chebyshev orthogonal polynomial
     integer, intent(in)   :: chgrd

! mesh for chebyshev orthogonal polynomial in [-1,1]
     real(dp), intent(in)  :: cmesh(chgrd)

! chebyshev orthogonal polynomial defined on [-1,1]
     real(dp), intent(out) :: rep_c(chgrd,chmax)

! local variables
! loop index
     integer :: i
     integer :: j

! check chmax
     if ( chmax <= 2 ) then
         call s_print_error('s_che_basis','chmax must be larger than 2')
     endif ! back if ( chmax <= 2 ) block

! the chebyshev orthogonal polynomials of the second kind can be defined
! by the following recurrence relation
!     $U_0(x) = 1$
!     $U_1(x) = 2x$
!     $U_{n+1}(x) = 2xU_n(x) - U_{n-1}(x)$
     do i=1,chgrd
         rep_c(i,1) = one
         rep_c(i,2) = two * cmesh(i)
         do j=3,chmax
             rep_c(i,j) = two * cmesh(i) * rep_c(i,j-1) - rep_c(i,j-2)
         enddo ! over j={3,chmax} loop
     enddo ! over i={1,chgrd} loop

     return
  end subroutine s_che_basis

!!
!! @sub s_svd_basis
!!
!! build the svd orthogonal polynomial in [-1,1] interval
!!
  subroutine s_svd_basis(svmax, svgrd, smesh, rep_s, bose, beta)
     use constants, only : dp
     use constants, only : pi, zero, one, two
     use constants, only : epss

     implicit none

! external arguments
! maximum order for svd orthogonal polynomial
     integer, intent(in)   :: svmax

! number of mesh points for svd orthogonal polynomial
     integer, intent(in)   :: svgrd

! using fermionic or bosonic kernel function
     logical, intent(in)   :: bose

! inversion of temperature
     real(dp), intent(in)  :: beta

! mesh for svd orthogonal polynomial in [-1,1]
     real(dp), intent(in)  :: smesh(svgrd)

! svd orthogonal polynomial defined on [-1,1]
     real(dp), intent(out) :: rep_s(svgrd,svmax)

! external arguments
! used to calculate the fermionic kernel function
     procedure ( real(dp) ) :: s_f_kernel

! used to calculate the bosonic kernel function
     procedure ( real(dp) ) :: s_b_kernel

! local parameters
! number of mesh points for real frequency
     integer, parameter  :: wsize = 513

! left boundary for real frequency mesh, \omega_{min}
     real(dp), parameter :: w_min = -10.0_dp

! right boundary for real frequency mesh, \omega_{max}
     real(dp), parameter :: w_max = +10.0_dp

! boundary for linear imaginary time mesh
! it must be the same with the one defined in the s_svd_point
     real(dp), parameter :: limit = +3.00_dp

! local variables
! loop index
     integer  :: i
     integer  :: j

! status flag
     integer  :: istat

! dummy real(dp) variable
     real(dp) :: t

! non-uniform imaginary time mesh
     real(dp), allocatable :: tmesh(:)
     real(dp), allocatable :: wmesh(:) ! integration weight

! real axis mesh
     real(dp), allocatable :: fmesh(:)

! fermionic or bosonic kernel function
     real(dp), allocatable :: fker(:,:)

! U, \Sigma, and V matrices for singular values decomposition
     real(dp), allocatable :: umat(:,:)
     real(dp), allocatable :: svec(:)
     real(dp), allocatable :: vmat(:,:)

! make sure wsize is less than svgrd
     if ( svgrd <= wsize ) then
         call s_print_error('s_svd_basis','please make sure svgrd > wsize')
     endif ! back if ( svgrd <= wsize ) block

! make sure wsize is larger than svmax
     if ( svmax >= wsize ) then
         call s_print_error('s_svd_basis','please make sure svmax < wsize')
     endif ! back if ( svmax >= wsize ) block

! allocate memory
     allocate(tmesh(svgrd),      stat=istat)
     allocate(wmesh(svgrd),      stat=istat)
     allocate(fmesh(wsize),      stat=istat)
     allocate(fker(svgrd,wsize), stat=istat)
     allocate(umat(svgrd,wsize), stat=istat)
     allocate(svec(wsize),       stat=istat)
     allocate(vmat(wsize,wsize), stat=istat)

     if ( istat /= 0 ) then
         call s_print_error('s_svd_basis','can not allocate enough memory')
     endif ! back if ( istat /= 0 ) block

! build non-uniform imaginary time mesh
     do i=1,svgrd
         t = limit * smesh(i) ! map the original mesh from [-1,1] to [-3,3]
         tmesh(i) = tanh( pi / two * sinh (t) )
         wmesh(i) = sqrt( pi / two * cosh (t) ) / cosh( pi / two * sinh(t) )
     enddo ! over i={1,svgrd} loop

! build real frequency mesh
     call s_linspace_d(w_min, w_max, wsize, fmesh)

! build the fermionic or bosonic kernel function
     do i=1,wsize
         do j=1,svgrd
             if ( bose .eqv. .true. ) then
                 fker(j,i) = wmesh(j) * s_b_kernel(tmesh(j), fmesh(i), beta)
             else
                 fker(j,i) = wmesh(j) * s_f_kernel(tmesh(j), fmesh(i), beta)
             endif ! back if ( bose .eqv. .true. ) block
         enddo ! over j={1,svgrd} loop
     enddo ! over i={1,wsize} loop

! make singular values decomposition
     call s_svd_dg(svgrd, wsize, wsize, fker, umat, svec, vmat)

! check svec
     if ( abs( svec(svmax) / svec(1) ) > epss ) then
         call s_print_error('s_svd_basis','please increase svmax')
     endif ! back if ( abs( svec(svmax) / svec(1) ) > epss ) block

! normalize umat to make sure the orthogonality
     do i=1,svgrd
         umat(i,:) = umat(i,:) / wmesh(i)
     enddo ! over i={1,svgrd} loop

     do i=1,svmax
         t = ( two * limit / float(svgrd) ) * sum( ( umat(:,i) * wmesh(:) )**2 )
         umat(:,i) = umat(:,i) / sqrt(t)
     enddo ! over i={1,svmax} loop

! copy umat to rep_s
     do i=1,svmax
         if ( umat(svgrd,i) < zero ) then
             rep_s(:,i) = -one * umat(:,i)
         else
             rep_s(:,i) = +one * umat(:,i)
         endif ! back if ( umat(svgrd,i) < zero ) block
     enddo ! over i={1,svmax} loop

! deallocate memory
     deallocate(tmesh)
     deallocate(wmesh)
     deallocate(fmesh)
     deallocate(fker )
     deallocate(umat )
     deallocate(svec )
     deallocate(vmat )

     return
  end subroutine s_svd_basis

!!
!! @sub s_svd_point
!!
!! for a given point val, return its index in the non-uniform mesh
!!
  subroutine s_svd_point(val, stp, pnt)
     use constants, only : dp
     use constants, only : pi, zero, one, two

     implicit none

! external arguments
! point's value, it lies in a non-uniform mesh [-1,1]
     real(dp), intent(in) :: val

! step for an uniform mesh [-1,1]
     real(dp), intent(in) :: stp

! index in the non-uniform mesh [-1,1]
     integer, intent(out) :: pnt

! local parameters
! boundary for linear imaginary time mesh
! it must be the same with the one defined in the s_svd_basis
     real(dp), parameter :: limit = 3.0_dp

! local variables
! dummy real(dp) variable
     real(dp) :: dt

!
! note:
!
! 1. we have tau in [0,\beta]. the mesh is uniform (size is ntime)
! 2. then tau is mapped into val in [-1,1]. the mesh is non-uniform (size is svgrd)
! 3. then val is mapped into dt in [0,6]. here the mesh is uniform (size is svgrd)
! 4. we calculate the index for dt in the uniform mesh [0,6] (size is svgrd)
! 5. clearly, the obtained index is the same with the one in the non-uniform mesh
!

! val \in [-1,1], convert it to dt \in [-3,3]
     if ( -one < val .and. val < one ) then
         dt = asinh( two / pi * atanh(val) )
     else
         if ( val > zero ) then ! val == +one
             dt = asinh( two / pi * atanh(val - 0.00001_dp) )
         else                   ! val == -one
             dt = asinh( two / pi * atanh(val + 0.00001_dp) )
         endif ! back if ( val > zero ) block
     endif ! back if ( -one < val .and. val < one ) block

! shift dt from [-3,3] to [0,6]
     dt = dt + limit

! get the index for dt in linear mesh [0,6]
     pnt = nint( dt * stp / limit ) + 1

     return
  end subroutine s_svd_point

!!========================================================================
!!>>> spherical Bessel functions                                       <<<
!!========================================================================

!!
!! @sub s_sph_jn
!!
!! computes the spherical Bessel functions of the first kind, j_n(x), for
!! argument x and n=0, 1, \ldots, n_{max}
!!
  subroutine s_sph_jn(nmax, x, jn)
     use constants, only : dp

     implicit none

! external arguments
! maximum order of spherical Bessel function
     integer, intent(in)   :: nmax

! real argument
     real(dp), intent(in)  :: x

! array of returned values
     real(dp), intent(out) :: jn(0:nmax)

! local variables
! loop index
     integer :: i

!
! note:
!
! 1. we use the Liang-Wu Cai (2011) algorithm to calculate the spherical
!    Bessel functions. see:
!        http://dx.doi.org/10.1016/j.cpc.2010.11.019
!    for more details.
!
! 2. this implementation is inspired by the corresponding python code in
!    the spf package. see:
!        https://github.com/tpudlik/sbf
!    for more details.
!
     do i=0,nmax
         call s_sph_jn_core(i, x, sin(x)/x, sin(x)/x**2 - cos(x)/x, jn(i))
     enddo ! over i={0,nmax} loop

     return
  end subroutine s_sph_jn

!!
!! @sub s_sph_jn_core
!!
!! helper subroutine for the calculation of spherical Bessel functions
!!
  subroutine s_sph_jn_core(n, z, f0, f1, val)
     use constants, only : dp

     implicit none

! external arguments
! order of spherical Bessel function
     integer, intent(in)   :: n

! real argument
     real(dp), intent(in)  :: z

! j0 and j1
     real(dp), intent(in)  :: f0, f1

! returned value
     real(dp), intent(out) :: val

! local variables
     integer  :: start_order, idx
     real(dp) :: jlp1, jl, jlm1, out

! quick return
     if ( n == 0 ) then
         val = f0; RETURN
     endif

     if ( n == 1 ) then
         val = f1; RETURN
     endif

     call s_sph_jn_order(n, z, start_order)
     jlp1 = 0.0_dp
     jl = 10.0_dp**(-305.0_dp)

     do idx=0,start_order - n - 1
         jlm1 = (2*(start_order - idx) + 1)*jl/z - jlp1
         jlp1 = jl
         jl = jlm1
     enddo ! over idx={0,start_order - n - 1} loop
     out = jlm1
     do idx=0,n-1
         jlm1 = (2*(n - idx) + 1)*jl/z - jlp1
         jlp1 = jl
         jl = jlm1
     enddo ! over idx={0,n-1} loop

     if ( abs(f1) <= abs(f0) ) then
         val = out*(f0/jlm1)
     else
         val = out*(f1/jlp1)
     endif ! back if ( abs(f1) <= abs(f0) ) block

     return
  end subroutine s_sph_jn_core

!!
!! @sub s_sph_jn_order
!!
!! helper subroutine for the calculation of spherical Bessel functions
!!
  subroutine s_sph_jn_order(n, z, val)
    use constants, only : dp

    implicit none

! external arguments
! order of spherical Bessel function
    integer, intent(in)  :: n

! real argument
    real(dp), intent(in) :: z

! returned value
    integer, intent(out) :: val

! local variables
    real(dp) :: o_approx
    real(dp) :: o_min
    real(dp) :: o_max

    o_approx = floor( 1.83_dp * abs(z)**0.91_dp + 9.0_dp )
    o_min = n + 1.0
    o_max = floor( 235.0_dp + 50.0_dp * sqrt( abs(z) ) )

    if ( o_approx < o_min ) then
        val = int(o_min)
    else if ( o_approx > o_max ) then
        val = int(o_max)
    else
        val = int(o_approx)
    endif ! back if ( o_approx < o_min ) block

    return
  end subroutine s_sph_jn_order

!!========================================================================
!!>>> Bernstein polynomials                                            <<<
!!========================================================================

!!
!! @sub s_bezier
!!
!! to evaluates the bernstein polynomials at a point x
!!
  subroutine s_bezier(n, x, bern)
     use constants, only : dp
     use constants, only : one

     implicit none

! external arguments
! the degree of the bernstein polynomials to be used. for any N, there
! is a set of N+1 bernstein polynomials, each of degree N, which form a
! basis for polynomials on [0,1]
     integer, intent(in)  :: n

! the evaluation point.
     real(dp), intent(in) :: x

! the values of the N+1 bernstein polynomials at X
     real(dp), intent(inout) :: bern(0:n)

! local variables
! loop index
     integer :: i
     integer :: j

! the bernstein polynomials are assumed to be based on [0,1].
! the formula is:
!
!    B(N,I)(X) = [N!/(I!*(N-I)!)] * (1-X)**(N-I) * X**I
!
! first values:
!
!    B(0,0)(X) = 1
!    B(1,0)(X) =      1-X
!    B(1,1)(X) =                X
!    B(2,0)(X) =     (1-X)**2
!    B(2,1)(X) = 2 * (1-X)    * X
!    B(2,2)(X) =                X**2
!    B(3,0)(X) =     (1-X)**3
!    B(3,1)(X) = 3 * (1-X)**2 * X
!    B(3,2)(X) = 3 * (1-X)    * X**2
!    B(3,3)(X) =                X**3
!    B(4,0)(X) =     (1-X)**4
!    B(4,1)(X) = 4 * (1-X)**3 * X
!    B(4,2)(X) = 6 * (1-X)**2 * X**2
!    B(4,3)(X) = 4 * (1-X)    * X**3
!    B(4,4)(X) =                X**4
!
! special values:
!
!    B(N,I)(X) has a unique maximum value at X = I/N.
!    B(N,I)(X) has an I-fold zero at 0 and and N-I fold zero at 1.
!    B(N,I)(1/2) = C(N,K) / 2**N
!    for a fixed X and N, the polynomials add up to 1:
!    sum ( 0 <= I <= N ) B(N,I)(X) = 1
!
     if ( n == 0 ) then
         bern(0) = one

     else if ( 0 < n ) then
         bern(0) = one - x
         bern(1) = x
         do i=2,n
             bern(i) = x * bern(i-1)
             do j=i-1,1,-1
                 bern(j) = x * bern(j-1) + ( one - x ) * bern(j)
             enddo ! over j={i-1,1} loop
             bern(0) = ( one - x ) * bern(0)
         enddo ! over i={2,n} loop

     endif ! back if ( n == 0 ) block

     return
  end subroutine s_bezier

!!========================================================================
!!>>> helper functions for s_svd_basis                                 <<<
!!========================================================================

!!
!! @fun s_safe_exp
!!
!! a safe exp call to avoid data overflow
!!
  function s_safe_exp(x) result(val)
     use constants, only : dp
     use constants, only : zero

     implicit none

! external arguments
! input variable
     real(dp), intent(in) :: x

! local variables
! return value
     real(dp) :: val

     if ( x < -60.0_dp ) then
         val = zero
     else
         val = exp(x)
     endif ! back if ( x < -60.0_dp ) block

     return
  end function s_safe_exp

!!
!! @fun s_f_kernel
!!
!! used to calculate fermionic kernel function
!!
  function s_f_kernel(tau, omega, beta) result(val)
     use constants, only : dp
     use constants, only : one, two

     implicit none

! external arguments
! imaginary time point, it is alreay scaled to [-1,1]
     real(dp), intent(in) :: tau

! real frequency point
     real(dp), intent(in) :: omega

! inversion of temperature
     real(dp), intent(in) :: beta

! external arguments
! a safe exp call
     procedure( real(dp) ) :: s_safe_exp

! local variables
! return value
     real(dp) :: val

! dimensionless variables
     real(dp) :: x, y

     x = tau
     y = beta * omega / two

     if ( y > 200.0_dp ) then
         val = s_safe_exp( -y * ( x + one ) )
     else if ( y < -200.0_dp ) then
         val = s_safe_exp(  y * ( one - x ) )
     else
         val = s_safe_exp( -x * y ) / ( two * cosh(y) )
     endif ! back if ( y > 200.0_dp ) block

     return
  end function s_f_kernel

!!
!! @fun s_b_kernel
!!
!! used to calculate bosonic kernel function
!!
  function s_b_kernel(tau, omega, beta) result(val)
     use constants, only : dp
     use constants, only : one, two

! external arguments
! imaginary time point, it is alreay scaled to [-1,1]
     real(dp), intent(in) :: tau

! real frequency point
     real(dp), intent(in) :: omega

! inversion of temperature
     real(dp), intent(in) :: beta

! external arguments
! a safe exp call
     procedure( real(dp) ) :: s_safe_exp

! local variables
! return value
     real(dp) :: val

! dimensionless variables
     real(dp) :: x, y

     x = tau
     y = beta * omega / two

     if ( abs(y) < 1E-10 ) then
         val = s_safe_exp( -x * y )
     else if ( y > +200.0_dp ) then
         val = two * y * s_safe_exp( -y * ( x + one ) )
     else if ( y < -200.0_dp ) then
         val = -two * y * s_safe_exp( y * ( one - x ) )
     else
         val = y * s_safe_exp( -x * y ) / sinh(y)
     endif ! back if ( abs(y) < 1E-10 ) block

     return
  end function s_b_kernel
