/*
 _              __   __                                             _
| |__   _   _  / _| / _| _ __ ___    __ _  _ __   _ __    ___    __| |  ___
| '_ \ | | | || |_ | |_ | '_ ` _ \  / _` || '_ \ | '_ \  / _ \  / _` | / _ \
| | | || |_| ||  _||  _|| | | | | || (_| || | | || | | || (_) || (_| ||  __/
|_| |_| \__,_||_|  |_|  |_| |_| |_| \__,_||_| |_||_| |_| \___/  \__,_| \___|

 hb HuffmanNode

 Released to Public Domain.
 --------------------------------------------------------------------------------------

*/

#include "hbclass.ch"

REQUEST HB_CODEPAGE_UTF8EX

class HuffmanNode

   data cChar as character

   data hHuffmanMap as hash

   data nFreq as numeric

   data oLeft as object
   data oRight as object
   data oHuffmanTree as object

   method isLeaf() as logical
   method BuildHuffmanMap(oNode as object,cCode as character)
   method BuildHuffmanTree(cText as character,hFreq as hash) as object
   method RebuildHuffmanTree(hMap as hash) as object
   method PackBitsToIntegers(cBits as character,nBitLen as numeric) as array
   method UnpackBitsFromIntegers(aPacked as array) as character
   method New(cChar as character,nFreq as numeric,oLeft as object,oRight as object) CONSTRUCTOR
   method HuffmanCompress(cText as character) as hash
   method HuffmanDecompress(hCompressed as hash) as character

  /* Novos metodos para compressao binaria */
   method HuffmanCompressToBinary(cText as character) as character
   method HuffmanDecompressFromBinary(cBinary as character) as character

end class

method New(cChar as character,nFreq as numeric,oLeft as object,oRight as object) class HuffmanNode
   hb_default(@cChar,"")
   hb_default(@nFreq,0)
   self:hHuffmanMap:={=>}
   self:cChar:=cChar
   self:nFreq:=nFreq
   self:oLeft:=oLeft
   self:oRight:=oRight
   return(self) as object

method isLeaf() class HuffmanNode
   return(((self:oLeft==nil).and.(self:oRight==nil))) as logical

method BuildHuffmanTree(cText as character,hFreq as hash) class HuffmanNode

   local aNodes as array:={}

   local cChar as character
   local cRemainingText as character

   local nNodes as numeric

   local oNode as object
   local oLeft as object
   local oRight as object

   self:oHuffmanTree:=HuffmanNode():New("",0,nil,nil)
   self:hHuffmanMap:={=>}

   if (!HB_ISHash(hFreq).or.Empty(hFreq))
      hFreq:={=>}
      cRemainingText:=cText
      while (hb_BLen(cRemainingText)>0)
         cChar:=hb_BLeft(cRemainingText,1)
         hFreq[cChar]:=StrOccurs(cChar,@cRemainingText)
      end while
   endif

   // Criar nos iniciais a partir de hFreq
   for each cChar in hb_HKeys(hFreq)
      aAdd(aNodes,HuffmanNode():New(cChar,hFreq[cChar],nil,nil))
   next each

   nNodes:=Len(aNodes)
   if (nNodes==0)
      return(nil)
   elseif (nNodes==1)
      return(aNodes[1]) as object
   endif

   while (nNodes>1)
      aNodes:=aSort(aNodes,{|x,y|(x:nFreq<y:nFreq)})
      oLeft:=aNodes[1]
      hb_aDel(aNodes,1,.T.)
      nNodes--
      oRight:=aNodes[1]
      hb_aDel(aNodes,1,.T.)
      nNodes--
      oNode:=HuffmanNode():New(nil,oLeft:nFreq+oRight:nFreq,oLeft,oRight)
      aAdd(aNodes,oNode)
      nNodes++
   end while

   return(aNodes[1]) as object

