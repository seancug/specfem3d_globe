#=====================================================================
#
#          S p e c f e m 3 D  G l o b e  V e r s i o n  3 . 3
#          --------------------------------------------------
#
#                 Dimitri Komatitsch and Jeroen Tromp
#    Seismological Laboratory - California Institute of Technology
#        (c) California Institute of Technology September 2002
#
#    A signed non-commercial agreement is required to use this program.
#   Please check http://www.gps.caltech.edu/research/jtromp for details.
#           Free for non-commercial academic research ONLY.
#      This program is distributed WITHOUT ANY WARRANTY whatsoever.
#      Do not redistribute this program without written permission.
#
#=====================================================================
#
# Copyright September 2002, by the California Institute of Technology.
# ALL RIGHTS RESERVED. United States Government Sponsorship Acknowledged.
#
# Any commercial use must be negotiated with the Office of Technology
# Transfer at the California Institute of Technology. This software may be
# subject to U.S. export control laws and regulations. By accepting
# this software, the user agrees to comply with all applicable U.S. export laws
# and regulations, including the International Traffic and Arms Regulations,
# 22 C.F.R. 120-130 and the Export Administration Regulations,
# 15 C.F.R. 730-744. User has the responsibility to obtain export licenses,
# or other export authority as may be required before exporting such
# information to foreign countries or providing access to foreign nationals.
# In no event shall the California Institute of Technology be liable to any
# party for direct, indirect, special, incidental or consequential damages,
# including lost profits, arising out of the use of this software and its
# documentation, even if the California Institute of Technology has been
# advised of the possibility of such damage.
#
# The California Institute of Technology specifically disclaims any
# warranties, including the implied warranties or merchantability and fitness
# for a particular purpose. The software and documentation provided hereunder
# is on an "as is" basis, and the California Institute of Technology has no
# obligations to provide maintenance, support, updates, enhancements or
# modifications.
#
#
# Makefile for SPECFEM3D GLOBE version 3.3 - September 2002
# Dimitri Komatitsch, MPI version
#

################ Pentium PC Beowulf #################
#
# Beowulf Portland pgf90
F90 = pgf90
MPIF90 = mpif90
FLAGS_CHECK = -fast -Mnobounds -Mneginfo -Mdclchk -Mstandard
FLAGS_NO_CHECK = -fast -Mnobounds -Mneginfo -Mdclchk -Munroll=c:6 -Mstandard -Knoieee
MPI_FLAGS = 
#
#
# Intel Fortran90 for Linux
#F90 = ifc
#MPIF90 = /usr/local/mpich/bin/mpif90
#FLAGS_NO_CHECK = -O3 -tpp6 -xK -ip -e95 -implicitnone -unroll6
#FLAGS_CHECK = $(FLAGS_NO_CHECK)
#MPI_FLAGS = -Vaxlib
#
#
# NAG compiler for Linux
#F90 = f95
#MPIF90 = mpif90
#FLAGS_CHECK = -O -u -strict95 -C=all
#FLAGS_NO_CHECK = -O -u -strict95
#MPI_FLAGS = 
#
# Lahey f90
#F90 = lf95
#MPIF90 = mpif90
#FLAGS_CHECK = --warn --wo --tpp --f95 --dal -O --chk
#FLAGS_NO_CHECK = --warn --wo --tpp --f95 --dal -O
#MPI_FLAGS = 

################ SGI Irix #################
##
##  CAUTION: always define setenv TRAP_FPE OFF on SGI before compiling
##
#F90 = f90
#MPIF90 = f90
#FLAGS_NO_CHECK = -ansi -u -64 -O3 -OPT:Olimit=0 -OPT:roundoff=3 -OPT:IEEE_arithmetic=3 -r10000 -mips4
#FLAGS_CHECK = $(FLAGS_NO_CHECK) -check_bounds
#MPI_FLAGS = -lmpi -lfastm -lfpe

