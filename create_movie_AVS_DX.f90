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

!
!---  create a movie of radial component of surface displacement
!---  in AVS or OpenDX format
!

  program create_movie_AVS_DX

  implicit none

  include "constants.h"

! threshold in percent of the maximum below which we cut the amplitude
  real(kind=CUSTOM_REAL), parameter :: THRESHOLD = 1._CUSTOM_REAL / 100._CUSTOM_REAL

! flag to apply non linear scaling to normalized norm of displacement
  logical, parameter :: NONLINEAR_SCALING = .true.

! coefficient of power law used for non linear scaling
  real(kind=CUSTOM_REAL), parameter :: POWER_SCALING = 0.30_CUSTOM_REAL

! flag to cut amplitude below a certain threshold
  logical, parameter :: APPLY_THRESHOLD = .true.

  integer it
  integer it1,it2
  integer nspectot_AVS_max
  integer ispec
  integer ibool_number,ibool_number1,ibool_number2,ibool_number3,ibool_number4
  real(kind=CUSTOM_REAL) xcoord,ycoord,zcoord,rval,thetaval,phival
  real(kind=CUSTOM_REAL) displx,disply,displz
  real(kind=CUSTOM_REAL) normal_x,normal_y,normal_z
  double precision min_field_current,max_field_current,max_absol
  logical USE_OPENDX,UNIQUE_FILE
  integer iformat,nframes,iframe

  character(len=150) outputname

  integer iproc,ipoin

! for sorting routine
  integer npointot,ilocnum,nglob,ieoff,ispecloc
  integer, dimension(:), allocatable :: iglob,loc,ireorder
  logical, dimension(:), allocatable :: ifseg,mask_point
  double precision, dimension(:), allocatable :: xp,yp,zp,xp_save,yp_save,zp_save,field_display

! movie files stored by solver
  real(kind=CUSTOM_REAL), dimension(:,:), allocatable :: &
         store_val_x,store_val_y,store_val_z, &
         store_val_ux,store_val_uy,store_val_uz

! parameters read from parameter file
  integer MIN_ATTENUATION_PERIOD,MAX_ATTENUATION_PERIOD,NER_CRUST,NER_220_MOHO,NER_400_220, &
             NER_600_400,NER_670_600,NER_771_670,NER_TOPDDOUBLEPRIME_771, &
             NER_CMB_TOPDDOUBLEPRIME,NER_ICB_CMB,NER_TOP_CENTRAL_CUBE_ICB, &
             NEX_ETA,NEX_XI,NER_DOUBLING_OUTER_CORE, &
             NPROC_ETA,NPROC_XI,NSEIS,NSTEP

  double precision DT

  logical TRANSVERSE_ISOTROPY,ANISOTROPIC_MANTLE,ANISOTROPIC_INNER_CORE,CRUSTAL,ELLIPTICITY, &
             GRAVITY,ONE_CRUST,ROTATION, &
             THREE_D,TOPOGRAPHY,ATTENUATION,OCEANS
  integer NSOURCES,NER_ICB_BOTTOMDBL,NER_TOPDBL_CMB
  double precision RATIO_BOTTOM_DBL_OC,RATIO_TOP_DBL_OC

  character(len=150) LOCAL_PATH

! parameters deduced from parameters read from file
  integer NPROC,NPROCTOT,NEX_PER_PROC_XI,NEX_PER_PROC_ETA
  integer NER,NER_CMB_670,NER_670_400,NER_CENTRAL_CUBE_CMB

! this for all the regions
  integer, dimension(MAX_NUM_REGIONS) :: NSPEC_AB,NSPEC_AC,NSPEC_BC, &
               NSPEC2D_A_XI,NSPEC2D_B_XI,NSPEC2D_C_XI, &
               NSPEC2D_A_ETA,NSPEC2D_B_ETA,NSPEC2D_C_ETA, &
               NSPEC2DMAX_XMIN_XMAX,NSPEC2DMAX_YMIN_YMAX, &
               NSPEC2D_BOTTOM,NSPEC2D_TOP, &
               NSPEC1D_RADIAL,NPOIN1D_RADIAL, &
               NPOIN2DMAX_XMIN_XMAX,NPOIN2DMAX_YMIN_YMAX, &
               NGLOB_AB,NGLOB_AC,NGLOB_BC