method procedure BuildHuffmanMap(oNode as object,cCode as character) class HuffmanNode

   local aStack as array:={{oNode,cCode}}

   local cCurrentCode as character

   local nStack as numeric:=1

   local oCurrent as object

   while (nStack>0)
      oCurrent:=aStack[nStack][1]
      cCurrentCode:=aStack[nStack][2]
      hb_aDel(aStack,nStack,.T.)
      nStack--
      if (oCurrent:isLeaf())
         self:hHuffmanMap[oCurrent:cChar]:=cCurrentCode
      else
         if (oCurrent:oRight!=nil)
            aAdd(aStack,{oCurrent:oRight,cCurrentCode+"1"})
            nStack++
         endif
         if (oCurrent:oLeft!=nil)
            aAdd(aStack,{oCurrent:oLeft,cCurrentCode+"0"})
            nStack++
         endif
      endif
   end while

   return

method HuffmanCompress(cText as character) class HuffmanNode

   local aPacked as array

   local cChar as character
   local cEncoded as character:=""
   local cRemainingText as character:=cText

   local hFreq as hash:={=>}

   local i as numeric
   local nBitLen as numeric

   self:oHuffmanTree:=self:BuildHuffmanTree(cText)  // Calcula hFreq internamente
   if (self:oHuffmanTree==nil)
      return({=>}) as hash
   endif

   // Copiar hFreq do processo de BuildHuffmanTree
   while (hb_BLen(cRemainingText) > 0)
      cChar:=hb_BLeft(cRemainingText,1)
      hFreq[cChar]:=StrOccurs(cChar,@cRemainingText)
   end while

   self:BuildHuffmanMap(self:oHuffmanTree,"")
   for i:=1 to hb_BLen(cText)
      cEncoded+=self:hHuffmanMap[hb_BSubStr(cText,i,1)]
   next i

   nBitLen:=hb_BLen(cEncoded)
   aPacked:=self:PackBitsToIntegers(cEncoded,nBitLen)

   return({"freq" => hFreq,"data" => aPacked}) as hash

method RebuildHuffmanTree(hMap as hash) class HuffmanNode

   local cBit as character
   local cChar as character
   local cCode as character

   local i as numeric

   local oRoot as object:=HuffmanNode():New(nil,0,nil,nil)
   local oNode as object

   for each cChar in hb_HKeys(hMap)
      cCode:=hMap[cChar]
      oNode:=oRoot
      for i:=1 to hb_BLen(cCode)
         cBit:=hb_BSubStr(cCode,i,1)
         if (cBit=="0")
            if (oNode:oLeft==nil)
               oNode:oLeft:=HuffmanNode():New(nil,0,nil,nil)
            endif
            oNode:=oNode:oLeft
         else
            if (oNode:oRight==nil)
               oNode:oRight:=HuffmanNode():New(nil,0,nil,nil)
            endif
            oNode:=oNode:oRight
         endif
      next i
      oNode:cChar:=cChar
   next each

   return(oRoot) as object

method HuffmanDecompress(hCompressed as hash) class HuffmanNode

   local cBit as character
   local cEncoded as character
   local cDecoded as character:=""

   local hFreq as hash

   local i as numeric

   local nBitLen as numeric

   local oNode as object
   local oRoot as object

   begin sequence

      if (!((hb_hHasKey(hCompressed,"freq")).and.(hb_hHasKey(hCompressed,"data"))))
         break
      endif

      hFreq:=hCompressed["freq"]
      if ((!hb_IsHash(hFreq)).or.(Len(hCompressed["data"])<1))
         break
      endif

      cEncoded:=self:UnpackBitsFromIntegers(hCompressed["data"])
      self:oHuffmanTree:=self:BuildHuffmanTree(nil,@hFreq)  // Usa hFreq diretamente
      self:hHuffmanMap:={=>}
      self:BuildHuffmanMap(self:oHuffmanTree,"")

      oRoot:=self:oHuffmanTree
      if (oRoot==nil)
         break
      endif

      nBitLen:=hCompressed["data"][1]
      oNode:=oRoot

      for i:=1 to nBitLen
         cBit:=hb_BSubStr(cEncoded,i,1)
         oNode:=if(cBit=="0",oNode:oLeft,oNode:oRight)
         if (oNode==nil)
            exit
         endif
         if (oNode:isLeaf())
            cDecoded+=oNode:cChar
            oNode:=oRoot
         endif
      next i
   end sequence

   return(cDecoded) as character

