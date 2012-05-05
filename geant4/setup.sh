#!/bin/bash

set -e

BASEURL="http://geant4.cern.ch/support/source"
GEANT4TARBALL="geant4.9.5.p01.tar.gz"
BASEINSTALLDIR="/opt"
INSTALLDIR="$BASEINSTALLDIR/${GEANT4TARBALL%.tar.gz}"	# remove the .tar.gz part
SOURCEDIR="./${GEANT4TARBALL%.tar.gz}"
BUILDDIR="./${GEANT4TARBALL%.tar.gz}-build"
PHYSICSDATA="physicsdata"
NUMBEROFJOBS="3"

usage()
{
    cat <<EOF
usage: `basename`
EOF
    exit 1
}

function print_globals()
{
    echo "------------------------------------------------------------"
    echo "RUNNING AS USER  = $(id -nu)"
    echo "BASE URL         = ${BASEURL}"
    echo "GEANT4 TARBALL   = ${GEANT4TARBALL}"
    echo "BASE INSTALL DIR = ${BASEINSTALLDIR}"
    echo "INSTALL DIR      = ${INSTALLDIR}"
    echo "SOURCE DIR       = ${SOURCEDIR}"
    echo "BUILD DIR        = ${BUILDDIR}"
    echo "PHYSICS DATA DIR = ${PHYSICSDATA}"
    echo "NUMBER OF JOBS   = ${NUMBEROFJOBS}"
    echo "------------------------------------------------------------"
}

function download_source()
{
    echo "-> Downloading source"
    curl -o $GEANT4TARBALL "${BASEURL}/${GEANT4TARBALL}"
    tar xzf ${GEANT4TARBALL}
}

function download_physicsdata()
{
	# Neutron data files WITH thermal cross sections
	# Neutron data files WITHOUT thermal cross sections
	# Data files for low energy electromagnetic processes
	# Data files for photon evaporation
	# Data files for radioactive decay hadronic processes
	# Data files for nuclear shell effects in INCL/ABLA hadronic model
	# Data files for evaluated neutron cross sections on natural composition of elements
	# Data files for shell ionisation cross sections
	# Data files for measured optical surface reflectance
    local -a datafiles=(
#	'G4NDL.4.0.tar.gz'			
#	'G4NDL.0.2.tar.gz'			
#	'G4EMLOW.6.23.tar.gz'			
	'G4PhotonEvaporation.2.2.tar.gz'	
#	'G4RadioactiveDecay.3.4.tar.gz'		
#	'G4ABLA.3.0.tar.gz'			
#	'G4NEUTRONXS.1.1.tar.gz'		
#	'G4PII.1.3.tar.gz'			
#	'RealSurface.1.0.tar.gz'
    );

    # Download physics data files
    for file in ${datafiles[@]}
    do
	echo "-> Downloading ${file}"
	curl -o ${file} "${BASEURL}/${file}"
    done

    # Copy physics data files to the installation directory
    mkdir -p "${INSTALLDIR}/${PHYSICSDATA}"
    for file in ${datafiles[@]}
    do
	echo "-> Copying ${file}"
	cp $file "${INSTALLDIR}/${PHYSICSDATA}"
    done

    # Extract the tarballs
    (
	cd "${INSTALLDIR}/${PHYSICSDATA}"
	for file in ${datafiles[@]}
	do
	    tar xzf $file
	done
    )
}

function install_prereqs()
{
    apt-get install cmake
    apt-get install libxerces-c-dev
}

function build()
{
    mkdir -p ${BUILDDIR}
    (
	cd ${BUILDDIR}
	cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}	\
	      -DCMAKE_BUILD_TYPE=Debug			\
	      -DGEANT4_USE_GDML=ON			\
	      -DGEANT4_USE_OPENGL_X11=ON		\
	    "../${SOURCEDIR}"
	make -j ${NUMBEROFJOBS}
    )
}

function install()
{
    (
	cd ${BUILDDIR}
	make install
    )
}

function print_exports()
{
    echo "------------------------------------------------------------"
    echo "Don't forget to add the following exports in your bash "
    echo "configuration file:"
    echo "export NeutronHPCrossSections=${INSTALLDIR}/${PHYSICSDATA}"
    echo "export G4LEDATA=${INSTALLDIR}/${PHYSICSDATA}"
    echo "export G4LEVELGAMMADATA=${INSTALLDIR}/${PHYSICSDATA}"
    echo "export G4RADIOACTIVEDATA=${INSTALLDIR}/${PHYSICSDATA}"
    echo "export G4ELASTICDATA=${INSTALLDIR}/${PHYSICSDATA}"
    echo "------------------------------------------------------------"    
}

print_globals
#download_source
#build
#download_physicsdata
#install
print_exports
