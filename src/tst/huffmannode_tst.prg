/*
 _              __   __                                             _         _         _
| |__   _   _  / _| / _| _ __ ___    __ _  _ __   _ __    ___    __| |  ___  | |_  ___ | |_
| '_ \ | | | || |_ | |_ | '_ ` _ \  / _` || '_ \ | '_ \  / _ \  / _` | / _ \ | __|/ __|| __|
| | | || |_| ||  _||  _|| | | | | || (_| || | | || | | || (_) || (_| ||  __/ | |_ \__ \| |_
|_| |_| \__,_||_|  |_|  |_| |_| |_| \__,_||_| |_||_| |_| \___/  \__,_| \___| \__| |___/\__|

 Example usage with valid and invalid test cases.

 Released to Public Domain.
 --------------------------------------------------------------------------------------

  hb_syslog.prg: Released to Public Domain.
  --------------------------------------------------------------------------------------
  ref.: ./github/harbour-core/contrib/xhb/hblog.ch
        ./github/harbour-core/contrib/xhb/hblog.prg
        ./github/harbour-core/contrib/xhb/hblognet.prg


*/

#include "hblog.ch"
#include "hbinkey.ch"
#include "hbcompat.ch"
#include "directry.ch"

REQUEST HB_CODEPAGE_UTF8EX

// Example usage
procedure Main()

   local aLogs as array

   local cPS as character:=hb_ps()
   local cCDP as character
   local cLogDir as character:=("."+cPS+"log"+cPS)
   local cLogFile as character:=(cLogDir+"huffmannode_tst.log")

   local nKoef as numeric
   local nStyle as numeric:=(HB_LOG_ST_DATE+HB_LOG_ST_ISODATE+HB_LOG_ST_TIME+HB_LOG_ST_LEVEL)
   local nSeverity as numeric:=HB_LOG_DEBUG
   local nFileCount as numeric:=5
   local nFileSize as numeric:=1

   #ifdef __ALT_D__ // Compile with -b -D__ALT_D__
     AltD(1)        // Enables the debugger. Press F5 to continue.
     AltD()         // Invokes the debugger
   #endif

   hb_DirCreate(cLogDir)

   aLogs:=Directory(cLogDir+"*.*")
   aEval(aLogs,{|e|hb_FileDelete(cLogDir+e[F_NAME])})

   cCDP:=hb_cdpSelect("UTF8EX")

   CLS

   nKoef:=(1024^4)
   nFileSize:=(nFileSize*nKoef)

   INIT LOG ON FILE (nSeverity,cLogFile,nFileSize,nFileCount)
   SET LOG STYLE (nStyle)

   hbHuffmanTST(nSeverity)

   CLOSE LOG

   hb_cdpSelect(cCDP)

   return

