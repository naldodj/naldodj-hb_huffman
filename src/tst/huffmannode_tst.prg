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

REQUEST HB_CODEPAGE_UTF8EX

// Example usage
procedure Main()

   local cCDP as character
   local cLogFile as character:=("huffmannode_tst.log")

   local nKoef as numeric
   local nStyle as numeric:=(HB_LOG_ST_DATE+HB_LOG_ST_ISODATE+HB_LOG_ST_TIME+HB_LOG_ST_LEVEL)
   local nSeverity as numeric:=HB_LOG_DEBUG
   local nFileCount as numeric:=5
   local nFileSize as numeric:=1
   local nFileSizeType as numeric:=2

   #ifdef __ALT_D__    // Compile with -b -D__ALT_D__
     AltD(1)         // Enables the debugger. Press F5 to continue.
     AltD()          // Invokes the debugger
   #endif

   cCDP:=hb_cdpSelect("UTF8EX")

   CLS

   nKoef:=if((nFileSizeType==1),1,if((nFileSizeType==2),1024,(1024^2)))
   nFileSize:=(nFileSize*nKoef)

   INIT LOG ON FILE (nSeverity,cLogFile,nFileSize,nFileCount)
   SET LOG STYLE (nStyle)

   hbHuffmanTST(nSeverity)

   CLOSE LOG

   hb_cdpSelect(cCDP)

   return

static procedure hbHuffmanTST(nSeverity as numeric)

   local aColors as array
   local aFunTst as array

   local cText as character
   local cFunName as character
   local cCompressed as character
   local cDecompressed as character

   local hCompressed as hash

   local lMatch as logical

   local oHuffmanNode as object:=HuffmanNode():New()

   local i as numeric

   aFunTst:=Array(0)
   aAdd(aFunTst,{@hbHuffmanTST_01(),"hbHuffmanTST_01",.T.})
   aAdd(aFunTst,{@hbHuffmanTST_02(),"hbHuffmanTST_02",.T.})
   aAdd(aFunTst,{@hbHuffmanTST_03(),"hbHuffmanTST_03",.T.})
   aAdd(aFunTst,{@hbHuffmanTST_04(),"hbHuffmanTST_04",.T.})

   aColors:=getColors(Len(aFunTst))

   for i:=1 to Len(aFunTst)

      cText:=aFunTst[i][1]:Eval()
      cFunName:=aFunTst[i][2]

      SetColor(aColors[i])
      QOut("=== Test "+hb_NToC(i)+" ("+cFunName+"): ===",hb_eol())
      SetColor("") /* Reset color to default */

      hCompressed:=oHuffmanNode:HuffmanCompress(cText)
      cCompressed:=hb_JSONEncode(hCompressed)
      cDecompressed:=oHuffmanNode:HuffmanDecompress(hCompressed)

      ? "Original: ",cText
      LOG "Original: "+cText PRIORITY nSeverity
      ? "Compressed: ",cCompressed,hb_eol()
      LOG "Compressed: "+cCompressed PRIORITY nSeverity
      ? "Decompressed: ",cDecompressed,hb_eol()
      LOG "Decompressed: "+cDecompressed PRIORITY nSeverity

      lMatch:=(cDecompressed==cText)

      if (lMatch)
          SetColor("g+/n")
      else
          SetColor("r+/n")
      endif

      ? "Matching: ",(cDecompressed==cText),hb_eol(),hb_eol()
      LOG "Matching: "+if((cDecompressed==cText),"TRUE","FALSE") PRIORITY nSeverity

      SetColor("")

      ? Replicate("=",80),hb_eol()
      LOG Replicate("=",80) PRIORITY nSeverity

      ? "CompressToBinary: "
      LOG "CompressToBinary: " PRIORITY nSeverity

      cCompressed:=oHuffmanNode:CompressToBinary(cText)
      ? "Tamanho Original: ", Len(cText)
      LOG "Tamanho Original: "+hb_NToC(Len(cText)) PRIORITY nSeverity
      ? "Tamanho binario:", Len(cCompressed)
      LOG "Tamanho binario: "+hb_NToC(Len(cCompressed)) PRIORITY nSeverity
      ? "Taxa de compressao: ", hb_NToS((1-Len(cCompressed)/Len(cText))*100,5,1)+"%"
      LOG "Taxa de compressao: "+hb_NToS((1-Len(cCompressed)/Len(cText))*100,5,1)+"%" PRIORITY nSeverity
      ? "Compressed: ",hb_base64encode(cCompressed),hb_eol()
      LOG "Compressed: "+cCompressed PRIORITY nSeverity

      cDecompressed:=oHuffmanNode:DecompressFromBinary(cCompressed)
      ? "Descomprimido: ", cDecompressed
      LOG "Descomprimido: "+cDecompressed PRIORITY nSeverity

      lMatch:=(cDecompressed==cText)

      if (lMatch)
          SetColor("g+/n")
      else
          SetColor("r+/n")
      endif

      ? "Matching: ",(cDecompressed==cText),hb_eol(),hb_eol()
      LOG "Matching: "+if((cDecompressed==cText),"TRUE","FALSE") PRIORITY nSeverity

      SetColor("")

      ? Replicate("=",80),hb_eol()
      LOG Replicate("=",80) PRIORITY nSeverity

   next i

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
