/*
 _              __   __
| |__   _   _  / _| / _| _ __ ___    __ _  _ __    ___   ___   _ __ ___   _ __   _ __   ___  ___  ___
| '_ \ | | | || |_ | |_ | '_ ` _ \  / _` || '_ \  / __| / _ \ | '_ ` _ \ | '_ \ | '__| / _ \/ __|/ __|
| | | || |_| ||  _||  _|| | | | | || (_| || | | || (__ | (_) || | | | | || |_) || |   |  __/\__ \\__ \
|_| |_| \__,_||_|  |_|  |_| |_| |_| \__,_||_| |_| \___| \___/ |_| |_| |_|| .__/ |_|    \___||___/|___/
                                                                        |_|
 Released to Public Domain.
 --------------------------------------------------------------------------------------

  hb_syslog.prg: Released to Public Domain.
  --------------------------------------------------------------------------------------
  ref.: ./github/harbour-core/contrib/xhb/hblog.ch
        ./github/harbour-core/contrib/xhb/hblog.prg
        ./github/harbour-core/contrib/xhb/hblognet.prg

*/

#include "hbver.ch"
#include "hblog.ch"
#include "hbinkey.ch"
#include "hbcompat.ch"
#include "directry.ch"

REQUEST HB_CODEPAGE_UTF8EX

// Example usage
procedure Main(...)

    local aArgs as array:=hb_AParams()
    local aLogs as array

    local cParam as character
    local cAction as character
    local cAppName as character
    local cArgName as character
    local cFileSource as character
    local cFileTarget as character
    local cFileContent as character

    local cPS as character:=hb_ps()
    local cCDP as character
    local cLogDir as character:=("."+cPS+"log"+cPS)
    local cLogFile as character

    local hCompressed as hash

    local lBinary as logical:=.T.
    local lBase64 as logical:=.T.

    local idx as numeric
    local nKoef as numeric
    local nStyle as numeric:=(HB_LOG_ST_DATE+HB_LOG_ST_ISODATE+HB_LOG_ST_TIME+HB_LOG_ST_LEVEL)
    local nSeverity as numeric:=HB_LOG_DEBUG
    local nFileCount as numeric:=5
    local nFileSize as numeric:=1

    local oErr as object
    local oHuffmanNode as object

    #ifdef __ALT_D__ // Compile with -b -D__ALT_D__
        AltD(1)        // Enables the debugger. Press F5 to continue.
        AltD()         // Invokes the debugger
    #endif

    hb_FNameSplit(hb_ProgName(),NIL,@cAppName)
    cLogFile:=(cLogDir+cAppName+".log")

    hb_DirCreate(cLogDir)

    aLogs:=Directory(cLogDir+"*.*")
    aEval(aLogs,{|e|hb_FileDelete(cLogDir+e[F_NAME])})

    cCDP:=hb_cdpSelect("UTF8EX")

    CLS

    nKoef:=(1024^4)
    nFileSize:=(nFileSize*nKoef)

    INIT LOG ON FILE (nSeverity,cLogFile,nFileSize,nFileCount)
    SET LOG STYLE (nStyle)

    BEGIN SEQUENCE WITH __BreakBlock()

    if (;
         (Empty(aArgs));
         .or.;
         (;
            Lower(aArgs[1])=="-h";
            .or.;
            Lower(aArgs[1])=="--help";
         );
      )
         ShowHelp(nil,aArgs,cAppName)
         break
    endif

      for each cParam in aArgs
         if (!Empty(cParam))
            if ((idx:=At("=",cParam))==0)
               cArgName:=Lower(cParam)
               cParam:=""
            else
               cArgName:=Left(cParam,idx-1)
               cParam:=SubStr(cParam,idx+1)
            endif
            switch cArgName
               case "-binary-"
                  lBinary:=.F.
                  exit
               case "-base64-"
                  lBase64:=.F.
                  exit
               case "-a"
               case "--action"
                  cAction:=Lower(Left(cParam,1))
                  exit
               case "-s"
               case "--source"
                  cFileSource:=cParam
                  exit
               case "-t"
               case "--target"
                  cFileTarget:=cParam
                  exit
               otherwise
                  ShowHelp("Unrecognized option:"+cArgName+iif(Len(cParam)>0,"="+cParam,""),cAppName)
                  break
            end switch
         endif
      next each

      if (Empty(cFileSource).or.(!hb_FileExists(cFileSource)))
         Throw(ErrorNew(cAppName,1001,"Main()","Source file not specified or not found.",{}))
         break
      endif

      if (Empty(cFileTarget))
         Throw(ErrorNew(cAppName,1001,"Main()","Target file not specified.",{}))
         break
      endif

      LOG "Date/Time: "+ hb_TToC(hb_DateTime(),"YYYY-MM-DD","HH:MM") PRIORITY nSeverity
      LOG "Action: "+if(cAction=="c","Compress","Decompress") PRIORITY nSeverity
      LOG "Source: "+cFileSource PRIORITY nSeverity
      LOG "Target: "+cFileTarget PRIORITY nSeverity
      LOG "Binary mode: "+if(lBinary,"true","false") PRIORITY nSeverity
      LOG "Base64 mode: "+if(lBase64,"true","false") PRIORITY nSeverity

      cFileContent:=hb_MemoRead(cFileSource)
      LOG "Source Size (bytes): "+hb_NToC(nFileSize:=hb_bLen(cFileContent)) PRIORITY nSeverity
      oHuffmanNode:=HuffmanNode():New()
      if (cAction=="c")
          if (lBase64)
              cFileContent:=hb_base64Encode(cFileContent,.F.)
          endif
          if (lBinary)
              cFileContent:=oHuffmanNode:HuffmanCompressToBinary(cFileContent)
          else
              hCompressed:=oHuffmanNode:HuffmanCompress(cFileContent)
              cFileContent:=hb_JSONEncode(hCompressed)
          endif
          LOG "Compressed Size (bytes): "+hb_NToC(hb_BLen(cFileContent)) PRIORITY nSeverity

          LOG "Compression Ratio: "+hb_NToC((1-(hb_BLen(cFileContent)/nFileSize))*100)+"%" PRIORITY nSeverity
      elseif (cAction$"du")
          if (lBinary)
              cFileContent:=oHuffmanNode:HuffmanDecompressFromBinary(cFileContent)
          else
              hCompressed:=hb_JSONDecode(cFileContent)
              cFileContent:=oHuffmanNode:HuffmanDecompress(hCompressed)
          endif
          if (lBase64)
              cFileContent:=hb_base64Decode(cFileContent,.F.)
          endif
          LOG "FileTarget Size: "+hb_NToC(hb_bLen(cFileContent)) PRIORITY nSeverity
      endif
      LOG "Result: "+if(hb_MemoWrit(cFileTarget,cFileContent),"true","false") PRIORITY nSeverity

    RECOVER USING oErr

        if (ValType(oErr)=="O")
            LOG oErr:Description PRIORITY HB_LOG_ERROR
        endif

    END SEQUENCE

    CLOSE LOG

    hb_cdpSelect(cCDP)

    return