static procedure hbHuffmanTST(nSeverity as numeric)

   local aFunc as array
   local aColors as array
   local aFunTst as array

   local cPS as character:=hb_ps()
   local cEOL as character:=hb_eol()
   local cText as character
   local cLogFile as character
   local cFunName as character
   local cCompressed as character
   local cDecompressed as character
   local cTextCompressed as character

   local hCompressed as hash

   local lMatch as logical

   local i as numeric

   local nLenText as numeric
   local nLenCompressed as numeric
   local nLenTextCompressed as numeric
   local nLenDecompressed as numeric

   local oHuffmanNode as object:=HuffmanNode():New()

   aFunTst:=Array(0)
   aAdd(aFunTst,{@hbHuffmanTST_01(),"hbHuffmanTST_01",.T.})
   aAdd(aFunTst,{@hbHuffmanTST_02(),"hbHuffmanTST_02",.T.})
   aAdd(aFunTst,{@hbHuffmanTST_03(),"hbHuffmanTST_03",.T.})
   aAdd(aFunTst,{@hbHuffmanTST_04(),"hbHuffmanTST_04",.T.})
   aAdd(aFunTst,{@hbHuffmanTST_05(),"hbHuffmanTST_05",.T.})

   aColors:=getColors(Len(aFunTst))

   for each aFunc in aFunTst

      i:=aFunc:__enumIndex()

      cText:=aFunc[1]:Eval()
      nLenText:=hb_bLen(cText)
      cFunName:=aFunc[2]

      SetColor(aColors[i])
      QOut("=== Test "+hb_NToC(i)+" ("+cFunName+"): ===",cEOL)
      SetColor("") /* Reset color to default */

      /*========================================================================*/

      hCompressed:=oHuffmanNode:HuffmanCompress(cText)
      cCompressed:=hb_JSONEncode(hCompressed)
      nLenCompressed:=hb_bLen(cCompressed)
      cLogFile:="."+cPS+"log"+cPS+cFunName+"_HuffmanCompress.log"
      hb_MemoWrit(cLogFile,cCompressed)
      cDecompressed:=oHuffmanNode:HuffmanDecompress(hCompressed)
      nLenDecompressed:=hb_bLen(cDecompressed)
      cLogFile:="."+cPS+"log"+cPS+cFunName+"_HuffmanDecompress.log"
      hb_MemoWrit(cLogFile,cDecompressed)

      *? "Original: ",cText
      LOG "Original: "+cText PRIORITY nSeverity
      *? "Compressed: ",cCompressed,cEOL
      LOG "Compressed: "+cCompressed PRIORITY nSeverity
      *? "Decompressed: ",cDecompressed,cEOL
      LOG "Decompressed: "+cDecompressed PRIORITY nSeverity

      ? "hb_bLen(cText): ",nLenText
      LOG "hb_bLen(cText): "+hb_NToC(nLenText) PRIORITY nSeverity
      ? "hb_bLen(cCompressed): ",nLenCompressed
      LOG "hb_bLen(cText): "+hb_NToC(nLenCompressed) PRIORITY nSeverity
      ? "hb_bLen(cDecompressed): ",nLenDecompressed
      LOG "hb_bLen(cDecompressed): "+hb_NToC(nLenDecompressed) PRIORITY nSeverity

      lMatch:=(cDecompressed==cText)

      if (lMatch)
          SetColor("g+/n")
      else
          SetColor("r+/n")
      endif

      ? "Matching: ",lMatch,cEOL,cEOL
      LOG "Matching: "+if(lMatch,"TRUE","FALSE") PRIORITY nSeverity

      SetColor("")

      ? Replicate("=",80),cEOL
      LOG Replicate("=",80) PRIORITY nSeverity

      /*========================================================================*/

      ? "Compress From HuffmanCompress: ("+cFunName+")"
      LOG "Compress From HuffmanCompress: ("+cFunName+")" PRIORITY nSeverity

      cTextCompressed:=cCompressed
      nLenTextCompressed:=hb_bLen(cTextCompressed)
      cCompressed:=oHuffmanNode:HuffmanCompressToBinary(cTextCompressed)
      nLenCompressed:=hb_bLen(cCompressed)
      cLogFile:="."+cPS+"log"+cPS+cFunName+"_HuffmanCompressToBinaryFromHuffmanCompress.log"
      hb_MemoWrit(cLogFile,cCompressed)
      ? "Tamanho Original: ", nLenTextCompressed
      LOG "Tamanho Original: "+hb_NToC(nLenTextCompressed) PRIORITY nSeverity
      ? "Tamanho binario:", nLenCompressed
      LOG "Tamanho binario: "+hb_NToC(nLenCompressed) PRIORITY nSeverity
      ? "Taxa de compressao: ", hb_NToS((1-nLenCompressed/nLenTextCompressed)*100,5,1)+"%"
      LOG "Taxa de compressao: "+hb_NToS((1-nLenCompressed/nLenTextCompressed)*100,5,1)+"%" PRIORITY nSeverity
      *? "Compressed: ",hb_base64encode(cCompressed),cEOL
      *LOG "Compressed: "+cCompressed PRIORITY nSeverity

      cDecompressed:=oHuffmanNode:HuffmanDecompressFromBinary(cCompressed)
      nLenDecompressed:=hb_BLen(cDecompressed)
      cLogFile:="."+cPS+"log"+cPS+cFunName+"_HuffmanDecompressFromBinaryFromHuffmanCompress.log"
      hb_MemoWrit(cLogFile,cDecompressed)
      *? "Descomprimido: ", cDecompressed
      LOG "Descomprimido: "+cDecompressed PRIORITY nSeverity
      ? "hb_bLen(cDecompressed): ",nLenDecompressed

      lMatch:=(cDecompressed==cTextCompressed)

      if (lMatch)
          SetColor("g+/n")
      else
          SetColor("r+/n")
      endif

      ? "Matching: ",lMatch,cEOL,cEOL
      LOG "Matching: "+if(lMatch,"TRUE","FALSE") PRIORITY nSeverity

      /*========================================================================*/

      hCompressed:=hb_JSONDecode(cDecompressed)
      cDecompressed:=oHuffmanNode:HuffmanDecompress(hCompressed)
      nLenDecompressed:=hb_bLen(cDecompressed)
      cLogFile:="."+cPS+"log"+cPS+cFunName+"_HuffmanDecompressHuffmanDecompressFromBinaryFromHuffmanCompress.log"
      hb_MemoWrit(cLogFile,cDecompressed)

      *? "Descomprimido: ", cDecompressed
      LOG "Descomprimido: "+cDecompressed PRIORITY nSeverity
      ? "hb_bLen(cDecompressed): ",nLenDecompressed

      lMatch:=((lMatch).and.(cDecompressed==cText))

      if (lMatch)
          SetColor("g+/n")
      else
          SetColor("r+/n")
      endif

      ? "Matching: ",lMatch,cEOL,cEOL
      LOG "Matching: "+if(lMatch,"TRUE","FALSE") PRIORITY nSeverity

      /*========================================================================*/

      SetColor("")

      ? "CompressToBinary: ("+cFunName+")"
      LOG "CompressToBinary: ("+cFunName+")" PRIORITY nSeverity

      cCompressed:=oHuffmanNode:HuffmanCompressToBinary(cText)
      nLenCompressed:=hb_bLen(cCompressed)
      cLogFile:="."+cPS+"log"+cPS+cFunName+"_HuffmanCompressToBinary.log"
      hb_MemoWrit(cLogFile,cCompressed)
      ? "Tamanho Original: ", nLenText
      LOG "Tamanho Original: "+hb_NToC(nLenText) PRIORITY nSeverity
      ? "Tamanho binario:", nLenCompressed
      LOG "Tamanho binario: "+hb_NToC(nLenCompressed) PRIORITY nSeverity
      ? "Taxa de compressao: ", hb_NToS((1-nLenCompressed/nLenText)*100,5,1)+"%"
      LOG "Taxa de compressao: "+hb_NToS((1-nLenCompressed/nLenText)*100,5,1)+"%" PRIORITY nSeverity
      *? "Compressed: ",hb_base64encode(cCompressed),cEOL
      *LOG "Compressed: "+cCompressed PRIORITY nSeverity

      cDecompressed:=oHuffmanNode:HuffmanDecompressFromBinary(cCompressed)
      nLenDecompressed:=hb_BLen(cDecompressed)
      cLogFile:="."+cPS+"log"+cPS+cFunName+"_HuffmanDecompressFromBinary.log"
      hb_MemoWrit(cLogFile,cDecompressed)
      *? "Descomprimido: ", cDecompressed
      LOG "Descomprimido: "+cDecompressed PRIORITY nSeverity
      ? "hb_bLen(cDecompressed): ",nLenDecompressed

      lMatch:=(cDecompressed==cText)

      if (lMatch)
          SetColor("g+/n")
      else
          SetColor("r+/n")
      endif

      ? "Matching: ",lMatch,cEOL,cEOL
      LOG "Matching: "+if(lMatch,"TRUE","FALSE") PRIORITY nSeverity

      SetColor("")

      ? Replicate("=",80),cEOL
      LOG Replicate("=",80) PRIORITY nSeverity

   next //each

   return