! ************** PROGRAM STARTS HERE **************

  print *
  print *,'Recombining all movie frames to create a movie'
  print *

  if(.not. SAVE_AVS_DX_MOVIE) stop 'movie frames were not saved by the solver'

  print *
  print *,'reading parameter file'
  print *

! read the parameter file
  call read_parameter_file(MIN_ATTENUATION_PERIOD,MAX_ATTENUATION_PERIOD,NER_CRUST,NER_220_MOHO,NER_400_220, &
        NER_600_400,NER_670_600,NER_771_670,NER_TOPDDOUBLEPRIME_771, &
        NER_CMB_TOPDDOUBLEPRIME,NER_ICB_CMB,NER_TOP_CENTRAL_CUBE_ICB,NER_DOUBLING_OUTER_CORE, &
        NEX_ETA,NEX_XI,NPROC_ETA,NPROC_XI,NSEIS,NSTEP, &
        DT,TRANSVERSE_ISOTROPY,ANISOTROPIC_MANTLE,ANISOTROPIC_INNER_CORE,CRUSTAL,OCEANS,ELLIPTICITY, &
        GRAVITY,ONE_CRUST,ATTENUATION, &
        ROTATION,THREE_D,TOPOGRAPHY,LOCAL_PATH,NSOURCES,NER_ICB_BOTTOMDBL,NER_TOPDBL_CMB,RATIO_BOTTOM_DBL_OC,RATIO_TOP_DBL_OC)

! compute other parameters based upon values read
  call compute_parameters(NER_CRUST,NER_220_MOHO,NER_400_220, &
      NER_600_400,NER_670_600,NER_771_670,NER_TOPDDOUBLEPRIME_771, &
      NER_CMB_TOPDDOUBLEPRIME,NER_ICB_CMB,NER_TOP_CENTRAL_CUBE_ICB, &
      NER,NER_CMB_670,NER_670_400,NER_CENTRAL_CUBE_CMB, &
      NEX_XI,NEX_ETA,NPROC_XI,NPROC_ETA, &
      NPROC,NPROCTOT,NEX_PER_PROC_XI,NEX_PER_PROC_ETA, &
      NSPEC_AB,NSPEC_AC,NSPEC_BC, &
      NSPEC2D_A_XI,NSPEC2D_B_XI,NSPEC2D_C_XI, &
      NSPEC2D_A_ETA,NSPEC2D_B_ETA,NSPEC2D_C_ETA, &
      NSPEC2DMAX_XMIN_XMAX,NSPEC2DMAX_YMIN_YMAX,NSPEC2D_BOTTOM,NSPEC2D_TOP, &
      NSPEC1D_RADIAL,NPOIN1D_RADIAL, &
      NPOIN2DMAX_XMIN_XMAX,NPOIN2DMAX_YMIN_YMAX, &
      NGLOB_AB,NGLOB_AC,NGLOB_BC,NER_ICB_BOTTOMDBL,NER_TOPDBL_CMB)

  print *
  print *,'There are ',NPROCTOT,' slices numbered from 0 to ',NPROCTOT-1
  print *

  ilocnum = NGNOD2D_AVS_DX*NEX_PER_PROC_XI*NEX_PER_PROC_ETA
  allocate(store_val_x(ilocnum,0:NPROCTOT-1))
  allocate(store_val_y(ilocnum,0:NPROCTOT-1))
  allocate(store_val_z(ilocnum,0:NPROCTOT-1))
  allocate(store_val_ux(ilocnum,0:NPROCTOT-1))
  allocate(store_val_uy(ilocnum,0:NPROCTOT-1))
  allocate(store_val_uz(ilocnum,0:NPROCTOT-1))

  print *,'1 = create files in OpenDX format'
  print *,'2 = create files in AVS UCD format with individual files'
  print *,'3 = create files in AVS UCD format with one time-dependent file'
  print *,'any other value = exit'
  print *
  print *,'enter value:'
  read(5,*) iformat
  if(iformat<1 .or. iformat>3) stop 'exiting...'
  if(iformat == 1) then
    USE_OPENDX = .true.
    UNIQUE_FILE = .false.
  else if(iformat == 2) then
    USE_OPENDX = .false.
    UNIQUE_FILE = .false.
  else
    USE_OPENDX = .false.
    UNIQUE_FILE = .true.
  endif

  print *,'movie frames have been saved every ',NMOVIE,' time steps'
  print *

  print *,'enter first time step of movie (e.g. 1)'
  read(5,*) it1

  print *,'enter last time step of movie (e.g. ',NSTEP,')'
  read(5,*) it2

  print *
  print *,'looping from ',it1,' to ',it2,' every ',NMOVIE,' time steps'

