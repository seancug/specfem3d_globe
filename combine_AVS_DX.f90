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

! combine AVS or DX global data files to check the mesh
! this is done in postprocessing after running the mesh generator

  program combine_AVS_DX

  implicit none

  include "constants.h"

! threshold for number of points per wavelength displayed
! otherwise the scale is too large and we cannot see the small values
! all values above this threshold are truncated
  double precision, parameter :: THRESHOLD_GRIDPOINTS = 12.

! non-linear scaling factor for elevation if topography for Earth model
  double precision, parameter :: SCALE_NON_LINEAR = 0.3

! maximum polynomial degree for which we can compute the stability condition
  integer, parameter :: NGLL_MAX_STABILITY = 15

  integer iproc,nspec,npoin
  integer ispec
  integer iglob1,iglob2,iglob3,iglob4
  integer ipoin,numpoin,numpoin2,iglobpointoffset,ntotpoin,ntotspec
  integer numelem,numelem2,iglobelemoffset,idoubling,maxdoubling
  integer iformat,ivalue,icolor,itarget_doubling
  integer imaterial,imatprop,ispec_scale_AVS_DX
  integer nrec,ir,iregion_code
  integer ntotpoinAVS_DX,ntotspecAVS_DX

  double precision vmin,vmax,deltavp,deltavs
  double precision xval,yval,zval
  double precision val_color,rnorm_factor

  logical threshold_used
  logical USE_OPENDX

! for source location
  integer yr,jda,ho,mi
  double precision x_target_source,y_target_source,z_target_source
  double precision r_target_source
  double precision x_source_trgl1,y_source_trgl1,z_source_trgl1
  double precision x_source_trgl2,y_source_trgl2,z_source_trgl2
  double precision x_source_trgl3,y_source_trgl3,z_source_trgl3
  double precision theta,phi,delta_trgl
  double precision sec,t_cmt,hdur
  double precision elat,elon,depth
  double precision moment_tensor(6)

! for receiver location
  integer irec
  double precision r_target
  double precision, allocatable, dimension(:) :: stlat,stlon,stele,stbur
  character(len=8), allocatable, dimension(:) :: station_name,network_name

  double precision, allocatable, dimension(:) :: x_target,y_target,z_target

! for the reference ellipsoid
  double precision reference,radius_dummy,theta_s,phi_s

! processor identification
  character(len=150) prname

! small offset for source and receiver line in AVS_DX
! (small compared to normalized radius of the Earth)

! for full Earth
  double precision, parameter :: small_offset_source_earth = 0.025d0
  double precision, parameter :: small_offset_receiver_earth = 0.0125d0

! for oceans only
  logical OCEANS_ONLY
  integer ioceans
  integer above_zero,below_zero

! for stability condition
  double precision, dimension (:), allocatable :: stability_value,gridpoints_per_wavelength,elevation_sphere
  double precision, dimension (:), allocatable :: dvp,dvs
  double precision, dimension (:), allocatable :: xcoord,ycoord,zcoord,vmincoord,vmaxcoord
  double precision stability_value_min,stability_value_max
  double precision gridpoints_per_wavelength_min,gridpoints_per_wavelength_max
  integer iloop_corners,istab,jstab
  integer ipointnumber1_horiz,ipointnumber2_horiz
  integer ipointnumber1_vert,ipointnumber2_vert
  double precision distance_horiz,distance_vert
  double precision stabmax,gridmin,scale_factor
  integer NGLL_current_horiz,NGLL_current_vert
  double precision percent_GLL(NGLL_MAX_STABILITY)

! for chunk numbering
  integer iproc_read,ichunk,idummy1,idummy2
  integer, dimension(:), allocatable :: ichunk_slice

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

! for all the regions
  integer, dimension(MAX_NUM_REGIONS) :: NSPEC_AB,NSPEC_AC,NSPEC_BC, &
               NSPEC2D_A_XI,NSPEC2D_B_XI,NSPEC2D_C_XI, &
               NSPEC2D_A_ETA,NSPEC2D_B_ETA,NSPEC2D_C_ETA, &
               NSPEC2DMAX_XMIN_XMAX,NSPEC2DMAX_YMIN_YMAX, &
               NSPEC2D_BOTTOM,NSPEC2D_TOP, &
               NSPEC1D_RADIAL,NPOIN1D_RADIAL, &
               NPOIN2DMAX_XMIN_XMAX,NPOIN2DMAX_YMIN_YMAX, &
               nglob_AB,nglob_AC,nglob_BC

  integer region_min,region_max

  double precision small_offset_source,small_offset_receiver

  integer proc_p1,proc_p2

! ************** PROGRAM STARTS HERE **************

  print *
  print *,'Recombining all AVS or DX files for slices'
  print *

  if(.not. SAVE_AVS_DX_MESH_FILES) stop 'AVS or DX files were not saved by the mesher'

  print *,'1 = create files in OpenDX format'
  print *,'2 = create files in AVS UCD format'
  print *,'any other value = exit'
  print *
  print *,'enter value:'
  read(5,*) iformat
  if(iformat<1 .or. iformat>2) stop 'exiting...'
  if(iformat == 1) then
    USE_OPENDX = .true.
  else
    USE_OPENDX = .false.
  endif

  print *
  print *,'1 = edges of all the slices only'
  print *,'2 = edges of the chunks only'
  print *,'3 = surface of the model only'
  print *,'any other value = exit'
  print *
  print *,'enter value:'
  read(5,*) ivalue
  if(ivalue<1 .or. ivalue>3) stop 'exiting...'

