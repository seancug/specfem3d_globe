!=====================================================================
!
!          S p e c f e m 3 D  G l o b e  V e r s i o n  3 . 3
!          --------------------------------------------------
!
!                 Dimitri Komatitsch and Jeroen Tromp
!    Seismological Laboratory - California Institute of Technology
!        (c) California Institute of Technology September 2002
!
!    A signed non-commercial agreement is required to use this program.
!   Please check http://www.gps.caltech.edu/research/jtromp for details.
!           Free for non-commercial academic research ONLY.
!      This program is distributed WITHOUT ANY WARRANTY whatsoever.
!      Do not redistribute this program without written permission.
!
!=====================================================================

  subroutine get_MPI_cutplanes_xi(myrank,prname,nspec,iMPIcut_xi,ibool,idoubling, &
                        xstore,ystore,zstore,mask_ibool,ichunk,npointot, &
                        NSPEC2D_A_ETA,NSPEC2D_B_ETA,NSPEC2D_C_ETA)

! this routine detects cut planes along xi
! In principle the left cut plane of the first slice
! and the right cut plane of the last slice are not used
! in the solver except if we want to have periodic conditions

  implicit none

  include "constants.h"

  integer nspec,ichunk,myrank
  integer NSPEC2D_A_ETA,NSPEC2D_B_ETA,NSPEC2D_C_ETA

  logical iMPIcut_xi(2,nspec)

  integer ibool(NGLLX,NGLLY,NGLLZ,nspec)
  integer idoubling(nspec)

  double precision xstore(NGLLX,NGLLY,NGLLZ,nspec)
  double precision ystore(NGLLX,NGLLY,NGLLZ,nspec)
  double precision zstore(NGLLX,NGLLY,NGLLZ,nspec)

! logical mask used to create arrays iboolleft_xi and iboolright_xi
  integer npointot
  logical mask_ibool(npointot)

! global element numbering
  integer ispec

! MPI cut-plane element numbering
  integer ispecc1,ispecc2,npoin2D_xi,ix,iy,iz
  integer nspec2Dtheor1,nspec2Dtheor2

  integer icode1D

! processor identification
  character(len=150) prname

! theoretical number of surface elements in the buffers
! cut planes along xi=constant correspond to ETA faces
  if(ichunk == CHUNK_AB .or. ichunk == CHUNK_AB_ANTIPODE) then
      nspec2Dtheor1 = NSPEC2D_A_ETA
      nspec2Dtheor2 = NSPEC2D_B_ETA
  else if(ichunk == CHUNK_AC .or. ichunk == CHUNK_AC_ANTIPODE) then
      nspec2Dtheor1 = NSPEC2D_A_ETA
      nspec2Dtheor2 = NSPEC2D_C_ETA
  else if(ichunk == CHUNK_BC .or. ichunk == CHUNK_BC_ANTIPODE) then
      nspec2Dtheor1 = NSPEC2D_B_ETA
      nspec2Dtheor2 = NSPEC2D_C_ETA
  endif

! write the MPI buffers for the left and right edges of the slice
! and the position of the points to check that the buffers are fine

!
! determine if the element falls on the left MPI cut plane
!

! global point number and coordinates left MPI cut-plane
  open(unit=10,file=prname(1:len_trim(prname))//'iboolleft_xi.txt',status='unknown')

! erase the logical mask used to mark points already found
  mask_ibool(:) = .false.

! nb of global points shared with the other slice
  npoin2D_xi = 0

! nb of elements in this cut-plane
  ispecc1=0

  do ispec=1,nspec
  if(iMPIcut_xi(1,ispec)) then

    ispecc1=ispecc1+1

! loop on all the points in that 2-D element, including edges
  ix = 1
  do iy=1,NGLLY
      do iz=1,NGLLZ

! select point, if not already selected
  if(.not. mask_ibool(ibool(ix,iy,iz,ispec))) then
      mask_ibool(ibool(ix,iy,iz,ispec)) = .true.
      npoin2D_xi = npoin2D_xi + 1

! code for assembling contributions
      call get_codes_buffers(idoubling(ispec),iz,icode1D)

      write(10,*) ibool(ix,iy,iz,ispec),icode1D,xstore(ix,iy,iz,ispec), &
              ystore(ix,iy,iz,ispec),zstore(ix,iy,iz,ispec)
  endif

      enddo
  enddo

  endif
  enddo

! put flag to indicate end of the list of points
  write(10,*) '0 0  0.  0.  0.'

! write total number of points
  write(10,*) npoin2D_xi

  close(10)

! compare number of surface elements detected to analytical value
  if(ispecc1 /= nspec2Dtheor1 .and. ispecc1 /= nspec2Dtheor2) &
    call exit_MPI(myrank,'error MPI cut-planes detection in xi=left')

!
! determine if the element falls on the right MPI cut plane
!

! global point number and coordinates right MPI cut-plane
  open(unit=10,file=prname(1:len_trim(prname))//'iboolright_xi.txt',status='unknown')

! erase the logical mask used to mark points already found
  mask_ibool(:) = .false.

! nb of global points shared with the other slice
  npoin2D_xi = 0

! nb of elements in this cut-plane
  ispecc2=0

  do ispec=1,nspec
  if(iMPIcut_xi(2,ispec)) then

    ispecc2=ispecc2+1

! loop on all the points in that 2-D element, including edges
  ix = NGLLX
  do iy=1,NGLLY
      do iz=1,NGLLZ

! select point, if not already selected
  if(.not. mask_ibool(ibool(ix,iy,iz,ispec))) then
      mask_ibool(ibool(ix,iy,iz,ispec)) = .true.
      npoin2D_xi = npoin2D_xi + 1

! code for assembling contributions
      call get_codes_buffers(idoubling(ispec),iz,icode1D)

      write(10,*) ibool(ix,iy,iz,ispec),icode1D,xstore(ix,iy,iz,ispec), &
              ystore(ix,iy,iz,ispec),zstore(ix,iy,iz,ispec)
  endif

      enddo
  enddo

  endif
  enddo

! put flag to indicate end of the list of points
  write(10,*) '0 0  0.  0.  0.'

! write total number of points
  write(10,*) npoin2D_xi

  close(10)

! compare number of surface elements detected to analytical value
  if(ispecc2 /= nspec2Dtheor1 .and. ispecc2 /= nspec2Dtheor2) &
    call exit_MPI(myrank,'error MPI cut-planes detection in xi=right')

  end subroutine get_MPI_cutplanes_xi