################## Compaq Dec Alpha #################
#F90 = f90
#MPIF90 = f90
#FLAGS_NO_CHECK = -fast -warn truncated_source -warn argument_checking -warn unused -warn declarations -std95 -check nounderflow
#FLAGS_CHECK = $(FLAGS_NO_CHECK) -check bounds
#MPI_FLAGS = -lfmpi -lmpi

################## Earth Simulator and NEC SX-5 ##################
#F90 = f90
#MPIF90 = f90
#FLAGS_CHECK = -C hopt -R2 -Wf" -L nostdout noinclist mrgmsg noeject -msg b -pvctl loopcnt=14000000 expand=10 fullmsg vecthreshold=20 -s" -pi auto line=100 exp=swap_all,rank
#FLAGS_NO_CHECK = $(FLAGS_CHECK)
#MPI_FLAGS =

######## IBM SP or Power 4 - file names need to be *.f instead of *.f90 ######
#F90 = mpxlf90
#MPIF90 = mpxlf90
#FLAGS_CHECK = -O3 -Q -qarch=auto -qcache=auto -qtune=auto -qlanglvl=95pure -qmaxmem=65536 -qflag=L:L -qhalt=L
#FLAGS_CHECK = -q32 -O3 -qarch=pwr4 -qlanglvl=95pure -qflag=L:L -qhalt=L
#FLAGS_NO_CHECK = $(FLAGS_CHECK)
#MPI_FLAGS = 

O = obj

baksave:
	cp *f90 *h README_SPECFEM3D_V3.3 DATA/Par_file* Makefile go_mesher go_solver runall mymachines path_change_files.pl bak

backup:
	tar cvf SPECFEM3D_V3.3.tar *f90 *h README_SPECFEM3D_V3.3 DATA/Par_file Makefile go_mesher go_solver runall mymachines path_change_files.pl

meshfem3D: constants.h \
       $O/meshfem3D.o \
       $O/create_regions_mesh.o \
       $O/create_chunk_buffers.o \
       $O/topo_bathy.o \
       $O/calc_jacobian.o \
       $O/crustal_model.o \
       $O/make_ellipticity.o \
       $O/rthetaphi_xyz.o \
       $O/get_jacobian_boundaries.o \
       $O/get_flags_boundaries.o \
       $O/get_MPI_cutplanes_xi.o \
       $O/get_MPI_cutplanes_eta.o \
       $O/get_MPI_1D_buffers.o \
       $O/get_ellipticity.o \
       $O/get_global.o \
       $O/get_model.o \
       $O/write_AVS_DX_global_faces_data.o \
       $O/write_AVS_DX_global_chunks_data.o \
       $O/write_AVS_DX_surface_data.o \
       $O/write_AVS_DX_global_data.o \
       $O/write_AVS_DX_mesh_quality_data.o \
       $O/create_name_database.o \
       $O/define_subregions_crust_mantle.o \
       $O/define_subregions_outer_core.o \
       $O/define_subregions_inner_core.o \
       $O/get_codes_buffers.o \
       $O/get_shape3D.o \
       $O/get_shape2D.o \
       $O/hex_nodes.o \
       $O/lagrange_poly.o \
       $O/intgrl.o \
       $O/lgndr.o \
       $O/read_3D_mantle_model.o \
       $O/mesh_radial.o \
       $O/numerical_recipes.o \
       $O/prem_model.o \
       $O/montagner_model.o \
       $O/anisotropic_inner_core_model.o \
       $O/reduce.o \
       $O/save_arrays.o \
       $O/add_topography.o \
       $O/exit_mpi.o \
       $O/read_parameter_file.o \
       $O/compute_parameters.o \
       $O/sort_array_coordinates.o \
       $O/save_header_file.o \
       $O/gll_library.o