! warning if surface elevation
  if(ivalue == 3) then
    print *,'******************************************'
    print *,'*** option 7 to color using topography ***'
    print *,'******************************************'
  endif

  print *
  print *,'1 = color by doubling flag'
  print *,'2 = by slice number'
  print *,'3 = by stability value'
  print *,'4 = by gridpoints per wavelength'
  print *,'5 = dvp/vp'
  print *,'6 = dvs/vs'
  print *,'7 = elevation of Earth model'
  print *,'8 = by region number'
  print *,'9 = focus on one doubling flag only'
  print *,'any other value=exit'
  print *
  print *,'enter value:'
  read(5,*) icolor
  if(icolor<1 .or. icolor >9) stop 'exiting...'
  if((icolor == 3 .or. icolor == 4) .and. ivalue /= 2) &
    stop 'need chunks only to represent stability or gridpoints per wavelength'

  if(icolor == 9) then
    print *
    print *,'enter value of target doubling flag:'
    read(5,*) itarget_doubling
  endif

! for oceans only
  OCEANS_ONLY = .false.
  if(ivalue == 3 .and. icolor == 7) then
    print *
    print *,'1 = represent full topography (topo + oceans)'
    print *,'2 = represent oceans only'
    print *
    read(5,*) ioceans
    if(ioceans == 1) then
      OCEANS_ONLY = .false.
    else if(ioceans == 2) then
      OCEANS_ONLY = .true.
    else
      stop 'incorrect option for the oceans'
    endif
  endif

  print *
  print *,'1 = material property by doubling flag'
  print *,'2 = by slice number'
  print *,'3 = by region number'
  print *,'4 = by chunk number'
  print *,'any other value=exit'
  print *
  print *,'enter value:'
  read(5,*) imaterial
  if(imaterial < 1 .or. imaterial > 4) stop 'exiting...'

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

! user can specify a range of processors here
  print *
  print *,'enter first proc (proc numbers start at 0) = '
  read(5,*) proc_p1
  if(proc_p1 < 0) proc_p1 = 0
  if(proc_p1 > NPROCTOT-1) proc_p1 = NPROCTOT-1

  print *,'enter last proc (enter -1 for all procs) = '
  read(5,*) proc_p2
  if(proc_p2 == -1) proc_p2 = NPROCTOT-1
  if(proc_p2 < 0) proc_p2 = 0
  if(proc_p2 > NPROCTOT-1) proc_p2 = NPROCTOT-1

! set interval to maximum if user input is not correct
  if(proc_p1 <= 0) proc_p1 = 0
  if(proc_p2 < 0) proc_p2 = NPROCTOT - 1

  print *
  print *,'There are ',NPROCTOT,' slices numbered from 0 to ',NPROCTOT-1
  print *

! open file with global slice number addressing
  write(*,*) 'reading slice addressing'
  write(*,*)
  allocate(ichunk_slice(0:NPROCTOT-1))
  open(unit=IIN,file='OUTPUT_FILES/addressing.txt',status='old')
  do iproc = 0,NPROCTOT-1
    read(IIN,*) iproc_read,ichunk,idummy1,idummy2
    if(iproc_read /= iproc) stop 'incorrect slice number read'
    ichunk_slice(iproc) = ichunk
  enddo
  close(IIN)

! define percentage of smallest distance between GLL points for NGLL points
! percentages were computed by calling the GLL points routine for each degree
  percent_GLL(2) = 100.d0
  percent_GLL(3) = 50.d0
  percent_GLL(4) = 27.639320225002102d0
  percent_GLL(5) = 17.267316464601141d0
  percent_GLL(6) = 11.747233803526763d0
  percent_GLL(7) = 8.4888051860716516d0
  percent_GLL(8) = 6.4129925745196719d0
  percent_GLL(9) = 5.0121002294269914d0
  percent_GLL(10) = 4.0233045916770571d0
  percent_GLL(11) = 3.2999284795970416d0
  percent_GLL(12) = 2.7550363888558858d0
  percent_GLL(13) = 2.3345076678918053d0
  percent_GLL(14) = 2.0032477366369594d0
  percent_GLL(15) = 1.7377036748080721d0

! convert to real percentage
  percent_GLL(:) = percent_GLL(:) / 100.d0

! clear flag to detect if threshold used
  threshold_used = .false.

! set length of segments for source and receiver representation
  small_offset_source = small_offset_source_earth
  small_offset_receiver = small_offset_receiver_earth

! set total number of points and elements to zero
  ntotpoin = 0
  ntotspec = 0

  region_min = 1
  region_max = MAX_NUM_REGIONS

! if representing surface elements, only one region
  if(ivalue == 3) then
    region_min = IREGION_CRUST_MANTLE
    region_max = IREGION_CRUST_MANTLE
  endif

  do iregion_code = region_min,region_max

! loop on the selected range of processors
  do iproc = proc_p1,proc_p2

  print *,'Reading slice ',iproc,' in region ',iregion_code

