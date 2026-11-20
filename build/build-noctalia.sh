#!/usr/bin/bash
# Build Fedora's own noctalia package with the lock-screen on-screen keyboard
# patch (patches/noctalia-lockscreen-osk.patch, upstream PR #5233).
# Output: binary RPMs in /out. If Fedora's noctalia already contains the
# feature, /out stays empty and the image uses the repo package unchanged.
set -euxo pipefail

patch=/patches/noctalia-lockscreen-osk.patch
top=/src/rpmbuild
mkdir -p /out "$top"/{SOURCES,SPECS}

dnf5 -y install rpm-build rpmdevtools 'dnf5-command(builddep)' 'dnf5-command(download)' git-core patch
cd /src
dnf5 -y download --source noctalia
srpm="$(ls noctalia-*.src.rpm)"
rpm -i --define "_topdir $top" "$srpm"
spec="$top/SPECS/noctalia.spec"
dnf5 -y builddep "$spec"

# Prep once without the patch to see whether upstream already ships the feature.
rpmbuild --define "_topdir $top" -bp --nodeps "$spec"
srcdir="$(find "$top/BUILD" -maxdepth 3 -type f -name meson.build -path '*noctalia*' -printf '%h\n' | head -1)"
test -n "$srcdir"
if [[ -e "$srcdir/src/shell/lockscreen/lockscreen_keyboard.cpp" ]]; then
  echo "Fedora's noctalia already has the lock-screen keyboard; not patching."
  exit 0
fi
# Fail loudly (not silently ship without the keyboard) if the patch no longer applies.
patch -p1 --dry-run -d "$srcdir" < "$patch"

cp "$patch" "$top/SOURCES/"
# Add the patch to the spec. %autosetup applies every PatchN automatically;
# otherwise apply it right after %setup.
sed -i '0,/^Source0\?:/s//Patch9999:      noctalia-lockscreen-osk.patch\n&/' "$spec"
grep -q '^Patch9999:' "$spec"
if ! grep -q '^%autosetup' "$spec"; then
  sed -i '0,/^%setup.*/s//&\n%patch -P9999 -p1/' "$spec"
fi
# Mark the build so it's identifiable (rpm -q shows .lfosk).
sed -i 's/^\(Release:[[:space:]]*\)\(.*\)$/\1\2.lfosk/' "$spec"

rpmbuild --define "_topdir $top" -bb --nocheck "$spec"
find "$top/RPMS" -name 'noctalia-[0-9]*.rpm' -not -name '*debug*' -exec cp -v {} /out/ \;
ls /out/*.rpm