static procedure ShowSubHelp(xLine as anytype,/*@*/nMode as numeric,nIndent as numeric,n as numeric)

   DO CASE
      CASE xLine == NIL
      CASE HB_ISNUMERIC( xLine )
         nMode := xLine
      CASE HB_ISEVALITEM( xLine )
         Eval( xLine )
      CASE HB_ISARRAY( xLine )
         IF nMode == 2
            OutStd( Space( nIndent ) + Space( 2 ) )
         ENDIF
         AEval( xLine, {| x, n | ShowSubHelp( x, @nMode, nIndent + 2, n ) } )
         IF nMode == 2
            OutStd( hb_eol() )
         ENDIF
      OTHERWISE
         DO CASE
            CASE nMode == 1 ; OutStd( Space( nIndent ) + xLine + hb_eol() )
            CASE nMode == 2 ; OutStd( iif( n > 1, ", ", "" ) + xLine )
            OTHERWISE       ; OutStd( "(" + hb_ntos( nMode ) + ") " + xLine + hb_eol() )
         ENDCASE
   ENDCASE

   RETURN

static function HBRawVersion()
   return(;
       hb_StrFormat( "%d.%d.%d%s (%s) (%s)";
      ,hb_Version(HB_VERSION_MAJOR);
      ,hb_Version(HB_VERSION_MINOR);
      ,hb_Version(HB_VERSION_RELEASE);
      ,hb_Version(HB_VERSION_STATUS);
      ,hb_Version(HB_VERSION_ID);
      ,"20"+Transform(hb_Version(HB_VERSION_REVISION),"99-99-99 99:99"));
   ) as character

static procedure ShowHelp(cExtraMessage as character,aArgs as array,cAppName as character)

   local aHelp as array
   local nMode as numeric:=1

   if (Empty(aArgs).or.(Len(aArgs)<=1).or.(Empty(aArgs[1])))
      aHelp:={;
          cExtraMessage;
         ,"";
         ,cAppName+" "+HBRawVersion();
         ,"";
         ,"Copyright (c) 2026-"+hb_NToS(Year(Date()))+", "+hb_Version(HB_VERSION_URL_BASE);
         ,"";
         ,"Syntax:";
         ,"";
         ,{cAppName+" [options]"};
         ,"";
         ,"Options:";
         ,{;
             "-h or --help Show this help";
            ,"-a, --action <c=compress|d=decompress>";
            ,"-s, --source <file> Source file.";
            ,"-t, --target <file> Target file.";
            ,"-binary- Disable binary compression.";
            ,"-base64- Disable Base64 encoding.";
         };
         ,"";
      }
   else
      ShowHelp("Unrecognized help option",nil,cAppName)
      return
   endif

   /* using hbmk2 style */
   aEval(aHelp,{|x|ShowSubHelp(x,@nMode,0)})

   return
