program odbcman;

{$APPTYPE CONSOLE}

{$R *.res}

//
// odbcman_en.dpr
// 24-08-2023
//
// Author:
//       Hakan Emre Kartal <hek@nula.com.tr>
//
// Copyright (c) 2023 Hakan Emre Kartal
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

uses
  WinApi.Windows,
  System.Win.Registry,
  System.SysUtils,
  System.Classes;

{$REGION ' Constants '}
const
  ODBC_BASE_REGKEY              = '\SOFTWARE\ODBC';

  ODBC_INI_REGKEY               = ODBC_BASE_REGKEY    + '\ODBC.INI';
  ODBC_INI_DATA_SOURCES_REGKEY  = ODBC_INI_REGKEY     + '\ODBC Data Sources';

  ODBCINST_INI_REGKEY           = ODBC_BASE_REGKEY    + '\ODBCINST.INI';
  ODBCINST_DRIVERS_REGKEY       = ODBCINST_INI_REGKEY + '\ODBC Drivers';

  ODBC_CHARSET_ANSI             = 'ansi';
  ODBC_CHARSET_UNICODE          = 'unicode';

  MySQL_DEFAULT_DESCRIPTION     = '';
  MySQL_DEFAULT_PASSWORD        = '';

  // MySQL default port.
  MySQL_PORT                    = 3306;

  // MySQL default server remote address (127.0.0.1@localhost).
  MySQL_SERVER                  = 'localhost';

  CharacterSets : array[ Boolean ] of string = (ODBC_CHARSET_ANSI, ODBC_CHARSET_UNICODE);
{$ENDREGION}

{$REGION ' Method Declarations '}

(*
 * Checks whether MySQL installed.
 * If exist return 'True' else 'False'.
 *
 *)
function QueryMySQL         ( inIsUnicode : Boolean = False ) : Boolean;
                              forward;

(*
 * Retrieves MySQL driver parameters.
 * If exist return 'True' else 'False'.
 *
 *)
function GetMySQLArgs       ( var outDriver, outDriverName : string;
                              inIsUnicode : Boolean = False ) : Boolean;
                              forward;

(*
 *
 * Add a new ODBC connection for MySQL.
 * If exist return 'True' else 'False'.
 *
 *)
function ODBCLinkForMySQL   ( inLinkName, inDriver,
                              inDriverName, inUserName : string;
                              inPassword : string = MySQL_DEFAULT_PASSWORD;
                              inDescription : string = MySQL_DEFAULT_DESCRIPTION ) : Boolean;
                              forward;

(*
 * Deletes an existing MySQL ODBC connection.
 * If exist return 'True' else 'False'.
 *
 *)
function ODBCUnlinkForMySQL ( inLinkName : string ) : Boolean; forward;

{$ENDREGION}

{$REGION ' Metods İşlev '}

function QueryMySQL( inIsUnicode : Boolean ) : Boolean;
var
  n : Integer;
  l_objValues : TStrings;
  l_strValue, l_strName : string;
begin
  with TRegistry.Create() do
  try
    RootKey := HKEY_LOCAL_MACHINE;

    Result := OpenKeyReadOnly( ODBCINST_DRIVERS_REGKEY );

    if (Result) then
    begin
      l_objValues := TStringList.Create();
      try
        GetValueNames( l_objValues );

        Result := (l_objValues.Count > 0);

        if (Result) then
          for n := 0 to (l_objValues.Count - 1) do
          begin
            l_strValue := l_objValues[ n ];
            l_strName := LowerCase( l_strValue );

            if ((l_strName.IndexOf( 'mysql' ) >= 0) and (l_strName.IndexOf( CharacterSets[ inIsUnicode ] ) >= 0)) then
            begin
              l_strValue := LowerCase( ReadString( l_strValue ) );
              Exit(l_strValue = 'installed');
            end;
          end;
      finally
        l_objValues.Destroy();
      end;
    end;
  finally
    Destroy();
  end;
end;

function GetMySQLArgs( var outDriver, outDriverName : string; inIsUnicode : Boolean ) : Boolean;
var
  l_objKeys : TStrings;
  l_strKey, l_strName : string;
  n : Integer;
begin
  with TRegistry.Create() do
  try
    RootKey := HKEY_LOCAL_MACHINE;

    Result := OpenKeyReadOnly( ODBCINST_INI_REGKEY );

    if (Result) then
    begin
      l_objKeys := TStringList.Create();
      try
        GetKeyNames( l_objKeys );

        Result := (l_objKeys.Count > 0);

        if (Result) then
          for n := 0 to (l_objKeys.Count - 1) do
          begin
            l_strKey := l_objKeys[ n ];
            l_strName := LowerCase( l_strKey );

            if ((l_strName.IndexOf( 'mysql' ) >= 0) and (l_strName.IndexOf( CharacterSets[ inIsUnicode ] ) >= 0)) then
            begin
              CloseKey();

              l_strName := IncludeTrailingPathDelimiter( ODBCINST_INI_REGKEY ) + l_strKey;

              if (OpenKeyReadOnly( l_strName )) then
                begin
                  outDriverName := l_strKey;
                  outDriver := ReadString( 'Driver' );

                  Exit(True);
                end
              else
                Exit(False);
            end;
          end;
      finally
        l_objKeys.Destroy();
      end;
    end;
  finally
    Destroy();
  end;
