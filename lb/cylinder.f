      include "cmtparticles.usrp"
c-----------------------------------------------------------------------
c README -  JH111516 - Rarefaction test case. FIRST PLACE WE TRY
!           entropy viscosity in EUler gas dynamics! IF it works here,
!           fold it in!!
c README -  JH122716 - OK NOW TRY EVM after re-doing viscous stress tensor
!           and fixing some (not all. some) BC problems in Navier-Stokes
c-----------------------------------------------------------------------
      subroutine uservp (ix,iy,iz,eg)
      include 'SIZE'
      include 'TOTAL'   ! this is not
      include 'CMTDATA' ! the best idea
      include 'NEKUSE'
      integer e,eg

      e = gllel(eg)

!-----------------------------------------------------------------------
! c_E-> \infty. wave speed visco only
!-----------------------------------------------------------------------
!     mu=rho*t(ix,iy,iz,e,3)

!-----------------------------------------------------------------------
! finite c_E. res2 viscosity clipped in subroutine resvisc (or evmsmooth;
!             I still haven't decided it.
!-----------------------------------------------------------------------
      mu=rho*res2(ix,iy,iz,e,1) ! finite c_E;
      nu_s=0.75*mu/rho


      mu=0.5*mu ! A factor of
           ! 2 lurks in agradu's evaluation of strain rate, even in EVM
      lambda=0.0
      udiff=0.0
      utrans=0.

      return
      end
c-----------------------------------------------------------------------
      subroutine userf  (ix,iy,iz,eg)
      include 'SIZE'
      include 'TOTAL'
      include 'NEKUSE'
      integer e,eg

      common /part_two_way/  ptw
      real                   ptw(lx1,ly1,lz1,lelt,4) 
      e = gllel(eg)

c     ffx =  ptw(ix,iy,iz,e,1)/vtrans(ix,iy,iz,e,1) !Nek5000
c     ffy =  ptw(ix,iy,iz,e,2)/vtrans(ix,iy,iz,e,1)
c     ffz =  ptw(ix,iy,iz,e,3)/vtrans(ix,iy,iz,e,1)

      ffx =  ptw(ix,iy,iz,e,1) ! cmtnek
      ffy =  ptw(ix,iy,iz,e,2)
      ffz =  ptw(ix,iy,iz,e,3)

c     ffx = 0.0
c     ffy = 0.0
c     ffz = 0.0
      return
      end
c-----------------------------------------------------------------------
      subroutine userq  (ix,iy,iz,eg)
      include 'SIZE'
      include 'TOTAL'
      include 'NEKUSE'
      integer e,eg

      qvol   = 0.0

      return
      end
c-----------------------------------------------------------------------
      subroutine userchk
      include 'SIZE'
      include 'TOTAL'
      include 'TORO'
      include 'CMTDATA'
      integer  e,f,eq
      character*26 zefn 
      character (len=8):: fmt !format descriptor
      character(5) x1, x2
      fmt = '(I4.4)'

      luout = 60

      nxyz= nx1*ny1*nz1
      n = nxyz*nelt
      ifxyo=.true.
      if (istep.gt.1) ifxyo=.false.

      time=time_cmt
      dt=dt_cmt

      if (time_cmt.eq.0.0) then
         call compute_mesh_h(meshh,xm1,ym1,zm1) ! never hurts
! smooth useric
! [a,b] a_{me,ngb}, b_{me,ngb} for {me,ngb}={L,R}
         all=-1.0e36
         bll=diaph1
         arr=diaph1
         brr=1.0e36
         arl=all
         brl=bll
         alr=arr
         blr=brr
         do e=1,nelt
            reps=1.0/meshh(e)
! [a,b] a_{me,ngb}, b_{me,ngb} for {me,ngb}={L,R}
            do i=1,nxyz
               zex=sqrt(xm1(i,1,1,e)**2+ym1(i,1,1,e)**2)
               if (zex.lt.diaph1) then ! I am L
                  sl=0.5*tanh(reps*(zex-all))-0.5*tanh(reps*(zex-bll))
                  sr=0.5*tanh(reps*(zex-alr))-0.5*tanh(reps*(zex-blr))
               else ! I am R
                  sl=0.5*tanh(reps*(zex-arl))-0.5*tanh(reps*(zex-brl))
                  sr=0.5*tanh(reps*(zex-arr))-0.5*tanh(reps*(zex-brr))
               endif
               u(i,1,1,1,e)=dl*sl   +dr*sr
               u(i,1,1,2,e)=dl*ul*sl+dr*ur*sr
               u(i,1,1,3,e)=0.0
               u(i,1,1,4,e)=0.0
               el=pl/(gmaref-1.0)+0.5*dl*ul**2
               er=pright/(gmaref-1.0)+0.5*dr*ur**2
               u(i,1,1,5,e)=el*sl   +er*sr
            enddo
         enddo
      endif

      call compute_primitive_vars

!added by keke
!      if(istep .eq. 300 .or. istep .eq. 600 .or. istep.eq.900 ) then
!c     write(zefn,'(a16,i6.6,a1,i2.2)') 'rhoprof',istep,'p',nid
!      tol=1.0e-6
!      write(x1, fmt) nid
!      write(x2, fmt) istep
!      OPEN(UNIT=2000+nid,FILE='rhoprof.nid.'//trim(x1)//
!     $        '.step.'//trim(x2), FORM="FORMATTED",
!     $        STATUS="REPLACE",ACTION="WRITE") 
!      do e=1,nelt
!         l=0
!         do k=1,nz1
!         do j=1,ny1
!         do i=1,nx1
!            l=l+1
!! profile writer not parallelized correctly
!            if (abs(ym1(i,j,k,e)).lt.tol .and. abs(zm1(i,j,k,e)).lt.tol) 
!     >                                 then
!                  write(UNIT=2000+nid,FMT='(5e25.16)')
!     >    xm1(i,j,k,e),u(i,j,k,1,e),vx(i,j,k,e),T(i,j,k,e,1),pr(i,j,k,e)
!            endif
!! profile writer not parallelized correctly
!         enddo
!         enddo
!         enddo
!      enddo
!      close(UNIT=2000+nid)
!      endif
       if(istep .eq. 6 .or. istep.eq.5) then !print the 5 primitive variables, 
                             ! u,v,w,T, pr
          !call printVx  !u
          !call printVy  !v
          !call printVz  !w
          !call printTemp   !T
          !call printPr  !p
          call printParticleLocation  !particle location
          call printParticleVelocity  !particle location
      endif 
!end added by keke
      umin = glmin(t,n)
      umax = glmax(t,n)
!     if (mod(kstep,100).eq.0) then
      if (nio.eq.0) then
         write(6,2)istep,time_cmt,umin,' <T<',umax
      endif
!     endif
2     format(i6,1p2e17.8,a4,1p1e17.8)


      if(ifoutfld.or.istep.eq.0) then
!     call out_fld_nek ! need restart condition
!-----------------------------------------------------------------------
! JH030317
! adding output fields for diagnostic purposes. optional, but perhaps should
! be flagged by values in uservp (Navier-Stokes vs EVM GP vs both)
         call copy(t(1,1,1,1,2),vdiff(1,1,1,1,imu),n) ! s1
         call cmult(t(1,1,1,1,2),2.0,n)
         call invcol2(t(1,1,1,1,2),vtrans(1,1,1,1,irho),n)
!                        t(:,3)=wavevisc              ! s2
         call copy(t(1,1,1,1,4),vdiff(1,1,1,1,inus),n)! s3
         call copy(t(1,1,1,1,5),res2,n)               ! s4
!        call rzero(t(1,1,1,1,6),n)
      endif ! ifoutfld

      return
      end
c-----------------------------------------------------------------------
      subroutine userbc (ix,iy,iz,iside,eg)
      include 'SIZE'
      include 'TSTEP'
      include 'NEKUSE'
      include 'INPUT'
      include 'TORO'
      include 'CMTDATA'
      include 'GEOM' ! not sure if this is a good idea.
      real nx,ny,nz  ! bite me it's fun
      integer e

!     e = gllel(eg)
      molarmass=molmass
      pres = PRight

      if (cbu .eq. 'W  ' .or. cbu .eq. 'I  ' .or. cbu .eq. 'SYM') then
         flux=0.0 ! not used in wall?
      elseif (cbu.eq.'O ') then
!        if (outflsub) pres=pinfty ! not yet. leave this in outflow_bc
      endif

      return
      end

c-----------------------------------------------------------------------

      subroutine useric (ix,iy,iz,eg)
      include 'SIZE'
      include 'TOTAL'
      include 'NEKUSE'
      include 'TORO'
      include 'PERFECTGAS'
      include 'CMTDATA'

! JH080614 actual arguments here (and corresponding dummy arguments)
!          are test3 ("left Woodward & Colella") in e1rpex.ini. They
!          will be appropriately distributed throughout the commons in
!          TORO along with the solution star state PMstar and UM.
! JH073114 Toro e1rpex provides SUBROUTINE SAMPLE and is crudely grafted
!          to the end of this .usr file.
      real   xerange(2,3,lelt)
      common /elementrange/ xerange
      real   xdrange(2,3)
      common /domainrange/ xdrange
c     real rxbop(2,3)
      real gpx, gpy

c     region to distribute high pressure
c     rxbop(1,1) = 0 ! xmin
c     rxbop(2,1) = 0.10 ! xmax
c     rxbop(1,2) = 0  ! ymin
c     rxbop(2,2) = 0.1 ! ymax
c     rxbop(1,3) = xdrange(1,3) ! zmin
c     rxbop(2,3) = xdrange(2,3) ! zmax

      e=gllel(eg)
      pres = PRight
      rho = DR
c        if(
c    >     ((abs(xerange(1,1,e)) .ge. rxbop(1,1) .and.
c    >        abs(xerange(1,1,e)) .lt. rxbop(2,1))
c    >.or.(abs(xerange(2,1,e)) .gt. rxbop(1,1) .and.
c    >       abs(xerange(2,1,e)) .le. rxbop(2,1)))
c    >       .and.
c    >    ((abs(xerange(1,2,e)) .ge. rxbop(1,2) .and.
c    >       abs(xerange(1,2,e)) .lt. rxbop(2,2))
c    >.or.(abs(xerange(2,2,e)) .gt. rxbop(1,2) .and.
c    >       abs(xerange(2,2,e)) .le. rxbop(2,2)))
c    >       .and.
c    >    ((xerange(1,3,e) .ge. rxbop(1,3) .and.
c    >        xerange(1,3,e) .lt. rxbop(2,3))
c    >.or.(xerange(2,3,e) .gt. rxbop(1,3) .and.
c    >        xerange(2,3,e) .le. rxbop(2,3)))
c    >                                                          ) then
c        pres = PL !set the pressure of elements in the boundary x=[-0.1,0.1]
c                     !y=[-0.1,0.1] z=[0.1,0.1] to high pressure
c        endif 

        if(x**2+y**2 .le. 0.01) then !the pressure range is in a radius
           rho = dl
           pres = PL                     ! of 0.1 from [0,0.1]
        endif

        ux = 0.
        uy = 0.
        uz = 0.
        phi = 1.0
        varsic(1) = phi*rho
        varsic(2) = varsic(1)*ux
        varsic(3) = varsic(1)*uy
        varsic(4) = varsic(1)*uz
        varsic(5) = varsic(1)*(cvgref*
     > MixtPerf_T_DPR(rho,pres,rgasref)+
     >  0.5*(ux**2+uy**2+uz**2))
        temp = MixtPerf_T_DPR(rho,pres,rgasref)
      cp=cpgref
      cv=cvgref
      return
      end
c-----------------------------------------------------------------------
      subroutine usrdat
      include 'SIZE'
      include 'TOTAL'
      include 'CMTDATA'
      include 'CMTTIMERS'
      include 'CMTBCDATA'
      include 'PERFECTGAS'

      molmass    = 29.
      gmaref=1.4
      rgasref    = MixtPerf_R_M(molmass,dum)
      cvgref     = rgasref/(gmaref-1.0)
      cpgref     = MixtPerf_Cp_CvR(cvgref,rgasref)

      res_freq = 1000000
      flio_freq=iostep
!-----------------------------------------------------------------------
! JH030317
! adding output fields for diagnostic purposes. optional, but perhaps should
! be flagged by values in uservp (Navier-Stokes vs EVM GP vs both)
!
! ldimt>=3 because we need ldimt1>=4
! vdiff(:,imu) = mu, first viscosity coeff, acting on symmetric strain rate sij
! vdiff(:,iknd) = kappa, thermal conductivity
! vdiff(:,ilam) = lambda, second viscosity coeff, acting on dilatational strain
! vdiff(:,inus) = nu_s, artificial mass diffusivity in GP fluxes
!
! Of course, these coefficients are not applied to corresponding ifield like in
! vanilla nek5000. likewise, vtrans doesn't correspond directly to vdiff, either.
! So T+1 array gets used for other stuff. Document things
! here and in userchk until they become standard

      nbc = 0      ! No changes in boundary conditions required
      do i=1,ldimt
         call add_temp(f2tbc,nbc,1)
      enddo

      igeom = 2
      call setup_topo
      return
      end
c-----------------------------------------------------------------------
      subroutine usrdat2
      include 'SIZE'
      include 'TOTAL'
      include 'TORO'
      include 'CMTBCDATA'
      include 'CMTDATA'
      include 'PERFECTGAS'   

      outflsub=.true.
      IFCNTFILT=.false.
      ifrestart=.false.
      ifsip=.false.
      gasmodel = 1
! JH080714 Now with parameter space to sweep through
      open(unit=81,file="riemann.inp",form="formatted")
      read (81,*) domlen
      read (81,*) diaph1
      read (81,*) gmaref
      read (81,*) dl
      read (81,*) ul
      read (81,*) pl
      read (81,*) dr
      read (81,*) ur
      read (81,*) pright
      close(81)

      c_max=0.5     ! should be 0.5, really
      c_sub_e=40.0

      return
      end
!-----------------------------------------------------------------------
      subroutine cmt_userEOS(ix,iy,iz,eg)
      include 'SIZE'
      include 'NEKUSE'
      include 'PARALLEL'
      include 'CMTDATA'
      include 'PERFECTGAS'
      integer e,eg

      cp=cpgref
      cv=cvgref
      temp=e_internal/cv
      asnd=MixtPerf_C_GRT(gmaref,rgasref,temp)
      pres=MixtPerf_P_DRT(rho,rgasref,temp)
      return
      end
!-----------------------------------------------------------------------
      subroutine usrdat3
      return
      end
c-----------------------------------------------------------------------
      subroutine e1rpex(DOMin,DIAPHin,GAMMAin,DLin,ULin,PLin,DRin,URin,
     >                  PRin,PSCALEin)
*----------------------------------------------------------------------*
*                                                                      *
C     Exact Riemann Solver for the Time-Dependent                      *
C     One Dimensional Euler Equations                                  *
*                                                                      *
C     Name of program: HE-E1RPEX                                       *
*                                                                      *
C     Purpose: to solve the Riemann problem exactly,                   *
C              for the time dependent one dimensional                  *
C              Euler equations for an ideal gas                        *
*                                                                      *
C     Input  file: e1rpex.ini                                          *
C     Output file: e1rpex.out (exact solution)                         *
*                                                                      *
C     Programer: E. F. Toro                                            *
*                                                                      *
C     Last revision: 31st May 1999                                     *
*                                                                      *
C     Theory is found in Ref. 1, Chapt. 4 and in original              *
C     references therein                                               *
*                                                                      *
C     1. Toro, E. F., "Riemann Solvers and Numerical                   *
C                      Methods for Fluid Dynamics"                     *
C                      Springer-Verlag, 1997                           *
C                      Second Edition, 1999                            *
*                                                                      *
C     This program is part of                                          *
*                                                                      *
C     NUMERICA                                                         *
C     A Library of Source Codes for Teaching,                          *
C     Research and Applications,                                       *
C     by E. F. Toro                                                    *
C     Published by NUMERITEK LTD, 1999                                 *
C     Website: www.numeritek.com                                       *
*                                                                      *
*----------------------------------------------------------------------*
*
      include 'TORO'
*
C     Declaration of variables:
*
      INTEGER I, CELLS
*
*
C     Input variables
*
C     DOMLEN   : Domain length
C     DIAPH1   : Position of diaphragm 1
C     CELLS    : Number of computing cells
C     GAMMA    : Ratio of specific heats
C     TIMEOU   : Output time
C     DL       : Initial density  on left state
C     UL       : Initial velocity on left state
C     PL       : Initial pressure on left state
C     DR       : Initial density  on right state
C     UR       : Initial velocity on right state
C     PR       : Initial pressure on right state
C     PSCALE   : Normalising constant
*
!     Initial data and parameters are now arguments

           DOMLEN=DOMin
           DIAPH1=DIAPHin
           GAMMA =GAMMAin
           DL    =DLin
           UL    =ULin
           PL    =PLin
           DR    =DRin
           UR    =URin
           PRight=PRin
           PSCALE=PSCALEin

C     Compute gamma related constants
*
      G1 = (GAMMA - 1.0)/(2.0*GAMMA)
      G2 = (GAMMA + 1.0)/(2.0*GAMMA)
      G3 = 2.0*GAMMA/(GAMMA - 1.0)
      G4 = 2.0/(GAMMA - 1.0)
      G5 = 2.0/(GAMMA + 1.0)
      G6 = (GAMMA - 1.0)/(GAMMA + 1.0)
      G7 = (GAMMA - 1.0)/2.0
      G8 = GAMMA - 1.0
*
C     Compute sound speeds
*
      CL = SQRT(GAMMA*PL/DL)
      CR = SQRT(GAMMA*PRight/DR)
*
C     The pressure positivity condition is tested for
*
      IF(G4*(CL+CR).LE.(UR-UL))THEN
*
C        The initial data is such that vacuum is generated.
C        Program stopped.
*
         WRITE(6,*)
         WRITE(6,*)'***Vacuum is generated by data***'
         WRITE(6,*)'***Program stopped***'
         WRITE(6,*)
*
         call exitt
      ENDIF
*
C     Exact solution for pressure and velocity in star
C     region is found
*
      CALL STARPU(PMstar, UM, PSCALE)
*
      return
      end
*
*----------------------------------------------------------------------*
*
      SUBROUTINE STARPU(P, U, PSCALE)
*
c     IMPLICIT NONE
*
C     Purpose: to compute the solution for pressure and
C              velocity in the Star Region
*
C     Declaration of variables
*
      INTEGER I, NRITER
*
      REAL    DL, UL, PL, CL, DR, UR, PRight, CR,
     &        CHANGE, FL, FLD, FR, FRD, P, POLD, PSTART,
     &        TOLPRE, U, UDIFF, PSCALE
*
      COMMON /STATES/ DL, UL, PL, CL, DR, UR, PRight, CR
      DATA TOLPRE, NRITER/1.0E-06, 20/
*
C     Guessed value PSTART is computed
*
      CALL GUESSP(PSTART)
*
      POLD  = PSTART
      UDIFF = UR - UL
*
c     WRITE(6,*)'----------------------------------------'
c     WRITE(6,*)'   Iteration number      Change  '
c     WRITE(6,*)'----------------------------------------'
*
      DO 10 I = 1, NRITER
*
         CALL PREFUN(FL, FLD, POLD, DL, PL, CL)
         CALL PREFUN(FR, FRD, POLD, DR, PRight, CR)
         P      = POLD - (FL + FR + UDIFF)/(FLD + FRD)
         CHANGE = 2.0*ABS((P - POLD)/(P + POLD))
c        WRITE(6, 30)I, CHANGE
         IF(CHANGE.LE.TOLPRE)GOTO 20
         IF(P.LT.0.0)P = TOLPRE
         POLD  = P
*
 10   CONTINUE
*
      WRITE(6,*)'Divergence in Newton-Raphson iteration'
*
 20   CONTINUE
*
C     Compute velocity in Star Region
*
      U = 0.5*(UL + UR + FR - FL)
*
c     WRITE(6,*)'---------------------------------------'
c     WRITE(6,*)'   Pressure        Velocity'
c     WRITE(6,*)'---------------------------------------'
c     WRITE(6,40)P/PSCALE, U
c     WRITE(6,*)'---------------------------------------'
*
 30   FORMAT(5X, I5,15X, F12.7)
 40   FORMAT(2(F14.6, 5X))
*
      END
*
*----------------------------------------------------------------------*
*
      SUBROUTINE GUESSP(PMstar)
*
C     Purpose: to provide a guessed value for pressure
C              PM in the Star Region. The choice is made
C              according to adaptive Riemann solver using
C              the PVRS, TRRS and TSRS approximate
C              Riemann solvers. See Sect. 9.5 of Chapt. 9
C              of Ref. 1
*
c     IMPLICIT NONE
*
C     Declaration of variables
*
      REAL    DL, UL, PL, CL, DR, UR, PRight, CR,
     &        GAMMA, G1, G2, G3, G4, G5, G6, G7, G8,
     &        CUP, GEL, GER, PMstar, PMAX, PMIN, PPV, PQ,
     &        PTL, PTR, QMAX, QUSER, UM
*
      COMMON /GAMMAS/ GAMMA, G1, G2, G3, G4, G5, G6, G7, G8
      COMMON /STATES/ DL, UL, PL, CL, DR, UR, PRight, CR
*
      QUSER = 2.0
*
C     Compute guess pressure from PVRS Riemann solver
*
      CUP  = 0.25*(DL + DR)*(CL + CR)
      PPV  = 0.5*(PL + PRight) + 0.5*(UL - UR)*CUP
      PPV  = MAX(0.0, PPV)
      PMIN = MIN(PL,  PRight)
      PMAX = MAX(PL,  PRight)
      QMAX = PMAX/PMIN
*
      IF(QMAX.LE.QUSER.AND.
     & (PMIN.LE.PPV.AND.PPV.LE.PMAX))THEN
*
C        Select PVRS Riemann solver
*
         PMstar = PPV
      ELSE
         IF(PPV.LT.PMIN)THEN
*
C           Select Two-Rarefaction Riemann solver
*
            PQ  = (PL/PRight)**G1
            UM  = (PQ*UL/CL + UR/CR +
     &            G4*(PQ - 1.0))/(PQ/CL + 1.0/CR)
            PTL = 1.0 + G7*(UL - UM)/CL
            PTR = 1.0 + G7*(UM - UR)/CR
            PMstar  = 0.5*(PL*PTL**G3 + PRight*PTR**G3)
         ELSE
*
C           Select Two-Shock Riemann solver with
C           PVRS as estimate
*
            GEL = SQRT((G5/DL)/(G6*PL + PPV))
            GER = SQRT((G5/DR)/(G6*PRight + PPV))
            PMstar=(GEL*PL+GER*PRight-(UR-UL))/(GEL+GER)
         ENDIF
      ENDIF
*
      END
*
*----------------------------------------------------------------------*
*
      SUBROUTINE PREFUN(F,FD,P,DK,PK,CK)
*
C     Purpose: to evaluate the pressure functions
C              FL and FR in exact Riemann solver
C              and their first derivatives
*
c     IMPLICIT NONE
*
C     Declaration of variables
*
      REAL    AK, BK, CK, DK, F, FD, P, PK, PRATIO, QRT,
     &        GAMMA, G1, G2, G3, G4, G5, G6, G7, G8
*
      COMMON /GAMMAS/ GAMMA, G1, G2, G3, G4, G5, G6, G7, G8
*
      IF(P.LE.PK)THEN
*
C        Rarefaction wave
*
         PRATIO = P/PK
         F    = G4*CK*(PRATIO**G1 - 1.0)
         FD   = (1.0/(DK*CK))*PRATIO**(-G2)
      ELSE
*
C        Shock wave
*
         AK  = G5/DK
         BK  = G6*PK
         QRT = SQRT(AK/(BK + P))
         F   = (P - PK)*QRT
         FD  = (1.0 - 0.5*(P - PK)/(BK + P))*QRT
      ENDIF
*
      END
*
*----------------------------------------------------------------------*
*
      SUBROUTINE SAMPLE(PMstar, UM, S, D, U, P)
*
C     Purpose: to sample the solution throughout the wave
C              pattern. Pressure PM and velocity UM in the
C              Star Region are known. Sampling is performed
C              in terms of the 'speed' S = X/T. Sampled
C              values are D, U, P
*
C     Input variables : PMstar, UM, S, /GAMMAS/, /STATES/
C     Output variables: D, U, P
*
c     IMPLICIT NONE
*
C     Declaration of variables
*
      REAL    DL, UL, PL, CL, DR, UR, PRight, CR,
     &        GAMMA, G1, G2, G3, G4, G5, G6, G7, G8,
     &        C, CML, CMR, D, P, PMstar, PML, PMR,  S,
     &        SHL, SHR, SL, SR, STL, STR, U, UM
*
      COMMON /GAMMAS/ GAMMA, G1, G2, G3, G4, G5, G6, G7, G8
      COMMON /STATES/ DL, UL, PL, CL, DR, UR, PRight, CR

      IF(S.LE.UM)THEN
*
C        Sampling point lies to the left of the contact
C        discontinuity
*
         IF(PMstar.LE.PL)THEN
*
C           Left rarefaction
*
            SHL = UL - CL
*
            IF(S.LE.SHL)THEN
*
C              Sampled point is left data state
*
               D = DL
               U = UL
               P = PL
            ELSE
               CML = CL*(PMstar/PL)**G1
               STL = UM - CML
*
               IF(S.GT.STL)THEN
*
C                 Sampled point is Star Left state
*
                  D = DL*(PMstar/PL)**(1.0/GAMMA)
                  U = UM
                  P = PMstar
               ELSE
*
C                 Sampled point is inside left fan
*
                  U = G5*(CL + G7*UL + S)
                  C = G5*(CL + G7*(UL - S))
                  D = DL*(C/CL)**G4
                  P = PL*(C/CL)**G3
               ENDIF
            ENDIF
         ELSE
*
C           Left shock
*
            PML = PMstar/PL
            SL  = UL - CL*SQRT(G2*PML + G1)
*
            IF(S.LE.SL)THEN
*
C              Sampled point is left data state
*
               D = DL
               U = UL
               P = PL
*
            ELSE
*
C              Sampled point is Star Left state
*
               D = DL*(PML + G6)/(PML*G6 + 1.0)
               U = UM
               P = PMstar
            ENDIF
         ENDIF
      ELSE
*
C        Sampling point lies to the right of the contact
C        discontinuity
*
         IF(PMstar.GT.PRight)THEN
*
C           Right shock
*
            PMR = PMstar/PRight
            SR  = UR + CR*SQRT(G2*PMR + G1)
*
            IF(S.GE.SR)THEN
*
C              Sampled point is right data state
*
               D = DR
               U = UR
               P = PRight
            ELSE
*
C              Sampled point is Star Right state
*
               D = DR*(PMR + G6)/(PMR*G6 + 1.0)
               U = UM
               P = PMstar
            ENDIF
         ELSE
*
C           Right rarefaction
*
            SHR = UR + CR
*
            IF(S.GE.SHR)THEN
*
C              Sampled point is right data state
*
               D = DR
               U = UR
               P = PRight
            ELSE
               CMR = CR*(PMstar/PRight)**G1
               STR = UM + CMR
*
               IF(S.LE.STR)THEN
*
C                 Sampled point is Star Right state
*
                  D = DR*(PMstar/PRight)**(1.0/GAMMA)
                  U = UM
                  P = PMstar
               ELSE
*
C                 Sampled point is inside left fan
*
                  U = G5*(-CR + G7*UR + S)
                  C = G5*(CR - G7*(UR - S))
                  D = DR*(C/CR)**G4
                  P = PRight*(C/CR)**G3
               ENDIF
            ENDIF
         ENDIF
      ENDIF
*
      END
*
c----------------------------------------------------------------------c
*
      subroutine cmt_usrflt(rmult)
      include 'SIZE'
      real rmult(lx1)
      real alpfilt
      integer sfilt, kut
      real eta, etac
      call rone(rmult,lx1)
      alpfilt=36.0 ! H&W 5.3
      kut=lx1/2
      sfilt=8
      etac=real(kut)/real(nx1)
      do i=kut,nx1
         eta=real(i)/real(nx1)
         rmult(i)=exp(-alpfilt*((eta-etac)/(1.0-etac))**sfilt)
      enddo
      return
      end

c automatically added by makenek
      subroutine usrsetvert(glo_num,nel,nx,ny,nz) ! to modify glo_num
      integer*8 glo_num(1)

      return
      end

c automatically added by makenek
      subroutine userqtl

      call userqtl_scig

      return
      end

c automatically added by makenek
      subroutine cmt_userflux ! user defined flux
      include 'SIZE'
      include 'TOTAL'
      include 'NEKUSE'
      include 'CMTDATA'
      real fluxout(lx1*lz1)
      return
      end
