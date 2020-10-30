name: CI

on:
  push:

jobs:
  build:
    runs-on: windows-2016
    steps:
      - uses: actions/checkout@v2
      - name: Install Wget
        run: |
          choco install wget
      - name: Execute Script
        shell: bash
        continue-on-error: true
        run: |
          ./build-cairo-windows.sh
      - uses: actions/upload-artifact@v2
        with:
          name: cairo.makefile
          path: cairo/src/Makefile.win32
      - uses: actions/upload-artifact@v2
        with:
          name: cairo.makefile.edited
          path: cairo/build/Makefile.win32.common
      - uses: actions/upload-artifact@v2
        with:
          name: cairo.x86
          path: output
