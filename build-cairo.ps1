$ErrorActionPreference = "continue" #for-now
Write-Output "Setting enviroment variable using vswhere"
# from https://github.com/microsoft/vswhere/wiki/Start-Developer-Command-Prompt#using-powershell
$installationPath = vswhere.exe -prerelease -latest -property installationPath
if ($installationPath -and (test-path "$installationPath\Common7\Tools\vsdevcmd.bat")) {
    & "${env:COMSPEC}" /s /c "`"$installationPath\Common7\Tools\vsdevcmd.bat`" -no_logo && set" | foreach-object {
        $name, $value = $_ -split '=', 2
        set-content env:\"$name" $value
    }
}
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
Copy-Item -Path "libpng/projects/vstudio/Release Library/libpng16.lib" -Destination "libpng/libpng.lib"
Copy-Item -Path "libpng/projects/vstudio/Release Library/zlib.lib" -Destination "zlib/zlib.lib"
dir libpng
dir zlib
cd pixman
bash -c "sed s/-MD/-MT/ Makefile.win32.common > Makefile.win32.common.fixed"
bash -c "mv Makefile.win32.common.fixed Makefile.win32.common"
make pixman -B -f Makefile.win32 "CFG=release"
dir pixman/release
cd ..
cd freetype
devenv.com "builds/windows/vc2010/freetype.sln" -upgrade
devenv.com "builds/windows/vc2010/freetype.sln" -build "Release Static|$MSVC_PLATFORM_NAME"
#cp "``ls -1d "objs/$MSVC_PLATFORM_NAME/Release Static/freetype.lib"``" .
cp "builds\windows\vc2010\..\..\..\objs\$MSVC_PLATFORM_NAME\Release Static\freetype.lib" .
cd ..
dir freetype
$env:CHERE_INVOKING = 'yes'

#debug code here
$File = 'cairo/src/Makefile.win32'

# Process lines of text from file and assign result to $NewContent variable
$NewContent = Get-Content -Path $File |
    ForEach-Object {
        # Output the existing line to pipeline in any case
        $_

        # If line matches regex
        if($_ -match '.*cairo\.dll\: .*')
        {
            # Add output additional line
			'	@echo $(CAIRO_LDFLAGS)'
			'	@echo $@'
			'	@echo $(CAIRO_LIBS)'
			'	@echo $(PIXMAN_LIBS)'
			'	@echo $(OBJECTS)'
			'	@echo $(LD) $(CAIRO_LDFLAGS) -DLL -OUT:$@ $(CAIRO_LIBS) $(PIXMAN_LIBS) $(OBJECTS)'
			'	@$(LD) --help'
        }
    }

# Write content of $NewContent varibale back to file
$NewContent | Out-File -FilePath $File -Encoding Default -Force
#debug code end
bash -lc "./build-cairo.sh"
make -f Makefile.win32 cairo "CFG=release"
# Package headers with DLL
$OUTPUT_FOLDER = "output"
mkdir -p $OUTPUT_FOLDER/include
foreach ($file in @("cairo/cairo-version.h",
        "cairo/src/cairo-features.h",
        "cairo/src/cairo.h",
        "cairo/src/cairo-deprecated.h",
        "cairo/src/cairo-win32.h",
        "cairo/src/cairo-script.h",
        "cairo/src/cairo-ps.h",
        "cairo/src/cairo-pdf.h",
        "cairo/src/cairo-svg.h")) {
    Copy-Item $file $OUTPUT_FOLDER/include
}
Copy-Item cairo/src/cairo-ft.h $OUTPUT_FOLDER/include
mkdir -p $OUTPUT_FOLDER/lib/x86
Copy-Item cairo/src/release/cairo.lib $OUTPUT_FOLDER/lib/$OUTPUT_PLATFORM_NAME
Copy-Item cairo/src/release/cairo.dll $OUTPUT_FOLDER/lib/$OUTPUT_PLATFORM_NAME
Copy-Item cairo/COPYING* $OUTPUT_FOLDER

7z a cairo.zip output/*
echo 'Success!'
