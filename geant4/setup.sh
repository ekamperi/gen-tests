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

function usage()
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

# $1 is the filename, $2 is the expected sha1 sum
# return 0 for true (match), 1 for false (mismatch)
function sha1sum_matches()
{
    expectedsum=$2
    computedsum=$(sha1sum $1 | cut -f1 -d' ')

    if [ "$computedsum" == "$expectedsum" ];
    then
	return 0
    else
	return 1
    fi
}

function download_source()
{
    echo "-> Downloading source"
    curl -o $GEANT4TARBALL "${BASEURL}/${GEANT4TARBALL}"
    tar xzf ${GEANT4TARBALL}
}

function download_physicsdata()
{
    # We declare 'datafiles' as an associative array, with keys being the
    # filenames and values being the sha1 checksums of the files.
    local -A datafiles=(
	# Neutron data files WITH thermal cross sections
#	[G4NDL.4.0.tar.gz]=889e8ee3b348c649427725b8e12212bdca48b78e

	# Neutron data files WITHOUT thermal cross sections
	[G4NDL.0.2.tar.gz]=67d2d39a73cb175967d5299b9d6d8c26c2979639

	# Data files for low energy electromagnetic processes	
	[G4EMLOW.6.23.tar.gz]=25c65e6e42b7e259f739bf6e1689e67509a346c2

	# Data files for photon evaporation	
	[G4PhotonEvaporation.2.2.tar.gz]=9f598fed6c53f18a5525d38d8ec0c5bec8009aa4

	# Data files for radioactive decay hadronic processes	
	[G4RadioactiveDecay.3.4.tar.gz]=8c6ec693fe1e145d6c55bae28e7fd9da748c8e87

	# Data files for nuclear shell effects in INCL/ABLA hadronic model	
	[G4ABLA.3.0.tar.gz]=503621fd99150ca2623299031d2df0d3d1d0cf81

	# Data files for evaluated neutron cross sections on natural composition of elements
	[G4NEUTRONXS.1.1.tar.gz]=58b9a22584962cfc935e60d34b3b920b1bcd10df

	# Data files for shell ionisation cross sections	
	[G4PII.1.3.tar.gz]=020fb5abb8dc9d4dfc073c22025b998de1482738

	# Data files for measured optical surface reflectance
	[RealSurface.1.0.tar.gz]=9b4bd95c647dc702458eeaf89ebf62c5885e2ece
    );

    # Download physics data files, if they don't already exist in the current
    # working directory or if they do exist but their SHA1 sum is wrong (e.g.
    # partial download, corrupted file, etc.)
    for file in ${!datafiles[@]}
    do
	echo "-> Downloading ${file}"
	if [[ -f "${file}" ]] && sha1sum_matches "$file" "${datafiles[$file]}";
	then
            echo "File already exists. Skipping the download."
	else
	    curl -o ${file} "${BASEURL}/${file}"
	fi
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

#    yum install cmake
#    yum install xerces-c
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
download_physicsdata
#install
#print_exports