method PackBitsToIntegers(cBits as character,nBitLen as numeric) class HuffmanNode
   // Chama funcao em C
   return(PackBitsToIntegers(cBits,nBitLen)) as array

method UnpackBitsFromIntegers(aPacked as array) class HuffmanNode

   local cBits as character:=""

   local i as numeric
   local j as numeric

   local nBuffer as numeric

   for i:=2 to Len(aPacked)
      nBuffer:=aPacked[i]
      for j:=63 to 0 step -1
         cBits+=if(hb_bitTest(nBuffer,j),"1","0")
      next j
   next i

   return(cBits) as character

/* Metodos novos para compressao binaria */
method HuffmanCompressToBinary(cText as character) class HuffmanNode

   local aBinary as array:=Array(0)
   local cChunk as character
   local nPos as numeric:=1
   local nLen as numeric:=hb_BLen(cText)
   local nChunkSize as numeric:=32768  // 32KB por pacote para melhor compressao

   if (Empty(cText))
      return("")
   endif

   // Dividir o texto em chunks otimizados
   while (nPos <= nLen)
      if (nPos + nChunkSize - 1 > nLen)
         nChunkSize := nLen - nPos + 1
      endif

      cChunk := hb_BSubStr(cText, nPos, nChunkSize)
      cChunk := HB_HUFFMAN_PACK(cChunk)

      if (!Empty(cChunk))
         aAdd(aBinary, cChunk)
      endif

      nPos += nChunkSize
   end while

   return(hb_Serialize(aBinary))

method HuffmanDecompressFromBinary(cBinary as character) class HuffmanNode

   local aBinary as array
   local cChunk as character
   local cText as character:=""

   if (Empty(cBinary))
      return(cText)
   endif

   aBinary:=hb_DeSerialize(cBinary)
   FOR EACH cChunk IN aBinary
      cText += HB_HUFFMAN_UNPACK(cChunk)
   NEXT

   return(cText)

