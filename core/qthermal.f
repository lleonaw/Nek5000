      subroutine qthermal(ifvext,ifqvol,qvol)

C     Compute the thermal divergence QTL 
C
C     QTL := div(v) = -1/rho * Drho/Dt
c
c     If we use the ideal gas law and assume
c     that p,R is const we end up with
c     QTL = 1/(rho*cp) rho*cp*DT/Dt
C
C     where rho*cp*DT/Dt represents the RHS of the
C     energy equation expressed in terms of temperature.

      include 'SIZE'
      include 'TOTAL'

      logical ifvext,ifqvol 
      real qvol(1)    
 
      common /scrns/ w1(lx1,ly1,lz1,lelt)
     $              ,w2(lx1,ly1,lz1,lelt)
     $              ,w3(lx1,ly1,lz1,lelt)
     $              ,tx(lx1,ly1,lz1,lelt)
     $              ,ty(lx1,ly1,lz1,lelt)
     $              ,tz(lx1,ly1,lz1,lelt)


      nxyz = nx1*ny1*nz1
      ntot = nxyz*nelv

      ifld_save = ifield

c - - Assemble RHS of T-eqn
      ifield=2

      if(ifqvol) then
        call copy(qtl,qvol,ntot)
      else
        call setqvol(qtl) ! volumetric heating source
      endif
      call col2(qtl,bm1,ntot)

      ifield=1     !set right gs handle (QTL is only defined on the velocity mesh)
      call opgrad  (tx,ty,tz,t)
      call opdssum (tx,ty,tz)
      call opcolv  (tx,ty,tz,binvm1)
      call opcolv  (tx,ty,tz,vdiff(1,1,1,1,2))
      call opdiv   (w2,tx,ty,tz)

      call add2    (qtl,w2,ntot)
      call dssum   (qtl,nx1,ny1,nz1)
      call col2    (qtl,binvm1,ntot)

      ! QTL = T_RHS/(rho*cp**T)

      call col3    (w2,vtrans(1,1,1,1,2),t,ntot)
      call invcol2 (qtl,w2,ntot)


      dp0thdt = 0.0
      if (ifdp0dt) then

         ! extrapolte velocity to compute global mass flux
         if (ifvext) then
            call copy(tx,vx,ntot)
            call copy(ty,vy,ntot)
            if (if3d) call copy(tz,vz,ntot)

            call copy(vx,vx_e,ntot)
            call copy(vy,vy_e,ntot)
            if (if3d) call copy(vz,vz_e,ntot)
         endif

         dp0thdt = 0.0
         dd = gamma0 ! CVref/CPref ! Note CVref denotes the inverse CPref
         dd = -1.0*(dd - 1.)/dd

         call rone(w1,ntot)
         call cmult(w1,dd,ntot)
         call cadd(w1,1.0,ntot)
         call copy(w2,w1,ntot)
         call col2(w1,bm1,ntot)
  
         p0alph1 = p0th / glsum(w1,ntot)
  
         call copy   (w1,QTL,ntot)
         call col2   (w1,bm1,ntot)
         termQ = glsum(w1,ntot)
         termV = glcflux() 
         dp0thdt = p0alph1*(termQ - termV)

         if (ifvext) then
            call copy(vx,tx,ntot)
            call copy(vy,ty,ntot)
            if (if3d) call copy(vz,tz,ntot)
         endif

         dd =-dp0thdt/p0th
         call cmult(w2,dd,ntot)
         call add2 (qtl,w2,ntot)
      endif

      ifield = ifld_save

      return
      end
