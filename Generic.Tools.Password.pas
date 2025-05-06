//
//	Generic.Tools.Password 
//
//	Description:
//			Strong password generator: numeric, alphabetic, symbolic or mixed.		
//	
// Author:
//			Kartal, Hakan Emre <hek@nula.com.tr>
//
//	Creation:
//			2018.09.07
//	
//	Copyright (c) 2018-2025 by Kartal, Hakan Emre 
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
unit Generic.Tools.Password;

interface

uses
  System.Math,
  System.SysUtils;

const
  MINIMUM_PASSWORD_LENGTH = (5);
  MAXIMUM_NUMERIC_PASSWORD_LENGTH = (16);
  MAXIMUM_PASSWORD_LENGTH = (32);

type
  TPasswordType = set of (PasswordTypeNumeric, PasswordTypeAlphaNumeric, PasswordTypeSymbolic);
  TPasswordAlphabet = string;
  TPasswordLength = MINIMUM_PASSWORD_LENGTH..MAXIMUM_PASSWORD_LENGTH;

function Generate( const inPasswordType : TPasswordType; const inRequiredLength : TPasswordLength ) : string;

implementation

const
  NumericPasswordAlphabet : TPasswordAlphabet = ('0123456789');
  AlphanumericPasswordAlphabet : TPasswordAlphabet = ('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz');
  SymbolicPasswordAlphabet : TPasswordAlphabet = ('<>_-+%/\()=$#[]{}*?@.:!');

function Generate( const inPasswordType : TPasswordType; const inRequiredLength : TPasswordLength ) : string;

  function GenerateNumericCharacter() : Char;
  begin
    Result := NumericPasswordAlphabet[ 1 + Random( Length( NumericPasswordAlphabet ) ) ];
  end;

  function GenerateAlphanumericCharacter() : Char;
  begin
    Result := AlphanumericPasswordAlphabet[ 1 + Random( Length( AlphanumericPasswordAlphabet ) ) ];
  end;

  function GenerateSymbolicCharacter() : Char;
  begin
    Result := SymbolicPasswordAlphabet[ 1 + Random( Length( SymbolicPasswordAlphabet ) ) ];
  end;

var
  l_cbCh : Char;
  l_bSuccess : Boolean;
  l_iRequiredLength : Integer;

  procedure _GenerateNumericPasswordChar();
  begin
    if ((l_iRequiredLength > Length(Result)) and (PasswordTypeNumeric in inPasswordType)) then
    begin
      repeat
        l_cbCh := GenerateNumericCharacter();

        if (l_iRequiredLength > Length(NumericPasswordAlphabet)) then
          if (Result.IsEmpty()) then
            l_bSuccess := (Ord(l_cbCh) <> Ord('0'))
          else
            l_bSuccess := (Result.IsEmpty() or (Result[ Length(Result) ] <> l_cbCh))
        else if (Result.IsEmpty()) then
          l_bSuccess := (Ord(l_cbCh) <> Ord('0'))
        else
          l_bSuccess := (Result.IndexOf( l_cbCh ) = -1);

      until (l_bSuccess);

      Result := Result + l_cbCh;
    end;
  end;

  procedure _GenerateAlphaNumericPasswordChar();
  begin
    if ((l_iRequiredLength > Length(Result)) and (PasswordTypeAlphaNumeric in inPasswordType)) then
    begin
      repeat
        l_cbCh := GenerateAlphanumericCharacter();

        if (l_iRequiredLength > Length(NumericPasswordAlphabet)) then
          l_bSuccess := (Result.IsEmpty() or (Result[ Length(Result) ] <> l_cbCh))
        else
          l_bSuccess := (Result.IndexOf( l_cbCh ) = -1);

      until (l_bSuccess);

      Result := Result + l_cbCh;
    end;
  end;

  procedure _GenerateSymbolicPasswordChar();
  begin
    if ((l_iRequiredLength > Length(Result)) and (PasswordTypeSymbolic in inPasswordType)) then
    begin
      repeat
        l_cbCh := GenerateSymbolicCharacter();

        if (l_iRequiredLength > Length(NumericPasswordAlphabet)) then
          l_bSuccess := (Result.IsEmpty() or (Result[ Length(Result) ] <> l_cbCh))
        else
          l_bSuccess := (Result.IndexOf( l_cbCh ) = -1);

      until (l_bSuccess);

      Result := Result + l_cbCh;
    end;
  end;

begin
  Result := '';

  if (Byte(inPasswordType) > 0) then
  begin
//    Randomize();

    if ([PasswordTypeNumeric] = inPasswordType) then
      l_iRequiredLength := Min( inRequiredLength, MAXIMUM_NUMERIC_PASSWORD_LENGTH )
    else
      l_iRequiredLength := inRequiredLength;

    while (l_iRequiredLength > Length(Result)) do
      case (Random( 3 )) of
        (0): _GenerateNumericPasswordChar();
        (1): _GenerateAlphaNumericPasswordChar();
        (2): _GenerateSymbolicPasswordChar();
      end;
  end;
end;

// 25-06-2018-11-30 - HEK
initialization
  Randomize();


end.
