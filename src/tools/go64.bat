@setlocal
    del .\log\*.* /S /Q
    call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64
    F:\harbour_msvc\bin\win\msvc64\hbmk2 huffmancompress.hbp -comp=msvc64
    if EXIST .\huffmancompress.exe (
        cmd /c upx.exe .\huffmancompress.exe
        certutil -hashfile .\huffmancompress.exe SHA256 2>&1 | findstr /V "CertUtil" > huffmancompress.sha256
    )
@endlocal
