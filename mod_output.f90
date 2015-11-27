! Module that provides a way to dump the state

module mod_output
  use mod_constants
  use mod_read_parameters
  
  implicit none

  private

  public :: snapshot

contains

  ! Save a snapshot of state (s) at iteration, time
  subroutine snapshot (s, iteration, time, unit)
    use mod_variables
    
    implicit none
    
    type (state), intent(in)               :: s
    real (kind=x_precision), intent(in)    :: time
    integer, intent(in)                    :: iteration, unit
    
    integer                                :: i
    type (state) :: state_dim

    write(unit, fmt=*) '# ', iteration
    write(unit, fmt=*) '# ', time
    write(unit, fmt='(2a, 15(a16))') '# ', 'x', 'Omega', 'nu', 'v', 'T', 'P_rad',&
         'P_gaz', 'beta', 'cs', 'H', 'rho', 'S', 'Fz', 'M_dot', 'Cv'

    state_dim = s
    call dim_adim(1, state_dim)
    do i = 1, n_cell
       write(unit, fmt='(15(e16.8e2))') x_state%x(i), x_state%Omega(i), &
            state_dim%nu(i), state_dim%v(i), &
            state_dim%T(i), state_dim%Prad(i), state_dim%Pgaz(i), &
            state_dim%beta(i), state_dim%cs(i), &
            state_dim%H(i), state_dim%rho(i), state_dim%S(i), &
            state_dim%Fz(i), state_dim%Mdot(i), state_dim%Cv(i)
    end do
  end subroutine snapshot
  
end module mod_output