## use MPI here
	${MPIF90} $(FLAGS_CHECK) -o xmeshfem3D \
       $O/meshfem3D.o \
       $O/create_regions_mesh.o \
       $O/create_chunk_buffers.o \
       $O/topo_bathy.o \
       $O/calc_jacobian.o \
       $O/crustal_model.o \
       $O/make_ellipticity.o \
       $O/rthetaphi_xyz.o \
       $O/get_jacobian_boundaries.o \
       $O/get_flags_boundaries.o \
       $O/get_MPI_cutplanes_xi.o \
       $O/get_MPI_cutplanes_eta.o \
       $O/get_MPI_1D_buffers.o \
       $O/get_ellipticity.o \
       $O/get_global.o \
       $O/get_model.o \
       $O/write_AVS_DX_global_faces_data.o \
       $O/write_AVS_DX_global_chunks_data.o \
       $O/write_AVS_DX_surface_data.o \
       $O/write_AVS_DX_global_data.o \
       $O/write_AVS_DX_mesh_quality_data.o \
       $O/create_name_database.o \
       $O/define_subregions_crust_mantle.o \
       $O/define_subregions_outer_core.o \
       $O/define_subregions_inner_core.o \
       $O/get_codes_buffers.o \
       $O/get_shape3D.o \
       $O/get_shape2D.o \
       $O/hex_nodes.o \
       $O/lagrange_poly.o \
       $O/intgrl.o \
       $O/lgndr.o \
       $O/mesh_radial.o \
       $O/read_3D_mantle_model.o \
       $O/numerical_recipes.o \
       $O/prem_model.o \
       $O/montagner_model.o \
       $O/anisotropic_inner_core_model.o \
       $O/reduce.o \
       $O/save_arrays.o \
       $O/add_topography.o \
       $O/exit_mpi.o \
       $O/read_parameter_file.o \
       $O/compute_parameters.o \
       $O/sort_array_coordinates.o \
       $O/save_header_file.o \
       $O/gll_library.o $(MPI_FLAGS)

# solver also depends on values from mesher
specfem3D: constants.h OUTPUT_FILES/values_from_mesher.h \
       $O/specfem3D.o \
       $O/read_arrays_solver.o \
       $O/topo_bathy.o \
       $O/get_ellipticity.o \
       $O/make_ellipticity.o \
       $O/calc_jacobian.o \
       $O/get_cmt.o \
       $O/intgrl.o \
       $O/numerical_recipes.o \
       $O/reduce.o \
       $O/write_seismograms.o \
       $O/read_parameter_file.o \
       $O/compute_parameters.o \
       $O/locate_source.o \
       $O/locate_receivers.o \
       $O/make_gravity.o \
       $O/prem_model.o \
       $O/rthetaphi_xyz.o \
       $O/comp_source_time_function.o \
       $O/comp_source_spectrum.o \
       $O/recompute_jacobian.o \
       $O/hex_nodes.o \
       $O/lagrange_poly.o \
       $O/exit_mpi.o \
       $O/get_shape3D.o \
       $O/create_name_database.o \
       $O/define_update_dof.o \
       $O/read_arrays_buffers_solver.o \
       $O/define_derivation_matrices.o \
       $O/compute_arrays_source.o \
       $O/get_attenuation_model.o \
       $O/assemble_MPI_vector.o \
       $O/assemble_MPI_scalar.o \
       $O/compute_forces_crust_mantle.o \
       $O/compute_forces_outer_core.o \
       $O/compute_forces_inner_core.o \
       $O/gll_library.o
## use MPI here
	${MPIF90} $(FLAGS_NO_CHECK) -o xspecfem3D \
       $O/specfem3D.o \
       $O/read_arrays_solver.o \
       $O/topo_bathy.o \
       $O/get_ellipticity.o \
       $O/make_ellipticity.o \
       $O/calc_jacobian.o \
       $O/get_cmt.o \
       $O/intgrl.o \
       $O/numerical_recipes.o \
       $O/reduce.o \
       $O/write_seismograms.o \
       $O/read_parameter_file.o \
       $O/compute_parameters.o \
       $O/locate_source.o \
       $O/locate_receivers.o \
       $O/make_gravity.o \
       $O/prem_model.o \
       $O/rthetaphi_xyz.o \
       $O/comp_source_time_function.o \
       $O/comp_source_spectrum.o \
       $O/recompute_jacobian.o \
       $O/hex_nodes.o \
       $O/lagrange_poly.o \
       $O/exit_mpi.o \
       $O/get_shape3D.o \
       $O/create_name_database.o \
       $O/define_update_dof.o \
       $O/read_arrays_buffers_solver.o \
       $O/define_derivation_matrices.o \
       $O/compute_arrays_source.o \
       $O/get_attenuation_model.o \
       $O/assemble_MPI_vector.o \
       $O/assemble_MPI_scalar.o \
       $O/compute_forces_crust_mantle.o \
       $O/compute_forces_outer_core.o \
       $O/compute_forces_inner_core.o \
       $O/gll_library.o $(MPI_FLAGS)