! count number of movie frames
  nframes = 0
  do it = it1,it2
    if(mod(it,NMOVIE) == 0) nframes = nframes + 1
  enddo
  print *
  print *,'total number of frames will be ',nframes
  if(nframes == 0) stop 'null number of frames'

! define the total number of elements at the surface
  nspectot_AVS_max = 6 * NEX_XI * NEX_ETA

  print *
  print *,'there is a total of ',nspectot_AVS_max,' elements at the surface'
  print *

! maximum theoretical number of points at the surface
  npointot = NGNOD2D_AVS_DX * nspectot_AVS_max

! allocate arrays for sorting routine
  allocate(iglob(npointot),loc(npointot))
  allocate(ifseg(npointot))
  allocate(xp(npointot),yp(npointot),zp(npointot))
  allocate(xp_save(npointot),yp_save(npointot),zp_save(npointot))
  allocate(field_display(npointot))
  allocate(mask_point(npointot))
  allocate(ireorder(npointot))

!--- ****** read data saved by solver ******

  print *

  if(APPLY_THRESHOLD) print *,'Will apply a threshold to amplitude below ',100.*THRESHOLD,' %'

  if(NONLINEAR_SCALING) print *,'Will apply a non linear scaling with coef ',POWER_SCALING

! --------------------------------------

  iframe = 0

! loop on all the time steps in the range entered
  do it = it1,it2

! check if time step corresponds to a movie frame
  if(mod(it,NMOVIE) == 0) then

  iframe = iframe + 1

  print *
  print *,'reading snapshot time step ',it,' out of ',NSTEP
  print *

! read all the elements from the same file
  write(outputname,"('OUTPUT_FILES/moviedata',i6.6)") it
  open(unit=IOUT,file=outputname,status='old',form='unformatted')
  read(IOUT) store_val_x
  read(IOUT) store_val_y
  read(IOUT) store_val_z
  read(IOUT) store_val_ux
  read(IOUT) store_val_uy
  read(IOUT) store_val_uz
  close(IOUT)

! clear number of elements kept
  ispec = 0

! read points for all the slices
  do iproc = 0,NPROCTOT-1

! reset point number
  ipoin = 0

  do ispecloc = 1,NEX_PER_PROC_XI*NEX_PER_PROC_ETA

  ispec = ispec + 1
  ieoff = NGNOD2D_AVS_DX*(ispec-1)

! four points for each element
  do ilocnum = 1,NGNOD2D_AVS_DX

    ipoin = ipoin + 1

    xcoord = store_val_x(ipoin,iproc)
    ycoord = store_val_y(ipoin,iproc)
    zcoord = store_val_z(ipoin,iproc)

    displx = store_val_ux(ipoin,iproc)
    disply = store_val_uy(ipoin,iproc)
    displz = store_val_uz(ipoin,iproc)

! coordinates actually contain r theta phi, therefore convert back to x y z
    rval = xcoord
    thetaval = ycoord
    phival = zcoord
    call rthetaphi_2_xyz(xcoord,ycoord,zcoord,rval,thetaval,phival)

! compute unit normal vector to the surface
    normal_x = xcoord / sqrt(xcoord**2 + ycoord**2 + zcoord**2)
    normal_y = ycoord / sqrt(xcoord**2 + ycoord**2 + zcoord**2)
    normal_z = zcoord / sqrt(xcoord**2 + ycoord**2 + zcoord**2)

    xp(ilocnum+ieoff) = dble(xcoord)
    yp(ilocnum+ieoff) = dble(ycoord)
    zp(ilocnum+ieoff) = dble(zcoord)

! show radial component of displacement in the movie
    field_display(ilocnum+ieoff) = dble(displx*normal_x + disply*normal_y + displz*normal_z)

  enddo

  enddo
  enddo

! copy coordinate arrays since the sorting routine does not preserve them
  xp_save(:) = xp(:)
  yp_save(:) = yp(:)
  zp_save(:) = zp(:)