! create the name for the database of the current slide
  call create_serial_name_database(prname,iproc,iregion_code,LOCAL_PATH,NPROCTOT)

  if(ivalue == 1) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXpointsfaces.txt',status='old')
  else if(ivalue == 2) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXpointschunks.txt',status='old')
  else if(ivalue == 3) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXpointssurface.txt',status='old')
  endif

  read(10,*) npoin
  print *,'There are ',npoin,' global AVS or DX points in the slice'
  ntotpoin = ntotpoin + npoin
  close(10)

  if(ivalue == 1) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXelementsfaces.txt',status='old')
  else if(ivalue == 2) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXelementschunks.txt',status='old')
  else if(ivalue == 3) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXelementssurface.txt',status='old')
  endif

  read(10,*) nspec
  print *,'There are ',nspec,' AVS or DX elements in the slice'
  ntotspec = ntotspec + nspec
  close(10)

  enddo
  enddo

  print *
  print *,'There is a total of ',ntotspec,' elements in all the slices'
  print *,'There is a total of ',ntotpoin,' points in all the slices'
  print *

  ntotpoinAVS_DX = ntotpoin
  ntotspecAVS_DX = ntotspec

! write AVS or DX header with element data
  if(USE_OPENDX) then
    open(unit=11,file='OUTPUT_FILES/DX_fullmesh.dx',status='unknown')
    write(11,*) '# object 1 is the irregular positions'
    write(11,*) 'object 1 class array type float rank 1 shape 3 items ',ntotpoinAVS_DX,' data follows'
  else
    open(unit=11,file='OUTPUT_FILES/AVS_fullmesh.inp',status='unknown')
    write(11,*) ntotpoinAVS_DX,' ',ntotspecAVS_DX,' 0 1 0'
  endif

! allocate array for stability condition
  allocate(stability_value(ntotspecAVS_DX))
  allocate(gridpoints_per_wavelength(ntotspecAVS_DX))
  allocate(elevation_sphere(ntotspecAVS_DX))
  allocate(dvp(ntotspecAVS_DX))
  allocate(dvs(ntotspecAVS_DX))
  allocate(xcoord(ntotpoinAVS_DX))
  allocate(ycoord(ntotpoinAVS_DX))
  allocate(zcoord(ntotpoinAVS_DX))
  allocate(vmincoord(ntotpoinAVS_DX))
  allocate(vmaxcoord(ntotpoinAVS_DX))

! ************* generate points ******************

! set global point offset to zero
  iglobpointoffset = 0

  do iregion_code = region_min,region_max

! loop on the selected range of processors
  do iproc=proc_p1,proc_p2

  print *,'Reading slice ',iproc,' in region ',iregion_code

