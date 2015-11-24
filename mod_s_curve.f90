module mod_S_curve
  use mod_constants
  use mod_read_parameters
  use mod_variables
  implicit none

! _____________________________________________________________________________________________

  ! BE SURE TO CREATE TWO FILES IN YOUR WORKING DIRECTORY : s_curves ( & critical_points )        

  !PROBLEMATIC FOR THE SECOND CRITICAL POINT. 

!_____________________________________________________________________________________________

contains
  !-------------------------------------------------------------------------
  ! SUBROUTINES :
  !               curve                 : : fake main 
  !                                         --> output : 2 arrays for the coordinates (Temperature, S ) of the first critical point
  
  !               first_critical_point  : : 
  !                                     <-- input : T and Sigma for the optically thick medium + number of points
  !                                         --> output : (Temperature, Sigma) of the first critical point + index of the point

  !               second_critical_point  : : 
  !                                     <-- input : T and Sigma for the optically thin medium + T for the thick one + number of points + index of the thick critical point + precision
  !                                         --> output : (Temperature, Sigma) of the second critical point + index of the point

  !                build_s_curve         : : combining both thin and thick media 
  !                                     <-- input : T and Sigma for both media + index of the thin critical point 
  !                                         --> output : array for (Temperature, Sigma)

  !               quadratic              : : For a positive real solution of a quadratic equation ax^2 + bx + c =0 
  !                                     <-- input : factors a, b, c
  !                                         --> output : positive solution
 
  !               intial_variables       : : Computing some variables 
  !                                         --> output : rs, rmin, Mdot_0, Sigma_0, Omega_0, T_0 (+ nu_0 )

  !               variables              : : Computing all the variables for Q+ and Q-  
  !                                     <-- input : Temperature, Sigma, Omega + optical depth indicator (0 or 1) + more
  !                                         --> output : ...


  !               dichotomy              : : In order to find the result of the equation Q+ - Q- = 0
  !                                     <-- input : Temperature, Sigma, Omega + optical depth indicator (0 or 1) + precision + more
  !                                         --> output : Sigma between a computed range of surface density [Smin, Smax] for a given temperature

  !               + subroutines for displaying values and saving data into files
  !-------------------------------------------------------------------------

  subroutine curve( temperature, s)
    implicit none

    real(kind = x_precision),dimension(n_cell),intent(out)  :: temperature
    real(kind = x_precision),dimension(n_cell),intent(out)  :: s

    integer                                                :: i     = 0
    integer                                                :: k     = 0
    integer                                                :: l     = 0

    real(kind = x_precision)                               :: temp  = 0.0d0
    real(kind = x_precision), parameter                    :: t_min = 5.0d-1
    real(kind = x_precision), parameter                    :: t_max = 4.49d0

    integer, parameter                                     :: nb_it = 100

    real(kind = x_precision)                               :: eps   = 1.0d-4
    real(kind = x_precision)                               :: eps2   = 5.0d-1


    real(kind = x_precision)                               :: sigma = 0.0d0
    real(kind = x_precision)                               :: Smin  = 0.0d0
    real(kind = x_precision)                               :: Smax  = 0.0d0
    real(kind = x_precision)                               :: omega = 0.0d0
    real(kind = x_precision)                               :: r     = 0.0d0
    real(kind = x_precision)                               :: H     = 0.0d0
    real(kind = x_precision)                               :: rho   = 0.0d0
    real(kind = x_precision)                               :: cs    = 0.0d0
    real(kind = x_precision)                               :: nu    = 0.0d0
    real(kind = x_precision)                               :: Q_plus = 0.0d0
    real(kind = x_precision)                               :: Q_minus= 0.0d0
    real(kind = x_precision)                               :: K_ff   = 0.0d0
    real(kind = x_precision)                               :: K_e    = 0.0d0
    real(kind = x_precision)                               :: tau_eff= 0.0d0
    real(kind = x_precision)                               :: P_rad  = 0.0d0
    real(kind = x_precision)                               :: P_gaz  = 0.0d0
    real(kind = x_precision)                               :: f      = 0.0d0
    real(kind = x_precision)                               :: E_ff   = 0.0d0
    real(kind = x_precision)                               :: Fz     = 0.0d0
    integer                                                :: optical_depth =0
    
    real(kind = x_precision)                               :: rs
    real(kind = x_precision)                               :: rmin
    real(kind = x_precision)                               :: Mdot_0
    real(kind = x_precision)                               :: Sigma_0
    real(kind = x_precision)                               :: Omega_0
    real(kind = x_precision)                               :: rho_0
    real(kind = x_precision)                               :: T_0

    real(kind = x_precision),dimension(nb_it)              :: temp_t_1  =0.0d0
    real(kind = x_precision),dimension(nb_it)              :: sigma_t_1 =0.0d0
    real(kind = x_precision),dimension(nb_it)              :: temp_t_0  =0.0d0
    real(kind = x_precision),dimension(nb_it)              :: sigma_t_0 =0.0d0
    real(kind = x_precision),dimension(nb_it)              :: temp_real =0.0d0
    real(kind = x_precision),dimension(nb_it)              :: sigma_real=0.0d0

    character(len = 8)                                     :: number_of_cell
    character(len = 64)                                    :: fname_1
    character(len = 64)                                    :: fname_2
    character(len = 64)                                    :: fname_3

    integer                                                :: fid_1
    integer                                                :: fid_2
    integer                                                :: fid_3

    integer                                                :: index_fcp
    real(kind = x_precision)                               :: sigma_c_thick
    real(kind = x_precision)                               :: temp_c_thick
   ! real(kind = x_precision),dimension(n_cell)             :: sigma_thick
   ! real(kind = x_precision),dimension(n_cell)             :: temp_thick
    integer                                                :: index_scp
    real(kind = x_precision)                               :: sigma_c_thin
    real(kind = x_precision)                               :: temp_c_thin
   ! real(kind = x_precision),dimension(n_cell)             :: sigma_thin
   ! real(kind = x_precision),dimension(n_cell)             :: temp_thin    

    !------------------------------------------------------------------------

    call display_parameters()
    call initial_variables(rs, rmin, Mdot_0, Sigma_0, Omega_0, T_0, rho_0)
    call display_initial_variables(rs, rmin, Mdot_0, Sigma_0, Omega_0, T_0, rho_0)
    !-------------------------------------------------------------------------
    ! Test for 1 value of r
    !-------------------------------------------------------------------------
    do k              = 1 , n_cell

       !r = (rmax-rmin)/(n_cell-1)*(k-1) + rmin
       !r              = 10._x_precision*G*params%M/(c**2)
       r   = r_state%r(k)

       omega          = sqrt(G*params%M/r**3) / Omega_0

       write(number_of_cell,'(I5.5)') k
       fid_1 = 20 + k
       fid_2 = 21 + k
       fid_3 = 22 + k


       fname_1 = 's_curves/Temperature_Sigma_'//trim(number_of_cell)//'_1.dat'
       fname_2 = 's_curves/Temperature_Sigma_'//trim(number_of_cell)//'_0.dat'
       fname_3 = 's_curves/Temperature_Sigma_'//trim(number_of_cell)//'_tot.dat'


       open(fid_1,file  = fname_1, status='unknown',action='readwrite')
       open(fid_2,file  = fname_2, status='unknown',action='readwrite')
       open(fid_3,file  = fname_3, status='unknown',action='readwrite')


       do i          = 1, nb_it

          Smin        = 1d-2
          Smax        = 1d54

          temp        = (t_max-t_min)/(nb_it-1)*(i-1) + t_min
          optical_depth = 1

          sigma       = dichotomy(Smin, Smax, eps, temp, omega, sigma_0, Omega_0,rs, T_0, rho_0, optical_depth)

          call variables(temp, sigma, omega, H, rho, cs, nu, Q_plus, Q_minus, K_ff,&
              K_e, tau_eff, P_rad, P_gaz,E_ff,Fz,f,Sigma_0, Omega_0,rs, T_0, rho_0, optical_depth)

        !  call display_variables(temp,Omega,r, sigma, H, rho, cs, nu, Q_plus, Q_minus,&
        !      K_ff, K_e, tau_eff, P_rad, P_gaz,E_ff,Fz,f)

          temp_t_1(i)   =  temp 
          sigma_t_1(i)  = sigma   

          !do j          = 1, nb_it
          !   write(fid_2,'(1p,E12.6,4x,1p,E12.6,4x,1p,E12.6)')sigma_real_1(j),temp_real_1(j)
          !enddo

          optical_depth = 0

          sigma       = dichotomy(Smin, Smax, eps, temp, omega, sigma_0, Omega_0,rs, T_0, rho_0, optical_depth)

          call variables(temp, sigma, omega, H, rho, cs, nu, Q_plus, Q_minus, K_ff,&
               K_e, tau_eff, P_rad, P_gaz,E_ff,Fz,f,Sigma_0, Omega_0,rs, T_0, rho_0, optical_depth)

        !  call display_variables(temp,Omega,r, sigma, H, rho, cs, nu, Q_plus, Q_minus,&
        !      K_ff, K_e, tau_eff, P_rad, P_gaz,E_ff,Fz,f)

          temp_t_0(i)   =  temp 
          sigma_t_0(i)  =  sigma   


         ! do l          = 1, nb_it
         !    write(fid_1,'(1p,E12.6,4x,1p,E12.6,4x,1p,E12.6)')sigma_real_0(l),temp_real_0(l)
         ! enddo
          
       enddo


       call first_critical_point(sigma_t_1, temp_t_1, index_fcp,sigma_c_thick, temp_c_thick, nb_it)

       call second_critical_point(sigma_t_1, sigma_t_0, temp_t_1,&
         index_fcp, index_scp, sigma_c_thin, temp_c_thin, nb_it, eps2)

       call build_s_curve(sigma_t_1, sigma_t_0, temp_t_1,nb_it, index_scp, sigma_real, temp_real)

       call display_critical_points(sigma_c_thin, temp_c_thin,sigma_c_thick, temp_c_thick, k)


       
          do l          = 1, nb_it

             temp_real(l)  = log10( temp_real(l) * T_0 )
             sigma_real(l) = log10( sigma_real(l) * Sigma_0 )

             write(fid_3,'(1p,E12.6,4x,1p,E12.6,4x,1p,E12.6)')sigma_real(l),temp_real(l)
          enddo


       close(fid)
       close(fid_2)
       close(fid_3)

          temperature(k) = temp_c_thick
          s(k)           = sigma_c_thick * Omega**(1._x_precision / 3._x_precision)
          

       !  temp_thick(k)  = log10( temp_c_thick * T_0 )
       !  sigma_thick(k) = log10( sigma_c_thick * Sigma_0 )       
       !  temp_thin(k)  = log10( temp_c_thin * T_0 )
       !  sigma_thin(k) = log10( sigma_c_thin * Sigma_0 ) !PROBLEMATIC 
     

    enddo

     !  call write_critical_points(n_cell, r_state%r, rs, sigma_thin, temp_thin, sigma_thick, temp_thick)


  end subroutine curve


  
  !-------------------------------------------------------------------------
  ! Subroutine in order to find the first critical point
  !-------------------------------------------------------------------------
  subroutine first_critical_point(sigma_real_1,temp_real_1, index_fcp,sigma_c_thick, temp_c_thick, nb_it)
    implicit none
    integer,intent(in)                                   :: nb_it

    real(kind = x_precision),dimension(nb_it),intent(in) :: sigma_real_1
    real(kind = x_precision),dimension(nb_it),intent(in) :: temp_real_1

    integer                                  ,intent(out):: index_fcp
    real(kind = x_precision)                 ,intent(out):: sigma_c_thick
    real(kind = x_precision)                 ,intent(out):: temp_c_thick
    integer                                              :: i
    i = 1
    do while (sigma_real_1(i) .le. sigma_real_1(i+1) .and. i .lt. nb_it - 1)
       index_fcp = i
       sigma_c_thick = sigma_real_1(i)
       temp_c_thick = temp_real_1(i)
       i = i + 1
    enddo

    endsubroutine first_critical_point





    !-------------------------------------------------------------------------
    ! Subroutine in order to find the second critical point
    !-------------------------------------------------------------------------
    subroutine second_critical_point(sigma_real_1, sigma_real_0, temp_real_1,&
         index_fcp, index_scp, sigma_c_thin, temp_c_thin, nb_it, eps2)
    implicit none
    integer,intent(in)                                   :: nb_it

    real(kind = x_precision),dimension(nb_it),intent(in) :: sigma_real_1
    real(kind = x_precision),dimension(nb_it),intent(in) :: temp_real_1
    real(kind = x_precision),dimension(nb_it),intent(in) :: sigma_real_0

    real(kind = x_precision)                 ,intent(in):: eps2

    integer                                  ,intent(in) :: index_fcp
    integer                                  ,intent(out):: index_scp

    real(kind = x_precision)                 ,intent(out):: sigma_c_thin
    real(kind = x_precision)                 ,intent(out):: temp_c_thin
    integer                                              :: i = 0
            ! write(*,*)index_fcp

    do i = index_fcp, nb_it
      ! write(*,*)sigma_real_0(i), sigma_real_1(i)
     !  write(*,*)(dabs(sigma_real_1(i) - sigma_real_0(i+1)))
    end do
    
        do i = index_fcp, nb_it - 1

           if(dabs(sigma_real_1(i) - sigma_real_0(i+1)) .lt. eps2)then
           index_scp = i
           ! sigma_c_thin = (sigma_real_1(i) + sigma_real_0(i+1))/2._x_precision
           sigma_c_thin =  sigma_real_0(i+1)

           temp_c_thin = temp_real_1(i)
           end if
        enddo

    endsubroutine second_critical_point


    
    subroutine build_s_curve(sigma_real_1, sigma_real_0, temp_real_1,nb_it, index_scp, sigma_real, temp_real)
      implicit none
      integer,intent(in)                                   :: nb_it
      
      real(kind = x_precision),dimension(nb_it),intent(in) :: sigma_real_1
      real(kind = x_precision),dimension(nb_it),intent(in) :: sigma_real_0
      real(kind = x_precision),dimension(nb_it),intent(in) :: temp_real_1
      integer                                  ,intent(in) :: index_scp
      !real(kind = x_precision),dimension(:),allocatable,intent(out) :: sigma_real
      !real(kind = x_precision),dimension(:),allocatable,intent(out) :: temp_real
      real(kind = x_precision),dimension(nb_it),intent(out) :: sigma_real
      real(kind = x_precision),dimension(nb_it),intent(out) :: temp_real
      integer::i = 0

      do i = 1,index_scp
         sigma_real(i) = sigma_real_1(i)
         temp_real(i) = temp_real_1(i)
      enddo
      do i = index_scp + 1, nb_it
         sigma_real(i) = sigma_real_0(i)
         temp_real(i) = temp_real_1(i)
      enddo
      
    end subroutine build_s_curve


    subroutine display_critical_points(sigma_c_thin, temp_c_thin,sigma_c_thick, temp_c_thick,k)

      implicit none
      real(kind = x_precision)                 ,intent(in):: sigma_c_thin
      real(kind = x_precision)                 ,intent(in):: temp_c_thin
      real(kind = x_precision)                 ,intent(in):: sigma_c_thick
      real(kind = x_precision)                 ,intent(in):: temp_c_thick
      integer                                  ,intent(in):: k
      !------------------------------------------------------------------------
      write(*,*)'**** Critical Point',k,'********'
      write(*,*)'****************************************'
      write(*,"(' Optically thin (T,sigma) :',1p,E12.4,4x,1p,E12.4)")temp_c_thin,sigma_c_thin
      write(*,"(' Optically thick (T,sigma):',1p,E12.4,4x,1p,E12.4)")temp_c_thick,sigma_c_thick

      write(*,*)'****************************************'

    end subroutine display_critical_points


    subroutine write_critical_points(n,radius, rs, sigma_c_thin, temp_c_thin,sigma_c_thick, temp_c_thick)

      implicit none
     
      integer                                  ,intent(in):: n 
      real(kind = x_precision),dimension(n)    ,intent(in):: radius
      real(kind = x_precision)                 ,intent(in):: rs
      real(kind = x_precision),dimension(n)    ,intent(in):: sigma_c_thin
      real(kind = x_precision),dimension(n)    ,intent(in):: temp_c_thin
      real(kind = x_precision),dimension(n)    ,intent(in):: sigma_c_thick
      real(kind = x_precision),dimension(n)    ,intent(in):: temp_c_thick
      integer                                             :: i
      integer                                             :: fid_4 = 11
      character(len = 64)                                 :: fname_4
      !------------------------------------------------------------------------
       fname_4 = 'critical_points/file.dat'

       open(fid_4,file  = fname_4, status='unknown',action='write')
       !write(fid_4)'nb_cell,temp_c_thin,sigma_c_thin,temp_c_thick,sigma_thin'
      
          do i=1, n
             write(fid_4,'(E12.6,1p,E12.6,4x,1p,E12.6,4x,1p,E12.6,4x,1p,E12.6)')sqrt(radius(i)/rs),&
                        temp_c_thin(i),sigma_c_thin(i),temp_c_thick(i),sigma_c_thick(i)
          end do 
       
       close(fid_4)

    end subroutine write_critical_points
    


    
  !-------------------------------------------------------------------------
  !Subroutine for resolving a quadratic equation as long as the solutions are
  !a set of real numbers
  !-------------------------------------------------------------------------
  subroutine quadratic(coeff_a, coeff_b, coeff_c, sol)

    implicit none
    real(kind=x_precision), intent(in)                     :: coeff_a,coeff_b,coeff_c
    real(kind=x_precision), intent(out)                    :: sol
    real(kind=x_precision)                                 :: sol_1 = 0.0d0
    real(kind=x_precision)                                 :: sol_2 = 0.0d0
    real(kind=x_precision)                                 :: delta = 0.0d0
    !------------------------------------------------------------------------

    delta          = coeff_b**2 - 4_x_precision * coeff_a * coeff_c

    if (coeff_a == 0.0) then
      write(*,*)'Coefficient a in the quadratic equation is nought.'
      continue
    else 


    if (delta .lt. 0.) then
      write(*,*)'No solutions in the R field.'
 
   else
      sol_1         = -0.5_x_precision *(coeff_b + sign(sqrt(delta),coeff_b))/coeff_a
      if (sol_1 .lt. 0.d-12) then
         write(*,*)'Problem'
         stop
      endif
      sol_2 = (coeff_c / (coeff_a * sol_1))
      sol = max(sol_1,sol_2)

    end if

    end if
  end subroutine quadratic



  !-------------------------------------------------------------------------
  !Subroutine in order to compute initial variables rs, rmin, Mdot_0,
  !Sigma_0, Omega_0, T_0
  !-------------------------------------------------------------------------
  subroutine initial_variables(rs, rmin, Mdot_0, Sigma_0, Omega_0, T_0, rho_0)
    implicit none

    real(kind=x_precision),intent(out)                      :: rs
    real(kind=x_precision),intent(out)                      :: rmin
    real(kind=x_precision),intent(out)                      :: Mdot_0
    real(kind=x_precision),intent(out)                      :: Sigma_0
    real(kind=x_precision),intent(out)                      :: Omega_0
    real(kind=x_precision),intent(out)                      :: T_0
    real(kind=x_precision),intent(out)                      :: rho_0
    real(kind=x_precision)                                  :: nu_0

    !------------------------------------------------------------------------

    rs                 = 2._x_precision * G * params%M/(c**2)
    rmin               = 3._x_precision * rs
    Mdot_0             = params%Mdot
    Omega_0            = sqrt(G * params%M / rs**3 )
    Sigma_0            = Mdot_0 /(Omega_0 * rs**2 * 2_x_precision * pi)
    T_0                = (Mdot_0 * c**2 / (48._x_precision * pi * rs**2 * stefan * &
                         sqrt(27._x_precision) ) )**(1._x_precision/4._x_precision)
    rho_0              = Sigma_0 / (2._x_precision * rs)
    nu_0                 = 2._x_precision * rs**2 * Omega_0 / 3._x_precision

  end subroutine initial_variables



  !-------------------------------------------------------------------------
  !Subroutine in order to compute variables H, rho, cs, nu, Q_plus, Q_minus,
  !K_ff, K_e, tau_eff, P_rad, P_gaz,E_ff,Fz given T, Sigma and Omega 
  !------------------------------------------------------------------------
  subroutine variables(T, Sigma, Omega, H, rho, cs, nu, Q_plus, Q_minus,&
       K_ff, K_e, tau_eff, P_rad, P_gaz,E_ff,Fz,f,Sigma_0,&
     Omega_0,rs, T_0, rho_0, optical_depth)
    implicit none

    real(kind = x_precision),intent(in)                      :: T,Sigma,Omega
    real(kind = x_precision),intent(in)                      :: Sigma_0
    real(kind = x_precision),intent(in)                      :: Omega_0
    real(kind = x_precision),intent(in)                      :: T_0
    real(kind = x_precision),intent(in)                      :: rho_0
    real(kind = x_precision),intent(in)                      :: rs
    integer, intent(in)                                      :: optical_depth
    real(kind = x_precision)                                 :: coeff_a=0.,coeff_b=0.,coeff_c=0.

    real(kind = x_precision),intent(out)                     :: H
    real(kind = x_precision),intent(out)                     :: rho
    real(kind = x_precision),intent(out)                     :: cs
    real(kind = x_precision),intent(out)                     :: nu
    real(kind = x_precision),intent(out)                     :: Q_plus
    real(kind = x_precision),intent(out)                     :: K_ff
    real(kind = x_precision),intent(out)                     :: K_e
    real(kind = x_precision),intent(out)                     :: E_ff
    real(kind = x_precision),intent(out)                     :: tau_eff
    real(kind = x_precision),intent(out)                     :: Fz
    real(kind = x_precision),intent(out)                     :: Q_minus
    real(kind = x_precision),intent(out)                     :: P_rad
    real(kind = x_precision),intent(out)                     :: P_gaz
    real(kind = x_precision),intent(out)                     :: f
    !------------------------------------------------------------------------

    coeff_a              = (Omega**2 * Omega_0**2 * Sigma * Sigma_0)/2._x_precision
    coeff_b              = (-1._x_precision/3._x_precision) * cst_rad*T**4 * T_0**4 / rs
    coeff_c              = (-1._x_precision * params%RTM * T  *  Sigma * Sigma_0)/(2._x_precision * rs**2)

    call quadratic(coeff_a , coeff_b , coeff_c , H)


    rho                  = Sigma / H
    P_rad                = T**4
    P_gaz                = rho * T
    cs                   = Omega * H
    nu                   = params%alpha * cs * H
    K_ff                 = 6.13d22 * rho_0 * rho * (T_0 * T)**(-3.5_x_precision)
    K_e                  = params%kappa_e
    E_ff                 = 6.22d20 * (rho_0 * rho)**2 * sqrt(T_0 * T)
    tau_eff              = 0.5_x_precision * sqrt(K_e * K_ff) * Sigma * Sigma_0


    !-------------------------------------------------------------------------
    !Select the case for the optical depth to compute Fz
    !-------------------------------------------------------------------------

   ! if (tau_eff .ge. 1.)  then
   !    optical_depth     = 1
   ! else
   !    optical_depth     = 0
   ! end if

    select case(optical_depth)

    case(1)

       Fz = 2._x_precision * c**2 * T**4 /(27._x_precision * sqrt(3._x_precision) &
            * (K_ff + K_e) * Sigma * Sigma_0) * (Omega**(1._x_precision / 3._x_precision))
    case (0)

       Fz = 4._x_precision * rs * E_ff * H / (Omega_0 * Sigma_0)

    end select

    Q_plus              = 3._x_precision  * rs**2 * nu * Omega**2 * Omega_0**2
    Q_minus             = Fz  / ( Sigma * Omega**(1._x_precision / 3._x_precision) )

    f                   = Q_plus - Q_minus

  end subroutine variables


  !-------------------------------------------------------------------------
  ! Dichotomic function in order to determine the change of sign in a given
  ! interval [Smin,Smax] with an epsilon precision
  !-------------------------------------------------------------------------
  real(kind=x_precision) function dichotomy(Smin, Smax, eps, T, omega, sigma_0, Omega_0,rs, T_0, rho_0, optical_depth)
    use mod_read_parameters
    use mod_constants
    use mod_variables
    implicit none

    real(kind=x_precision),intent(inout)                     :: Smin,Smax
    real(kind=x_precision),intent(in)                        :: eps
    real(kind=x_precision),intent(in)                        :: T
    real(kind=x_precision),intent(in)                        :: omega
    real(kind=x_precision),intent(in)                        :: Sigma_0
    real(kind=x_precision),intent(in)                        :: Omega_0
    real(kind=x_precision),intent(in)                        :: T_0
    real(kind=x_precision),intent(in)                        :: rho_0
    real(kind=x_precision),intent(in)                        :: rs
    integer,intent(in)                                       :: optical_depth

    real(kind=x_precision)                                   :: H
    real(kind=x_precision)                                   :: rho
    real(kind=x_precision)                                   :: cs
    real(kind=x_precision)                                   :: nu
    real(kind=x_precision)                                   :: Q_plus
    real(kind=x_precision)                                   :: Q_minus
    real(kind=x_precision)                                   :: K_ff
    real(kind=x_precision)                                   :: K_e
    real(kind=x_precision)                                   :: tau_eff
    real(kind=x_precision)                                   :: P_rad
    real(kind=x_precision)                                   :: P_gaz
    real(kind=x_precision)                                   :: f_min
    real(kind=x_precision)                                   :: f_max
    real(kind=x_precision)                                   :: f_center
    real(kind=x_precision)                                   :: E_ff
    real(kind=x_precision)                                   :: Fz
    real(kind=x_precision)                                   :: S_center = 0._x_precision
    integer                                                  :: j = 0


    !-------------------------------------------------------------------------
    ! N-> Number of iterations for the dichotomy
    ! Smin, Smax -> Starting range
    ! eps -> Precision
    ! T-> Fixed variable
    !-------------------------------------------------------------------------
    S_center             = (Smin+Smax)/2.
    j = 0
    call variables(T, Smin, Omega, H, rho, cs, nu, Q_plus, Q_minus, K_ff, K_e,&
         tau_eff, P_rad, P_gaz,E_ff,Fz,f_min,Sigma_0, Omega_0,rs,T_0,rho_0,optical_depth)

    call variables(T, Smax, Omega, H, rho, cs, nu, Q_plus, Q_minus, K_ff, K_e, &
         tau_eff, P_rad, P_gaz,E_ff,Fz,f_max,Sigma_0, Omega_0,rs,T_0, rho_0, optical_depth)

  !   write(*,*)'fmin = ',f_min
  !   write(*,*)'fmax = ',f_max

    if ( f_max * f_min .gt. 0.) then
   !    write(*,*)'This function image does not switch its sign in this particular interval.'
     !  dichotomy = 0

    else if( f_max * f_min .lt. 0.) then
       iteration:do while ( dabs( Smax - Smin ) .ge. eps .and. j .lt. 10000)


    call variables(T, Smin, Omega, H, rho, cs, nu, Q_plus, Q_minus, K_ff, K_e,&
         tau_eff, P_rad, P_gaz,E_ff,Fz,f_min,Sigma_0, Omega_0,rs,T_0,rho_0, optical_depth)

    call variables(T, Smax, Omega, H, rho, cs, nu, Q_plus, Q_minus, K_ff, K_e, &
         tau_eff, P_rad, P_gaz,E_ff,Fz,f_max,Sigma_0, Omega_0,rs,T_0, rho_0, optical_depth)

    call variables(T, S_center, Omega, H, rho, cs, nu, Q_plus, Q_minus, K_ff,&
         K_e, tau_eff, P_rad, P_gaz,E_ff,Fz,f_center,Sigma_0, Omega_0,rs,T_0, rho_0, optical_depth)


          if(f_min * f_center .gt. 0.) then

             Smin         = S_center

          else if (f_max * f_center .gt. 0.) then
             Smax         = S_center

          endif

          S_center       = (Smin + Smax) * 1._x_precision / 2._x_precision
          j               = j + 1

       end do iteration
         dichotomy = S_center

    endif


  end function dichotomy


  !-------------------------------------------------------------------------
  !Subroutine in order to display parameters
  !-------------------------------------------------------------------------
  subroutine display_parameters()

    write(*,*)'           Input Parameters             '
    write(*,*)'****************************************'
    write(*,"(' BH_mass     =',1p,E12.4)") params%M
    write(*,"(' Mdot        =',1p,E12.4)") params%Mdot
    ! write(*,"(' rmax        =',1p,E12.4)") rmax
    write(*,"(' alpha       =',1p,E12.4)") params%alpha
    ! write(*,"(' X           =',1p,E12.4)") X
    write(*,*)'****************************************'
    !read(*,*)

  end subroutine display_parameters


  !-------------------------------------------------------------------------
  !Subroutine in order to display initial variables
  !-------------------------------------------------------------------------
  subroutine display_initial_variables(rs, rmin, Mdot_0, Sigma_0, Omega_0, T_0, rho_0)
    implicit none

    real(kind = x_precision), intent(in)                     :: rs
    real(kind = x_precision), intent(in)                     :: rmin
    real(kind = x_precision), intent(in)                     :: Mdot_0
    real(kind = x_precision), intent(in)                     :: Sigma_0
    real(kind = x_precision), intent(in)                     :: Omega_0
    real(kind = x_precision), intent(in)                     :: T_0
    real(kind = x_precision), intent(in)                     :: rho_0

    !-----------------------------------------------------------------------

    write(*,*)'           Initial Variables            '
    write(*,*)'****************************************'
    write(*,"(' Temp_0      =',1p,E12.4)") T_0
    write(*,"(' Sigma_0     =',1p,E12.4)") Sigma_0
    write(*,"(' Omega_0     =',1p,E12.4)") Omega_0
    write(*,"(' Omega_max   =',1p,E12.4)") sqrt(G*params%M / rmin**3)
    write(*,"(' H_0         =',1p,E12.4)") rs
    write(*,"(' Mdot_0      =',1p,E12.4)") Mdot_0
    write(*,"(' rho_0       =',1p,E12.4)") rho_0
    write(*,"(' rmin        =',1p,E12.4)") rmin
    write(*,"(' rs          =',1p,E12.4)") rs
    write(*,*)'****************************************'

   ! read(*,*)

  end subroutine display_initial_variables


  !-------------------------------------------------------------------------
  !Subroutine in order to display variables
  !-------------------------------------------------------------------------
  subroutine display_variables(temp,Omega,r,sigma, H, rho, cs, nu, Q_plus, &
       Q_minus, K_ff, K_e, tau_eff, P_rad, P_gaz,E_ff,Fz,f)
    implicit none

    real(kind = x_precision), intent(in)                     :: temp
    real(kind = x_precision), intent(in)                     :: Omega
    real(kind = x_precision), intent(in)                     :: r
    real(kind = x_precision), intent(in)                     :: sigma
    real(kind = x_precision), intent(in)                     :: H
    real(kind = x_precision), intent(in)                     :: rho
    real(kind = x_precision), intent(in)                     :: cs
    real(kind = x_precision), intent(in)                     :: nu
    real(kind = x_precision), intent(in)                     :: Q_plus
    real(kind = x_precision), intent(in)                     :: Q_minus
    real(kind = x_precision), intent(in)                     :: K_ff
    real(kind = x_precision), intent(in)                     :: K_e
    real(kind = x_precision), intent(in)                     :: tau_eff
    real(kind = x_precision), intent(in)                     :: P_rad
    real(kind = x_precision), intent(in)                     :: P_gaz
    real(kind = x_precision), intent(in)                     :: f
    real(kind = x_precision), intent(in)                     :: E_ff
    real(kind = x_precision), intent(in)                     :: Fz
    !------------------------------------------------------------------------

    write(*,*)'               Variables                '
    write(*,*)'****************************************'
    write(*,"(' r           =',1p,E12.4)") r
    write(*,"(' Temp        =',1p,E12.4)") temp
    write(*,"(' Sigma       =',1p,E12.4)") sigma
    write(*,"(' Omega       =',1p,E12.4)") Omega
    write(*,"(' H           =',1p,E12.4)") H
    write(*,"(' rho         =',1p,E12.4)") rho
    write(*,"(' cs          =',1p,E12.4)") cs
    write(*,"(' nu          =',1p,E12.4)") nu
    write(*,"(' Q plus      =',1p,E12.4)") Q_plus
    write(*,"(' Q minus     =',1p,E12.4)") Q_minus
    write(*,"(' K_ff        =',1p,E12.4)") K_ff
    write(*,"(' K_e         =',1p,E12.4)") K_e
    write(*,"(' tau_eff     =',1p,E12.4)") tau_eff
    write(*,"(' P_gaz       =',1p,E12.4)") P_gaz
    write(*,"(' P_rad       =',1p,E12.4)") P_rad
    write(*,"(' E_ff        =',1p,E12.4)") E_ff
    write(*,"(' delta Q     =',1p,E12.4)") f
    write(*,"(' Fz          =',1p,E12.4)") Fz
    write(*,*)'****************************************'
  end subroutine display_variables


end module mod_S_curve