end;

function ODBCLinkForMySQL( inLinkName, inDriver, inDriverName, inUserName, inPassword, inDescription : string ) : Boolean;

  function LinkDataSource() : Boolean; // Installed?
  begin
    with TRegistry.Create() do
    try
      RootKey := HKEY_LOCAL_MACHINE;

      try
        if (KeyExists( ODBC_INI_DATA_SOURCES_REGKEY )) then
          Result := OpenKey( ODBC_INI_DATA_SOURCES_REGKEY, True )
        else
          Result := CreateKey( ODBC_INI_DATA_SOURCES_REGKEY );
      except
        Exit(False);
      end;

      if (Result) then
      begin
        try
          WriteString( inLinkName, inDriverName );
        except
          Result := False;
        end;
      end;
    finally
      Destroy();
    end;
  end;

var
  l_strKey : string;

begin
  try
    Result := LinkDataSource();
  except
    Exit(False);
  end;

  if (Result) then
    with TRegistry.Create() do
    try
      RootKey := HKEY_LOCAL_MACHINE;

      l_strKey := (IncludeTrailingPathDelimiter( ODBC_INI_REGKEY ) + inLinkName);

      Result := OpenKey( l_strKey, True );

      if (Result) then
      begin
        try
          WriteString( 'DESCRIPTION', inDescription );
          WriteString( 'Driver',      inDriver );
          WriteString( 'PORT',        MySQL_PORT.ToString() );
          WriteString( 'PWD',         inPassword );
          WriteString( 'UID',         inUserName );
          WriteString( 'SERVER',      MySQL_SERVER );
        except
          Exit(False);
        end;
      end;
    finally
      Destroy();
    end;
end;

function ODBCUnlinkForMySQL( inLinkName : string ) : Boolean;
begin
  with TRegistry.Create() do
  try
    RootKey := HKEY_LOCAL_MACHINE;

    Result := OpenKey( ODBC_INI_DATA_SOURCES_REGKEY, False );

    if (Result) then
    begin
      try
        DeleteValue( inLinkName );
      except
        Exit(False);
      end;

      CloseKey();
    end;

    try
      Result := DeleteKey( IncludeTrailingPathDelimiter( ODBC_INI_REGKEY ) + inLinkName );
    except
      Exit(False);
    end;
  finally
    Destroy();
  end;
end;

{$ENDREGION}

procedure Test;
const
  TestLinkName    = 'Test';
  TestUserName    = 'TestUser';
  TestPassword    = 'TestPwd';
  TestDescription = 'TestDescription';
const
  StatusStrings : array[ Boolean ] of string = ('None', 'Exists');
  ResultStrings : array[ Boolean ] of string = ('Unsuccessful', 'Successful');
var
  l_strDriver,
  l_strDriverName : string;
begin
  WriteLn( 'MySQL.ANSI:                                   ',
           StatusStrings[ QueryMySQL() ] );

  WriteLn( 'MySQL.Unicode:                                ',
           StatusStrings[ QueryMySQL( True ) ] );

  WriteLn;

  WriteLn( 'MySQL.ANSI.GetMySQLArgs:                      ',
           StatusStrings[ GetMySQLArgs( l_strDriver, l_strDriverName ) ] );

  WriteLn;

  WriteLn( #9'Driver:                               ', l_strDriver );
  WriteLn( #9'Driver Name:                          ', l_strDriverName );
  WriteLn( #9'Add MySQL.ANSI.ODBCLinkForMySQL:      ',
           ResultStrings[ ODBCLinkForMySQL( TestLinkName, l_strDriver,
                                            l_strDriverName, TestUserName,
                                            TestPassword, TestDescription ) ] );

  WriteLn( #9'Delete MySQL.ANSI.ODBCUnlinkForMySQL: ',
           ResultStrings[ ODBCUnlinkForMySQL( TestLinkName ) ] );

  WriteLn;

  WriteLn( 'MySQL.Unicode.GetMySQLArgs:                   ',
           StatusStrings[ GetMySQLArgs( l_strDriver, l_strDriverName, True ) ] );

  WriteLn;

  WriteLn( #9'Driver:                               ', l_strDriver );
  WriteLn( #9'Driver Name:                          ', l_strDriverName );
  WriteLn( #9'Add MySQL.ANSI.ODBCLinkForMySQL:      ',
           ResultStrings[ ODBCLinkForMySQL( TestLinkName, l_strDriver,
                                            l_strDriverName, TestUserName,
                                            TestPassword, TestDescription ) ] );
  WriteLn( #9'Delete MySQL.ANSI.ODBCUnlinkForMySQL: ',
           ResultStrings[ ODBCUnlinkForMySQL( TestLinkName ) ] );
end;

begin
  try
    Test;
  except
    on l_objException : Exception do
      Writeln( l_objException.ClassName(), ': ', l_objException.Message );
  end;

  ReadLn;
end.
