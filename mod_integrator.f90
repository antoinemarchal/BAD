! Module of the integrator that transforms the state_in to the state_out

module mod_integrator
  use mod_constants
  use mod_timestep
  use mod_read_parameters
  use mod_variables

  implicit none
  private

  public :: do_timestep_T, do_timestep_S_imp, do_timestep_S_exp

contains

  function f(s)
  !process the right term of \partial T* / \partial t* = (see Recapitulatif des adimensionenemts in report)
    implicit none

    type(state), intent(in)                    :: s
    real (kind=x_precision), dimension(n_cell) :: f

    ! Second member of the dT/dt equation
    f = (s%Qplus - s%Qminus) / s%Cv

  end function f

  function f_exp(s)
    !function to process the right term of dT/dt
    !return an array corresponding to the right term of dT/dt in each box
    implicit none

    type(state), intent(in)                    :: s
    real (kind=x_precision), dimension(n_cell) :: f_exp

    real (kind=x_precision)                    :: overdx, overdx2
    real (kind=x_precision), dimension(n_cell) :: dS_over_dt, dS_over_x_over_dx, S_over_x, dT_over_dx, nuS

    overdx  = 1._x_precision / params%dx
    overdx2 = overdx**2
    nuS     = s%nu * s%S

    ! Compute dT/dx as the right spatial derivative
    dT_over_dx(1:n_cell - 1) = (s%T(2:n_cell) - s%T(1:n_cell - 1)) * overdx
    dT_over_dx(n_cell)       = 0

    ! Compute d(S/x)/dx as the right spatial derivative
    S_over_x                        = s%S / x_state%x
    dS_over_x_over_dx(1:n_cell - 1) = (S_over_x(2:n_cell) - S_over_x(1:n_cell - 1)) * overdx
    dS_over_x_over_dx(n_cell)       = ( params%dx - nuS(n_cell) + nuS(n_cell-1) ) / &
                                      ( x_state%x(n_cell)**2 * s%v(n_cell) * params%dx**2 )

    ! Compute dS/dt using the corresponding equation, with d²(nuS)/dx² as (d(left)+d(right))/2
    dS_over_dt(1:n_cell-1) = ( nuS(2:n_cell) &
                             - 2._x_precision*nuS(1:n_cell-1) &
                             + nuS(1:n_cell-1) ) &
                             * overdx2 / x_state%x(1:n_cell-1)**2
    dS_over_dt(n_cell)     = ( params%dx - nuS(n_cell) + nuS(n_cell-1) ) / &
                             ( x_state%x(n_cell)**2 * params%dx**2 )
    ! FIX THIS : dS_over_dt is wrongly defined !


    !right term
    f_exp = ( 3._x_precision * state_0%v_0**2 * s%nu * x_state%Omega**2 &
            - s%Fz * x_state%x / s%s &
            + params%RTM * ( 4._x_precision - 3._x_precision * s%beta ) / s%beta * s%T / s%S &
            * ( dS_over_dt + s%v * dS_over_x_over_dx ) &
            - s%Cv * s%v / x_state%x * dT_over_dx ) &
            / s%Cv

  end function f_exp


  subroutine do_timestep_S_imp (s, dt)
  !process the temporal evolution of S
    implicit none

    type (state), intent(inout)                   :: s

    real(kind = x_precision)                      :: overdx, overdx2, dtoverdx2
    real(kind = x_precision), intent(in)          :: dt
    integer                                       :: info

    real(kind = x_precision), dimension(n_cell)   :: diag, x2
    real(kind = x_precision), dimension(n_cell-1) :: diag_low, diag_up

    overdx    = 1._x_precision / params%dx
    overdx2   = overdx**2
    dtoverdx2 = dt*overdx2

    x2 = x_state%x**2

    ! Create the diagonals NOT VERIFIED YET
    diag     =  1 + 2 * s%nu / x2 * dtoverdx2
    diag_up  = -s%nu(2:n_cell  ) / x2(1:n_cell-1) * dtoverdx2
    diag_low = -s%nu(1:n_cell-1) / x2(2:  n_cell) * dtoverdx2

    diag(n_cell)       = 1 + s%nu(n_cell) / x2(n_cell) * dtoverdx2
    diag_low(n_cell-1) = -s%nu(n_cell-1) / x2(n_cell)  * dtoverdx2

    s%S(n_cell) = s%S(n_cell) + dt * overdx / x2(n_cell)

    ! Solving for S, this does modify s%S directly
    call dgtsv(n_cell, 1, diag_low, diag, diag_up, s%S, n_cell, info)

    if (info /= 0) then
      stop "error in DGTSV call in subroutine do_timestep_S"
    end if
  end subroutine do_timestep_S_imp

  subroutine do_timestep_S_exp (states, dt)
    !process the temporal evolution of S with an explicit algorithm
    !using only on the superior branch of the S curve NOT VERIFIED YET
    implicit none

    type (state), intent(inout)                :: states
    real (kind=x_precision), intent(in)        :: dt

    real (kind=x_precision), dimension(0:n_cell+1) :: nuS ! two more for beginning / end

    nuS(0) = 0
    nuS(1:n_cell) = states%nu * states%S
    nuS(n_cell+1) = params%dx + nuS(n_cell)

    states%S = states%S + dt * (1._x_precision / x_state%x**2 * &
               (nuS(2:n_cell+1) - 2._x_precision * nuS(1:n_cell) + nuS(0:n_cell-1)) / &
               params%dx**2)

  end subroutine do_timestep_S_exp

  subroutine do_timestep_T(s, dt, converge, epst)
  !process the temporal evolution of T
    implicit none

    type (state), intent(inout)       :: s
    logical, intent(out)              :: converge
    real(kind=x_precision),intent(in) :: epst

    type (state)                                :: s_deriv
    real(kind = x_precision), intent(in)        :: dt

    real(kind = x_precision), dimension(n_cell) :: dtemp, rhs, newT
    real(kind = x_precision), dimension(n_cell) :: f0, fT
    real(kind = x_precision) :: maxi

    dtemp     = s%T * 1.e-3_x_precision
    s_deriv   = s
    s_deriv%T = s%T + dtemp

    call compute_variables(s_deriv)
    call compute_variables(s)
    ! Let dT/dt = f0 and d²T/dt² = f1 so T(t+1) = T(t) + dt * f0 * (1 + dt * f1)

    f0 = f(s)
    fT = (f(s_deriv) - f0) / dtemp

    rhs = f0 / fT * (exp(fT*dt) - 1._x_precision)
    ! rhs = dt*f0 * (1._x_precision + 0.5_x_precision*dt*fT)

    newT = s%T + rhs
    ! When the minimum value of T is ≤0, reduce the timestep
    if (minval(newT) < 0) then
       converge = .false.
       print*, 'Convergence problem!'
       ! print*,newT
       stop
    end if

    ! do while (minval(newT) < 0)
    !    print*, 'Convergence problem. Reducing dt', dt
    !    dt = dt / 2
    !    rhs = f0 / fT * (exp(fT*dt) - 1)
    !    newT = s%T + rhs
    ! end do

    s%T = newT

    maxi = maxval(abs(rhs / s%T))
    if (maxi < epst) then
       ! print *,'Converged — RHS=',  maxi
       converge = .true.
    else
       ! print *, 'Not converged — RHS=', maxi
       converge = .false.
    end if

    ! Copy the result
  end subroutine do_timestep_T

end module mod_integrator
