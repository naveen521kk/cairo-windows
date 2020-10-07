Write-Output "Setting enviroment variable using vswhere"
# from https://github.com/microsoft/vswhere/wiki/Start-Developer-Command-Prompt#using-powershell
$installationPath = vswhere.exe -prerelease -latest -property installationPath
if ($installationPath -and (test-path "$installationPath\Common7\Tools\vsdevcmd.bat")) {
  & "${env:COMSPEC}" /s /c "`"$installationPath\Common7\Tools\vsdevcmd.bat`" -no_logo && set" | foreach-object {
    $name, $value = $_ -split '=', 2
    set-content env:\"$name" $value
  }
}
$env:PATH = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE;" + $env:PATH
$USE_FREETYPE = 1
$CAIRO_VERSION = "cairo-1.17.2"
$PIXMAN_VERSION = "pixman-0.40.0"
$LIBPNG_VERSION = "libpng-1.6.37"
$ZLIB_VERSION = "zlib-1.2.11"
$FREETYPE_VERSION = "freetype-2.10.2"
$MSVC_PLATFORM_NAME = 'Win32'
wget "https://www.cairographics.org/snapshots/$CAIRO_VERSION.tar.xz" -o "$CAIRO_VERSION.tar.xz"
wget "https://www.cairographics.org/releases/$PIXMAN_VERSION.tar.gz" -o "$PIXMAN_VERSION.tar.gz"
wget "https://download.sourceforge.net/libpng/$LIBPNG_VERSION.tar.gz" -o "$LIBPNG_VERSION.tar.gz" -UserAgent "wget"
wget "http://www.zlib.net/$ZLIB_VERSION.tar.gz" -o "$ZLIB_VERSION.tar.gz"
wget "http://download.savannah.gnu.org/releases/freetype/$FREETYPE_VERSION.tar.gz" -o "$FREETYPE_VERSION.tar.gz"
7z x "$CAIRO_VERSION.tar.xz"
7z x "$CAIRO_VERSION.tar"
7z x "$PIXMAN_VERSION.tar.gz"
7z x "$PIXMAN_VERSION.tar"
7z x "$LIBPNG_VERSION.tar.gz"
7z x "$LIBPNG_VERSION.tar"
7z x "$ZLIB_VERSION.tar.gz"
7z x "$ZLIB_VERSION.tar"
7z x "$FREETYPE_VERSION.tar.gz"
7z x "$FREETYPE_VERSION.tar"
move "$FREETYPE_VERSION" freetype
move "$CAIRO_VERSION" cairo
move "$ZLIB_VERSION" zlib
move "$LIBPNG_VERSION" libpng
move "$PIXMAN_VERSION" pixman
cd libpng
bash -c "sed 's#4996</Disable#4996;5045</Disable#' projects/vstudio/zlib.props > zlib.props.fixed"
bash -c "mv zlib.props.fixed projects/vstudio/zlib.props"
devenv.com "projects\vstudio\vstudio.sln" -upgrade
devenv.com "projects\vstudio\vstudio.sln" -build "Release Library|$MSVC_PLATFORM_NAME" -project libpng
cd ..
bash -c 'cp "libpng/projects/vstudio/x64/Release Library/libpng16.lib" "libpng/libpng.lib"'
bash -c 'cp "libpng/projects/vstudio/x64/Release Library/zlib.lib" "zlib/zlib.lib"'
cd pixman
bash -c "sed s/-MD/-MT/ Makefile.win32.common > Makefile.win32.common.fixed"
bash -c "mv Makefile.win32.common.fixed Makefile.win32.common"
C:\msys64\usr\bin\bash -lc 'make pixman -B -f Makefile.win32 "CFG=release"'
cd freetype
devenv.com "builds/windows/vc2010/freetype.sln" -upgrade
devenv.com "builds/windows/vc2010/freetype.sln" -build "Release Static|$MSVC_PLATFORM_NAME"
bash -c 'cp "`ls -1d "objs/$MSVC_PLATFORM_NAME/Release Static/freetype.lib"`" .'
cd ..
cd cairo
bash -c "sed 's/-MD/-MT/;s/zdll.lib/zlib.lib/' build/Makefile.win32.common > Makefile.win32.common.fixed"
bash -c 'mv Makefile.win32.common.fixed build/Makefile.win32.common'
bash -c "sed '/^CAIRO_LIBS =/s/$/ $(top_builddir)\/..\/freetype\/freetype.lib/;/^DEFAULT_CFLAGS =/s/$/ -I$(top_srcdir)\/..\/freetype\/include/' build/Makefile.win32.common > Makefile.win32.common.fixed"
bash -c "mv Makefile.win32.common.fixed build/Makefile.win32.common"
bash -c 'sed "s/CAIRO_HAS_FT_FONT=./CAIRO_HAS_FT_FONT=$USE_FREETYPE/" build/Makefile.win32.features > Makefile.win32.features.fixed'
bash -c 'mv Makefile.win32.features.fixed build/Makefile.win32.features'
make -B -f Makefile.win32 cairo "CFG=release"
     