!--- sort the list based upon coordinates to get rid of multiples
  print *,'sorting list of points'
  call get_global_AVS(nspectot_AVS_max,xp,yp,zp,iglob,loc,ifseg,nglob,npointot)

!--- print total number of points found
  print *
  print *,'found a total of ',nglob,' points'
  print *,'initial number of points (with multiples) was ',npointot

!--- ****** create AVS file using sorted list ******

! create file name and open file
  if(USE_OPENDX) then
    write(outputname,"('OUTPUT_FILES/DX_movie_',i6.6,'.dx')") it
    open(unit=11,file=outputname,status='unknown')
    write(11,*) 'object 1 class array type float rank 1 shape 3 items ',nglob,' data follows'
  else
    if(UNIQUE_FILE .and. iframe == 1) then
      open(unit=11,file='OUTPUT_FILES/AVS_movie_all.inp',status='unknown')
      write(11,*) nframes
      write(11,*) 'data'
      write(11,401) 1,1
      write(11,*) nglob,' ',nspectot_AVS_max
    else if(.not. UNIQUE_FILE) then
      write(outputname,"('OUTPUT_FILES/AVS_movie_',i6.6,'.inp')") it
      open(unit=11,file=outputname,status='unknown')
      write(11,*) nglob,' ',nspectot_AVS_max,' 1 0 0'
    endif
  endif

! if unique file, output geometry only once
  if(.not. UNIQUE_FILE .or. iframe == 1) then

! output list of points
  mask_point = .false.
  ipoin = 0
  do ispec=1,nspectot_AVS_max
  ieoff = NGNOD2D_AVS_DX*(ispec-1)
! four points for each element
  do ilocnum = 1,NGNOD2D_AVS_DX
    ibool_number = iglob(ilocnum+ieoff)
    if(.not. mask_point(ibool_number)) then
      ipoin = ipoin + 1
      ireorder(ibool_number) = ipoin
      if(USE_OPENDX) then
        write(11,"(f8.5,1x,f8.5,1x,f8.5)") &
          xp_save(ilocnum+ieoff),yp_save(ilocnum+ieoff),zp_save(ilocnum+ieoff)
      else
        write(11,"(i6,1x,f8.5,1x,f8.5,1x,f8.5)") ireorder(ibool_number), &
          xp_save(ilocnum+ieoff),yp_save(ilocnum+ieoff),zp_save(ilocnum+ieoff)
      endif
    endif
    mask_point(ibool_number) = .true.
  enddo
  enddo

  if(USE_OPENDX) &
    write(11,*) 'object 2 class array type int rank 1 shape 4 items ',nspectot_AVS_max,' data follows'

! output list of elements
  do ispec=1,nspectot_AVS_max
    ieoff = NGNOD2D_AVS_DX*(ispec-1)
! four points for each element
    ibool_number1 = iglob(ieoff + 1)
    ibool_number2 = iglob(ieoff + 2)
    ibool_number3 = iglob(ieoff + 3)
    ibool_number4 = iglob(ieoff + 4)
    if(USE_OPENDX) then
! point order in OpenDX is 1,4,2,3 *not* 1,2,3,4 as in AVS
      write(11,210) ireorder(ibool_number1)-1,ireorder(ibool_number4)-1,ireorder(ibool_number2)-1,ireorder(ibool_number3)-1
    else
      write(11,211) ispec,ireorder(ibool_number1),ireorder(ibool_number4),ireorder(ibool_number2),ireorder(ibool_number3)
    endif
  enddo

 210 format(i6,1x,i6,1x,i6,1x,i6)
 211 format(i6,' 1 quad ',i6,1x,i6,1x,i6,1x,i6)

  endif

  if(USE_OPENDX) then
    write(11,*) 'attribute "element type" string "quads"'
    write(11,*) 'attribute "ref" string "positions"'
    write(11,*) 'object 3 class array type float rank 0 items ',nglob,' data follows'
  else
    if(UNIQUE_FILE) then
      if(iframe > 1) then
        if(iframe < 10) then
          write(11,401) iframe,iframe
        else if(iframe < 100) then
          write(11,402) iframe,iframe
        else if(iframe < 1000) then
          write(11,403) iframe,iframe
        else
          write(11,404) iframe,iframe
        endif
      endif
      write(11,*) '1 0'
    endif