#pragma BEGINDUMP

   #include "hbapi.h"
   #include "hbapiitm.h"
   #include "hbapierr.h"
   #include <string.h>
   #include <stdlib.h>
   #include <limits.h>

   /* Para strcpy_s no Windows, strncpy no Linux */
   #ifdef _WIN32
     #define STRCPY_SAFE(dest, src) strcpy_s(dest, sizeof(dest), src)
   #else
     #define STRCPY_SAFE(dest, src) strncpy(dest, src, sizeof(dest)-1); dest[sizeof(dest)-1] = '\0'
   #endif

   HB_FUNC_STATIC(STROCCURS)
   {
      PHB_ITEM pText1 = hb_param(1, HB_IT_STRING);
      PHB_ITEM pText2 = hb_param(2, HB_IT_STRING);

      if( pText1 && pText2 && HB_ISBYREF(2) )
      {
         const char *s1 = hb_itemGetCPtr(pText1);
         const char *s2 = hb_itemGetCPtr(pText2);
         HB_SIZE len = hb_itemGetCLen(pText2);
         HB_SIZE count = 0;
         HB_SIZE newLen = 0;

         /* Alocar buffer temporario */
         char *tempBuffer = (char*) hb_xgrab(len + 1);
         if( !tempBuffer )
         {
            hb_errRT_BASE_SubstR(EG_MEM, 3012, NULL, "STROCCURS", HB_ERR_ARGS_BASEPARAMS);
            return;
         }

         /* Processar string */
         for( HB_SIZE i = 0; i < len; i++ )
         {
            if( s1[0] == s2[i] )
               count++;
            else
               tempBuffer[newLen++] = s2[i];
         }

         /* Atualizar string de referencia */
         if( newLen > 0 )
         {
            hb_storclen(tempBuffer, newLen, 2);
         }
         else
         {
            hb_storc("", 2);
         }

         hb_xfree(tempBuffer);
         hb_retns(count);
      }
      else
      {
         hb_errRT_BASE_SubstR(EG_ARG, 3012, NULL, "STROCCURS", HB_ERR_ARGS_BASEPARAMS);
      }
   }

   HB_FUNC_STATIC(PACKBITSTOINTEGERS)
   {
      PHB_ITEM pBits = hb_param(1, HB_IT_STRING);
      PHB_ITEM pBitLen = hb_param(2, HB_IT_NUMERIC);

      if( pBits && pBitLen )
      {
         const char *cBits = hb_itemGetCPtr(pBits);
         long nBitLen = hb_itemGetNL(pBitLen);
         HB_ISIZ i, bufferLen = 0;
         HB_MAXUINT buffer = 0;
         HB_ISIZ arraySize = (nBitLen + 63) / 64 + 1;

         /* Verificar se o tamanho da string corresponde ao nBitLen */
         HB_ISIZ actualLen = hb_itemGetCLen(pBits);
         if( (HB_ISIZ) nBitLen > actualLen )
         {
            hb_errRT_BASE_SubstR(EG_BOUND, 3012, NULL, "PACKBITSTOINTEGERS", HB_ERR_ARGS_BASEPARAMS);
            return;
         }

         PHB_ITEM aOut = hb_itemArrayNew(arraySize);
         if( !aOut )
         {
            hb_errRT_BASE_SubstR(EG_MEM, 3012, NULL, "PACKBITSTOINTEGERS", HB_ERR_ARGS_BASEPARAMS);
            return;
         }

         hb_arraySetNL(aOut, 1, nBitLen);

         for( i = 0; i < nBitLen; i++ )
         {
            buffer = (buffer << 1) | (cBits[i] == '1' ? 1 : 0);
            if( ++bufferLen >= 64 )
            {
               hb_arraySetNInt(aOut, (i / 64) + 2, buffer);
               buffer = 0;
               bufferLen = 0;
            }
         }

         if( bufferLen > 0 )
         {
            hb_arraySetNInt(aOut, (nBitLen / 64) + 2, buffer << (64 - bufferLen));
         }

         hb_itemReturnRelease(aOut);
      }
      else
      {
         hb_errRT_BASE_SubstR(EG_ARG, 3012, NULL, "PACKBITSTOINTEGERS", HB_ERR_ARGS_BASEPARAMS);
      }
   }

   /* =================================================== */
   /* C HUFFMAN                                           */
   /* =================================================== */

   /* LIMITES OTIMIZADOS PARA PERFORMANCE E ESTABILIDADE */
   #define MAX_TREE_SIZE       65536      /* 64KB para arvore */
   #define MAX_INPUT_SIZE      65536      /* 64KB entrada maxima */
   #define MAX_COMPRESSED_SIZE 131072     /* 128KB comprimido maximo */
   #define MAX_OUTPUT_SIZE     65536      /* 64KB saida maxima */

   /* Tabela de codigos Huffman */
   typedef struct {
       char code[256];
       int len;
   } HUFFMAN_CODE;

   /* Estrutura do no Huffman */
   typedef struct _huffman_node {
       unsigned char ch;
       int freq;
       struct _huffman_node *left;
       struct _huffman_node *right;
   } HUFFMAN_NODE;

   /* Estrutura para compactacao de bits */
   typedef struct {
       unsigned char* data;
       int bit_pos;
       int byte_pos;
       int capacity;
   } BIT_WRITER;

   typedef struct {
       const unsigned char* data;
       int bit_pos;
       int byte_pos;
       int max_bytes;
   } BIT_READER;

   /* Inicializa bit writer */
   static BIT_WRITER* bit_writer_init(int capacity) {
       BIT_WRITER* bw = (BIT_WRITER*)hb_xgrab(sizeof(BIT_WRITER));
       if( !bw ) return NULL;

       /* Capacidade otimizada */
       if( capacity < 1024 ) capacity = 1024;
       if( capacity > MAX_COMPRESSED_SIZE ) capacity = MAX_COMPRESSED_SIZE;

       bw->data = (unsigned char*)hb_xgrab(capacity);
       if( !bw->data ) {
           hb_xfree(bw);
           return NULL;
       }

       bw->bit_pos = 0;
       bw->byte_pos = 0;
       bw->capacity = capacity;

       hb_xmemset(bw->data, 0, capacity);
       return bw;
   }

   /* Libera bit writer */
   static void bit_writer_free(BIT_WRITER* bw) {
       if(bw) {
           if(bw->data) hb_xfree(bw->data);
           hb_xfree(bw);
       }
   }

   /* Escreve um bit */
   static void bit_writer_write(BIT_WRITER* bw, int bit) {
       if(bw->byte_pos >= bw->capacity) {
           /* Expande buffer */
           int new_capacity = bw->capacity * 2;
           if( new_capacity > MAX_COMPRESSED_SIZE ) {
               new_capacity = MAX_COMPRESSED_SIZE;
           }

           if( new_capacity <= bw->capacity ) {
               return;
           }

           unsigned char* new_data = (unsigned char*)hb_xgrab(new_capacity);
           if( !new_data ) return;

           hb_xmemcpy(new_data, bw->data, bw->capacity);
           hb_xmemset(new_data + bw->capacity, 0, new_capacity - bw->capacity);

           hb_xfree(bw->data);
           bw->data = new_data;
           bw->capacity = new_capacity;
       }

       if(bit) {
           bw->data[bw->byte_pos] |= (1 << (7 - bw->bit_pos));
       }

       bw->bit_pos++;
       if(bw->bit_pos == 8) {
           bw->bit_pos = 0;
           bw->byte_pos++;
       }
   }

   /* Escreve multiplos bits */
   static void bit_writer_write_bits(BIT_WRITER* bw, const char* bits, int len) {
       int i;
       for(i = 0; i < len; i++) {
           bit_writer_write(bw, bits[i] == '1' ? 1 : 0);
       }
   }

   /* Finaliza escrita */
   static void bit_writer_finish(BIT_WRITER* bw) {
       if(bw->bit_pos > 0) {
           bw->byte_pos++;
       }
   }

   /* Inicializa bit reader */
   static BIT_READER* bit_reader_init(const unsigned char* data, int max_bytes) {
       BIT_READER* br = (BIT_READER*)hb_xgrab(sizeof(BIT_READER));
       br->data = data;
       br->bit_pos = 0;
       br->byte_pos = 0;
       br->max_bytes = max_bytes;
       return br;
   }

   /* Libera bit reader */
   static void bit_reader_free(BIT_READER* br) {
       hb_xfree(br);
   }

   /* Le um bit */
   static int bit_reader_read(BIT_READER* br) {
       if(br->byte_pos >= br->max_bytes) {
           return -1;
       }

       int bit = (br->data[br->byte_pos] >> (7 - br->bit_pos)) & 1;

       br->bit_pos++;
       if(br->bit_pos == 8) {
           br->bit_pos = 0;
           br->byte_pos++;
       }

       return bit;
   }

   /* Funcao para liberar a arvore */
   static void free_tree(HUFFMAN_NODE* root) {
       if(root == NULL) return;

       HUFFMAN_NODE** stack = (HUFFMAN_NODE**)hb_xgrab(MAX_TREE_SIZE * sizeof(HUFFMAN_NODE*));
       int top = 0;

       stack[top++] = root;

       while(top > 0) {
           HUFFMAN_NODE* node = stack[--top];

           if(node->left != NULL) stack[top++] = node->left;
           if(node->right != NULL) stack[top++] = node->right;

           hb_xfree(node);
       }

       hb_xfree(stack);
   }

   /* Conta frequencias */
   static void count_freq(const unsigned char* data, HB_SIZE len, int* freq) {
       HB_SIZE i;
       for(i = 0; i < 256; i++) freq[i] = 0;
       for(i = 0; i < len; i++) freq[data[i]]++;
   }

   /* Funcao auxiliar: cria no */
   static HUFFMAN_NODE* create_node(unsigned char ch, int freq) {
       HUFFMAN_NODE* node = (HUFFMAN_NODE*)hb_xgrab(sizeof(HUFFMAN_NODE));
       if(node != NULL) {
           node->ch = ch;
           node->freq = freq;
           node->left = node->right = NULL;
       }
       return node;
   }

   /* Constroi arvore Huffman otimizada */
   static HUFFMAN_NODE* build_tree(int* freq) {
       HUFFMAN_NODE* nodes[256];
       HUFFMAN_NODE* left, *right, *parent;
       int i, j, n = 0;

       for(i = 0; i < 256; i++) {
           if(freq[i] > 0) {
               nodes[n++] = create_node((unsigned char)i, freq[i]);
               if( n >= 256 ) break;
           }
       }

       if(n == 0) return NULL;
       if(n == 1) return nodes[0];

       while(n > 1) {
           /* Ordenacao otimizada */
           for(i = 0; i < n-1; i++) {
               for(j = i+1; j < n; j++) {
                   if(nodes[i]->freq > nodes[j]->freq) {
                       HUFFMAN_NODE* temp = nodes[i];
                       nodes[i] = nodes[j];
                       nodes[j] = temp;
                   }
               }
           }

           left = nodes[0];
           right = nodes[1];
           parent = create_node(0, left->freq + right->freq);
           parent->left = left;
           parent->right = right;

           nodes[0] = parent;
           for(i = 1; i < n-1; i++) {
               nodes[i] = nodes[i+1];
           }
           n--;
       }

       return nodes[0];
   }

   /* Gera codigos Huffman */
   static void generate_codes(HUFFMAN_NODE* node, HUFFMAN_CODE* codes, char* buffer, int depth) {
       if(node == NULL) return;

       if(depth >= 255) return;

       if(node->left == NULL && node->right == NULL) {
           buffer[depth] = '\0';
           STRCPY_SAFE(codes[node->ch].code, buffer);
           codes[node->ch].len = depth;
       } else {
           if(node->left != NULL) {
               buffer[depth] = '0';
               generate_codes(node->left, codes, buffer, depth + 1);
           }
           if(node->right != NULL) {
               buffer[depth] = '1';
               generate_codes(node->right, codes, buffer, depth + 1);
           }
       }
   }

   /* Serializa arvore */
   static int serialize_tree(HUFFMAN_NODE* node, unsigned char* buf, int pos) {
       if(node == NULL) return pos;

       if(node->left == NULL && node->right == NULL) {
           buf[pos++] = 1;
           buf[pos++] = node->ch;
       } else {
           buf[pos++] = 0;
           pos = serialize_tree(node->left, buf, pos);
           pos = serialize_tree(node->right, buf, pos);
       }

       return pos;
   }

   /* Calcula tamanho da arvore serializada */
   static int tree_size(HUFFMAN_NODE* node) {
       if(node == NULL) return 0;
       if(node->left == NULL && node->right == NULL) return 2;
       return 1 + tree_size(node->left) + tree_size(node->right);
   }

   /* Deserializa arvore */
   static HUFFMAN_NODE* deserialize_tree(const unsigned char* buf, int* pos, int max_pos) {
       if(*pos >= max_pos) return NULL;

       if(buf[*pos] == 1) {
           (*pos)++;
           if(*pos >= max_pos) return NULL;
           HUFFMAN_NODE* node = create_node(buf[*pos], 0);
           (*pos)++;
           return node;
       } else if(buf[*pos] == 0) {
           (*pos)++;
           HUFFMAN_NODE* node = create_node(0, 0);
           node->left = deserialize_tree(buf, pos, max_pos);
           node->right = deserialize_tree(buf, pos, max_pos);
           return node;
       }

       return NULL;
   }

   /* Funcao principal de compressao */
   HB_FUNC_STATIC( HB_HUFFMAN_PACK )
   {
      PHB_ITEM pInput = hb_param(1, HB_IT_STRING);

      if( !pInput )
      {
         hb_retc("");
         return;
      }

      const unsigned char* input = (unsigned char*) hb_itemGetCPtr(pInput);
      HB_SIZE input_len = hb_itemGetCLen(pInput);

      if( input_len == 0 )
      {
         hb_retc("");
         return;
      }

      /* Limite de entrada */
      if( input_len > MAX_INPUT_SIZE )
      {
         hb_retc("");
         return;
      }

      int i;
      int freq[256];

      /* 1. Contar frequencias */
      count_freq(input, input_len, freq);

      /* Verificar dados para comprimir */
      int unique_chars = 0;
      for( i = 0; i < 256; i++ )
      {
         if( freq[i] > 0 ) unique_chars++;
      }

      if( unique_chars == 0 )
      {
         hb_retc("");
         return;
      }

      /* 2. Construir arvore */
      HUFFMAN_NODE* root = build_tree(freq);
      if( root == NULL )
      {
         hb_retc("");
         return;
      }

      /* 3. Gerar codigos */
      HUFFMAN_CODE codes[256];
      char gen_buffer[256];
      for( i = 0; i < 256; i++ )
      {
         codes[i].len = 0;
         codes[i].code[0] = '\0';
      }

      generate_codes(root, codes, gen_buffer, 0);

      /* 4. Serializar arvore */
      int tree_len = tree_size(root);
      if( tree_len <= 0 || tree_len > MAX_TREE_SIZE )
      {
         free_tree(root);
         hb_retc("");
         return;
      }

      unsigned char* tree_buf = (unsigned char*) hb_xgrab(tree_len);
      if( !tree_buf )
      {
         free_tree(root);
         hb_retc("");
         return;
      }

      int tree_pos = 0;
      tree_pos = serialize_tree(root, tree_buf, 0);

      /* 5. Codificar dados */
      BIT_WRITER* bw = bit_writer_init((int) input_len + 256);
      if( !bw )
      {
         hb_xfree(tree_buf);
         free_tree(root);
         hb_retc("");
         return;
      }

      for( i = 0; i < (int) input_len; i++ )
      {
         unsigned char ch = input[i];
         if( codes[ch].len > 0 && codes[ch].len < 256 )
         {
            bit_writer_write_bits(bw, codes[ch].code, codes[ch].len);
         }
      }
      bit_writer_finish(bw);

      /* 6. Preparar buffer final */
      int total_len = 8 + tree_len + bw->byte_pos;

      if( total_len <= 8 || total_len > MAX_COMPRESSED_SIZE )
      {
         hb_xfree(tree_buf);
         bit_writer_free(bw);
         free_tree(root);
         hb_retc("");
         return;
      }

      unsigned char* output = (unsigned char*) hb_xgrab(total_len);
      if( !output )
      {
         hb_xfree(tree_buf);
         bit_writer_free(bw);
         free_tree(root);
         hb_retc("");
         return;
      }

      /* Header */
      output[0] = (tree_len >> 8) & 0xFF;
      output[1] = tree_len & 0xFF;
      output[2] = (input_len >> 24) & 0xFF;
      output[3] = (input_len >> 16) & 0xFF;
      output[4] = (input_len >> 8) & 0xFF;
      output[5] = input_len & 0xFF;
      output[6] = (bw->byte_pos >> 8) & 0xFF;
      output[7] = bw->byte_pos & 0xFF;

      hb_xmemcpy(output + 8, tree_buf, tree_len);
      hb_xmemcpy(output + 8 + tree_len, bw->data, bw->byte_pos);

      hb_retclen((char*) output, total_len);

      /* Limpeza */
      hb_xfree(tree_buf);
      bit_writer_free(bw);
      hb_xfree(output);
      free_tree(root);
   }

   /* Funcao principal de descompressao */
   HB_FUNC_STATIC( HB_HUFFMAN_UNPACK )
   {
      PHB_ITEM pInput = hb_param(1, HB_IT_STRING);

      if( !pInput )
      {
         hb_retc("");
         return;
      }

      const unsigned char* input = (unsigned char*) hb_itemGetCPtr(pInput);
      HB_SIZE input_len = hb_itemGetCLen(pInput);

      if( input_len == 0 || input_len < 8 )
      {
         hb_retc("");
         return;
      }

      /* Extrair header */
      int tree_len = (input[0] << 8) | input[1];
      HB_SIZE orig_len = ((HB_SIZE)input[2] << 24) |
                        ((HB_SIZE)input[3] << 16) |
                        ((HB_SIZE)input[4] << 8) |
                        input[5];
      int data_len = (input[6] << 8) | input[7];

      /* Verificacoes */
      if( tree_len <= 0 || tree_len > MAX_TREE_SIZE )
      {
         hb_retc("");
         return;
      }

      if( data_len < 0 || data_len > MAX_COMPRESSED_SIZE )
      {
         hb_retc("");
         return;
      }

      HB_SIZE required_len = 8 + (HB_SIZE)tree_len + (HB_SIZE)data_len;
      if( required_len > input_len || required_len < 8 )
      {
         hb_retc("");
         return;
      }

      if( orig_len == 0 || orig_len > MAX_OUTPUT_SIZE )
      {
         hb_retc("");
         return;
      }

      /* 1. Deserializar arvore */
      int tree_pos = 8;
      int max_tree_pos = 8 + tree_len;

      HUFFMAN_NODE* root = deserialize_tree(input, &tree_pos, max_tree_pos);
      if( root == NULL )
      {
         hb_retc("");
         return;
      }

      /* 2. Preparar bit reader */
      const unsigned char* compressed_data = input + 8 + tree_len;

      BIT_READER* br = bit_reader_init(compressed_data, data_len);
      if( !br )
      {
         free_tree(root);
         hb_retc("");
         return;
      }

      /* 3. Decodificar dados */
      unsigned char* output = (unsigned char*) hb_xgrab(orig_len + 1);
      if( output == NULL )
      {
         bit_reader_free(br);
         free_tree(root);
         hb_retc("");
         return;
      }

      HB_SIZE out_pos = 0;

      if(root != NULL && root->left == NULL && root->right == NULL) {
          /* Caso especial: apenas um simbolo unico */
          for(HB_SIZE i = 0; i < orig_len; i++) {
              output[i] = root->ch;
          }
          out_pos = orig_len;
      } else {
          HUFFMAN_NODE* current = root;
          int bit;

          while(out_pos < orig_len) {
              bit = bit_reader_read(br);
              if(bit < 0) {
                  break;
              }

              if(bit == 0) {
                  current = current->left;
              } else {
                  current = current->right;
              }

              if(current == NULL) {
                  break;
              }

              if(current->left == NULL && current->right == NULL) {
                  output[out_pos++] = current->ch;
                  current = root;
              }
          }
      }

      output[out_pos] = '\0';

      if(out_pos == orig_len) {
          hb_retclen((char*) output, orig_len);
      } else if(out_pos > 0) {
          hb_retclen((char*) output, out_pos);
      } else {
          hb_retc("");
      }

      hb_xfree(output);
      bit_reader_free(br);
      free_tree(root);
   }

#pragma ENDDUMP
