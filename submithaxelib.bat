@echo off
del asynctools.zip >nul 2>&1

cd src
copy ..\README.md .
zip -r ..\asynctools.zip .
del README.md
cd ..

haxelib submit asynctools.zip
del asynctools.zip
