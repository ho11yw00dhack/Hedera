#!/bin/sh
basedir="$(dirname "$(readlink -f "${0}")")"; cd "${basedir}"
type su-to-root >/dev/null 2>&1 || { 
	echo >&2 "I require menu, but it's not installed. aborting!";exit 1;}
_scriptdep="debhelper dpkg-dev fakeroot findutils sed gawk grep libfile-fcntllock-perl alien"
_makedep=""

install_depends() {
	dpkg --get-selections|awk '{if ($2 == "install") print $1}' > "$basedir"/installed
	printf "==>trying to install build dependencies\n"
	su-to-root -c "apt update; apt-get install --no-install-recommends $_makedep $_scriptdep"
	dpkg --get-selections|awk '{if ($2 == "install") print $1}' > "$basedir"/installed-new
}
clean() {
	pkgdiff=$(diff installed installed-new | grep ">" | tr "\n" " " | sed -e 's/> //' -e 's/ > / /g')
	if [ ! -z "$pkgdiff" ]; then
		printf "==>trying to remove build dependencies\n"
		su-to-root -c "apt-get -m remove $pkgdiff"
	fi
	rm installed installed-new
}
_date=$(date '-R')
_release=$(date -u +%Y.%m.%d)
build() {
	cd "${basedir}"
	for _dir in $(echo $(find ${basedir} -mindepth 1 -maxdepth 1 -type d -name "deb")); do
		cd "$_dir"
		echo "$PWD"
		cp debian/changelog.tmp debian/changelog
		sed -i "s/__RELEASE__/$_release/" debian/changelog
		chmod +x debian/rules
		fakeroot debian/rules binary
		cd ..
	done
}
###start
install_depends
cd "${basedir}"
build
##only tested on suse
fakeroot alien -r -c -k -v --description="A universal widget theme" hedera_${_release}-1_all.deb
mv -f hedera_${_release}-1_all.deb hedera_current.deb
mv -f hedera-${_release}-1.noarch.rpm hedera_current.rpm
clean
printf "\n\n\ndone\n\n\n"
sleep 5