convolve_source_timefunction: $O/convolve_source_timefunction.o
	${F90} $(FLAGS_CHECK) -o xconvolve_source_timefunction $O/convolve_source_timefunction.o

create_header_file: $O/create_header_file.o $O/read_parameter_file.o \
     $O/compute_parameters.o $O/define_subregions_crust_mantle.o $O/hex_nodes.o $O/save_header_file.o
	${F90} $(FLAGS_CHECK) -o xcreate_header_file $O/create_header_file.o \
     $O/read_parameter_file.o $O/compute_parameters.o $O/define_subregions_crust_mantle.o $O/hex_nodes.o $O/save_header_file.o

create_movie_AVS_DX: $O/create_movie_AVS_DX.o $O/read_parameter_file.o \
     $O/compute_parameters.o $O/rthetaphi_xyz.o
	${F90} $(FLAGS_CHECK) -o xcreate_movie_AVS_DX $O/create_movie_AVS_DX.o \
     $O/read_parameter_file.o $O/compute_parameters.o $O/rthetaphi_xyz.o

combine_AVS_DX: constants.h $O/combine_AVS_DX.o $O/get_cmt.o $O/reduce.o \
       $O/read_parameter_file.o $O/compute_parameters.o $O/create_serial_name_database.o $O/rthetaphi_xyz.o
	${F90} $(FLAGS_CHECK) -o xcombine_AVS_DX $O/combine_AVS_DX.o $O/get_cmt.o \
       $O/reduce.o $O/read_parameter_file.o $O/compute_parameters.o $O/create_serial_name_database.o $O/rthetaphi_xyz.o

check_mesh_quality_AVS_DX: constants.h $O/check_mesh_quality_AVS_DX.o \
       $O/read_parameter_file.o $O/compute_parameters.o $O/create_serial_name_database.o
	${F90} $(FLAGS_CHECK) -o xcheck_mesh_quality_AVS_DX $O/check_mesh_quality_AVS_DX.o \
       $O/read_parameter_file.o $O/compute_parameters.o $O/create_serial_name_database.o

check_buffers_1D: constants.h $O/check_buffers_1D.o \
       $O/read_parameter_file.o $O/compute_parameters.o $O/create_serial_name_database.o
	${F90} $(FLAGS_CHECK) -o xcheck_buffers_1D $O/check_buffers_1D.o \
       $O/read_parameter_file.o $O/compute_parameters.o $O/create_serial_name_database.o

check_buffers_2D: constants.h $O/check_buffers_2D.o \
       $O/read_parameter_file.o $O/compute_parameters.o $O/create_serial_name_database.o
	${F90} $(FLAGS_CHECK) -o xcheck_buffers_2D $O/check_buffers_2D.o \
       $O/read_parameter_file.o $O/compute_parameters.o $O/create_serial_name_database.o

check_buffers_corners_chunks: constants.h $O/check_buffers_corners_chunks.o \
       $O/read_parameter_file.o $O/compute_parameters.o $O/create_serial_name_database.o
	${F90} $(FLAGS_CHECK) -o xcheck_buffers_corners_chunks $O/check_buffers_corners_chunks.o \
       $O/read_parameter_file.o $O/compute_parameters.o $O/create_serial_name_database.o

check_buffers_faces_chunks: constants.h $O/check_buffers_faces_chunks.o \
       $O/read_parameter_file.o $O/compute_parameters.o $O/create_serial_name_database.o
	${F90} $(FLAGS_CHECK) -o xcheck_buffers_faces_chunks $O/check_buffers_faces_chunks.o \
       $O/read_parameter_file.o $O/compute_parameters.o $O/create_serial_name_database.o

