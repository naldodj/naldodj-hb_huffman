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

   local cCDP as character
   local cLogFile as character:=(".\log\huffmannode_tst.log")

   local nKoef as numeric
   local nStyle as numeric:=(HB_LOG_ST_DATE+HB_LOG_ST_ISODATE+HB_LOG_ST_TIME+HB_LOG_ST_LEVEL)
   local nSeverity as numeric:=HB_LOG_DEBUG
   local nFileCount as numeric:=5
   local nFileSize as numeric:=1

   #ifdef __ALT_D__    // Compile with -b -D__ALT_D__
     AltD(1)         // Enables the debugger. Press F5 to continue.
     AltD()          // Invokes the debugger
   #endif

   hb_DirCreate(".\log\")

   aLogs:=Directory(".\log\*.*")
   aEval(aLogs,{|e|hb_FileDelete(".\log\"+e[F_NAME])})

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
   aAdd(aFunTst,{@hbHuffmanTST_05(),"hbHuffmanTST_05",.T.})

   aColors:=getColors(Len(aFunTst))

   for i:=1 to Len(aFunTst)

      cText:=aFunTst[i][1]:Eval()
      cFunName:=aFunTst[i][2]

      SetColor(aColors[i])
      QOut("=== Test "+hb_NToC(i)+" ("+cFunName+"): ===",hb_eol())
      SetColor("") /* Reset color to default */

      hCompressed:=oHuffmanNode:HuffmanCompress(cText)
      cCompressed:=hb_JSONEncode(hCompressed)
      hb_MemoWrit(".\log\"+cFunName+"_HuffmanCompress.log",cCompressed)
      cDecompressed:=oHuffmanNode:HuffmanDecompress(hCompressed)
      hb_MemoWrit(".\log\"+cFunName+"_HuffmanDecompress.log",cDecompressed)

      *? "Original: ",cText
      LOG "Original: "+cText PRIORITY nSeverity
      *? "Compressed: ",cCompressed,hb_eol()
      *LOG "Compressed: "+cCompressed PRIORITY nSeverity
      *? "Decompressed: ",cDecompressed,hb_eol()
      *LOG "Decompressed: "+cDecompressed PRIORITY nSeverity
      ? "hb_bLen(cDecompressed): ",hb_bLen(cDecompressed)
      ? "hb_bLen(cText): ",hb_bLen(cText)

      lMatch:=(cDecompressed==cText)

      if (lMatch)
          SetColor("g+/n")
      else
          SetColor("r+/n")
      endif

      ? "Matching: ",lMatch,hb_eol(),hb_eol()
      LOG "Matching: "+if(lMatch,"TRUE","FALSE") PRIORITY nSeverity

      SetColor("")

      ? Replicate("=",80),hb_eol()
      LOG Replicate("=",80) PRIORITY nSeverity

      ? "CompressToBinary: "
      LOG "CompressToBinary: " PRIORITY nSeverity

      cCompressed:=oHuffmanNode:HuffmanCompressToBinary(cText)
      hb_MemoWrit(".\log\"+cFunName+"_HuffmanCompressToBinary.log",cCompressed)
      ? "Tamanho Original: ", hb_bLen(cText)
      LOG "Tamanho Original: "+hb_NToC(hb_bLen(cText)) PRIORITY nSeverity
      ? "Tamanho binario:", hb_bLen(cCompressed)
      LOG "Tamanho binario: "+hb_NToC(hb_bLen(cCompressed)) PRIORITY nSeverity
      ? "Taxa de compressao: ", hb_NToS((1-hb_bLen(cCompressed)/hb_bLen(cText))*100,5,1)+"%"
      LOG "Taxa de compressao: "+hb_NToS((1-hb_bLen(cCompressed)/hb_bLen(cText))*100,5,1)+"%" PRIORITY nSeverity
      *? "Compressed: ",hb_base64encode(cCompressed),hb_eol()
      *LOG "Compressed: "+cCompressed PRIORITY nSeverity

      cDecompressed:=oHuffmanNode:HuffmanDecompressFromBinary(cCompressed)
      hb_MemoWrit(".\log\"+cFunName+"_HuffmanDecompressFromBinary.log",cDecompressed)
      *? "Descomprimido: ", cDecompressed
      LOG "Descomprimido: "+cDecompressed PRIORITY nSeverity
      ? "hb_bLen(cDecompressed): ",hb_bLen(cDecompressed)
      ? "hb_bLen(cText): ",hb_bLen(cText)

      lMatch:=(cDecompressed==cText)

      if (lMatch)
          SetColor("g+/n")
      else
          SetColor("r+/n")
      endif

      ? "Matching: ",lMatch,hb_eol(),hb_eol()
      LOG "Matching: "+if(lMatch,"TRUE","FALSE") PRIORITY nSeverity

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

    if (hb_FileExists("./data/loremipsum.log"))
        cText:=hb_MemoRead("./data/loremipsum.log")
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

    if (hb_FileExists("./data/emoji-data.log"))
        cText:=hb_MemoRead("./data/emoji-data.log")
    else
        cText:=ProcName()
    endif

    return(cText)
