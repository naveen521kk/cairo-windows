USE_FREETYPE=1
cd cairo
sed 's/-MD/-MT/;s/zdll.lib/zlib.lib/' build/Makefile.win32.common > Makefile.win32.common.fixed
mv Makefile.win32.common.fixed build/Makefile.win32.common
sed '/^CAIRO_LIBS =/s/$/ $(top_builddir)\/..\/freetype\/freetype.lib/;/^DEFAULT_CFLAGS =/s/$/ -I$(top_srcdir)\/..\/freetype\/include/' build/Makefile.win32.common > Makefile.win32.common.fixed
mv Makefile.win32.common.fixed build/Makefile.win32.common
sed "s/CAIRO_HAS_FT_FONT=./CAIRO_HAS_FT_FONT=$USE_FREETYPE/" build/Makefile.win32.features > Makefile.win32.features.fixed
mv Makefile.win32.features.fixed build/Makefile.win32.features
# pass -B for switching between x86/x64
make -B -f Makefile.win32 cairo "CFG=release"
cd ..