clean:
	rm -f $O/*.o *.o work.pc* xmeshfem3D xspecfem3D xcombine_AVS_DX xcheck_mesh_quality_AVS_DX xcheck_buffers_1D xcheck_buffers_2D xcheck_buffers_corners_chunks xcheck_buffers_faces_chunks xconvolve_source_timefunction xcreate_header_file xcreate_movie_AVS_DX

####
#### rule for each .o file below
####

###
### optimized flags and dependence on values from mesher here
###

$O/specfem3D.o: constants.h OUTPUT_FILES/values_from_mesher.h specfem3D.f90
	${MPIF90} $(FLAGS_NO_CHECK) -c -o $O/specfem3D.o specfem3D.f90

$O/compute_forces_crust_mantle.o: constants.h OUTPUT_FILES/values_from_mesher.h compute_forces_crust_mantle.f90
	${F90} $(FLAGS_NO_CHECK) -c -o $O/compute_forces_crust_mantle.o compute_forces_crust_mantle.f90

$O/compute_forces_outer_core.o: constants.h OUTPUT_FILES/values_from_mesher.h compute_forces_outer_core.f90
	${F90} $(FLAGS_NO_CHECK) -c -o $O/compute_forces_outer_core.o compute_forces_outer_core.f90

$O/compute_forces_inner_core.o: constants.h OUTPUT_FILES/values_from_mesher.h compute_forces_inner_core.f90
	${F90} $(FLAGS_NO_CHECK) -c -o $O/compute_forces_inner_core.o compute_forces_inner_core.f90

### use MPI here
$O/assemble_MPI_vector.o: constants.h assemble_MPI_vector.f90
	${MPIF90} $(FLAGS_NO_CHECK) -c -o $O/assemble_MPI_vector.o assemble_MPI_vector.f90

### use MPI here
$O/assemble_MPI_scalar.o: constants.h assemble_MPI_scalar.f90
	${MPIF90} $(FLAGS_NO_CHECK) -c -o $O/assemble_MPI_scalar.o assemble_MPI_scalar.f90

$O/read_arrays_solver.o: constants.h OUTPUT_FILES/values_from_mesher.h read_arrays_solver.f90
	${F90} $(FLAGS_CHECK) -c -o $O/read_arrays_solver.o read_arrays_solver.f90

###
### regular compilation options here
###

$O/convolve_source_timefunction.o: convolve_source_timefunction.f90
	${F90} $(FLAGS_CHECK) -c -o $O/convolve_source_timefunction.o convolve_source_timefunction.f90

$O/create_header_file.o: create_header_file.f90
	${F90} $(FLAGS_CHECK) -c -o $O/create_header_file.o create_header_file.f90

$O/combine_AVS_DX.o: constants.h combine_AVS_DX.f90
	${F90} $(FLAGS_CHECK) -c -o $O/combine_AVS_DX.o combine_AVS_DX.f90

$O/check_mesh_quality_AVS_DX.o: constants.h check_mesh_quality_AVS_DX.f90
	${F90} $(FLAGS_CHECK) -c -o $O/check_mesh_quality_AVS_DX.o check_mesh_quality_AVS_DX.f90

## use MPI here
$O/create_chunk_buffers.o: constants.h create_chunk_buffers.f90
	${MPIF90} $(FLAGS_CHECK) -c -o $O/create_chunk_buffers.o create_chunk_buffers.f90

$O/sort_array_coordinates.o: constants.h sort_array_coordinates.f90
	${F90} $(FLAGS_CHECK) -c -o $O/sort_array_coordinates.o sort_array_coordinates.f90

$O/check_buffers_1D.o: constants.h check_buffers_1D.f90
	${F90} $(FLAGS_CHECK) -c -o $O/check_buffers_1D.o check_buffers_1D.f90

$O/check_buffers_2D.o: constants.h check_buffers_2D.f90
	${F90} $(FLAGS_CHECK) -c -o $O/check_buffers_2D.o check_buffers_2D.f90

$O/check_buffers_corners_chunks.o: constants.h check_buffers_corners_chunks.f90
	${F90} $(FLAGS_CHECK) -c -o $O/check_buffers_corners_chunks.o check_buffers_corners_chunks.f90

$O/check_buffers_faces_chunks.o: constants.h check_buffers_faces_chunks.f90
	${F90} $(FLAGS_CHECK) -c -o $O/check_buffers_faces_chunks.o check_buffers_faces_chunks.f90

### use MPI here
$O/locate_source.o: constants.h locate_source.f90
	${MPIF90} $(FLAGS_CHECK) -c -o $O/locate_source.o locate_source.f90

### use MPI here
$O/locate_receivers.o: constants.h locate_receivers.f90
	${MPIF90} $(FLAGS_CHECK) -c -o $O/locate_receivers.o locate_receivers.f90

## use MPI here
$O/exit_mpi.o: constants.h exit_mpi.f90
	${MPIF90} $(FLAGS_CHECK) -c -o $O/exit_mpi.o exit_mpi.f90

$O/read_parameter_file.o: constants.h read_parameter_file.f90
	${F90} $(FLAGS_CHECK) -c -o $O/read_parameter_file.o read_parameter_file.f90

$O/compute_parameters.o: constants.h compute_parameters.f90
	${F90} $(FLAGS_CHECK) -c -o $O/compute_parameters.o compute_parameters.f90

$O/topo_bathy.o: constants.h topo_bathy.f90
	${F90} $(FLAGS_CHECK) -c -o $O/topo_bathy.o topo_bathy.f90

$O/calc_jacobian.o: constants.h calc_jacobian.f90
	${F90} $(FLAGS_CHECK) -c -o $O/calc_jacobian.o calc_jacobian.f90

$O/crustal_model.o: constants.h crustal_model.f90
	${F90} $(FLAGS_CHECK) -c -o $O/crustal_model.o crustal_model.f90

$O/make_ellipticity.o: constants.h make_ellipticity.f90
	${F90} $(FLAGS_CHECK) -c -o $O/make_ellipticity.o make_ellipticity.f90

$O/get_jacobian_boundaries.o: constants.h get_jacobian_boundaries.f90
	${F90} $(FLAGS_CHECK) -c -o $O/get_jacobian_boundaries.o get_jacobian_boundaries.f90

$O/create_movie_AVS_DX.o: constants.h create_movie_AVS_DX.f90
	${F90} $(FLAGS_CHECK) -c -o $O/create_movie_AVS_DX.o create_movie_AVS_DX.f90

$O/get_flags_boundaries.o: constants.h get_flags_boundaries.f90
	${F90} $(FLAGS_CHECK) -c -o $O/get_flags_boundaries.o get_flags_boundaries.f90

$O/get_MPI_cutplanes_xi.o: constants.h get_MPI_cutplanes_xi.f90
	${F90} $(FLAGS_CHECK) -c -o $O/get_MPI_cutplanes_xi.o get_MPI_cutplanes_xi.f90

$O/get_MPI_cutplanes_eta.o: constants.h get_MPI_cutplanes_eta.f90
	${F90} $(FLAGS_CHECK) -c -o $O/get_MPI_cutplanes_eta.o get_MPI_cutplanes_eta.f90

$O/get_MPI_1D_buffers.o: constants.h get_MPI_1D_buffers.f90
	${F90} $(FLAGS_CHECK) -c -o $O/get_MPI_1D_buffers.o get_MPI_1D_buffers.f90

$O/get_cmt.o: constants.h get_cmt.f90
	${F90} $(FLAGS_CHECK) -c -o $O/get_cmt.o get_cmt.f90

$O/get_ellipticity.o: constants.h get_ellipticity.f90
	${F90} $(FLAGS_CHECK) -c -o $O/get_ellipticity.o get_ellipticity.f90

$O/get_global.o: constants.h get_global.f90
	${F90} $(FLAGS_CHECK) -c -o $O/get_global.o get_global.f90

$O/make_gravity.o: constants.h make_gravity.f90
	${F90} $(FLAGS_CHECK) -c -o $O/make_gravity.o make_gravity.f90

$O/rthetaphi_xyz.o: constants.h rthetaphi_xyz.f90
	${F90} $(FLAGS_CHECK) -c -o $O/rthetaphi_xyz.o rthetaphi_xyz.f90

$O/get_model.o: constants.h get_model.f90
	${F90} $(FLAGS_CHECK) -c -o $O/get_model.o get_model.f90

$O/write_AVS_DX_global_faces_data.o: constants.h write_AVS_DX_global_faces_data.f90
	${F90} $(FLAGS_CHECK) -c -o $O/write_AVS_DX_global_faces_data.o write_AVS_DX_global_faces_data.f90

$O/write_AVS_DX_global_chunks_data.o: constants.h write_AVS_DX_global_chunks_data.f90
	${F90} $(FLAGS_CHECK) -c -o $O/write_AVS_DX_global_chunks_data.o write_AVS_DX_global_chunks_data.f90

$O/write_AVS_DX_surface_data.o: constants.h write_AVS_DX_surface_data.f90
	${F90} $(FLAGS_CHECK) -c -o $O/write_AVS_DX_surface_data.o write_AVS_DX_surface_data.f90

$O/write_AVS_DX_global_data.o: constants.h write_AVS_DX_global_data.f90
	${F90} $(FLAGS_CHECK) -c -o $O/write_AVS_DX_global_data.o write_AVS_DX_global_data.f90

$O/write_AVS_DX_mesh_quality_data.o: constants.h write_AVS_DX_mesh_quality_data.f90
	${F90} $(FLAGS_CHECK) -c -o $O/write_AVS_DX_mesh_quality_data.o write_AVS_DX_mesh_quality_data.f90

$O/get_shape3D.o: constants.h get_shape3D.f90
	${F90} $(FLAGS_CHECK) -c -o $O/get_shape3D.o get_shape3D.f90

$O/get_shape2D.o: constants.h get_shape2D.f90
	${F90} $(FLAGS_CHECK) -c -o $O/get_shape2D.o get_shape2D.f90

$O/hex_nodes.o: constants.h hex_nodes.f90
	${F90} $(FLAGS_CHECK) -c -o $O/hex_nodes.o hex_nodes.f90

$O/intgrl.o: constants.h intgrl.f90
	${F90} $(FLAGS_CHECK) -c -o $O/intgrl.o intgrl.f90

$O/read_3D_mantle_model.o: constants.h read_3D_mantle_model.f90
	${F90} $(FLAGS_CHECK) -c -o $O/read_3D_mantle_model.o read_3D_mantle_model.f90

$O/mesh_radial.o: constants.h mesh_radial.f90
	${F90} $(FLAGS_CHECK) -c -o $O/mesh_radial.o mesh_radial.f90

## use MPI here
$O/meshfem3D.o: constants.h meshfem3D.f90
	${MPIF90} $(FLAGS_CHECK) -c -o $O/meshfem3D.o meshfem3D.f90

$O/numerical_recipes.o: constants.h numerical_recipes.f90
	${F90} $(FLAGS_CHECK) -c -o $O/numerical_recipes.o numerical_recipes.f90

$O/lgndr.o: constants.h lgndr.f90
	${F90} $(FLAGS_CHECK) -c -o $O/lgndr.o lgndr.f90

$O/prem_model.o: constants.h prem_model.f90
	${F90} $(FLAGS_CHECK) -c -o $O/prem_model.o prem_model.f90

$O/montagner_model.o: constants.h montagner_model.f90
	${F90} $(FLAGS_CHECK) -c -o $O/montagner_model.o montagner_model.f90

$O/anisotropic_inner_core_model.o: constants.h anisotropic_inner_core_model.f90
	${F90} $(FLAGS_CHECK) -c -o $O/anisotropic_inner_core_model.o anisotropic_inner_core_model.f90

$O/reduce.o: constants.h reduce.f90
	${F90} $(FLAGS_CHECK) -c -o $O/reduce.o reduce.f90

$O/save_arrays.o: constants.h save_arrays.f90
	${F90} $(FLAGS_CHECK) -c -o $O/save_arrays.o save_arrays.f90

$O/save_header_file.o: constants.h save_header_file.f90
	${F90} $(FLAGS_CHECK) -c -o $O/save_header_file.o save_header_file.f90

$O/comp_source_time_function.o: constants.h comp_source_time_function.f90
	${F90} $(FLAGS_CHECK) -c -o $O/comp_source_time_function.o comp_source_time_function.f90

$O/comp_source_spectrum.o: constants.h comp_source_spectrum.f90
	${F90} $(FLAGS_CHECK) -c -o $O/comp_source_spectrum.o comp_source_spectrum.f90

$O/add_topography.o: constants.h add_topography.f90
	${F90} $(FLAGS_CHECK) -c -o $O/add_topography.o add_topography.f90

$O/write_seismograms.o: constants.h write_seismograms.f90
	${F90} $(FLAGS_CHECK) -c -o $O/write_seismograms.o write_seismograms.f90

$O/lagrange_poly.o: constants.h lagrange_poly.f90
	${F90} $(FLAGS_CHECK) -c -o $O/lagrange_poly.o lagrange_poly.f90

$O/recompute_jacobian.o: constants.h recompute_jacobian.f90
	${F90} $(FLAGS_CHECK) -c -o $O/recompute_jacobian.o recompute_jacobian.f90

$O/create_regions_mesh.o: constants.h create_regions_mesh.f90
	${F90} $(FLAGS_CHECK) -c -o $O/create_regions_mesh.o create_regions_mesh.f90

$O/create_name_database.o: constants.h create_name_database.f90
	${F90} $(FLAGS_CHECK) -c -o $O/create_name_database.o create_name_database.f90

$O/create_serial_name_database.o: constants.h create_serial_name_database.f90
	${F90} $(FLAGS_CHECK) -c -o $O/create_serial_name_database.o create_serial_name_database.f90

$O/define_subregions_crust_mantle.o: constants.h define_subregions_crust_mantle.f90
	${F90} $(FLAGS_CHECK) -c -o $O/define_subregions_crust_mantle.o define_subregions_crust_mantle.f90

$O/define_subregions_outer_core.o: constants.h define_subregions_outer_core.f90
	${F90} $(FLAGS_CHECK) -c -o $O/define_subregions_outer_core.o define_subregions_outer_core.f90

$O/define_subregions_inner_core.o: constants.h define_subregions_inner_core.f90
	${F90} $(FLAGS_CHECK) -c -o $O/define_subregions_inner_core.o define_subregions_inner_core.f90

$O/get_codes_buffers.o: constants.h get_codes_buffers.f90
	${F90} $(FLAGS_CHECK) -c -o $O/get_codes_buffers.o get_codes_buffers.f90

$O/define_update_dof.o: constants.h define_update_dof.f90
	${F90} $(FLAGS_CHECK) -c -o $O/define_update_dof.o define_update_dof.f90

$O/read_arrays_buffers_solver.o: constants.h read_arrays_buffers_solver.f90
	${F90} $(FLAGS_CHECK) -c -o $O/read_arrays_buffers_solver.o read_arrays_buffers_solver.f90

$O/define_derivation_matrices.o: constants.h define_derivation_matrices.f90
	${F90} $(FLAGS_CHECK) -c -o $O/define_derivation_matrices.o define_derivation_matrices.f90

$O/compute_arrays_source.o: constants.h compute_arrays_source.f90
	${F90} $(FLAGS_CHECK) -c -o $O/compute_arrays_source.o compute_arrays_source.f90

$O/get_attenuation_model.o: constants.h get_attenuation_model.f90
	${F90} $(FLAGS_CHECK) -c -o $O/get_attenuation_model.o get_attenuation_model.f90

$O/gll_library.o: constants.h gll_library.f90
	${F90} $(FLAGS_CHECK) -c -o $O/gll_library.o gll_library.f90
