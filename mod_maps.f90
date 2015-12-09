module mod_maps
  use mod_constants
  use mod_read_parameters
  use mod_variables

  implicit none

  integer                  :: nb_S  ! The number of points along Sigma axis
  integer                  :: nb_T  ! The number of points along T axis
  real(kind = x_precision) :: T_min ! Lowest value of Temperature range
  real(kind = x_precision) :: T_max ! Highest value of Temperature range
  real(kind = x_precision) :: S_min ! Lowest value of Sigma range
  real(kind = x_precision) :: S_max ! Highest value of Sigma range


contains

  subroutine set_conditions(nbS, nbT, Tmin, Tmax, Smin, Smax)
    implicit none

    integer, intent(in) :: nbS
    integer, intent(in) :: nbT
    real(kind = x_precision), intent(in) :: Tmin ! Lowest value of Temperature range
    real(kind = x_precision), intent(in) :: Tmax ! Highest value of Temperature range
    real(kind = x_precision), intent(in) :: Smin ! Lowest value of Sigma range
    real(kind = x_precision), intent(in) :: Smax ! Highest value of Sigma range

    nb_S = nbS
    nb_T = nbT
    T_min = Tmin
    T_max = Tmax
    S_min = Smin
    S_max = Smax

  end subroutine set_conditions

  ! Build the T, Sigma grid given the number of points along each axis and the ranges
  subroutine build_grid()
    implicit none

    type(state),              dimension(nb_T,nb_S)        :: grid    ! The states grid
    real(kind = x_precision), dimension(n_cell,nb_T,nb_S) :: Q_res   ! The Q+-Q- grids, one for each position in the disk
    real(kind = x_precision), dimension(n_cell,nb_T,nb_S) :: tau_res ! The tau grids, one for each position in the disk
    real(kind = x_precision) :: dT     ! Temperature steps in the grid
    real(kind = x_precision) :: dS     ! Sigma steps in the grid
    real(kind = x_precision) :: T_temp ! Temporary variable to store Temperature
    real(kind = x_precision) :: S_temp ! Temporary variable to store Sigma
    integer                  :: i,j,k  ! Loop counters

    ! Compute the Temperature and Sigma steps
    dT = (T_max - T_min) / (nb_T - 1)
    dS = (S_max - S_min) / (nb_S - 1)

    ! Loop over first dimension
    do i = 1, nb_T

      ! Compute the i-th values
      T_temp = dT * (i-1) + T_min
      S_temp = dS * (i-1) + S_min

      ! Store them along first/second dimension
      do k = 1, n_cell
        grid(i,1:nb_S)%T(k) = T_temp ! Does not work without (k), so put it there
        grid(1:nb_T,i)%S(k) = S_temp * x_state%x(k) ! Actually the state use S, not Sigma
      end do
    end do

    do i = 1, nb_T
      do j = 1, nb_S
        call compute_variables(grid(i,j)) ! Compute the variables in each position of the state
        do k = 1, n_cell ! For each position on the disk
          Q_res(k,i,j) = grid(i,j)%Qplus(k) - grid(i,j)%Qminus(k) ! Q+ - Q-
          tau_res(k,i,j) = grid(i,j)%tau(k) ! tau_eff
        end do
      end do
    end do

    call save_data(Q_res, tau_res)

  end subroutine build_grid

  subroutine save_data(Q_res, tau_res)
    implicit none

    real(kind = x_precision), dimension(n_cell,nb_T,nb_S), intent(in) :: Q_res   ! The Q+-Q- grids, one for each position in the disk
    real(kind = x_precision), dimension(n_cell,nb_T,nb_S), intent(in) :: tau_res ! The tau grids, one for each position in the disk

    character(len = 64) :: fname       ! Name of the output file
    character(len = 16) :: line_fmt    ! Format of lines in the output file
    character(len = 8)  :: cell_number ! Cell number, to use in filename
    integer             :: fid         ! File descriptor
    integer             :: ios         ! I/O status
    integer             :: i,j,k       ! Loop counters

    write(line_fmt,'(A,I4,A)') '(',nb_S,'(e11.3e2))'

    do k = 1, n_cell

      write(cell_number,'(I5.5)') k
      fid = 30 + k
      fname = 'maps/map_'//trim(cell_number)//'.dat'

      open(fid, file = fname, action='write', status = 'replace', iostat = ios)
      if (ios /= 0) then
        write(*,*)"Error while opening the ", fname," file."
        stop
      endif

      write(fid, fmt = '(A)') '# T bounds'
      write(fid, fmt = '(2(e11.3e2))') T_min*state_0%T_0, T_max*state_0%T_0

      write(fid, fmt = '(A)') '# Sigma bounds'
      write(fid, fmt = '(2(e11.3e2))') S_min*state_0%S_0, S_max*state_0%S_0

      write(fid, fmt = '(A)') '# Q grid'
      do i = 1, nb_T
        write(fid, fmt = line_fmt) (Q_res(k,nb_T+1-i,j), j = 1, nb_S)
      end do

      write(fid, fmt = '(A)') '# tau grid'
      do i = 1, nb_T
        write(fid, fmt = line_fmt) (tau_res(k,nb_T+1-i,j), j = 1, nb_S)
      end do

      close(fid)

    enddo

  end subroutine save_data

end module mod_maps