static function getColors(nTests as numeric)

    local aColors as array:=Array(nTests)
    local aColorBase as array:={"N","B","G","BG","R","RB","GR","W"}

    local i as numeric

    for i:=1 to nTests
        aColors[i]:="W+/"+aColorBase[(i-1)%8+1]
    next i

    return(aColors)

static function hbHuffmanTST_01()

    local cText as character

    #pragma __cstream|cText:=%s
Marinaldo de Jesus
    #pragma __endtext

    return(cText)

    static function hbHuffmanTST_02()

    local cText as character

    #pragma __cstream|cText:=%s
THIS TEXT VERY,VERY,VERY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY LARGE WILL PASS THROUGH THE HUFFMAN FILTER!
    #pragma __endtext

    return(cText)

    static function hbHuffmanTST_03()

    local cText as character

    if (hb_FileExists("./data/loremipsum.txt"))
        cText:=hb_MemoRead("./data/loremipsum.txt")
    else
        cText:=ProcName()
    endif

    return(cText)

    static function hbHuffmanTST_04()

    local cText as character

    if (hb_FileExists("./huffmannode.prg"))
        cText:=hb_MemoRead("./huffmannode.prg")
    else
        cText:=ProcName()
    endif

    return(cText)

    static function hbHuffmanTST_05()

    local cText as character

    if (hb_FileExists("./data/emoji-data.txt"))
        cText:=hb_MemoRead("./data/emoji-data.txt")
    else
        cText:=ProcName()
    endif

    return(cText)