! create the name for the database of the current slide
  call create_serial_name_database(prname,iproc,iregion_code,LOCAL_PATH,NPROCTOT)

  if(ivalue == 1) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXpointsfaces.txt',status='old')
  else if(ivalue == 2) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXpointschunks.txt',status='old')
    open(unit=12,file=prname(1:len_trim(prname))//'AVS_DXpointschunks_stability.txt',status='old')
  else if(ivalue == 3) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXpointssurface.txt',status='old')
  endif

  read(10,*) npoin
  print *,'There are ',npoin,' global AVS or DX points in the slice'

! read local points in this slice and output global AVS or DX points
  do ipoin=1,npoin
      read(10,*) numpoin,xval,yval,zval
      if(ivalue == 2) read(12,*) numpoin2,vmin,vmax
      if(numpoin /= ipoin) stop 'incorrect point number'
      if(ivalue == 2 .and. numpoin2 /= ipoin) stop 'incorrect point number'
! write to AVS or DX global file with correct offset
      if(USE_OPENDX) then
        write(11,"(f8.5,1x,f8.5,1x,f8.5)") xval,yval,zval
      else
        write(11,"(i6,1x,f8.5,1x,f8.5,1x,f8.5)") numpoin + iglobpointoffset,xval,yval,zval
      endif

! save coordinates in global array of points for stability condition
    xcoord(numpoin + iglobpointoffset) = xval
    ycoord(numpoin + iglobpointoffset) = yval
    zcoord(numpoin + iglobpointoffset) = zval
    vmincoord(numpoin + iglobpointoffset) = vmin
    vmaxcoord(numpoin + iglobpointoffset) = vmax

  enddo

  iglobpointoffset = iglobpointoffset + npoin

  close(10)
  if(ivalue == 2) close(12)

  enddo
  enddo

! ************* generate elements ******************

! get source information for frequency for number of points per lambda
  print *,'reading source duration from the CMTSOLUTION file'
  call get_cmt(yr,jda,ho,mi,sec,t_cmt,hdur,elat,elon,depth,moment_tensor,DT,1)

! set global element and point offsets to zero
  iglobpointoffset = 0
  iglobelemoffset = 0
  maxdoubling = -1
  above_zero = 0
  below_zero = 0

  if(USE_OPENDX) then
    write(11,*) '# object 2 is the irregular connections, quads, connecting the positions'
    write(11,*) 'object 2 class array type int rank 1 shape 4 items ',ntotspecAVS_DX,' data follows'
  endif

  do iregion_code = region_min,region_max

! loop on the selected range of processors
  do iproc=proc_p1,proc_p2

  print *,'Reading slice ',iproc,' in region ',iregion_code

! create the name for the database of the current slide
  call create_serial_name_database(prname,iproc,iregion_code,LOCAL_PATH,NPROCTOT)

  if(ivalue == 1) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXelementsfaces.txt',status='old')
    open(unit=12,file=prname(1:len_trim(prname))//'AVS_DXpointsfaces.txt',status='old')
  else if(ivalue == 2) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXelementschunks.txt',status='old')
    if(icolor == 5 .or. icolor == 6) &
      open(unit=13,file=prname(1:len_trim(prname))//'AVS_DXelementschunks_dvp_dvs.txt',status='old')
    open(unit=12,file=prname(1:len_trim(prname))//'AVS_DXpointschunks.txt',status='old')
  else if(ivalue == 3) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXelementssurface.txt',status='old')
    open(unit=12,file=prname(1:len_trim(prname))//'AVS_DXpointssurface.txt',status='old')
  endif

  read(10,*) nspec
  read(12,*) npoin
  print *,'There are ',npoin,' global AVS or DX points in the slice'
  print *,'There are ',nspec,' AVS or DX elements in the slice'

! read local elements in this slice and output global AVS or DX elements
  do ispec=1,nspec
      read(10,*) numelem,idoubling,iglob1,iglob2,iglob3,iglob4
      if(icolor == 5 .or. icolor == 6) then
        read(13,*) numelem2,deltavp,deltavs
        dvp(numelem + iglobelemoffset) = deltavp
        dvs(numelem + iglobelemoffset) = deltavs
      endif
  if(numelem /= ispec) stop 'incorrect element number'
  if((icolor == 5 .or. icolor == 6) .and. numelem2 /= ispec) stop 'incorrect element number'
! compute max of the doubling flag
  maxdoubling = max(maxdoubling,idoubling)

! assign material property (which can be filtered later in AVS_DX)
  if(imaterial == 1) then
    imatprop = idoubling
  else if(imaterial == 2) then
    imatprop = iproc
  else if(imaterial == 3) then
    imatprop = iregion_code
  else if(imaterial == 4) then
    imatprop = ichunk_slice(iproc)
  else
    stop 'invalid code for material property'
  endif

! write to AVS or DX global file with correct offset

! quadrangles (2-D)
      iglob1 = iglob1 + iglobpointoffset
      iglob2 = iglob2 + iglobpointoffset
      iglob3 = iglob3 + iglobpointoffset
      iglob4 = iglob4 + iglobpointoffset

! in the case of OpenDX, node numbers start at zero
! in the case of AVS, node numbers start at one
      if(USE_OPENDX) then
! point order in OpenDX is 1,4,2,3 *not* 1,2,3,4 as in AVS
        write(11,210) iglob1-1,iglob4-1,iglob2-1,iglob3-1
      else
        write(11,211) numelem + iglobelemoffset,imatprop,iglob1,iglob2,iglob3,iglob4
      endif

! get number of GLL points in current element
      NGLL_current_horiz = NGLLX
      NGLL_current_vert = NGLLZ

! check that the degree is not above the threshold for list of percentages
      if(NGLL_current_horiz > NGLL_MAX_STABILITY .or. &
         NGLL_current_vert > NGLL_MAX_STABILITY) &
           stop 'degree too high to compute stability value'

! scaling factor to compute real value of stability condition
    scale_factor = dsqrt(PI*GRAV*RHOAV)

! compute stability value
    stabmax = -1.d0
    gridmin = HUGEVAL

    if(idoubling == IFLAG_CRUST) then

! distinguish between horizontal and vertical directions in crust
! because we have a different polynomial degree in each direction
! this works because the mesher always creates the 2D surfaces starting
! from the lower-left corner, continuing to the lower-right corner and so on
    do iloop_corners = 1,2

    select case(iloop_corners)

      case(1)
        ipointnumber1_horiz = iglob1
        ipointnumber2_horiz = iglob2

        ipointnumber1_vert = iglob1
        ipointnumber2_vert = iglob4

      case(2)
        ipointnumber1_horiz = iglob4
        ipointnumber2_horiz = iglob3

        ipointnumber1_vert = iglob2
        ipointnumber2_vert = iglob3

    end select

    distance_horiz = &
       dsqrt((xcoord(ipointnumber2_horiz)-xcoord(ipointnumber1_horiz))**2 &
           + (ycoord(ipointnumber2_horiz)-ycoord(ipointnumber1_horiz))**2 &
           + (zcoord(ipointnumber2_horiz)-zcoord(ipointnumber1_horiz))**2)

    distance_vert = &
       dsqrt((xcoord(ipointnumber2_vert)-xcoord(ipointnumber1_vert))**2 &
           + (ycoord(ipointnumber2_vert)-ycoord(ipointnumber1_vert))**2 &
           + (zcoord(ipointnumber2_vert)-zcoord(ipointnumber1_vert))**2)

! compute stability value using the scaled interval
    stabmax = dmax1(scale_factor*DT*vmaxcoord(ipointnumber1_horiz)/(distance_horiz*percent_GLL(NGLL_current_horiz)),stabmax)
    stabmax = dmax1(scale_factor*DT*vmaxcoord(ipointnumber1_vert)/(distance_vert*percent_GLL(NGLL_current_vert)),stabmax)

! compute number of points per wavelength
    gridmin = dmin1(scale_factor*hdur*vmincoord(ipointnumber1_horiz)*dble(NGLL_current_horiz)/distance_horiz,gridmin)
    gridmin = dmin1(scale_factor*hdur*vmincoord(ipointnumber1_vert)*dble(NGLL_current_vert)/distance_vert,gridmin)

    enddo

! regular regions with same polynomial degree everywhere

  else

    do istab = 1,4
      do jstab = 1,4
        if(jstab /= istab) then

          if(istab == 1) then
            ipointnumber1_vert = iglob1
          else if(istab == 2) then
            ipointnumber1_vert = iglob2
          else if(istab == 3) then
            ipointnumber1_vert = iglob3
          else if(istab == 4) then
            ipointnumber1_vert = iglob4
          endif

          if(jstab == 1) then
            ipointnumber2_vert = iglob1
          else if(jstab == 2) then
            ipointnumber2_vert = iglob2
          else if(jstab == 3) then
            ipointnumber2_vert = iglob3
          else if(jstab == 4) then
            ipointnumber2_vert = iglob4
          endif

    distance_vert = &
       dsqrt((xcoord(ipointnumber2_vert)-xcoord(ipointnumber1_vert))**2 &
           + (ycoord(ipointnumber2_vert)-ycoord(ipointnumber1_vert))**2 &
           + (zcoord(ipointnumber2_vert)-zcoord(ipointnumber1_vert))**2)

! compute stability value using the scaled interval
    stabmax = dmax1(scale_factor*DT*vmaxcoord(ipointnumber1_vert)/(distance_vert*percent_GLL(NGLL_current_vert)),stabmax)

! compute number of points per wavelength
    gridmin = dmin1(scale_factor*hdur*vmincoord(ipointnumber1_vert)*dble(NGLL_current_vert)/distance_vert,gridmin)

        endif
      enddo
    enddo

  endif

  stability_value(numelem + iglobelemoffset) = stabmax
  gridpoints_per_wavelength(numelem + iglobelemoffset) = gridmin

!   compute elevation to represent ellipticity or topography at the surface
!   use point iglob1 for instance and subtract reference

!   get colatitude and longitude of current point
    xval = xcoord(iglob1)
    yval = ycoord(iglob1)
    zval = zcoord(iglob1)

    call xyz_2_rthetaphi_dble(xval,yval,zval,radius_dummy,theta_s,phi_s)
    call reduce(theta_s,phi_s)

!   if topography then subtract reference ellipsoid or sphere for color code
!   if ellipticity then subtract reference sphere for color code
!   otherwise subtract nothing
    if(TOPOGRAPHY .or. CRUSTAL) then
      if(ELLIPTICITY) then
        reference = 1.d0 - (3.d0*dcos(theta_s)**2 - 1.d0)/3.d0/299.8d0
      else
        reference = R_UNIT_SPHERE
      endif
    else if(ELLIPTICITY) then
      reference = R_UNIT_SPHERE
    else
      reference = 0.
    endif

!   compute elevation
    elevation_sphere(numelem + iglobelemoffset) = &
         (dsqrt(xval**2 + yval**2 + zval**2) - reference)

  enddo

  iglobelemoffset = iglobelemoffset + nspec
  iglobpointoffset = iglobpointoffset + npoin

  close(10)
  close(12)
  if(icolor == 5 .or. icolor == 6) close(13)

  enddo
  enddo

 210 format(i6,1x,i6,1x,i6,1x,i6)
 211 format(i6,1x,i3,' quad ',i6,1x,i6,1x,i6,1x,i6)

! saturate color scale for elevation since small values
! apply non linear scaling if topography to enhance regions around sea level

  if(TOPOGRAPHY .or. CRUSTAL) then

! compute absolute maximum
    rnorm_factor = maxval(dabs(elevation_sphere(:)))

! map to [-1,1]
    elevation_sphere(:) = elevation_sphere(:) / rnorm_factor

! apply non-linear scaling
    do ispec_scale_AVS_DX = 1,ntotspecAVS_DX

      xval = elevation_sphere(ispec_scale_AVS_DX)

! compute total area consisting of oceans
! and suppress areas that are not considered oceans if needed
! use arbitrary threshold to suppress artefacts in ETOPO5 model
      if(xval >= -0.018) then
        if(OCEANS_ONLY) xval = 0.
        above_zero = above_zero + 1
      else
        below_zero = below_zero + 1
      endif

      if(xval >= 0.) then
        if(.not. OCEANS_ONLY) then
          elevation_sphere(ispec_scale_AVS_DX) = xval ** SCALE_NON_LINEAR
        else
          elevation_sphere(ispec_scale_AVS_DX) = 0.
        endif
      else
        elevation_sphere(ispec_scale_AVS_DX) = - dabs(xval) ** SCALE_NON_LINEAR
      endif

    enddo

  else

! regular scaling to real distance if no topography
    elevation_sphere(:) = R_EARTH * elevation_sphere(:)

  endif

  if(THREE_D) then

! compute absolute maximum for dvp
    rnorm_factor = maxval(dabs(dvp(:)))

! map to [-1,1]
    dvp(:) = dvp(:) / rnorm_factor

! apply non-linear scaling
    do ispec_scale_AVS_DX = 1,ntotspecAVS_DX
      xval = dvp(ispec_scale_AVS_DX)
      if(xval >= 0.) then
        dvp(ispec_scale_AVS_DX) = xval ** SCALE_NON_LINEAR
      else
        dvp(ispec_scale_AVS_DX) = - dabs(xval) ** SCALE_NON_LINEAR
      endif
    enddo

! compute absolute maximum for dvs
    rnorm_factor = maxval(dabs(dvs(:)))

! map to [-1,1]
    dvs(:) = dvs(:) / rnorm_factor

! apply non-linear scaling
    do ispec_scale_AVS_DX = 1,ntotspecAVS_DX
      xval = dvs(ispec_scale_AVS_DX)
      if(xval >= 0.) then
        dvs(ispec_scale_AVS_DX) = xval ** SCALE_NON_LINEAR
      else
        dvs(ispec_scale_AVS_DX) = - dabs(xval) ** SCALE_NON_LINEAR
      endif
    enddo

  endif

! ************* generate element data values ******************

! output AVS or DX header for data
  if(USE_OPENDX) then
    write(11,*) 'attribute "element type" string "quads"'
    write(11,*) 'attribute "ref" string "positions"'
    write(11,*) '# object 3 is the element data, which are in a one-to-one'
    write(11,*) '# correspondence with the connections ("dep" on connections)'
    write(11,*) 'object 3 class array type float rank 0 items ',ntotspecAVS_DX,' data follows'
  else
    write(11,*) '1 1'
    write(11,*) 'Zcoord, meters'
  endif

! set global element and point offsets to zero
  iglobelemoffset = 0

  do iregion_code = region_min,region_max

! loop on the selected range of processors
  do iproc=proc_p1,proc_p2

  print *,'Reading slice ',iproc,' in region ',iregion_code

! create the name for the database of the current slide
  call create_serial_name_database(prname,iproc,iregion_code,LOCAL_PATH,NPROCTOT)

  if(ivalue == 1) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXelementsfaces.txt',status='old')
  else if(ivalue == 2) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXelementschunks.txt',status='old')
  else if(ivalue == 3) then
    open(unit=10,file=prname(1:len_trim(prname))//'AVS_DXelementssurface.txt',status='old')
  endif

  read(10,*) nspec
  print *,'There are ',nspec,' AVS or DX elements in the slice'

! read local elements in this slice and output global AVS or DX elements
  do ispec=1,nspec
      read(10,*) numelem,idoubling,iglob1,iglob2,iglob3,iglob4
      if(numelem /= ispec) stop 'incorrect element number'

! data is either the slice number or the mesh doubling region flag
      if(icolor == 1) then
        val_color = dble(idoubling)
      else if(icolor == 2) then
        val_color = dble(iproc)
      else if(icolor == 3) then
        val_color = stability_value(numelem + iglobelemoffset)
      else if(icolor == 4) then
        val_color = gridpoints_per_wavelength(numelem + iglobelemoffset)
!       put a threshold for number of points per wavelength displayed
!       otherwise the scale is too large and we cannot see the small values
        if(val_color > THRESHOLD_GRIDPOINTS) then
          val_color = THRESHOLD_GRIDPOINTS
          threshold_used = .true.
        endif
      else if(icolor == 5) then
!     minus sign to get the color scheme right: blue is fast (+) and red is slow (-)
        val_color = -dvp(numelem + iglobelemoffset)
      else if(icolor == 6) then
!     minus sign to get the color scheme right: blue is fast (+) and red is slow (-)
        val_color = -dvs(numelem + iglobelemoffset)
      else if(icolor == 7) then
        val_color = elevation_sphere(numelem + iglobelemoffset)

      else if(icolor == 8) then
        val_color = iregion_code
      else if(icolor == 9) then
        if(idoubling == itarget_doubling) then
          val_color = dble(iregion_code)
        else
          val_color = dble(IFLAG_DUMMY)
        endif
      else
        stop 'incorrect coloring code'
      endif

! write to AVS or DX global file with correct offset
      if(USE_OPENDX) then
        write(11,*) sngl(val_color)
      else
        write(11,*) numelem + iglobelemoffset,' ',sngl(val_color)
      endif
  enddo

  iglobelemoffset = iglobelemoffset + nspec

  close(10)

  enddo
  enddo

! define OpenDX field
  if(USE_OPENDX) then
    write(11,*) 'attribute "dep" string "connections"'
    write(11,*) '# a field is created with three components:'
    write(11,*) '# "positions", "connections" and "data"'
    write(11,*) 'object "irregular positions irregular connections" class field'
    write(11,*) 'component "positions" value 1'
    write(11,*) 'component "connections" value 2'
    write(11,*) 'component "data" value 3'
    write(11,*) 'end'
  endif

  close(11)

  print *
  print *,'maximum value of doubling flag in all slices = ',maxdoubling
  print *

! print min and max of stability and points per lambda

  if(ivalue == 2) then

! compute minimum and maximum of stability value and points per wavelength

    stability_value_min = minval(stability_value)
    stability_value_max = maxval(stability_value)

    gridpoints_per_wavelength_min = minval(gridpoints_per_wavelength)
    gridpoints_per_wavelength_max = maxval(gridpoints_per_wavelength)

    print *
    print *,'stability value min, max, ratio = ', &
      stability_value_min,stability_value_max,stability_value_max / stability_value_min

    print *
    print *,'number of points per wavelength min, max, ratio = ', &
      gridpoints_per_wavelength_min,gridpoints_per_wavelength_max, &
      gridpoints_per_wavelength_max / gridpoints_per_wavelength_min

    print *
    print *,'half duration of ',sngl(hdur),' s used for points per wavelength'
    print *

    if(hdur < 5.*DT) then
      print *,'***************************************************************'
      print *,'Source time function is a Heaviside, points per wavelength meaningless'
      print *,'***************************************************************'
      print *
    endif

    if(icolor == 4 .and. threshold_used) then
      print *,'***************************************************************'
      print *,'the number of points per wavelength have been cut above a threshold'
      print *,'of ',THRESHOLD_GRIDPOINTS,' to avoid saturation of color scale'
      print *,'***************************************************************'
      print *
    endif
  endif

! if we have the surface for the Earth, print min and max of elevation

  if(ivalue == 3) then
    print *
    print *,'elevation min, max = ',minval(elevation_sphere),maxval(elevation_sphere)
    if(TOPOGRAPHY .or. CRUSTAL) print *,'elevation has been normalized for topography'
    print *

! print percentage of oceans at surface of the globe
    print *
    print *,'the oceans represent ',100. * below_zero / (above_zero + below_zero),' % of the surface of the mesh'
    print *

  endif

!
! create an AVS or DX file with the source and the receivers as well
!

!   get source information
    print *,'reading position of the source from the CMTSOLUTION file'
    call get_cmt(yr,jda,ho,mi,sec,t_cmt,hdur,elat,elon,depth,moment_tensor,DT,1)

!   convert geographic latitude elat (degrees)
!   to geocentric colatitude theta (radians)
    theta=PI/2.0d0-atan(0.99329534d0*dtan(dble(elat)*PI/180.0d0))
    phi=dble(elon)*PI/180.0d0
    call reduce(theta,phi)

!   compute Cartesian position of the source (ignore ellipticity for AVS_DX)
!   the point for the source is put at the surface for clarity (depth ignored)
!   even slightly above to superimpose to real surface

    r_target_source = 1.02d0
    x_target_source = r_target_source*dsin(theta)*dcos(phi)
    y_target_source = r_target_source*dsin(theta)*dsin(phi)
    z_target_source = r_target_source*dcos(theta)

! save triangle for AVS or DX representation of epicenter
    r_target_source = 1.05d0
    delta_trgl = 1.8 * pi / 180.
    x_source_trgl1 = r_target_source*dsin(theta+delta_trgl)*dcos(phi-delta_trgl)
    y_source_trgl1 = r_target_source*dsin(theta+delta_trgl)*dsin(phi-delta_trgl)
    z_source_trgl1 = r_target_source*dcos(theta+delta_trgl)

    x_source_trgl2 = r_target_source*dsin(theta+delta_trgl)*dcos(phi+delta_trgl)
    y_source_trgl2 = r_target_source*dsin(theta+delta_trgl)*dsin(phi+delta_trgl)
    z_source_trgl2 = r_target_source*dcos(theta+delta_trgl)

    x_source_trgl3 = r_target_source*dsin(theta-delta_trgl)*dcos(phi)
    y_source_trgl3 = r_target_source*dsin(theta-delta_trgl)*dsin(phi)
    z_source_trgl3 = r_target_source*dcos(theta-delta_trgl)

    ntotpoinAVS_DX = 2
    ntotspecAVS_DX = 1

    print *
    print *,'reading position of the receivers'

! get number of stations from receiver file
    open(unit=11,file='DATA/STATIONS',status='old')

! read total number of receivers
    read(11,*) nrec
    print *,'There are ',nrec,' three-component stations'
    print *
    if(nrec < 1) stop 'incorrect number of stations read - need at least one'

    allocate(station_name(nrec))
    allocate(network_name(nrec))
    allocate(stlat(nrec))
    allocate(stlon(nrec))
    allocate(stele(nrec))
    allocate(stbur(nrec))

    allocate(x_target(nrec))
    allocate(y_target(nrec))
    allocate(z_target(nrec))

! loop on all the stations
    do irec=1,nrec
      read(11,*) station_name(irec),network_name(irec),stlat(irec),stlon(irec),stele(irec),stbur(irec)

! convert geographic latitude stlat (degrees)
! to geocentric colatitude theta (radians)
      theta=PI/2.0d0-atan(0.99329534d0*dtan(stlat(irec)*PI/180.0d0))
      phi=stlon(irec)*PI/180.0d0
      call reduce(theta,phi)

! compute the Cartesian position of the receiver (ignore ellipticity for AVS_DX)
! points for the receivers are put at the surface for clarity (depth ignored)
      r_target=1.0d0
      x_target(irec) = r_target*dsin(theta)*dcos(phi)
      y_target(irec) = r_target*dsin(theta)*dsin(phi)
      z_target(irec) = r_target*dcos(theta)

    enddo

    close(11)

! duplicate source to have right color normalization in AVS_DX
  ntotpoinAVS_DX = ntotpoinAVS_DX + 2*nrec + 1
  ntotspecAVS_DX = ntotspecAVS_DX + nrec + 1

! write AVS or DX header with element data
! add source and receivers (small AVS or DX lines)
! duplicate source to have right color normalization in AVS_DX
  if(USE_OPENDX) then
    open(unit=11,file='OUTPUT_FILES/DX_source_receivers.dx',status='unknown')
    write(11,*) '# object 1 is the irregular positions'
    write(11,*) 'object 1 class array type float rank 1 shape 3 items ',ntotpoinAVS_DX,' data follows'
    write(11,*) sngl(x_target_source),' ',sngl(y_target_source),' ',sngl(z_target_source)
    write(11,*) sngl(x_target_source+0.1*small_offset_source),' ', &
      sngl(y_target_source+0.1*small_offset_source),' ',sngl(z_target_source+0.1*small_offset_source)
    write(11,*) sngl(x_target_source+1.3*small_offset_source),' ', &
      sngl(y_target_source+1.3*small_offset_source),' ',sngl(z_target_source+1.3*small_offset_source)
    do ir=1,nrec
      write(11,*) sngl(x_target(ir)),' ',sngl(y_target(ir)),' ',sngl(z_target(ir))
      write(11,*) sngl(x_target(ir)+small_offset_receiver),' ', &
        sngl(y_target(ir)+small_offset_receiver),' ',sngl(z_target(ir)+small_offset_receiver)
    enddo
    write(11,*) 'object 2 class array type int rank 1 shape 2 items ',ntotspecAVS_DX,' data follows'
    write(11,*) '0 1'
    do ir=1,nrec
      write(11,*) 4+2*(ir-1)-1,' ',4+2*(ir-1)
    enddo
    write(11,*) '0 2'
    write(11,*) 'attribute "element type" string "lines"'
    write(11,*) 'attribute "ref" string "positions"'
    write(11,*) 'object 3 class array type float rank 0 items ',ntotspecAVS_DX,' data follows'
    write(11,*) '1.'
    do ir=1,nrec
      write(11,*) ' 255.'
    enddo
    write(11,*) ' 120.'
    write(11,*) 'attribute "dep" string "connections"'
    write(11,*) 'object "irregular connections  irregular positions" class field'
    write(11,*) 'component "positions" value 1'
    write(11,*) 'component "connections" value 2'
    write(11,*) 'component "data" value 3'
    write(11,*) 'end'
    close(11)
  else
    open(unit=11,file='OUTPUT_FILES/AVS_source_receivers.inp',status='unknown')
    write(11,*) ntotpoinAVS_DX,' ',ntotspecAVS_DX,' 0 1 0'
    write(11,*) '1 ',sngl(x_target_source),' ',sngl(y_target_source),' ',sngl(z_target_source)
    write(11,*) '2 ',sngl(x_target_source+0.1*small_offset_source),' ', &
      sngl(y_target_source+0.1*small_offset_source),' ',sngl(z_target_source+0.1*small_offset_source)
    write(11,*) '3 ',sngl(x_target_source+1.3*small_offset_source),' ', &
      sngl(y_target_source+1.3*small_offset_source),' ',sngl(z_target_source+1.3*small_offset_source)
    do ir=1,nrec
      write(11,*) 4+2*(ir-1),' ',sngl(x_target(ir)),' ',sngl(y_target(ir)),' ',sngl(z_target(ir))
      write(11,*) 4+2*(ir-1)+1,' ',sngl(x_target(ir)+small_offset_receiver),' ', &
        sngl(y_target(ir)+small_offset_receiver),' ',sngl(z_target(ir)+small_offset_receiver)
    enddo
    write(11,*) '1 1 line 1 2'
    do ir=1,nrec
      write(11,*) ir+1,' 1 line ',4+2*(ir-1),' ',4+2*(ir-1)+1
    enddo
    write(11,*) ir+1,' 1 line 1 3'
    write(11,*) '1 1'
    write(11,*) 'Zcoord, meters'
    write(11,*) '1 1.'
    do ir=1,nrec
      write(11,*) ir+1,' 255.'
    enddo
    write(11,*) ir+1,' 120.'
    close(11)
  endif

! create a file with the epicenter only, represented as a triangle

! write AVS or DX header with element data
  if(USE_OPENDX) then
    open(unit=11,file='OUTPUT_FILES/DX_epicenter.dx',status='unknown')
    write(11,*) '# object 1 is the irregular positions'
    write(11,*) 'object 1 class array type float rank 1 shape 3 items 3 data follows'
    write(11,*) sngl(x_source_trgl1),' ',sngl(y_source_trgl1),' ',sngl(z_source_trgl1)
    write(11,*) sngl(x_source_trgl2),' ',sngl(y_source_trgl2),' ',sngl(z_source_trgl2)
    write(11,*) sngl(x_source_trgl3),' ',sngl(y_source_trgl3),' ',sngl(z_source_trgl3)
    write(11,*) 'object 2 class array type int rank 1 shape 3 items 1 data follows'
    write(11,*) '0 1 2'
    write(11,*) 'attribute "element type" string "triangles"'
    write(11,*) 'attribute "ref" string "positions"'
    write(11,*) 'object 3 class array type float rank 0 items 1 data follows'
    write(11,*) '1.'
    write(11,*) 'attribute "dep" string "connections"'
    write(11,*) 'object "irregular connections  irregular positions" class field'
    write(11,*) 'component "positions" value 1'
    write(11,*) 'component "connections" value 2'
    write(11,*) 'component "data" value 3'
    write(11,*) 'end'
    close(11)
  else
    open(unit=11,file='OUTPUT_FILES/AVS_epicenter.inp',status='unknown')
    write(11,*) '3 1 0 1 0'
    write(11,*) '1 ',sngl(x_source_trgl1),' ',sngl(y_source_trgl1),' ',sngl(z_source_trgl1)
    write(11,*) '2 ',sngl(x_source_trgl2),' ',sngl(y_source_trgl2),' ',sngl(z_source_trgl2)
    write(11,*) '3 ',sngl(x_source_trgl3),' ',sngl(y_source_trgl3),' ',sngl(z_source_trgl3)
    write(11,*) '1 1 tri 1 2 3'
    write(11,*) '1 1'
    write(11,*) 'Zcoord, meters'
    write(11,*) '1 1.'
    close(11)
  endif

  end program combine_AVS_DX
