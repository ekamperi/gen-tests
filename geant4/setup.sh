#!/bin/bash

set -e
set -x

BASEURL="http://geant4.cern.ch/support/source"
GEANT4TARBALL="geant4.9.5.p01.tar.gz"
BASEINSTALLDIR="/opt"
INSTALLDIR="$BASEINSTALLDIR/${GEANT4TARBALL%.tar.gz}"	# remove the .tar.gz part
SOURCEDIR="./${GEANT4TARBALL%.tar.gz}"
BUILDDIR="./${GEANT4TARBALL%.tar.gz}-build"
XERCESC_ROOT_DIR="/opt/xerces-c-3.1.1"
PHYSICSDATA="physicsdata"
NUMBEROFJOBS="3"
SOLARIS11DIFFURL="http://leaf.dragonflybsd.org/~beket/geant4/solaris11.diff"

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
    echo "XERCESC_ROOT_DIR = ${XERCESC_ROOT_DIR}"
    echo "PHYSICS DATA DIR = ${PHYSICSDATA}"
    echo "NUMBER OF JOBS   = ${NUMBEROFJOBS}"
    echo "SOLARIS11DIFFURL = ${SOLARIS11DIFFURL}"
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

# $1 is the filename, $2 is the expected sha1 sum
# return 0 for true (exists), 1 for false (does not exist)

function file_exists()
{
    if [[ -f "$1" ]] && sha1sum_matches "$1" "$2";
    then
	return 0
    else
	return 1
    fi
}

function download_source()
{
    echo "-> Downloading source"
    if file_exists "${GEANT4TARBALL}" "b1b938f735a8b966621704cc77448c786777dd01"
    then
        echo "File already exists. Skipping the download."
    else
	curl -o $GEANT4TARBALL "${BASEURL}/${GEANT4TARBALL}"
    fi
    tar xzf ${GEANT4TARBALL}
}

function download_physicsdata()
{
    # We declare 'datafiles' as an associative array, with keys being the
    # filenames and values being the sha1 checksums of the files.

    local -A datafiles=(
	# Neutron data files WITH thermal cross sections
	[G4NDL.4.0.tar.gz]=889e8ee3b348c649427725b8e12212bdca48b78e

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
    for file in ${!datafiles[@]}
    do
	echo "-> Copying ${file}"
	cp $file "${INSTALLDIR}/${PHYSICSDATA}"
    done

    # Extract the tarballs

    (
	cd "${INSTALLDIR}/${PHYSICSDATA}"
	for file in ${!datafiles[@]}
	do
	    tar xzf $file
	done
    )
}

function install_prereqs()
{
    true
#    apt-get install cmake
#    apt-get install libxerces-c-dev

#    yum install cmake
#    yum install xerces-c
#    yum groupinstall "X Software Development"
}

function pre_build()
{
    if [ $(uname -s) == "SunOS" ];
    then
	echo "Applying solaris11.diff patch to source tree"
	rm   -f solaris11.diff
	curl -o solaris11.diff ${SOLARIS11DIFFURL}
	patch -p0 < solaris11.diff
    fi
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
	      -DGEANT4_INSTALL_EXAMPLES=ON		\
	      -DXERCESC_ROOT_DIR=${XERCESC_ROOT_DIR}	\
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

# $1 is the example name,
# e.g. N02 for 2nd example in examples/novice/N02

function build_example()
{
    pathtoGeant4=$(find "${INSTALLDIR}" -name "Geant4Config.cmake")
    pathtoGeant4=${pathtoGeant4%/Geant4Config.cmake}

    pathtoExample=$(find "${INSTALLDIR}/share" -name "$1")

    cp -R "${pathtoExample}" .
    mkdir -p "$1-build"
    (
	cd "$1-build"
	cmake -DGeant4_DIR="${pathtoGeant4}" ../$1
	make -j ${NUMBEROFJOBS}
    )
}

function print_exports()
{
    local -A envvars=(
	[G4ABLADATA]=G4ABLA3.0
	[G4LEDATA]=G4EMLOW6.23
	[G4LEVELGAMMADATA]=G4PhotonEvaporation2.2
	[G4NEUTRONHPDATA]=G4NDL4.0
	[G4NEUTRONXSDATA]=G4NEUTRONXS1.1
	[G4PIIDATA]=G4PII1.3
	[G4RADIOACTIVEDATA]=G4RadioactiveDecay3.4
	[G4REALSURFACEDATA]=RealSurface1.0
    );

    echo "------------------------------------------------------------"
    echo "Don't forget to add the following exports in your bash "
    echo "configuration file:"
    for var in ${!envvars[@]};
    do
	echo "export ${var}=${INSTALLDIR}/${PHYSICSDATA}/${envvars[$var]}"
    done
    echo "------------------------------------------------------------"

    echo "export G4LIB_BUILD_GDML=1"
    echo "export G4LIB_USE_GDML=1"

    echo "export G4INSTALL=/opt/geant4.9.5.p01/share/Geant4-9.5.1/geant4make"
    echo "export G4INCLUDE=/opt/geant4.9.5.p01/include/Geant4"

    echo "export G4INSTALL=/opt/geant4.9.5.p01/share/Geant4-9.5.1/geant4make"
    echo "export G4SYSTEM=Linux-g++"
    echo "export G4LIB=/home/stathis/gen-tests/geant4/geant4.9.5.p01-build/outputs/library"

    echo "------------------------------------------------------------"
}

print_globals
download_source
pre_build
build
download_physicsdata		# not needed if -DGEANT4_INSTALL_DATA=ON
install
print_exports			# not needed if -DGEANT4_INSTALL_DATA=ON

#build_example "$1"