! dummy text for labels
    write(11,*) '1 1'
    write(11,*) 'a, b'
  endif

! step number for AVS multistep file
 401 format('step',i1,' image',i1)
 402 format('step',i2,' image',i2)
 403 format('step',i3,' image',i3)
 404 format('step',i4,' image',i4)

! output data values
  mask_point = .false.

! compute min and max of data value to normalize
  min_field_current = minval(field_display(:))
  max_field_current = maxval(field_display(:))

! make sure range is always symmetric and center is in zero
! this assumption works only for fields that can be negative
! would not work for norm of vector for instance
! (we would lose half of the color palette if no negative values)
  max_absol = max(abs(min_field_current),abs(max_field_current))
  min_field_current = - max_absol
  max_field_current = + max_absol

! print minimum and maximum amplitude in current snapshot
  print *
  print *,'minimum amplitude in current snapshot = ',min_field_current
  print *,'maximum amplitude in current snapshot = ',max_field_current
  print *

! normalize field to [0:1]
  field_display(:) = (field_display(:) - min_field_current) / (max_field_current - min_field_current)

! rescale to [-1,1]
  field_display(:) = 2.*field_display(:) - 1.

! apply threshold to normalized field
  if(APPLY_THRESHOLD) &
    where(abs(field_display(:)) <= THRESHOLD) field_display = 0.

! apply non linear scaling to normalized field if needed
  if(NONLINEAR_SCALING) then
    where(field_display(:) >= 0.)
      field_display = field_display ** POWER_SCALING
    elsewhere
      field_display = - abs(field_display) ** POWER_SCALING
    endwhere
  endif

! apply non linear scaling to normalized field if needed
  if(NONLINEAR_SCALING) then
    where(field_display(:) >= 0.)
      field_display = field_display ** POWER_SCALING
    elsewhere
      field_display = - abs(field_display) ** POWER_SCALING
    endwhere
  endif

! map back to [0,1]
  field_display(:) = (field_display(:) + 1.) / 2.

! map field to [0:255] for AVS color scale
  field_display(:) = 255. * field_display(:)

! output point data
  do ispec=1,nspectot_AVS_max
  ieoff = NGNOD2D_AVS_DX*(ispec-1)
! four points for each element
  do ilocnum = 1,NGNOD2D_AVS_DX
    ibool_number = iglob(ilocnum+ieoff)
    if(.not. mask_point(ibool_number)) then
      if(USE_OPENDX) then
        write(11,501) field_display(ilocnum+ieoff)
      else
        write(11,502) ireorder(ibool_number),field_display(ilocnum+ieoff)
      endif
    endif
    mask_point(ibool_number) = .true.
  enddo
  enddo

 501 format(f7.2)
 502 format(i6,1x,f7.2)

! define OpenDX field
  if(USE_OPENDX) then
    write(11,*) 'attribute "dep" string "positions"'
    write(11,*) 'object "irregular positions irregular connections" class field'
    write(11,*) 'component "positions" value 1'
    write(11,*) 'component "connections" value 2'
    write(11,*) 'component "data" value 3'
    write(11,*) 'end'
  endif

  if(.not. UNIQUE_FILE) close(11)

! end of loop and test on all the time steps for all the movie images
  endif
  enddo

  if(UNIQUE_FILE) close(11)

  print *
  print *,'done creating movie'
  print *
  print *,'AVS files are stored in OUTPUT_FILES/AVS_movie_*.inp'
  print *,'DX files are stored in OUTPUT_FILES/DX_movie_*.dx'
  print *

  end program create_movie_AVS_DX

!
!=====================================================================
!

  subroutine get_global_AVS(nspec,xp,yp,zp,iglob,loc,ifseg,nglob,npointot)

! this routine MUST be in double precision to avoid sensitivity
! to roundoff errors in the coordinates of the points

! leave sorting subroutines in same source file to allow for inlining

  implicit none

  include "constants.h"

  integer npointot
  integer iglob(npointot),loc(npointot)
  logical ifseg(npointot)
  double precision xp(npointot),yp(npointot),zp(npointot)
  integer nspec,nglob

  integer ispec,i,j
  integer ieoff,ilocnum,nseg,ioff,iseg,ig

  integer, dimension(:), allocatable :: ind,ninseg,iwork
  double precision, dimension(:), allocatable :: work

