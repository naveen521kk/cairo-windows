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

#wget "https://gitlab.freedesktop.org/cairo/cairo/-/archive/master/cairo-master.zip" -o "cairo.zip"
#7z x cairo.zip -ocairo
git clone https://gitlab.freedesktop.org/cairo/cairo.git
cd cairo
choco install gtk-runtime
py -3.8 -m pip install --upgrade meson ninja
mkdir final
meson build --default-library=static -Dfontconfig=enabled -Dfreetype=enabled -Dglib=enabled -Dzlib=enabled
ninja -C build

Copy-Item cairo/build $OUTPUT_FOLDER
7z a cairo.zip output/*
echo 'Success!'
