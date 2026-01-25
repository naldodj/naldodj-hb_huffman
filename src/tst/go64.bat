@setlocal
    del *.log*
    call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64
    F:\harbour_msvc\bin\win\msvc64\hbmk2 huffmannode_tst.hbp -comp=msvc64
    if EXIST .\huffmannode_tst.exe (
        cmd /c upx.exe .\huffmannode_tst.exe
        certutil -hashfile .\huffmannode_tst.exe SHA256 > huffmannode_tst.sh256
    )
@endlocal