! dynamically allocate arrays
  allocate(ind(npointot))
  allocate(ninseg(npointot))
  allocate(iwork(npointot))
  allocate(work(npointot))

! establish initial pointers
  do ispec=1,nspec
    ieoff=NGNOD2D_AVS_DX*(ispec-1)
    do ilocnum=1,NGNOD2D_AVS_DX
      loc(ilocnum+ieoff)=ilocnum+ieoff
    enddo
  enddo

  ifseg(:)=.false.

  nseg=1
  ifseg(1)=.true.
  ninseg(1)=npointot

  do j=1,NDIM

! sort within each segment
  ioff=1
  do iseg=1,nseg
    if(j == 1) then
      call rank(xp(ioff),ind,ninseg(iseg))
    else if(j == 2) then
      call rank(yp(ioff),ind,ninseg(iseg))
    else
      call rank(zp(ioff),ind,ninseg(iseg))
    endif
    call swap_all(loc(ioff),xp(ioff),yp(ioff),zp(ioff),iwork,work,ind,ninseg(iseg))
    ioff=ioff+ninseg(iseg)
  enddo

! check for jumps in current coordinate
! compare the coordinates of the points within a small tolerance
  if(j == 1) then
    do i=2,npointot
      if(dabs(xp(i)-xp(i-1)) > SMALLVALTOL) ifseg(i)=.true.
    enddo
  else if(j == 2) then
    do i=2,npointot
      if(dabs(yp(i)-yp(i-1)) > SMALLVALTOL) ifseg(i)=.true.
    enddo
  else
    do i=2,npointot
      if(dabs(zp(i)-zp(i-1)) > SMALLVALTOL) ifseg(i)=.true.
    enddo
  endif

! count up number of different segments
  nseg=0
  do i=1,npointot
    if(ifseg(i)) then
      nseg=nseg+1
      ninseg(nseg)=1
    else
      ninseg(nseg)=ninseg(nseg)+1
    endif
  enddo
  enddo

! assign global node numbers (now sorted lexicographically)
  ig=0
  do i=1,npointot
    if(ifseg(i)) ig=ig+1
    iglob(loc(i))=ig
  enddo

  nglob=ig

! deallocate arrays
  deallocate(ind)
  deallocate(ninseg)
  deallocate(iwork)
  deallocate(work)

  end subroutine get_global_AVS

! -----------------------------------

! sorting routines put in same file to allow for inlining

  subroutine rank(A,IND,N)
!
! Use Heap Sort (Numerical Recipes)
!
  implicit none

  integer n
  double precision A(n)
  integer IND(n)

  integer i,j,l,ir,indx
  double precision q

  do j=1,n
   IND(j)=j
  enddo

  if (n == 1) return

  L=n/2+1
  ir=n
  100 CONTINUE
   IF (l>1) THEN
      l=l-1
      indx=ind(l)
      q=a(indx)
   ELSE
      indx=ind(ir)
      q=a(indx)
      ind(ir)=ind(1)
      ir=ir-1
      if (ir == 1) then
         ind(1)=indx
         return
      endif
   ENDIF
   i=l
   j=l+l
  200    CONTINUE
   IF (J <= IR) THEN
      IF (J<IR) THEN
         IF ( A(IND(j))<A(IND(j+1)) ) j=j+1
      ENDIF
      IF (q<A(IND(j))) THEN
         IND(I)=IND(J)
         I=J
         J=J+J
      ELSE
         J=IR+1
      ENDIF
   goto 200
   ENDIF
   IND(I)=INDX
  goto 100
  end subroutine rank

! ------------------------------------------------------------------

  subroutine swap_all(IA,A,B,C,IW,W,ind,n)
!
! swap arrays IA, A, B and C according to addressing in array IND
!
  implicit none

  integer n

  integer IND(n)
  integer IA(n),IW(n)
  double precision A(n),B(n),C(n),W(n)

  integer i

  IW(:) = IA(:)
  W(:) = A(:)

  do i=1,n
    IA(i)=IW(ind(i))
    A(i)=W(ind(i))
  enddo

  W(:) = B(:)

  do i=1,n
    B(i)=W(ind(i))
  enddo

  W(:) = C(:)

  do i=1,n
    C(i)=W(ind(i))
  enddo

  end subroutine swap_all
