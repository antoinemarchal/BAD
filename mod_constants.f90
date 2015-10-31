! Module that exposes the integrator that transforms the state_in to thet state_out

module mod_constants
  implicit none

  integer, parameter, public :: x_precision = selected_real_kind(15)
  integer, parameter, public :: n_cell = 256
  integer, parameter, public :: n_iterations = 1000

  real(kind = x_precision), parameter, public :: G       = 6.67408e-8_x_precision !gravitationnal cst in cgs
  real(kind = x_precision), parameter, public :: c       = 2.99792458e10_x_precision !speed of light in cgs
  real(kind = x_precision), parameter, public :: pi      = 4.0_x_precision*atan(1.0_x_precision) 
  real(kind = x_precision), parameter, public :: M_sun   = 1.98855e33_x_precision !mass of the sun in cgs
  real(kind = x_precision), parameter, public :: cst_rad = 7.5657308531642009e-17_x_precision !constant of radiation in cgs
  real(kind = x_precision), parameter, public :: stefan  = (c * cst_rad) / 4.0_x_precision !Stefan cst in cgs
  real(kind = x_precision), parameter, public :: kmp     = 8.3144598e7_x_precision !Boltzmann cst over proton mass in cgs = gas cst
  real(kind = x_precision), parameter, public :: gammag  = 5._x_precision / 3._x_precision
  real(kind = x_precision), parameter, public :: kb      = 1.3806488e-16_x_precision !Boltzmann cst in cgs
  real(kind = x_precision), parameter, public :: mp      = kb / kmp !proton mass in cgs
  real(kind = x_precision), parameter, public :: thomson = 6.6524587158e-25_x_precision !Thomson cross-section in cgs

  type parameters
    real(kind = x_precision) :: M, Mdot, X, RTM, alpha, rmax
    !M     : Black hole Mass
    !Mdot  : Acretion rate at rmax
    !X     : Chemical composition
    !RTM   : Gas constant × T_0 ÷ μ
    !alpha : Viscosity parameter
    !rmax  : Maximal radius of accretion disk
  end type parameters

  type state
    real(kind = x_precision), dimension(n_cell) :: Omega, x, nu, v, T, P_rad, P_gaz, beta, cs, H, rho, S, Fz, M_dot, Cv
    !Omega : Angular velocity
    !x     : Space variable
    !nu    : Viscosity
    !v     : Local, radial accretion speed
    !T     : Temperature
    !P_rad : Radiative pressure
    !P_gaz : Gaz pressure
    !beta  : Pressure indicator
    !cs    : Speed of sound
    !H     : Disk half-height
    !rho   : Volume density
    !S     : Variable of density
    !Fz    : Radiative flux
    !M_dot : Accretion rate
    !Cv    : Heat capacity at constant volume
  end type state

  type adim_state
    real(kind= x_precision) :: Omega_0, temps_0, x_0, nu_0, v_0, cs_0, S_0, H_0, M_dot_0, rho_0, T_0, Fz_0, Cv_0, P_gaz_0, P_rad_0
  end type adim_state
  
contains
    
end module mod_constants

