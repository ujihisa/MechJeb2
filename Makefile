# Makefile for building MechJeb

ifeq ($(OS),Windows_NT)
	# do 'Doze stuff
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		ifndef XDG_DATA_HOME
			XDG_DATA_HOME := ${HOME}/.local/share
		endif
		ifndef KSPDIR
			KSPDIR := ${XDG_DATA_HOME}/Steam/SteamApps/common/Kerbal Space Program
		endif
		MANAGED := ${KSPDIR}/KSP_Data/Managed/
	endif
	ifeq ($(UNAME_S),Darwin)
		ifndef KSPDIR
			KSPDIR  := ${HOME}/Library/Application Support/Steam/steamapps/common/Kerbal Space Program
		endif
		ifndef MANAGED
		MANAGED := ${KSPDIR}/KSP.app/Contents/Resources/Data/Managed/
		endif
	endif
endif


MECHJEBFILES := $(shell find MechJeb2 -name "*.cs")

MSBUILD := msbuild
NUGET   := nuget
GIT     := git
TAR     := tar
ZIP     := zip

VERSION := $(shell ${GIT} describe --tags --always)

all: build

info:
	@echo "== MechJeb2 Build Information =="
	@echo "  nuget:   ${NUGET}"
	@echo "  msbuild: ${MSBUILD}"
	@echo "  git:     ${GIT}"
	@echo "  tar:     ${TAR}"
	@echo "  zip:     ${ZIP}"
	@echo "  KSP Data: ${KSPDIR}"
	@echo "================================"

build: build/MechJeb2.dll


build/MechJeb2.dll: ${MECHJEBFILES} MechJeb2/MechJeb2.csproj MechJebLib/MechJebLib.csproj MechJebLibBindings/MechJebLibBindings.csproj alglib/alglib.csproj MechJebLib/packages.config MechJebLibTest/packages.config
	mkdir -p build
	mkdir -p /tmp/ksp
	${NUGET} restore MechJeb2.sln
	${MSBUILD} /p:Configuration=Release /p:ReferencePath="${MANAGED}" /p:KspDir=/tmp/ksp MechJeb2.sln
	cp MechJeb2/bin/Release/MechJeb2.dll build/
	cp MechJebLib/bin/Release/MechJebLib.dll build/
	cp MechJebLibBindings/bin/Release/MechJebLibBindings.dll build/
	cp alglib/bin/Release/alglib.dll build/
	cp packages/JetBrains.Annotations.2023.3.0/lib/net20/JetBrains.Annotations.dll build/
	test -f MechJeb2/bin/Release/MechJeb2.pdb && cp MechJeb2/bin/Release/MechJeb2.pdb build/ || true
	test -f MechJebLib/bin/Release/MechJebLib.pdb && cp MechJebLib/bin/Release/MechJebLib.pdb build/ || true
	test -f MechJebLibBindings/bin/Release/MechJebLibBindings.pdb && cp MechJebLibBindings/bin/Release/MechJebLibBindings.pdb build/ || true
	test -f alglib/bin/Release/alglib.pdb && cp alglib/bin/Release/alglib.pdb build/ || true
	test -f packages/JetBrains.Annotations.2023.3.0/lib/net20/JetBrains.Annotations.xml && cp packages/JetBrains.Annotations.2023.3.0/lib/net20/JetBrains.Annotations.xml build/ || true

package: build ${MECHJEBFILES}
	mkdir -p package/MechJeb2/Plugins
	cp -r Parts package/MechJeb2/
	cp -r Icons package/MechJeb2/
	cp -r Bundles package/MechJeb2/
	cp -r Localization package/MechJeb2/
	cp build/MechJeb2.dll package/MechJeb2/Plugins/
	cp LICENSE.md README.md package/MechJeb2/

%.tar.gz:
	${TAR} zcf $@ package/MechJeb2

tar.gz: package MechJeb-${VERSION}.tar.gz

%.zip:
	${ZIP} -9 -r $@ package/MechJeb2

zip: package MechJeb-${VERSION}.zip


clean:
	@echo "Cleaning up build and package directories..."
	rm -rf build/ package/

install: build
	mkdir -p "${KSPDIR}"/GameData/MechJeb2/Plugins
	cp -r Parts "${KSPDIR}"/GameData/MechJeb2/
	cp -r Icons "${KSPDIR}"/GameData/MechJeb2/
	cp -r Bundles "${KSPDIR}"/GameData/MechJeb2/
	cp -r Localization "${KSPDIR}"/GameData/MechJeb2/
	for FILENAME in \
		JetBrains.Annotations \
		MechJeb2 \
		MechJebLib \
		MechJebLibBindings \
		alglib \
	do \
		cp build/$${FILENAME}.dll "${KSPDIR}"/GameData/MechJeb2/Plugins/; \
		test -f build/$${FILENAME}.pdb && cp build/$${FILENAME}.pdb "${KSPDIR}"/GameData/MechJeb2/Plugins/; \
		test -f build/$${FILENAME}.xml && cp build/$${FILENAME}.xml "${KSPDIR}"/GameData/MechJeb2/Plugins/; \
	done

uninstall: info
	rm -rf "${KSPDIR}"/GameData/MechJeb2/Plugins
	rm -rf "${KSPDIR}"/GameData/MechJeb2/Parts
	rm -rf "${KSPDIR}"/GameData/MechJeb2/Icons


.PHONY : all info build package tar.gz zip clean install uninstall
