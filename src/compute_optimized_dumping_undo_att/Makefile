#=====================================================================
#
#          S p e c f e m 3 D  G l o b e  V e r s i o n  6 . 0
#          --------------------------------------------------
#
#          Main authors: Dimitri Komatitsch and Jeroen Tromp
#                        Princeton University, USA
#             and University of Pau / CNRS / INRIA, France
# (c) Princeton University / California Institute of Technology and University of Pau / CNRS / INRIA
#                            August 2013
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#=====================================================================

DIR = compute_optimized_dumping_undo_att

# The rest of this file is generic
#######################################

####
#### targets
####

default:
	$(MAKE) -C ../.. $(DIR)

all:
	$(MAKE) -C ../.. all

clean:
	$(MAKE) -C ../.. CLEAN=$(DIR) clean

cleanall:
	$(MAKE) -C ../.. clean

backup:
	mkdir -p bak
	cp *f90 *h Makefile bak

bak: backup

.PHONY: default all clean cleanall backup bak

