{*********************************************************}
{                                                         }
{                 Zeos Database Objects                   }
{         Interbase Database Connectivity Classes         }
{                                                         }
{        Originally written by Sergey Merkuriev           }
{                                                         }
{*********************************************************}

{@********************************************************}
{    Copyright (c) 1999-2012 Zeos Development Group       }
{                                                         }
{ License Agreement:                                      }
{                                                         }
{ This library is distributed in the hope that it will be }
{ useful, but WITHOUT ANY WARRANTY; without even the      }
{ implied warranty of MERCHANTABILITY or FITNESS FOR      }
{ A PARTICULAR PURPOSE.  See the GNU Lesser General       }
{ Public License for more details.                        }
{                                                         }
{ The source code of the ZEOS Libraries and packages are  }
{ distributed under the Library GNU General Public        }
{ License (see the file COPYING / COPYING.ZEOS)           }
{ with the following  modification:                       }
{ As a special exception, the copyright holders of this   }
{ library give you permission to link this library with   }
{ independent modules to produce an executable,           }
{ regardless of the license terms of these independent    }
{ modules, and to copy and distribute the resulting       }
{ executable under terms of your choice, provided that    }
{ you also meet, for each linked independent module,      }
{ the terms and conditions of the license of that module. }
{ An independent module is a module which is not derived  }
{ from or based on this library. If you modify this       }
{ library, you may extend this exception to your version  }
{ of the library, but you are not obligated to do so.     }
{ If you do not wish to do so, delete this exception      }
{ statement from your version.                            }
{                                                         }
{                                                         }
{ The project web site is located on:                     }
{   http://zeos.firmos.at  (FORUM)                        }
{   http://sourceforge.net/p/zeoslib/tickets/ (BUGTRACKER)}
{   svn://svn.code.sf.net/p/zeoslib/code-0/trunk (SVN)    }
{                                                         }
{   http://www.sourceforge.net/projects/zeoslib.          }
{                                                         }
{                                                         }
{                                 Zeos Development Group. }
{********************************************************@}

unit ZDbcInterbase6Utils;

interface

{$I ZDbc.inc}

uses
  SysUtils, Classes, {$IFDEF MSEgui}mclasses,{$ENDIF} Types,
  ZDbcIntfs, ZDbcStatement, ZPlainFirebirdDriver, ZCompatibility,
  ZPlainFirebirdInterbaseConstants, ZDbcCachedResultSet, ZDbcLogging, ZMessages,
  ZVariant, ZTokenizer;

type
  { Interbase Statement Type }
  TZIbSqlStatementType = (stUnknown, stSelect, stInsert, stUpdate, stDelete,
    stDDL, stGetSegment, stPutSegment, stExecProc, stStartTrans, stCommit,
    stRollback, stSelectForUpdate, stSetGenerator, stDisconnect);

  { Interbase Error Class}
  EZIBConvertError = class(Exception);

  { Paparameter string name and it value}
  TZIbParam = record
    Name: AnsiString;
    Number: word;
  end;
  PZIbParam = ^TZIbParam;

  { Interbase blob Information structure
    contain iformation about blob size in bytes,
    segments count, segment size in bytes and blob type
    Note: blob type can be text an binary }
  TIbBlobInfo = record
    NumSegments: Word;
    MaxSegmentSize: Word;
    BlobType: SmallInt;
    TotalSize: LongInt;
  end;

  { Base interface for sqlda }
  IZSQLDA = interface
    ['{2D0D6029-B31C-4E39-89DC-D86D20437C35}']
    procedure InitFields(Parameters: boolean);
    procedure AllocateSQLDA;
    procedure FreeParamtersValues;

    function GetData: PXSQLDA;
    function IsBlob(const Index: Word): boolean;
    function IsNullable(const Index: Word): boolean;

    function GetFieldCount: Integer;
    function GetFieldSqlName(const Index: Word): String;
    function GetFieldRelationName(const Index: Word): String;
    function GetFieldOwnerName(const Index: Word): String;
    function GetFieldAliasName(const Index: Word): String;
    function GetFieldIndex(const Name: AnsiString): Word;
    function GetFieldScale(const Index: Word): integer;
    function GetFieldSqlType(const Index: Word): TZSQLType;
    function GetFieldLength(const Index: Word): SmallInt;
    function GetIbSqlType(const Index: Word): Smallint;
    function GetIbSqlSubType(const Index: Word): Smallint;
    function GetIbSqlLen(const Index: Word): Smallint;
  end;

  { parameters interface sqlda}
  IZParamsSQLDA = interface(IZSQLDA)
    ['{D2C3D5E1-F3A6-4223-9A6E-3048B99A06C4}']
    procedure WriteBlob(const Index: Integer; Stream: TStream);
    procedure UpdateNull(const Index: Integer; Value: boolean);
    procedure UpdateBoolean(const Index: Integer; Value: boolean);
    procedure UpdateByte(const Index: Integer; Value: ShortInt);
    procedure UpdateShort(const Index: Integer; Value: SmallInt);
    procedure UpdateInt(const Index: Integer; Value: Integer);
    procedure UpdateLong(const Index: Integer; Value: Int64);
    procedure UpdateFloat(const Index: Integer; Value: Single);
    procedure UpdateDouble(const Index: Integer; Value: Double);
    procedure UpdateBigDecimal(const Index: Integer; Value: Extended);
    procedure UpdatePChar(const Index: Integer; Value: PAnsiChar);
    procedure UpdateString(const Index: Integer; Value: RawByteString);
    procedure UpdateBytes(const Index: Integer; Value: TByteDynArray);
    procedure UpdateDate(const Index: Integer; Value: TDateTime);
    procedure UpdateTime(const Index: Integer; Value: TDateTime);
    procedure UpdateTimestamp(const Index: Integer; Value: TDateTime);
    procedure UpdateQuad(const Index: Word; const Value: TISC_QUAD);
  end;

  { Result interface for sqlda}
  IZResultSQLDA = interface(IZSQLDA)
    ['{D2C3D5E1-F3A6-4223-9A6E-3048B99A06C4}']
    procedure ReadBlobFromStream(const Index: Word; Stream: TStream);
    procedure ReadBlobFromString(const Index: Word; var str: AnsiString);
    procedure ReadBlobFromVariant(const Index: Word; var Value: Variant);

    function IsNull(const Index: Integer): Boolean;
    function GetPChar(const Index: Integer): PChar;
    function GetString(const Index: Integer): RawByteString;
    function GetBoolean(const Index: Integer): Boolean;
    function GetByte(const Index: Integer): Byte;
    function GetShort(const Index: Integer): SmallInt;
    function GetInt(const Index: Integer): Integer;
    function GetLong(const Index: Integer): Int64;
    function GetFloat(const Index: Integer): Single;
    function GetDouble(const Index: Integer): Double;
    function GetBigDecimal(const Index: Integer): Extended;
    function GetBytes(const Index: Integer): TByteDynArray;
    function GetDate(const Index: Integer): TDateTime;
    function GetTime(const Index: Integer): TDateTime;
    function GetTimestamp(const Index: Integer): TDateTime;
    function GetValue(const Index: Word): Variant;
    function GetQuad(const Index: Integer): TISC_QUAD;
  end;

  { Base class contain core functions to work with sqlda structure
    Can allocate memory for sqlda structure get basic information }
  TZSQLDA = class (TZCodePagedObject, IZSQLDA)
  private
    FHandle: PISC_DB_HANDLE;
    FTransactionHandle: PISC_TR_HANDLE;
    FXSQLDA: PXSQLDA;
    FPlainDriver: IZInterbasePlainDriver;
    Temp: AnsiString;
    procedure CheckRange(const Index: Word);
    procedure IbReAlloc(var P; OldSize, NewSize: Integer);
    procedure SetFieldType(const Index: Word; Size: Integer; Code: Smallint;
      Scale: Smallint);
  public
    constructor Create(PlainDriver: IZInterbasePlainDriver;
      Handle: PISC_DB_HANDLE; TransactionHandle: PISC_TR_HANDLE;
      ConSettings: PZConSettings); virtual;
    procedure InitFields(Parameters: boolean);
    procedure AllocateSQLDA; virtual;
    procedure FreeParamtersValues;

    function IsBlob(const Index: Word): boolean;
    function IsNullable(const Index: Word): boolean;

    function GetFieldCount: Integer;
    function GetFieldSqlName(const Index: Word): String;
    function GetFieldOwnerName(const Index: Word): String;
    function GetFieldRelationName(const Index: Word): String;
    function GetFieldAliasName(const Index: Word): String;
    function GetFieldIndex(const Name: AnsiString): Word;
    function GetFieldScale(const Index: Word): integer;
    function GetFieldSqlType(const Index: Word): TZSQLType;
    function GetFieldLength(const Index: Word): SmallInt;
    function GetData: PXSQLDA;

    function GetIbSqlType(const Index: Word): Smallint;
    function GetIbSqlSubType(const Index: Word): Smallint;
    function GetIbSqlLen(const Index: Word): Smallint;
  end;

  { Parameters class for sqlda structure.
    It clas can only write data to parameters/fields }
  TZParamsSQLDA = class (TZSQLDA, IZParamsSQLDA)
  private
    procedure EncodeString(Code: Smallint; const Index: Word; const Str: RawByteString);
    procedure EncodeBytes(Code: Smallint; const Index: Word; const Value: TByteDynArray);
    procedure UpdateDateTime(const Index: Integer; Value: TDateTime);
  public
    destructor Destroy; override;

    procedure WriteBlob(const Index: Integer; Stream: TStream);

    procedure UpdateNull(const Index: Integer; Value: boolean);
    procedure UpdateBoolean(const Index: Integer; Value: boolean);
    procedure UpdateByte(const Index: Integer; Value: ShortInt);
    procedure UpdateShort(const Index: Integer; Value: SmallInt);
    procedure UpdateInt(const Index: Integer; Value: Integer);
    procedure UpdateLong(const Index: Integer; Value: Int64);
    procedure UpdateFloat(const Index: Integer; Value: Single);
    procedure UpdateDouble(const Index: Integer; Value: Double);
    procedure UpdateBigDecimal(const Index: Integer; Value: Extended);
    procedure UpdatePChar(const Index: Integer; Value: PAnsiChar);
    procedure UpdateString(const Index: Integer; Value: RawByteString);
    procedure UpdateBytes(const Index: Integer; Value: TByteDynArray);
    procedure UpdateDate(const Index: Integer; Value: TDateTime);
    procedure UpdateTime(const Index: Integer; Value: TDateTime);
    procedure UpdateTimestamp(const Index: Integer; Value: TDateTime);
    procedure UpdateQuad(const Index: Word; const Value: TISC_QUAD);
  end;

  { Resultset class for sqlda structure.
    It class read data from sqlda fields }
  TZResultSQLDA = class (TZSQLDA, IZResultSQLDA)
  private
    function DecodeString(const Code: Smallint; const Index: Word): RawByteString;
    procedure DecodeString2(const Code: Smallint; const Index: Word; out Str: RawByteString);
  protected
    FDefaults: array of Variant;
  public
    destructor Destroy; override;

    procedure AllocateSQLDA; override;

    procedure ReadBlobFromStream(const Index: Word; Stream: TStream);
    procedure ReadBlobFromString(const Index: Word; var str: AnsiString);
    procedure ReadBlobFromVariant(const Index: Word; var Value: Variant);

    function IsNull(const Index: Integer): Boolean;
    function GetPChar(const Index: Integer): PChar;
    function GetString(const Index: Integer): RawByteString;
    function GetBoolean(const Index: Integer): Boolean;
    function GetByte(const Index: Integer): Byte;
    function GetShort(const Index: Integer): SmallInt;
    function GetInt(const Index: Integer): Integer;
    function GetLong(const Index: Integer): Int64;
    function GetFloat(const Index: Integer): Single;
    function GetDouble(const Index: Integer): Double;
    function GetBigDecimal(const Index: Integer): Extended;
    function GetBytes(const Index: Integer): TByteDynArray;
    function GetDate(const Index: Integer): TDateTime;
    function GetTime(const Index: Integer): TDateTime;
    function GetTimestamp(const Index: Integer): TDateTime;
    function GetValue(const Index: Word): Variant;
    function GetQuad(const Index: Integer): TISC_QUAD;
  end;

  function RandomString(Len: integer): AnsiString;
  function CreateIBResultSet(SQL: string; Statement: IZStatement;
    NativeResultSet: IZResultSet): IZResultSet;

  {Interbase6 Connection Functions}
  function GenerateDPB(Info: TStrings; var FDPBLength, Dialect: Word): PAnsiChar;
  function GenerateTPB(Params: TStrings; var Handle: TISC_DB_HANDLE): PISC_TEB;
  function GetInterbase6DatabaseParamNumber(const Value: AnsiString): word;
  function GetInterbase6TransactionParamNumber(const Value: AnsiString): word;

  { Interbase6 errors functions }
  function GetNameSqlType(Value: Word): AnsiString;
  function CheckInterbase6Error(PlainDriver: IZInterbasePlainDriver;
    StatusVector: TARRAY_ISC_STATUS; LoggingCategory: TZLoggingCategory = lcOther;
    SQL: string = '') : Integer;

  { Interbase information functions}
  function GetVersion(PlainDriver: IZInterbasePlainDriver;
    Handle: PISC_DB_HANDLE): AnsiString;
  function GetDBImplementationNo(PlainDriver: IZInterbasePlainDriver;
    Handle: PISC_DB_HANDLE): LongInt;
  function GetDBImplementationClass(PlainDriver: IZInterbasePlainDriver;
    Handle: PISC_DB_HANDLE): LongInt;
  function GetLongDbInfo(PlainDriver: IZInterbasePlainDriver;
    Handle: PISC_DB_HANDLE; DatabaseInfoCommand: Integer): LongInt;
  function GetStringDbInfo(PlainDriver: IZInterbasePlainDriver;
    Handle: PISC_DB_HANDLE; DatabaseInfoCommand: Integer): AnsiString;
  function GetDBSQLDialect(PlainDriver: IZInterbasePlainDriver;
    Handle: PISC_DB_HANDLE): Integer;

  { Interbase statement functions}
  function PrepareStatement(PlainDriver: IZInterbasePlainDriver;
    Handle: PISC_DB_HANDLE; TrHandle: PISC_TR_HANDLE; Dialect: Word;
    SQL: RawByteString; LogSQL: String;
    var StmtHandle: TISC_STMT_HANDLE): TZIbSqlStatementType;
  procedure PrepareResultSqlData(PlainDriver: IZInterbasePlainDriver;
    Handle: PISC_DB_HANDLE; Dialect: Word; LogSQL: string;
    var StmtHandle: TISC_STMT_HANDLE; SqlData: IZResultSQLDA);
  procedure PrepareParameters(PlainDriver: IZInterbasePlainDriver; LogSQL: string;
    Dialect: Word; var StmtHandle: TISC_STMT_HANDLE; ParamSqlData: IZParamsSQLDA);
  procedure BindSQLDAInParameters(PlainDriver: IZInterbasePlainDriver;
    InParamValues: TZVariantDynArray; InParamTypes: TZSQLTypeArray;
    InParamCount: Integer; ParamSqlData: IZParamsSQLDA; ConSettings: PZConSettings);
  procedure FreeStatement(PlainDriver: IZInterbasePlainDriver;
    StatementHandle: TISC_STMT_HANDLE; Options : Word);
  function GetStatementType(PlainDriver: IZInterbasePlainDriver;
    StmtHandle: TISC_STMT_HANDLE): TZIbSqlStatementType;
  function GetAffectedRows(PlainDriver: IZInterbasePlainDriver;
    StmtHandle: TISC_STMT_HANDLE; StatementType: TZIbSqlStatementType): integer;

  function ConvertInterbase6ToSqlType(SqlType, SqlSubType: Integer;
    const CtrlsCPType: TZControlsCodePage): TZSqlType;

  { interbase blob routines }
  procedure GetBlobInfo(PlainDriver: IZInterbasePlainDriver;
    BlobHandle: TISC_BLOB_HANDLE; var BlobInfo: TIbBlobInfo);
  procedure ReadBlobBufer(PlainDriver: IZInterbasePlainDriver;
    Handle: PISC_DB_HANDLE; TransactionHandle: PISC_TR_HANDLE;
    BlobId: TISC_QUAD; var Size: Integer; var Buffer: Pointer);
  function GetIBScaleDivisor(Scale: SmallInt): Int64;


const
  { Default Interbase blob size for readig }
  DefaultBlobSegmentSize = 16 * 1024;

  IBScaleDivisor: array[-15..-1] of Int64 = (1000000000000000,100000000000000,
    10000000000000,1000000000000,100000000000,10000000000,1000000000,100000000,
    10000000,1000000,100000,10000,1000,100,10);

  { count database parameters }
  MAX_DPB_PARAMS = 67;
  { prefix database parameters names it used in paramters scann procedure }
  BPBPrefix = 'isc_dpb_';
  { list database parameters and their apropriate numbers }
  DatabaseParams: array [0..MAX_DPB_PARAMS]of TZIbParam = (
    (Name:'isc_dpb_version1';         Number: isc_dpb_version1),
    (Name:'isc_dpb_cdd_pathname';     Number: isc_dpb_cdd_pathname),
    (Name:'isc_dpb_allocation';       Number: isc_dpb_allocation),
    (Name:'isc_dpb_journal';          Number: isc_dpb_journal),
    (Name:'isc_dpb_page_size';        Number: isc_dpb_page_size),
    (Name:'isc_dpb_num_buffers';      Number: isc_dpb_num_buffers),
    (Name:'isc_dpb_buffer_length';    Number: isc_dpb_buffer_length),
    (Name:'isc_dpb_debug';            Number: isc_dpb_debug),
    (Name:'isc_dpb_garbage_collect';  Number: isc_dpb_garbage_collect),
    (Name:'isc_dpb_verify';           Number: isc_dpb_verify),
    (Name:'isc_dpb_sweep';            Number: isc_dpb_sweep),
    (Name:'isc_dpb_enable_journal';   Number: isc_dpb_enable_journal),
    (Name:'isc_dpb_disable_journal';  Number: isc_dpb_disable_journal),
    (Name:'isc_dpb_dbkey_scope';      Number: isc_dpb_dbkey_scope),
    (Name:'isc_dpb_number_of_users';  Number: isc_dpb_number_of_users),
    (Name:'isc_dpb_trace';            Number: isc_dpb_trace),
    (Name:'isc_dpb_no_garbage_collect'; Number: isc_dpb_no_garbage_collect),
    (Name:'isc_dpb_damaged';          Number: isc_dpb_damaged),
    (Name:'isc_dpb_license';          Number: isc_dpb_license),
    (Name:'isc_dpb_sys_user_name';    Number: isc_dpb_sys_user_name),
    (Name:'isc_dpb_encrypt_key';      Number: isc_dpb_encrypt_key),
    (Name:'isc_dpb_activate_shadow';  Number: isc_dpb_activate_shadow),
    (Name:'isc_dpb_sweep_interval';   Number: isc_dpb_sweep_interval),
    (Name:'isc_dpb_delete_shadow';    Number: isc_dpb_delete_shadow),
    (Name:'isc_dpb_force_write';      Number: isc_dpb_force_write),
    (Name:'isc_dpb_begin_log';        Number: isc_dpb_begin_log),
    (Name:'isc_dpb_quit_log';         Number: isc_dpb_quit_log),
    (Name:'isc_dpb_no_reserve';       Number: isc_dpb_no_reserve),
    (Name:'isc_dpb_username';         Number: isc_dpb_user_name),
    (Name:'isc_dpb_password';         Number: isc_dpb_password),
    (Name:'isc_dpb_password_enc';     Number: isc_dpb_password_enc),
    (Name:'isc_dpb_sys_user_name_enc';  Number: isc_dpb_sys_user_name_enc),
    (Name:'isc_dpb_interp';           Number: isc_dpb_interp),
    (Name:'isc_dpb_online_dump';      Number: isc_dpb_online_dump),
    (Name:'isc_dpb_old_file_size';    Number: isc_dpb_old_file_size),
    (Name:'isc_dpb_old_num_files';    Number: isc_dpb_old_num_files),
    (Name:'isc_dpb_old_file';         Number: isc_dpb_old_file),
    (Name:'isc_dpb_old_start_page';   Number: isc_dpb_old_start_page),
    (Name:'isc_dpb_old_start_seqno';  Number: isc_dpb_old_start_seqno),
    (Name:'isc_dpb_old_start_file';   Number: isc_dpb_old_start_file),
    (Name:'isc_dpb_drop_walfile';     Number: isc_dpb_drop_walfile),
    (Name:'isc_dpb_old_dump_id';      Number: isc_dpb_old_dump_id),
    (Name:'isc_dpb_wal_backup_dir';   Number: isc_dpb_wal_backup_dir),
    (Name:'isc_dpb_wal_chkptlen';     Number: isc_dpb_wal_chkptlen),
    (Name:'isc_dpb_wal_numbufs';      Number: isc_dpb_wal_numbufs),
    (Name:'isc_dpb_wal_bufsize';      Number: isc_dpb_wal_bufsize),
    (Name:'isc_dpb_wal_grp_cmt_wait'; Number: isc_dpb_wal_grp_cmt_wait),
    (Name:'isc_dpb_lc_messages';      Number: isc_dpb_lc_messages),
    (Name:'isc_dpb_lc_ctype';         Number: isc_dpb_lc_ctype),
    (Name:'isc_dpb_cache_manager';    Number: isc_dpb_cache_manager),
    (Name:'isc_dpb_shutdown';         Number: isc_dpb_shutdown),
    (Name:'isc_dpb_online';           Number: isc_dpb_online),
    (Name:'isc_dpb_shutdown_delay';   Number: isc_dpb_shutdown_delay),
    (Name:'isc_dpb_reserved';         Number: isc_dpb_reserved),
    (Name:'isc_dpb_overwrite';        Number: isc_dpb_overwrite),
    (Name:'isc_dpb_sec_attach';       Number: isc_dpb_sec_attach),
    (Name:'isc_dpb_disable_wal';      Number: isc_dpb_disable_wal),
    (Name:'isc_dpb_connect_timeout';  Number: isc_dpb_connect_timeout),
    (Name:'isc_dpb_dummy_packet_interval'; Number: isc_dpb_dummy_packet_interval),
    (Name:'isc_dpb_gbak_attach';      Number: isc_dpb_gbak_attach),
    (Name:'isc_dpb_sql_role_name';    Number: isc_dpb_sql_role_name),
    (Name:'isc_dpb_set_page_buffers'; Number: isc_dpb_set_page_buffers),
    (Name:'isc_dpb_working_directory';  Number: isc_dpb_working_directory),
    (Name:'isc_dpb_sql_dialect';      Number: isc_dpb_SQL_dialect),
    (Name:'isc_dpb_set_db_readonly';  Number: isc_dpb_set_db_readonly),
    (Name:'isc_dpb_set_db_sql_dialect'; Number: isc_dpb_set_db_SQL_dialect),
    (Name:'isc_dpb_gfix_attach';      Number: isc_dpb_gfix_attach),
    (Name:'isc_dpb_gstat_attach';     Number: isc_dpb_gstat_attach)
  );

  { count transaction parameters }
  MAX_TPB_PARAMS = 16;
  { prefix transaction parameters names it used in paramters scann procedure }
  TPBPrefix = 'isc_tpb_';
  { list transaction parameters and their apropriate numbers }
  TransactionParams: array [0..MAX_TPB_PARAMS]of TZIbParam = (
    (Name:'isc_tpb_version1';         Number: isc_tpb_version1),
    (Name:'isc_tpb_version3';         Number: isc_tpb_version3),
    (Name:'isc_tpb_consistency';      Number: isc_tpb_consistency),
    (Name:'isc_tpb_concurrency';      Number: isc_tpb_concurrency),
    (Name:'isc_tpb_exclusive';        Number: isc_tpb_exclusive),
    (Name:'isc_tpb_shared';           Number: isc_tpb_shared),
    (Name:'isc_tpb_protected';        Number: isc_tpb_protected),
    (Name:'isc_tpb_wait';             Number: isc_tpb_wait),
    (Name:'isc_tpb_nowait';           Number: isc_tpb_nowait),
    (Name:'isc_tpb_read';             Number: isc_tpb_read),
    (Name:'isc_tpb_write';            Number: isc_tpb_write),
    (Name:'isc_tpb_ignore_limbo';     Number: isc_tpb_ignore_limbo),
    (Name:'isc_tpb_read_committed';   Number: isc_tpb_read_committed),
    (Name:'isc_tpb_rec_version';      Number: isc_tpb_rec_version),
    (Name:'isc_tpb_no_rec_version';   Number: isc_tpb_no_rec_version),
    (Name:'isc_tpb_lock_read';        Number: isc_tpb_lock_read),
    (Name:'isc_tpb_lock_write';       Number: isc_tpb_lock_write)
    );

implementation

uses
  Variants, ZSysUtils, Math, ZDbcInterbase6, ZEncoding
  {$IFDEF WITH_UNITANSISTRINGS}, AnsiStrings{$ENDIF};

{**
   Generate specific length random string and return it
   @param Len a length result string
   @return random string
}
function RandomString(Len: integer): AnsiString;
begin
  Result := '';
  while Length(Result) < Len do
    Result := Result + AnsiString(IntToStr(Trunc(Random(High(Integer)))));
  if Length(Result) > Len then
    Result := Copy(Result, 1, Len);
end;

{**
  Create CachedResultSet with using TZCachedResultSet and return it.
  @param SQL a sql query command
  @param Statement a zeos statement object
  @param NativeResultSet a native result set
  @return cached ResultSet
}
function CreateIBResultSet(SQL: string; Statement: IZStatement; NativeResultSet: IZResultSet): IZResultSet;
var
  CachedResolver: TZInterbase6CachedResolver;
  CachedResultSet: TZCachedResultSet;
begin
  if (Statement.GetResultSetConcurrency <> rcReadOnly)
     or (Statement.GetResultSetType <> rtForwardOnly) then
  begin
    CachedResolver  := TZInterbase6CachedResolver.Create(Statement,  NativeResultSet.GetMetadata);
    CachedResultSet := TZCachedResultSet.Create(NativeResultSet, SQL,
      CachedResolver, Statement.GetConnection.GetConSettings);
    CachedResultSet.SetConcurrency(Statement.GetResultSetConcurrency);
    Result := CachedResultSet;
  end
  else
    Result := NativeResultSet;
end;

{**
  Generate database connection string by connection information
  @param DPB - a database connection string
  @param Dialect - a sql dialect number
  @param Info - a list connection interbase parameters
  @return a generated string length
}
function GenerateDPB(Info: TStrings; var FDPBLength, Dialect: Word): PAnsiChar;
var
  I, Pos, PValue: Integer;
  ParamNo: Word;
  Buffer: String;
  DPB, ParamName, ParamValue: AnsiString;
begin
  FDPBLength := 1;
  DPB := AnsiChar(isc_dpb_version1);

  for I := 0 to Info.Count - 1 do
  begin
    Buffer := Info.Strings[I];
    Pos := FirstDelimiter(' ='#9#10#13, Buffer);
    ParamName := AnsiString(Copy(Buffer, 1, Pos - 1));
    Delete(Buffer, 1, Pos);
    ParamValue := AnsiString(Buffer);
    ParamNo := GetInterbase6DatabaseParamNumber(ParamName);

    case ParamNo of
      0: Continue;
      isc_dpb_set_db_SQL_dialect:
        Dialect := StrToIntDef(String(ParamValue), 0);
      isc_dpb_user_name, isc_dpb_password, isc_dpb_password_enc,
      isc_dpb_sys_user_name, isc_dpb_license, isc_dpb_encrypt_key,
      isc_dpb_lc_messages, isc_dpb_lc_ctype, isc_dpb_sql_role_name,
	  isc_dpb_connect_timeout:
        begin
          DPB := DPB + AnsiChar(ParamNo) + AnsiChar(Length(ParamValue)) + ParamValue;
          Inc(FDPBLength, 2 + Length(ParamValue));
        end;
      isc_dpb_num_buffers, isc_dpb_dbkey_scope, isc_dpb_force_write,
      isc_dpb_no_reserve, isc_dpb_damaged, isc_dpb_verify:
        begin
          DPB := DPB + AnsiChar(ParamNo) + #1 + AnsiChar(StrToInt(String(ParamValue)));
          Inc(FDPBLength, 3);
        end;
      isc_dpb_sweep:
        begin
          DPB := DPB + AnsiChar(ParamNo) + #1 + AnsiChar(isc_dpb_records);
          Inc(FDPBLength, 3);
        end;
      isc_dpb_sweep_interval:
        begin
          PValue := StrToInt(String(ParamValue));
          DPB := DPB + AnsiChar(ParamNo) + #4 + PAnsiChar(@PValue)[0] +
                 PAnsiChar(@PValue)[1] + PAnsiChar(@PValue)[2] + PAnsiChar(@PValue)[3];
          Inc(FDPBLength, 6);
        end;
      isc_dpb_activate_shadow, isc_dpb_delete_shadow, isc_dpb_begin_log,
      isc_dpb_quit_log:
        begin
          DPB := DPB + AnsiChar(ParamNo) + #1 + #0;
          Inc(FDPBLength, 3);
        end;
    end;
  end;

  {$IFDEF UNICODE}
  Result := AnsiStrAlloc(FDPBLength + 1);
  {$ELSE}
  Result := StrAlloc(FDPBLength + 1);
  {$ENDIF}


  {$IFDEF WITH_STRPCOPY_DEPRECATED}AnsiStrings.{$ENDIF}StrPCopy(Result, DPB);
end;

{**
   Generate transaction structuer by connection information
   @param Params - a transaction parameters list
   @param Dialect - a database connection handle
   @return a transaction ISC structure
}
function GenerateTPB(Params: TStrings; var Handle: TISC_DB_HANDLE): PISC_TEB;
var
  I: Integer;
  TPBLength,ParamNo: Word;
  TempStr, ParamValue: AnsiString;
  TPB: PAnsiChar;
  IsolationLevel: Boolean;
begin
  TPBLength := 0;
  TempStr := '';
  IsolationLevel := False;

  { Prepare transaction parameters string }
  for I := 0 to Params.Count - 1 do
  begin
    ParamValue := AnsiString(Params.Strings[I]);
    ParamNo := GetInterbase6TransactionParamNumber(ParamValue);

    case ParamNo of
      0: Continue;
      isc_tpb_lock_read, isc_tpb_lock_write:
        begin
          TempStr := TempStr + AnsiChar(ParamNo) + AnsiChar(Length(ParamValue)) + ParamValue;
          Inc(TPBLength, Length(ParamValue) + 2);
        end;
      else
        begin
          TempStr := TempStr + AnsiChar(ParamNo);
          Inc(TPBLength, 1);
        end;
    end;

    { Check what was set use transaction isolation level }
    if not IsolationLevel then
      case ParamNo of
        isc_tpb_concurrency, isc_tpb_consistency,
        isc_tpb_read_committed:
          IsolationLevel := True
        else
          IsolationLevel := False;
      end;

  end;

   { Allocate transaction parameters PAnsiChar buffer
    if temporally parameters string is empty the set null pointer for
    default database transaction}
  if (TPBLength > 0) and (IsolationLevel) then
  begin
    {$IFDEF UNICODE}
    TPB := AnsiStrAlloc(TPBLength + 1);
    {$ELSE}
    TPB := StrAlloc(TPBLength + 1);
    {$ENDIF}
    TPB := {$IFDEF WITH_STRPCOPY_DEPRECATED}AnsiStrings.{$ENDIF}StrPCopy(TPB, TempStr);

  end
  else
    TPB := nil;

  { Allocate transaction structure }
  Result := AllocMem(SizeOf(TISC_TEB));
  with Result^ do
  begin
    db_handle := @Handle;
    tpb_length := TPBLength;
    tpb_address := TPB;
  end;
end;

{**
  Return interbase connection parameter number by it name
  @param Value - a connection parameter name
  @return - connection parameter number
}
function GetInterbase6DatabaseParamNumber(const Value: AnsiString): Word;
var
 I: Integer;
 ParamName: AnsiString;
begin
  ParamName := {$IFDEF WITH_UNITANSISTRINGS}AnsiStrings.{$ENDIF}AnsiLowerCase(Value);
  Result := 0;
  if System.Pos(BPBPrefix, String(ParamName)) = 1 then
    for I := 1 to MAX_DPB_PARAMS do
    begin
      if ParamName = DatabaseParams[I].Name then
      begin
        Result := DatabaseParams[I].Number;
        Break;
      end;
    end;
end;

{**
  Return interbase transaction parameter number by it name
  @param Value - a transaction parameter name
  @return - transaction parameter number
}
function GetInterbase6TransactionParamNumber(const Value: AnsiString): Word;
var
 I: Integer;
 ParamName: AnsiString;
begin
  ParamName := {$IFDEF WITH_UNITANSISTRINGS}AnsiStrings.{$ENDIF}AnsiLowerCase(Value);
  Result := 0;
  if System.Pos(TPBPrefix, String(ParamName)) = 1 then
    for I := 1 to MAX_TPB_PARAMS do
    begin
      if ParamName = TransactionParams[I].Name then
      begin
        Result := TransactionParams[I].Number;
        Break;
      end;
    end;
end;

{**
  Converts a Interbase6 native types into ZDBC SQL types.
  @param the interbase type
  @param the interbase subtype
  @return a SQL undepended type.

  <b>Note:</b> The interbase type and subtype get from RDB$TYPES table
}
function ConvertInterbase6ToSqlType(SqlType, SqlSubType: Integer;
  const CtrlsCPType: TZControlsCodePage): TZSQLType;
begin
  Result := ZDbcIntfs.stUnknown;

  case SqlType of
    blr_bool, blr_not_nullable: Result := stBoolean;
    blr_varying2, blr_varying, blr_cstring, blr_cstring2, blr_domain_name,
    blr_domain_name2, blr_column_name, blr_column_name2:
      Result := stString;
    blr_text, blr_text2:
      case SqlSubType of
        CS_BINARY: Result := stBytes;
      else
        Result := stString;
      end;
    blr_d_float: Result := stDouble;
    blr_float: Result := stFloat;
    blr_double: Result := stDouble;
    blr_blob_id, blr_quad: Result := stLong;
    blr_int64:
      case SqlSubType of
        RDB_NUMBERS_NONE: Result := stLong;
        RDB_NUMBERS_NUMERIC: Result := stDouble;
        RDB_NUMBERS_DECIMAL: Result := stBigDecimal;
      end;
    blr_long:
      begin
        case SqlSubType of
          RDB_NUMBERS_NONE: Result := stInteger;
          RDB_NUMBERS_NUMERIC: Result := stDouble;
          RDB_NUMBERS_DECIMAL: Result := stBigDecimal;
        end;
      end;
    blr_short:
      begin
        case SqlSubType of
          RDB_NUMBERS_NONE: Result := stShort;
          RDB_NUMBERS_NUMERIC: Result := stDouble;
          RDB_NUMBERS_DECIMAL: Result := stDouble;
        end;
      end;
    blr_sql_date: Result := stDate;
    blr_sql_time: Result := stTime;
    blr_timestamp: Result := stTimestamp;
    blr_blob, blr_blob2:
      begin
        case SqlSubType of
          { Blob Subtypes }
          { types less than zero are reserved for customer use }
          isc_blob_untyped: Result := stBinaryStream;

          { internal subtypes }
          isc_blob_text: Result := stAsciiStream;
          isc_blob_blr: Result := stBinaryStream;
          isc_blob_acl: Result := stAsciiStream;
          isc_blob_ranges: Result := stBinaryStream;
          isc_blob_summary: Result := stBinaryStream;
          isc_blob_format: Result := stAsciiStream;
          isc_blob_tra: Result := stAsciiStream;
          isc_blob_extfile: Result := stAsciiStream;
          isc_blob_debug_info: Result := stBinaryStream;
        end;
      end;
    else
      Result := ZDbcIntfs.stUnknown;
  end;
  if ( CtrlsCPType = cCP_UTF16) then
    case result of
      stString: Result := stUnicodeString;
      stAsciiStream: Result := stUnicodeStream;
    end;
end;

{**
   Return Interbase SqlType by it number
   @param Value the SqlType number
}
function GetNameSqlType(Value: Word): AnsiString;
begin
  case Value of
    SQL_VARYING: Result := 'SQL_VARYING';
    SQL_TEXT: Result := 'SQL_TEXT';
    SQL_DOUBLE: Result := 'SQL_DOUBLE';
    SQL_FLOAT: Result := 'SQL_FLOAT';
    SQL_LONG: Result := 'SQL_LONG';
    SQL_SHORT: Result := 'SQL_SHORT';
    SQL_TIMESTAMP: Result := 'SQL_TIMESTAMP';
    SQL_BLOB: Result := 'SQL_BLOB';
    SQL_D_FLOAT: Result := 'SQL_D_FLOAT';
    SQL_ARRAY: Result := 'SQL_ARRAY';
    SQL_QUAD: Result := 'SQL_QUAD';
    SQL_TYPE_TIME: Result := 'SQL_TYPE_TIME';
    SQL_TYPE_DATE: Result := 'SQL_TYPE_DATE';
    SQL_INT64: Result := 'SQL_INT64';
    SQL_BOOLEAN: Result := 'SQL_BOOLEAN';
  else
    Result := 'Unknown';
  end
end;

{**
  Checks for possible sql errors.
  @param PlainDriver a Interbase Plain drver
  @param StatusVector a status vector. It contain information about error
  @param Sql a sql query commend

  @Param Integer Return is the ErrorCode that happened - for disconnecting the database
}
function CheckInterbase6Error(PlainDriver: IZInterbasePlainDriver;
  StatusVector: TARRAY_ISC_STATUS; LoggingCategory: TZLoggingCategory = lcOther;
  SQL: string = '') : Integer;
var
  Msg: array[0..1024] of AnsiChar;
  PStatusVector: PISC_STATUS;
  ErrorMessage, ErrorSqlMessage: string;
  ErrorCode: LongInt;
begin
  Result := 0;
  if (StatusVector[0] = 1) and (StatusVector[1] > 0) then
  begin
    ErrorMessage := '';
    PStatusVector := @StatusVector;
    while PlainDriver.isc_interprete(Msg, @PStatusVector) > 0 do
      ErrorMessage := ErrorMessage + ' ' + String(Msg);

    ErrorCode := PlainDriver.isc_sqlcode(@StatusVector);
    PlainDriver.isc_sql_interprete(ErrorCode, Msg, 1024);
    ErrorSqlMessage := String(Msg);

{$IFDEF INTERBASE_EXTENDED_MESSAGES}
    if SQL <> '' then
      SQL := Format(' The SQL: %s; ', [SQL]);
{$ENDIF}

    if ErrorMessage <> '' then
    begin
      DriverManager.LogError(LoggingCategory, PlainDriver.GetProtocol,
        ErrorMessage, ErrorCode, ErrorSqlMessage + SQL);

      //AVZ Ignore error codes for disconnected database -901, -902
      if ((ErrorCode <> -901) and (ErrorCode <> -902)) then
      begin
{$IFDEF INTERBASE_EXTENDED_MESSAGES}
        raise EZSQLException.CreateWithCode(ErrorCode,
          Format('SQL Error: %s. Error Code: %d. %s',
          [ErrorMessage, ErrorCode, ErrorSqlMessage]) + SQL);
{$ELSE}
        raise EZSQLException.CreateWithCode(ErrorCode,
          Format('SQL Error: %s. Error Code: %d. %s',
          [ErrorMessage, ErrorCode, ErrorSqlMessage]));
{$ENDIF}
      end
        else
      begin      //AVZ -- Added exception back in to help error trapping
        raise EZSQLException.CreateWithCode(ErrorCode,
          Format('SQL Error: %s. Error Code: %d. %s',
          [ErrorMessage, ErrorCode, ErrorSqlMessage]));

        Result := DISCONNECT_ERROR;
      end;
    end;
  end;
end;

{**
   Prepare statement and create statement handle.
   @param PlainDriver a interbase plain driver
   @param Handle a interbase connection handle
   @param TrHandle a transaction handle
   @param Dialect a interbase sql dialect number
   @param Sql a sql query
   @param StmtHandle a statement handle
   @param SqlData a interbase sql result data
   @return sql statement type
}
function PrepareStatement(PlainDriver: IZInterbasePlainDriver;
  Handle: PISC_DB_HANDLE; TrHandle: PISC_TR_HANDLE; Dialect: Word;
  SQL: RawByteString; LogSQL: String; var StmtHandle: TISC_STMT_HANDLE):
  TZIbSqlStatementType;
var
  StatusVector: TARRAY_ISC_STATUS;
  iError : Integer; //Error for disconnect
begin
  { Allocate an sql statement }
  if StmtHandle = 0 then
  begin
    PlainDriver.isc_dsql_allocate_statement(@StatusVector, Handle, @StmtHandle);
    CheckInterbase6Error(PlainDriver, StatusVector, lcOther, LogSQL);
  end;
  { Prepare an sql statement }
  PlainDriver.isc_dsql_prepare(@StatusVector, TrHandle, @StmtHandle,
    0, PAnsiChar(SQL), Dialect, nil);

  iError := CheckInterbase6Error(PlainDriver, StatusVector, lcPrepStmt, LogSQL); //Check for disconnect AVZ

  { Set Statement Type }
  if (iError <> DISCONNECT_ERROR) then //AVZ
    Result := GetStatementType(PlainDriver, StmtHandle)
  else
    Result := stDisconnect;

  if Result in [stUnknown, stGetSegment, stPutSegment, stStartTrans] then
  begin
    FreeStatement(PlainDriver, StmtHandle, DSQL_CLOSE);  //AVZ
    raise EZSQLException.Create(SStatementIsNotAllowed);
  end;
end;

{**
   Describe SQLDA and allocate memory for result values.
   @param PlainDriver a interbase plain driver
   @param Handle a interbase connection handle
   @param Dialect a interbase sql dialect number
   @param Sql a sql query
   @param StmtHandle a statement handle
   @param SqlData a interbase sql result data
}
procedure PrepareResultSqlData(PlainDriver: IZInterbasePlainDriver;
    Handle: PISC_DB_HANDLE; Dialect: Word; LogSQL: string;
    var StmtHandle: TISC_STMT_HANDLE; SqlData: IZResultSQLDA);
var
  StatusVector: TARRAY_ISC_STATUS;
begin
  { Initialise ouput param and fields }
  PlainDriver.isc_dsql_describe(@StatusVector, @StmtHandle, Dialect,
    SqlData.GetData);
  CheckInterbase6Error(PlainDriver, StatusVector, lcExecute, LogSQL);

  if SqlData.GetData^.sqld > SqlData.GetData^.sqln then
  begin
    SqlData.AllocateSQLDA;
    PlainDriver.isc_dsql_describe(@StatusVector, @StmtHandle,
      Dialect, SqlData.GetData);
    CheckInterbase6Error(PlainDriver, StatusVector, lcExecute, LogSql);
  end;
  SqlData.InitFields(False);
end;

{**
   Return interbase statement type by statement handle
   @param PlainDriver a interbase plain driver
   @param StmtHandle a statement handle
   @return interbase statement type
}
function GetStatementType(PlainDriver: IZInterbasePlainDriver;
  StmtHandle: TISC_STMT_HANDLE): TZIbSqlStatementType;
var
  TypeItem: AnsiChar;
  StatusVector: TARRAY_ISC_STATUS;
  StatementLength: integer;
  StatementBuffer: array[0..7] of AnsiChar;
begin
  Result := stUnknown;
  TypeItem := AnsiChar(isc_info_sql_stmt_type);

  { Get information about a prepared DSQL statement. }
  PlainDriver.isc_dsql_sql_info(@StatusVector, @StmtHandle, 1,
    @TypeItem, SizeOf(StatementBuffer), StatementBuffer);
  CheckInterbase6Error(PlainDriver, StatusVector);

  if StatementBuffer[0] = AnsiChar(isc_info_sql_stmt_type) then
  begin
    StatementLength := PlainDriver.isc_vax_integer(
      @StatementBuffer[1], 2);
    Result := TZIbSqlStatementType(PlainDriver.isc_vax_integer(
      @StatementBuffer[3], StatementLength));
  end;
end;

{**
   Free interbse allocated statement and SQLDA for input and utput parameters
   @param  the interbase plain driver
   @param  the interbse statement handle
}
procedure FreeStatement(PlainDriver: IZInterbasePlainDriver; StatementHandle: TISC_STMT_HANDLE; Options: Word);
var
  StatusVector: TARRAY_ISC_STATUS;
begin
  if StatementHandle <> 0  then
    PlainDriver.isc_dsql_free_statement(@StatusVector, @StatementHandle, Options);
  //CheckInterbase6Error(PlainDriver, StatusVector); //raises an unwanted exception if Connection was reopened  See: http://sourceforge.net/p/zeoslib/tickets/40/
end;

{**
   Get affected rows.
   <i>Note:<i> it function may call after statement execution
   @param PlainDriver a interbase plain driver
   @param StmtHandle a statement handle
   @param StatementType a statement type
   @return affected rows
}
function GetAffectedRows(PlainDriver: IZInterbasePlainDriver;
  StmtHandle: TISC_STMT_HANDLE; StatementType: TZIbSqlStatementType): Integer;
var
  ReqInfo: AnsiChar;
  OutBuffer: array[0..255] of AnsiChar;
  StatusVector: TARRAY_ISC_STATUS;
begin
  Result := -1;
  ReqInfo := AnsiChar(isc_info_sql_records);

  if PlainDriver.isc_dsql_sql_info(@StatusVector, @StmtHandle, 1,
    @ReqInfo, SizeOf(OutBuffer), OutBuffer) > 0 then
    Exit;
  CheckInterbase6Error(PlainDriver, StatusVector);
  if OutBuffer[0] = AnsiChar(isc_info_sql_records) then
  begin
    case StatementType of
      stUpdate: Result := PlainDriver.isc_vax_integer(@OutBuffer[6], 4);
      stDelete: Result := PlainDriver.isc_vax_integer(@OutBuffer[13], 4);
      stSelect: Result := PlainDriver.isc_vax_integer(@OutBuffer[20], 4);
      stInsert: Result := PlainDriver.isc_vax_integer(@OutBuffer[27], 4);
    else
       Result := -1;
    end;
  end;
end;

{**
   Prepare sql statement parameters and fill parameters by values
   @param PlainDriver a interbase plain driver
   @param Dialect a interbase sql dialect number
   @param StmtHandle a statement handle
   @param SqlData a interbase sql result data
}
procedure PrepareParameters(PlainDriver: IZInterbasePlainDriver; LogSQL: string;
   Dialect: Word; var StmtHandle: TISC_STMT_HANDLE; ParamSqlData: IZParamsSQLDA);
var
  StatusVector: TARRAY_ISC_STATUS;
begin
  {check dynamic sql}
  PlainDriver.isc_dsql_describe_bind(@StatusVector, @StmtHandle, Dialect,
    ParamSqlData.GetData);
  CheckInterbase6Error(PlainDriver, StatusVector, lcExecute, LogSQL);

  { Resize XSQLDA structure if needed }
  if ParamSqlData.GetData^.sqld > ParamSqlData.GetData^.sqln then
  begin
    ParamSqlData.AllocateSQLDA;
    PlainDriver.isc_dsql_describe_bind(@StatusVector, @StmtHandle, Dialect,
      ParamSqlData.GetData);
    CheckInterbase6Error(PlainDriver, StatusVector, lcExecute, LogSQL);
  end;

  ParamSqlData.InitFields(True);
end;

procedure BindSQLDAInParameters(PlainDriver: IZInterbasePlainDriver;
  InParamValues: TZVariantDynArray; InParamTypes: TZSQLTypeArray;
  InParamCount: Integer; ParamSqlData: IZParamsSQLDA; ConSettings: PZConSettings);
var
  I: Integer;
  TempBlob: IZBlob;
  TempStream: TStream;
begin
  if InParamCount <> ParamSqlData.GetFieldCount then
    raise EZSQLException.Create(SInvalidInputParameterCount);

  {$R-}
  for I := 0 to ParamSqlData.GetFieldCount - 1 do
  begin
    ParamSqlData.UpdateNull(I, DefVarManager.IsNull(InParamValues[I]));
    if DefVarManager.IsNull(InParamValues[I])then
      Continue
    else
    case InParamTypes[I] of
      stBoolean:
        ParamSqlData.UpdateBoolean(I,
          SoftVarManager.GetAsBoolean(InParamValues[I]));
      stByte:
        ParamSqlData.UpdateByte(I,
          SoftVarManager.GetAsInteger(InParamValues[I]));
      stShort:
        ParamSqlData.UpdateShort(I,
          SoftVarManager.GetAsInteger(InParamValues[I]));
      stInteger:
        ParamSqlData.UpdateInt(I,
          SoftVarManager.GetAsInteger(InParamValues[I]));
      stLong:
        ParamSqlData.UpdateLong(I,
          SoftVarManager.GetAsInteger(InParamValues[I]));
      stFloat:
        ParamSqlData.UpdateFloat(I,
          SoftVarManager.GetAsFloat(InParamValues[I]));
      stDouble:
        ParamSqlData.UpdateDouble(I,
          SoftVarManager.GetAsFloat(InParamValues[I]));
      stBigDecimal:
        ParamSqlData.UpdateBigDecimal(I,
          SoftVarManager.GetAsFloat(InParamValues[I]));
      stString:
         if ( ConSettings.ClientCodePage.ID = CS_NONE ) and not
            (ParamSqlData.GetIbSqlSubType(I) = CS_NONE) then //CharSet 'NONE' writes data 'as is'!
          ParamSqlData.UpdateString(I,
            PlainDriver.ZPlainString(SoftVarManager.GetAsString(InParamValues[I]),
            ConSettings, PlainDriver.ValidateCharEncoding(ParamSqlData.GetIbSqlSubType(I)).CP))
        else
          ParamSqlData.UpdateString(I,
            PlainDriver.ZPlainString(SoftVarManager.GetAsString(InParamValues[I]), ConSettings));
      stUnicodeString:
         if ( ConSettings.ClientCodePage.ID = CS_NONE ) and not
            (ParamSqlData.GetIbSqlSubType(I) = CS_NONE) then //CharSet 'NONE' writes data 'as is'!
          ParamSqlData.UpdateString(I,
            PlainDriver.ZPlainString(SoftVarManager.GetAsUnicodeString(InParamValues[I]),
            ConSettings, PlainDriver.ValidateCharEncoding(ParamSqlData.GetIbSqlSubType(I)).CP))
        else
          ParamSqlData.UpdateString(I,
            PlainDriver.ZPlainString(SoftVarManager.GetAsUnicodeString(InParamValues[I]), ConSettings));
      stBytes:
        ParamSqlData.UpdateBytes(I, SoftVarManager.GetAsBytes(InParamValues[I]));
      stDate:
        ParamSqlData.UpdateDate(I,
          SoftVarManager.GetAsDateTime(InParamValues[I]));
      stTime:
        ParamSqlData.UpdateTime(I,
          SoftVarManager.GetAsDateTime(InParamValues[I]));
      stTimestamp:
        ParamSqlData.UpdateTimestamp(I,
          SoftVarManager.GetAsDateTime(InParamValues[I]));
      stAsciiStream,
      stUnicodeStream,
      stBinaryStream:
        begin
          TempBlob := DefVarManager.GetAsInterface(InParamValues[I]) as IZBlob;
          if not TempBlob.IsEmpty then
          begin
            if (ParamSqlData.GetFieldSqlType(i) in [stUnicodeStream, stAsciiStream] ) then
              TempStream := TStringStream.Create(GetValidatedAnsiStringFromBuffer(TempBlob.GetBuffer, TempBlob.Length,
                TempBlob.WasDecoded, ConSettings))
            else
              TempStream := TempBlob.GetStream;
            if Assigned(TempStream) then
            begin
              ParamSqlData.WriteBlob(I, TempStream);
              TempStream.Free;
            end;
          end;
        end
      else
        raise EZIBConvertError.Create(SUnsupportedParameterType);
    end;
  end;
 {$IFOPT D+}
{$ENDIF}
end;

{**
   Read blob information by it handle such as blob segment size, segments count,
   blob size and type.
   @param PlainDriver
   @param BlobInfo the blob information structure
}
procedure GetBlobInfo(PlainDriver: IZInterbasePlainDriver;
  BlobHandle: TISC_BLOB_HANDLE; var BlobInfo: TIbBlobInfo);
var
  Items: array[0..3] of AnsiChar;
  Results: array[0..99] of AnsiChar;
  I, ItemLength: Integer;
  Item: Integer;
  StatusVector: TARRAY_ISC_STATUS;
begin
  I := 0;
  Items[0] := AnsiChar(isc_info_blob_num_segments);
  Items[1] := AnsiChar(isc_info_blob_max_segment);
  Items[2] := AnsiChar(isc_info_blob_total_length);
  Items[3] := AnsiChar(isc_info_blob_type);

  if PlainDriver.isc_blob_info(@StatusVector, @BlobHandle, 4, @items[0],
    SizeOf(Results), @Results[0]) > 0 then
  CheckInterbase6Error(PlainDriver, StatusVector);

  while (I < SizeOf(Results)) and (Results[I] <> AnsiChar(isc_info_end)) do
  begin
    Item := Integer(Results[I]);
    Inc(I);
    ItemLength := PlainDriver.isc_vax_integer(@results[I], 2);
    Inc(I, 2);
    case Item of
      isc_info_blob_num_segments:
        BlobInfo.NumSegments := PlainDriver.isc_vax_integer(@Results[I], ItemLength);
      isc_info_blob_max_segment:
        BlobInfo.MaxSegmentSize := PlainDriver.isc_vax_integer(@Results[I], ItemLength);
      isc_info_blob_total_length:
        BlobInfo.TotalSize := PlainDriver.isc_vax_integer(@Results[I], ItemLength);
      isc_info_blob_type:
        BlobInfo.BlobType := PlainDriver.isc_vax_integer(@Results[I], ItemLength);
    end;
    Inc(i, ItemLength);
  end;
end;

{**
   Read blob field data to stream by it ISC_QUAD value
   Note: DefaultBlobSegmentSize constant used for limit segment size reading
   @param Handle the database connection handle
   @param TransactionHandle the transaction handle
   @param BlobId the ISC_QUAD structure
   @param Size the result buffer size
   @param Buffer the pointer to result buffer

   Note: Buffer must be nill. Function self allocate memory for data
    and return it size
}
procedure ReadBlobBufer(PlainDriver: IZInterbasePlainDriver;
  Handle: PISC_DB_HANDLE; TransactionHandle: PISC_TR_HANDLE;
  BlobId: TISC_QUAD; var Size: Integer; var Buffer: Pointer);
var
  TempBuffer: PAnsiChar;
  BlobInfo: TIbBlobInfo;
  BlobSize, CurPos: LongInt;
  BytesRead, SegmentLenght: UShort;
  BlobHandle: TISC_BLOB_HANDLE;
  StatusVector: TARRAY_ISC_STATUS;
begin
  BlobHandle := 0;
  CurPos := 0;
//  SegmentLenght := UShort(DefaultBlobSegmentSize);

  { open blob }
  PlainDriver.isc_open_blob2(@StatusVector, Handle,
         TransactionHandle, @BlobHandle, @BlobId, 0 , nil);
  CheckInterbase6Error(PlainDriver, StatusVector);

  { get blob info }
  GetBlobInfo(PlainDriver, BlobHandle, BlobInfo);
  BlobSize := BlobInfo.TotalSize;
  Size := BlobSize;

  SegmentLenght := BlobInfo.MaxSegmentSize;

  { Allocates a blob buffer }
  Buffer := AllocMem(BlobSize);
  TempBuffer := Buffer;

  { Copies data to blob buffer }
  while CurPos < BlobSize do
  begin
    if (CurPos + SegmentLenght > BlobSize) then
      SegmentLenght := BlobSize - CurPos;
    if not(PlainDriver.isc_get_segment(@StatusVector, @BlobHandle,
           @BytesRead, SegmentLenght, TempBuffer) = 0) or
          (StatusVector[1] <> isc_segment) then
      CheckInterbase6Error(PlainDriver, StatusVector);
    Inc(CurPos, BytesRead);
    Inc(TempBuffer, BytesRead);
    BytesRead := 0;
  end;

  { close blob handle }
  PlainDriver.isc_close_blob(@StatusVector, @BlobHandle);
  CheckInterbase6Error(PlainDriver, StatusVector);
end;

function GetIBScaleDivisor(Scale: SmallInt): Int64;
var
  i: Integer;
begin
  Result := 1;
  if Scale > 0 then
    for i := 1 to Scale do
      Result := Result * 10
  else
    if Scale < 0 then
      for i := -1 downto Scale do
        Result := Result * 10;
end;
{**
   Return interbase server version string
   @param PlainDriver a interbase plain driver
   @param Handle the database connection handle
   @return interbase version string
}
function GetVersion(PlainDriver: IZInterbasePlainDriver;
  Handle: PISC_DB_HANDLE): AnsiString;
var
  DatabaseInfoCommand: AnsiChar;
  StatusVector: TARRAY_ISC_STATUS;
  Buffer: array[0..IBBigLocalBufferLength - 1] of AnsiChar;
begin
  DatabaseInfoCommand := AnsiChar(isc_info_version);
  PlainDriver.isc_database_info(@StatusVector, Handle, 1, @DatabaseInfoCommand,
    IBBigLocalBufferLength, Buffer);
  CheckInterbase6Error(PlainDriver, StatusVector);
  Buffer[5 + Integer(Buffer[4])] := #0;
  result := AnsiString(PAnsiChar(@Buffer[5]));
end;

{**
   Return interbase database implementation
   @param PlainDriver a interbase plain driver
   @param Handle the database connection handle
   @return interbase database implementation
}
function GetDBImplementationNo(PlainDriver: IZInterbasePlainDriver;
    Handle: PISC_DB_HANDLE): LongInt;
var
  DatabaseInfoCommand: AnsiChar;
  StatusVector: TARRAY_ISC_STATUS;
  Buffer: array[0..IBBigLocalBufferLength - 1] of AnsiChar;
begin
  DatabaseInfoCommand := AnsiChar(isc_info_implementation);
  PlainDriver.isc_database_info(@StatusVector, Handle, 1, @DatabaseInfoCommand,
    IBLocalBufferLength, Buffer);
  CheckInterbase6Error(PlainDriver, StatusVector);
  result := PlainDriver.isc_vax_integer(@Buffer[3], 1);
end;

{**
   Return interbase database implementation class
   @param PlainDriver a interbase plain driver
   @param Handle the database connection handle
   @return interbase database implementation class
}
function GetDBImplementationClass(PlainDriver: IZInterbasePlainDriver;
    Handle: PISC_DB_HANDLE): LongInt;
var
  DatabaseInfoCommand: AnsiChar;
  StatusVector: TARRAY_ISC_STATUS;
  Buffer: array[0..IBBigLocalBufferLength - 1] of AnsiChar;
begin
  DatabaseInfoCommand := AnsiChar(isc_info_implementation);
  PlainDriver.isc_database_info(@StatusVector, Handle, 1, @DatabaseInfoCommand,
    IBLocalBufferLength, Buffer);
  CheckInterbase6Error(PlainDriver, StatusVector);
  result := PlainDriver.isc_vax_integer(@Buffer[4], 1);
end;

{**
   Return interbase database info
   @param PlainDriver a interbase plain driver
   @param Handle the database connection handle
   @param DatabaseInfoCommand a database information command
   @return interbase database info
}
function GetLongDbInfo(PlainDriver: IZInterbasePlainDriver;
  Handle: PISC_DB_HANDLE; DatabaseInfoCommand: Integer): LongInt;
var
  Length: Integer;
  DatabaseInfoCommand1: AnsiChar;
  StatusVector: TARRAY_ISC_STATUS;
  Buffer: array[0..IBBigLocalBufferLength - 1] of AnsiChar;
begin
  DatabaseInfoCommand1 := AnsiChar(DatabaseInfoCommand);
  PlainDriver.isc_database_info(@StatusVector, Handle, 1, @DatabaseInfoCommand1,
    IBLocalBufferLength, Buffer);
  CheckInterbase6Error(PlainDriver, StatusVector);
  Length := PlainDriver.isc_vax_integer(@Buffer[1], 2);
  Result := PlainDriver.isc_vax_integer(@Buffer[4], Length);
end;

{**
   Return interbase database info string
   @param PlainDriver a interbase plain driver
   @param Handle a database connection handle
   @param DatabaseInfoCommand a database information command
   @return interbase database info string
}
function GetStringDbInfo(PlainDriver: IZInterbasePlainDriver;
  Handle: PISC_DB_HANDLE; DatabaseInfoCommand: Integer): AnsiString;
var
  DatabaseInfoCommand1: AnsiChar;
  StatusVector: TARRAY_ISC_STATUS;
  Buffer: array[0..IBBigLocalBufferLength - 1] of AnsiChar;
begin
   DatabaseInfoCommand1 := AnsiChar(DatabaseInfoCommand);
   PlainDriver.isc_database_info(@StatusVector, Handle, 1, @DatabaseInfoCommand1,
     IBLocalBufferLength, Buffer);
   CheckInterbase6Error(PlainDriver, StatusVector);
   Buffer[4 + Integer(Buffer[3])] := #0;
   Result := AnsiString(PAnsiChar(@Buffer[4]));
end;

{**
   Return interbase database dialect
   @param PlainDriver a interbase plain driver
   @param Handle the database connection handle
   @return interbase database dialect
}
function GetDBSQLDialect(PlainDriver: IZInterbasePlainDriver;
    Handle: PISC_DB_HANDLE): Integer;
var
  Length: Integer;
  DatabaseInfoCommand1: AnsiChar;
  StatusVector: TARRAY_ISC_STATUS;
  Buffer: array[0..IBBigLocalBufferLength - 1] of AnsiChar;
begin
   DatabaseInfoCommand1 := AnsiChar(isc_info_db_SQL_Dialect);
   PlainDriver.isc_database_info(@StatusVector, Handle, 1, @DatabaseInfoCommand1,
     IBLocalBufferLength, Buffer);
   CheckInterbase6Error(PlainDriver, StatusVector);
   if (Buffer[0] <> AnsiChar(isc_info_db_SQL_dialect)) then
     Result := 1
   else
   begin
     Length := PlainDriver.isc_vax_integer(@Buffer[1], 2);
     Result := PlainDriver.isc_vax_integer(@Buffer[3], Length);
   end;
end;

{ TSQLDA }
constructor TZSQLDA.Create(PlainDriver: IZInterbasePlainDriver;
  Handle: PISC_DB_HANDLE; TransactionHandle: PISC_TR_HANDLE;
  ConSettings: PZConSettings);
begin
  Self.ConSettings := ConSettings;
  FPlainDriver := PlainDriver;
  FHandle := Handle;
  FTransactionHandle := TransactionHandle;

  GetMem(FXSQLDA, XSQLDA_LENGTH(0));
  FillChar(FXSQLDA^, XSQLDA_LENGTH(0), 0);
  FXSQLDA.sqln := 0;
  FXSQLDA.sqld := 0;

  FXSQLDA.version := SQLDA_VERSION1;
end;
{**
   Allocate memory for SQLVar in SQLDA structure for every
   fields by it length.
}
procedure TZSQLDA.InitFields(Parameters: boolean);
var
  I: Integer;
  SqlVar: PXSQLVAR;
begin
  {$R-}
  for I := 0 to FXSQLDA.sqld - 1 do
  begin
    SqlVar := @FXSQLDA.SqlVar[I];
    case SqlVar.sqltype and (not 1) of
      SQL_BOOLEAN, SQL_TEXT, SQL_TYPE_DATE, SQL_TYPE_TIME, SQL_DATE,
      SQL_BLOB, SQL_ARRAY, SQL_QUAD, SQL_SHORT,
      SQL_LONG, SQL_INT64, SQL_DOUBLE, SQL_FLOAT, SQL_D_FLOAT:
        begin
          if SqlVar.sqllen = 0 then
            IbReAlloc(SqlVar.sqldata, 0, 1)
          else
            IbReAlloc(SqlVar.sqldata, 0, SqlVar.sqllen)
        end;
      SQL_VARYING:
          IbReAlloc(SqlVar.sqldata, 0, SqlVar.sqllen + 2)
    end;

    if Parameters = True then
    begin
      //This code used when allocated sqlind parameter for Param SQLDA
      SqlVar.sqltype := SqlVar.sqltype or 1;
      IbReAlloc(SqlVar.sqlind, 0, SizeOf(Short))
    end
    else
    begin
      //This code used when allocated sqlind parameter for Result SQLDA
      if (SqlVar.sqltype and 1) <> 0 then
        ReallocMem(SqlVar.sqlind, SizeOf(Short))
      else
        SqlVar.sqlind := nil;
    end;
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Clear allocated data for SQLDA paramters
}
procedure TZSQLDA.FreeParamtersValues;
var
  I: Integer;
  SqlVar: PXSQLVAR;
begin
  {$R-}
  for I := 0 to FXSQLDA.sqln - 1 do
  begin
    SqlVar := @FXSQLDA.SqlVar[I];
    FreeMem(SqlVar.sqldata);
    FreeMem(SqlVar.sqlind);
    SqlVar.sqldata := nil;
    SqlVar.sqlind := nil;
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Chech reange count fields. If index out of range raised exception.
   @param Index the index field
}
procedure TZSQLDA.CheckRange(const Index: Word);
begin
  Assert(Index < Word(FXSQLDA.sqln), 'Out of Range.');
end;

{**
   Return alias name for field
   @param Index the index fields
   @return the alias name
}
function TZSQLDA.GetFieldAliasName(const Index: Word): String;
begin
  CheckRange(Index);
  {$R-}
  SetString(Temp, FXSQLDA.sqlvar[Index].aliasname, FXSQLDA.sqlvar[Index].aliasname_length);
  Result := ZDbcString(Temp);
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return pointer to SQLDA structure
}
function TZSQLDA.GetData: PXSQLDA;
begin
  result := FXSQLDA;
end;

{**
   Get fields count not allocated.
   @return fields count
}
function TZSQLDA.GetFieldCount: Integer;
begin
  Result := FXSQLDA.sqld;
end;

{**
   Return field index by it name
   @param Index the index fields
   @return the index field
}
function TZSQLDA.GetFieldIndex(const Name: AnsiString): Word;
begin
  {$R-}
  for Result := 0 to GetFieldCount - 1 do
    if FXSQLDA.sqlvar[Result].aliasname_length = Length(name) then
      if {$IFDEF WITH_STRLICOPY_DEPRECATED}AnsiStrings.{$ENDIF}StrLIComp(@FXSQLDA.sqlvar[Result].aliasname, PAnsiChar(Name), FXSQLDA.sqlvar[Result].aliasname_length) = 0 then
        Exit;
  raise Exception.Create(Format(SFieldNotFound1, [name]));
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return field length
   @param Index the index fields
   @return the field lenth
}
function TZSQLDA.GetFieldLength(const Index: Word): SmallInt;
begin
  {$R-}
  case GetIbSqlType(Index) of
    SQL_TEXT: Result := GetIbSqlLen(Index);
    SQL_VARYING: Result := GetIbSqlLen(Index);
    //SQL_VARYING: Result := FPlainDriver.isc_vax_integer(GetData.sqlvar[Index].sqldata, 2);  //AVZ
    else
      Result := GetIbSqlLen(Index);
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return field scale
   @param Index the index fields
   @return the field scale
}
function TZSQLDA.GetFieldScale(const Index: Word): integer;
begin
  CheckRange(Index);
  {$R-}
  Result := Abs(FXSQLDA.sqlvar[Index].sqlscale);
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Convert Interbase sql type to SQLType
   @param Index the index fields
   @return the SQLType
}
function TZSQLDA.GetFieldSqlType(const Index: Word): TZSQLType;
var
  SqlScale: Integer;
  SqlSubType: Integer;
begin
  SqlScale := GetFieldScale(Index);
  SqlSubType := GetIbSqlSubType(Index);

  case GetIbSqlType(Index) of
    SQL_VARYING, SQL_TEXT:
      case SqlSubType of
        1: {Octets} Result := stBytes;
        else
          Result := stString;
      end;
    SQL_LONG:
      begin
        if SqlScale = 0 then
          Result := stInteger
        else
          Result := stDouble;
      end;
    SQL_SHORT:
      begin
        if SqlScale = 0 then
          Result := stShort
        else
          Result := stFloat; //Numeric with low precision
       end;
    SQL_FLOAT: Result := stFloat;
    SQL_DOUBLE: Result := stDouble;
    SQL_DATE: Result := stTimestamp;
    SQL_TYPE_TIME: Result := stTime;
    SQL_TYPE_DATE: Result := stDate;
    SQL_INT64:
      begin
        if SqlScale = 0 then
          Result := stLong
        else if Abs(SqlScale) <= 4 then
          Result := stDouble
        else
          Result := stBigDecimal;
      end;
    SQL_QUAD, SQL_ARRAY, SQL_BLOB:
      begin
        if SqlSubType = isc_blob_text then
          Result := stAsciiStream
        else
          Result := stBinaryStream;
      end;
    //SQL_ARRAY: Result := stBytes;
  else
      Result := stString;
  end;
  if ( ConSettings.CPType = cCP_UTF16 ) then
    case result of
      stString: Result := stUnicodeString;
      stAsciiStream: Result := stUnicodeStream;
    end;
end;

{**
   Return own name for field
   @param Index the index fields
   @return the own name
}
function TZSQLDA.GetFieldOwnerName(const Index: Word): String;
begin
  CheckRange(Index);
  {$R-}
  {$IFDEF WITH_RAWBYTESTRING}
  SetLength(Temp, FXSQLDA.sqlvar[Index].OwnName_length);
  System.Move(FXSQLDA.sqlvar[Index].OwnName, PAnsiChar(Temp)^, FXSQLDA.sqlvar[Index].OwnName_length);
  {$ELSE}
  SetString(Temp, FXSQLDA.sqlvar[Index].OwnName, FXSQLDA.sqlvar[Index].OwnName_length);
  {$ENDIF}
  Result := ZDbcString(Temp);
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return real name for field
   @param Index the index fields
   @return the real name
}
function TZSQLDA.GetFieldRelationName(const Index: Word): String;
begin
  CheckRange(Index);
  {$R-}
    {$IFDEF WITH_RAWBYTESTRING}
    SetLength(Temp, FXSQLDA.sqlvar[Index].RelName_length);
    System.Move(FXSQLDA.sqlvar[Index].RelName, PAnsiChar(Temp)^, FXSQLDA.sqlvar[Index].RelName_length);
    {$ELSE}
    SetString(Temp, FXSQLDA.sqlvar[Index].RelName, FXSQLDA.sqlvar[Index].RelName_length);
    {$ENDIF}
    Result := ZDbcString(Temp);
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Get Interbase sql fields lenth
   @param Index the index fields
   @return Interbase sql fields lenth
}
function TZSQLDA.GetIbSqlLen(const Index: Word): Smallint;
begin
  CheckRange(Index);
  {$R-}
  result := FXSQLDA.sqlvar[Index].sqllen;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return sql name for field
   @param Index the index fields
   @return the sql name
}
function TZSQLDA.GetFieldSqlName(const Index: Word): String;
begin
  CheckRange(Index);
  {$R-}
    {$IFDEF WITH_RAWBYTESTRING}
    SetLength(Temp, FXSQLDA.sqlvar[Index].sqlname_length);
    System.Move(FXSQLDA.sqlvar[Index].sqlname, PAnsiChar(Temp)^, FXSQLDA.sqlvar[Index].sqlname_length);
    {$ELSE}
    SetString(Temp, FXSQLDA.sqlvar[Index].sqlname, FXSQLDA.sqlvar[Index].sqlname_length);
    {$ENDIF}
    Result := ZDbcString(Temp);
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Get Interbase subsql type
   @param Index the index fields
   @return the Interbase subsql
}
function TZSQLDA.GetIbSqlSubType(const Index: Word): Smallint;
begin
  CheckRange(Index);
  {$R-}
  result := FXSQLDA.sqlvar[Index].sqlsubtype;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Get Interbase sql type
   @param Index the index fields
   @return the interbase sql type
}
function TZSQLDA.GetIbSqlType(const Index: Word): Smallint;
begin
  CheckRange(Index);
  {$R-}
  result := FXSQLDA.sqlvar[Index].sqltype and not (1);
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Reallocate memory and fill memory by #0
   @param pointer to memory block
   @param old size of memory block
   @param new size of memory block
}
procedure TZSQLDA.IbReAlloc(var P; OldSize, NewSize: Integer);
begin
  ReallocMem(Pointer(P), NewSize);
  if NewSize > OldSize then
      Fillchar((PAnsiChar(P) + OldSize)^, NewSize - OldSize, #0);
end;

procedure TZSQLDA.SetFieldType(const Index: Word; Size: Integer; Code: Smallint;
  Scale: Smallint);
begin
  CheckRange(Index);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    sqltype := Code;
    if Scale <= 0 then
      sqlscale := Scale;
    sqllen := Size;
    if (Size > 0) then
      IbReAlloc(sqldata, 0, Size)
    else
    begin
      FreeMem(sqldata);
      sqldata := nil;
    end;
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Indicate blob field
   @param Index the index fields
   @return true if blob field overwise false
}
function TZSQLDA.IsBlob(const Index: Word): boolean;
begin
  CheckRange(Index);
  {$R-}
  result := ((FXSQLDA.sqlvar[Index].sqltype and not(1)) = SQL_BLOB);
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Indicate blob field
   @param Index the index fields
   @return true if field nullable overwise false
}
function TZSQLDA.IsNullable(const Index: Word): boolean;
begin
  CheckRange(Index);
  {$R-}
  Result := FXSQLDA.sqlvar[Index].sqltype and 1 = 1
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Reallocate SQLDA to fields count length
   @param Value the count fields
}
procedure TZSQLDA.AllocateSQLDA;
begin
  IbReAlloc(FXSQLDA, XSQLDA_LENGTH(FXSQLDA.sqln), XSQLDA_LENGTH(FXSQLDA.sqld));
  FXSQLDA.sqln := FXSQLDA.sqld;
end;

{ TParamsSQLDA }

{**
   Free allocated memory and free object
}
destructor TZParamsSQLDA.Destroy;
begin
  FreeParamtersValues;
  FreeMem(FXSQLDA);
  inherited Destroy;
end;

{**
   Encode pascal string to Interbase paramter buffer
   @param Code the Interbase data type
   @param Index the index target filed
   @param Str the source string
}

procedure TZParamsSQLDA.EncodeString(Code: Smallint; const Index: Word;
  const Str: RawByteString);
var
  Len: Cardinal;
begin
  Len := Length(Str);
  {$R-}
   with FXSQLDA.sqlvar[Index] do
    case Code of
      SQL_TEXT :
        begin
          if (sqllen = 0) and (Str <> '') then //Manits: #0000249/pktfag
            GetMem(sqldata, Len)
          else
            IbReAlloc(sqldata, 0, Len + 1);
          sqllen := Len;
          Move(PAnsiChar(Str)^, sqldata^, sqllen);
        end;
      SQL_VARYING :
        begin
          sqllen := Len + 2;
          if sqllen = 0 then   //Egonhugeist: Todo: Need test case. Can't believe this line is correct! sqllen is min 2
            GetMem(sqldata, Len + 2)
          else
            IbReAlloc(sqldata, 0, Len + 2);
          PISC_VARYING(sqldata).strlen :=  Len;
          Move(PAnsiChar(Str)^, PISC_VARYING(sqldata).str, PISC_VARYING(sqldata).strlen);
        end;
    end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Encode Bytes dynamic array to Interbase paramter buffer
   @param Code the Interbase data type
   @param Index the index target filed
   @param Value the source array
}

procedure TZParamsSQLDA.EncodeBytes(Code: Smallint; const Index: Word;
  const Value: TByteDynArray);
var
  Len: Cardinal;
begin
  Len := Length(Value);
  {$R-}
   with FXSQLDA.sqlvar[Index] do
    case Code of
      SQL_TEXT :
        begin
          if (sqllen = 0) and ( Len <> 0 ) then //Manits: #0000249/pktfag
            GetMem(sqldata, Len)
          else
            IbReAlloc(sqldata, 0, Len + 1);
          sqllen := Len;
          Move(Pointer(Value)^, sqldata^, sqllen);
        end;
      SQL_VARYING :
        begin
          sqllen := Len + 2;
          if sqllen = 0 then   //Egonhugeist: Todo: Need test case. Can't believe this line is correct! sqllen is min 2
            GetMem(sqldata, Len + 2)
          else
            IbReAlloc(sqldata, 0, Len + 2);
          PISC_VARYING(sqldata).strlen :=  Len;
          Move(Pointer(Value)^, PISC_VARYING(sqldata).str, PISC_VARYING(sqldata).strlen);
        end;
    end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter BigDecimal value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateBigDecimal(const Index: Integer; Value: Extended);
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);

  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    if (sqlind <> nil) and (sqlind^ = -1) then
       Exit;

    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin //http://code.google.com/p/fbclient/wiki/DatatypeMapping
      case SQLCode of
        SQL_SHORT  : PSmallInt(sqldata)^ := Trunc(Value * IBScaleDivisor[sqlscale]);
        SQL_LONG   : PInteger(sqldata)^  := Trunc(Value * IBScaleDivisor[sqlscale]);
        SQL_INT64,
        SQL_QUAD   : //PInt64(sqldata)^    := Trunc(Value * GetIBScaleDivisor(sqlscale)); EgonHugeist: Trunc seems to have rounding issues!
            //remain issues if decimal digits > scale than we've school learned rounding success randomly only
            //each aproach did fail: RoundTo(Value, sqlscale*-1), Round etc.
            //so the developer has to take
            PInt64(sqldata)^    := StrToInt64(FloatToStrF(RoundTo(Value, sqlscale) * GetIBScaleDivisor(sqlscale), ffFixed, 18, 0));
        SQL_DOUBLE : PDouble(sqldata)^   := Value;                                        //I have tested with Query.ParamByName ().AsCurrency to check this, problem does not lie with straight SQL
      else
        raise EZIBConvertError.Create(SUnsupportedDataType);
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : PDouble(sqldata)^   := Value;
        SQL_LONG      : PInteger(sqldata)^ := Trunc(Value);
        SQL_D_FLOAT,
        SQL_FLOAT     : PSingle(sqldata)^ := Value;
        SQL_BOOLEAN   : PSmallint(sqldata)^ := Trunc(Value);
        SQL_SHORT     : PSmallint(sqldata)^ := Trunc(Value);
        SQL_INT64     : PInt64(sqldata)^ := Trunc(Value);
        SQL_TEXT      : EncodeString(SQL_TEXT, Index, AnsiString(FloatToStr(Value)));
        SQL_VARYING   : EncodeString(SQL_VARYING, Index, AnsiString(FloatToStr(Value)));
      else
        raise EZIBConvertError.Create(SUnsupportedDataType);
      end;
    if (sqlind <> nil) then
       sqlind^ := 0; // not null
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter Boolean value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateBoolean(const Index: Integer; Value: boolean);
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    if (sqlind <> nil) and (sqlind^ = -1) then
       Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : PSmallInt(sqldata)^ := ord(Value) * IBScaleDivisor[sqlscale];
        SQL_LONG   : PInteger(sqldata)^  := ord(Value) * IBScaleDivisor[sqlscale];
        SQL_INT64,
        SQL_QUAD   : PInt64(sqldata)^    := ord(Value) * IBScaleDivisor[sqlscale];
        SQL_DOUBLE : PDouble(sqldata)^   := ord(Value);
      else
        raise EZIBConvertError.Create(SUnsupportedParameterType);
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : PDouble(sqldata)^   := ord(Value);
        SQL_LONG      : PInteger(sqldata)^ := ord(Value);
        SQL_D_FLOAT,
        SQL_FLOAT     : PSingle(sqldata)^ := ord(Value);
        SQL_BOOLEAN   : PSmallint(sqldata)^ := ord(Value);
        SQL_SHORT     : PSmallint(sqldata)^ := ord(Value);
        SQL_INT64     : PInt64(sqldata)^ := ord(Value);
        SQL_TEXT      : EncodeString(SQL_TEXT, Index, AnsiString(IntToStr(ord(Value))));
        SQL_VARYING   : EncodeString(SQL_VARYING, Index, AnsiString(IntToStr(ord(Value))));
      else
        raise EZIBConvertError.Create(SUnsupportedParameterType);
      end;
    if (sqlind <> nil) then
       sqlind^ := 0; // not null
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter Byte value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateByte(const Index: Integer; Value: ShortInt);
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  SetFieldType(Index, sizeof(Smallint), SQL_SHORT + 1, 0);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    if (sqlind <> nil) and (sqlind^ = -1) then
       Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : PSmallInt(sqldata)^ := Value * IBScaleDivisor[sqlscale];
        SQL_LONG   : PInteger(sqldata)^  := Value * IBScaleDivisor[sqlscale];
        SQL_INT64,
        SQL_QUAD   : PInt64(sqldata)^    := Value * IBScaleDivisor[sqlscale];
        SQL_DOUBLE : PDouble(sqldata)^   := Value;
      else
        raise EZIBConvertError.Create(SUnsupportedParameterType);
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : PDouble(sqldata)^   := Value;
        SQL_LONG      : PInteger(sqldata)^ := Value;
        SQL_D_FLOAT,
        SQL_FLOAT     : PSingle(sqldata)^ := Value;
        SQL_BOOLEAN:
                     begin
                       if FPlainDriver.GetProtocol <> 'interbase-7' then
                         raise EZIBConvertError.Create(SUnsupportedDataType);
                       PSmallint(sqldata)^ := Value;
                     end;
        SQL_SHORT     : PSmallint(sqldata)^ := Value;
        SQL_INT64     : PInt64(sqldata)^ := Value;
        SQL_TEXT      : EncodeString(SQL_TEXT, Index, AnsiString(IntToStr(Value)));
        SQL_VARYING   : EncodeString(SQL_VARYING, Index, AnsiString(IntToStr(Value)));
      else
        raise EZIBConvertError.Create(SUnsupportedParameterType);
      end;
    if (sqlind <> nil) then
       sqlind^ := 0; // not null
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter byte value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateBytes(const Index: Integer; Value: TByteDynArray);
var
 SQLCode: SmallInt;
 Stream: TStream;
 Len: Integer;
begin
  CheckRange(Index);
//  SetFieldType(Index, Length(Value) + 1, SQL_TEXT + 1, 0);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));
    case SQLCode of
      SQL_TEXT      : EncodeBytes(SQL_TEXT, Index, Value);
      SQL_VARYING   : EncodeBytes(SQL_VARYING, Index, Value);
      SQL_LONG      : PInteger (sqldata)^ := Round(ZStrToFloat(BytesToStr(Value)) * IBScaleDivisor[sqlscale]); //AVZ
      SQL_SHORT     : PInteger (sqldata)^ := StrToInt(String(BytesToStr(Value)));
      SQL_TYPE_DATE : EncodeString(SQL_DATE, Index, BytesToStr(Value));
      SQL_DOUBLE    : PDouble (sqldata)^ := ZStrToFloat(BytesToStr(Value)) * IBScaleDivisor[sqlscale]; //AVZ
      SQL_D_FLOAT,
      SQL_FLOAT     : PSingle (sqldata)^ := ZStrToFloat(BytesToStr(Value)) * IBScaleDivisor[sqlscale];  //AVZ
      SQL_INT64     : PInt64(sqldata)^ := Trunc(ZStrToFloat(BytesToStr(Value)) * IBScaleDivisor[sqlscale]); //AVZ - INT64 value was not recognized
      SQL_BLOB, SQL_QUAD:
        begin
          Stream := TMemoryStream.Create;
          try
            Len := Length(Value);
            Stream.Size := Len;
            System.Move(Pointer(Value)^, TMemoryStream(Stream).Memory^, Len);
            WriteBlob(index, Stream);
          finally
            Stream.Free;
          end;
        end;
    else
      raise EZIBConvertError.Create(SErrorConvertion);
    end;
    if (sqlind <> nil) then
         sqlind^ := 0; // not null
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter Date value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateDate(const Index: Integer; Value: TDateTime);
begin
  SetFieldType(Index, sizeof(Integer), SQL_TYPE_DATE + 1, 0);
  UpdateDateTime(Index, Value);
end;

{**
   Set up parameter DateTime value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateDateTime(const Index: Integer;
  Value: TDateTime);
var
  y, m, d: word;
  hr, min, sec, msec: word;
  SQLCode: SmallInt;
  TmpDate: TCTimeStructure;
begin
  CheckRange(Index);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    DecodeDate(Value, y, m, d);
    DecodeTime(Value, hr, min, sec, msec);
    TmpDate.tm_year := y - 1900;
    TmpDate.tm_mon := m - 1;
    TmpDate.tm_mday := d;
    TmpDate.tm_hour := hr;
    TmpDate.tm_min := min;
    TmpDate.tm_sec := sec;
    TmpDate.tm_wday := 0;
    TmpDate.tm_yday := 0;
    TmpDate.tm_isdst := 0;

    if (sqlind <> nil) and (sqlind^ = -1) then
       Exit;
    SQLCode := (sqltype and not(1));

    case SQLCode of
      SQL_TYPE_DATE : FPlainDriver.isc_encode_sql_date(@TmpDate, PISC_DATE(sqldata));
      SQL_TYPE_TIME : begin
                        FPlainDriver.isc_encode_sql_time(@TmpDate, PISC_TIME(sqldata));
                        PISC_TIME(sqldata)^ := PISC_TIME(sqldata)^ + msec*10;
                      end;
      SQL_TIMESTAMP : begin
                        FPlainDriver.isc_encode_timestamp(@TmpDate,PISC_TIMESTAMP(sqldata));
                        PISC_TIMESTAMP(sqldata).timestamp_time :=PISC_TIMESTAMP(sqldata).timestamp_time + msec*10;
                      end;
      else
        raise EZIBConvertError.Create(SInvalidState);
    end;
    if (sqlind <> nil) then
         sqlind^ := 0; // not null
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter Double value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateDouble(const Index: Integer; Value: Double);
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  SetFieldType(Index, sizeof(double), SQL_DOUBLE + 1, 0);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : PSmallInt(sqldata)^ := Trunc(Value * IBScaleDivisor[sqlscale]);
        SQL_LONG   : PInteger(sqldata)^  := Trunc(Value * IBScaleDivisor[sqlscale]);
        SQL_INT64,
        SQL_QUAD   : PInt64(sqldata)^    := Trunc(Value * IBScaleDivisor[sqlscale]);
        SQL_DOUBLE : PDouble(sqldata)^   := Value;
      else
        raise EZIBConvertError.Create(SUnsupportedDataType);
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : PDouble(sqldata)^   := Value;
        SQL_LONG      : PInteger(sqldata)^ := Trunc(Value);
        SQL_D_FLOAT,
        SQL_FLOAT     : PSingle(sqldata)^ := Value;
        SQL_BOOLEAN   : PSmallint(sqldata)^ := Trunc(Value);
        SQL_SHORT     : PSmallint(sqldata)^ := Trunc(Value);
        SQL_INT64     : PInt64(sqldata)^ := Trunc(Value);
        SQL_TEXT      : EncodeString(SQL_TEXT, Index, AnsiString(FloatToStr(Value)));
        SQL_VARYING   : EncodeString(SQL_VARYING, Index, AnsiString(FloatToStr(Value)));
      else
        raise EZIBConvertError.Create(SUnsupportedDataType);
      end;
      if (sqlind <> nil) then
         sqlind^ := 0; // not null
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter Float value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateFloat(const Index: Integer; Value: Single);
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  SetFieldType(Index, sizeof(Single), SQL_FLOAT + 1, 1);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    if (sqlind <> nil) and (sqlind^ = -1) then
       Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : PSmallInt(sqldata)^ := Trunc(Value * IBScaleDivisor[sqlscale]);
        SQL_LONG   : PInteger(sqldata)^  := Trunc(Value * IBScaleDivisor[sqlscale]);
        SQL_INT64,
        SQL_QUAD   : PInt64(sqldata)^    := Trunc(Value * IBScaleDivisor[sqlscale]);
        SQL_DOUBLE : PDouble(sqldata)^   := Value;
        SQL_D_FLOAT,
        SQL_FLOAT  : PSingle(sqldata)^   := Value;
      else
        raise EZIBConvertError.Create(SUnsupportedDataType);
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : PDouble(sqldata)^   := Value;
        SQL_LONG      : PInteger(sqldata)^ := Trunc(Value);
        SQL_D_FLOAT,
        SQL_FLOAT     : PSingle(sqldata)^ := Value;
        SQL_BOOLEAN   : PSmallint(sqldata)^ := Trunc(Value);
        SQL_SHORT     : PSmallint(sqldata)^ := Trunc(Value);
        SQL_INT64     : PInt64(sqldata)^ := Trunc(Value);
        SQL_TEXT      : EncodeString(SQL_TEXT, Index, AnsiString(FloatToStr(Value)));
        SQL_VARYING   : EncodeString(SQL_VARYING, Index, AnsiString(FloatToStr(Value)));
      else
        raise EZIBConvertError.Create(SUnsupportedDataType);
      end;
      if (sqlind <> nil) then
         sqlind^ := 0; // not null
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter integer value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateInt(const Index: Integer; Value: Integer);
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  SetFieldType(Index, sizeof(Integer), SQL_LONG + 1, 0);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    if (sqlind <> nil) and (sqlind^ = -1) then
       Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : PSmallInt(sqldata)^ := Value * IBScaleDivisor[sqlscale];
        SQL_LONG   : PInteger(sqldata)^  := Value * IBScaleDivisor[sqlscale];
        SQL_INT64,
        SQL_QUAD   : PInt64(sqldata)^    := Value * IBScaleDivisor[sqlscale];
        SQL_DOUBLE : PDouble(sqldata)^   := Value;
      else
        raise EZIBConvertError.Create(SUnsupportedDataType);
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : PDouble(sqldata)^   := Value;
        SQL_LONG      : PInteger(sqldata)^ := Value;
        SQL_D_FLOAT,
        SQL_FLOAT     : PSingle(sqldata)^ := Value;
        SQL_BOOLEAN   : PSmallint(sqldata)^ := Value;
        SQL_SHORT     : PSmallint(sqldata)^ := Value;
        SQL_INT64     : PInt64(sqldata)^ := Value;
        SQL_TEXT      : EncodeString(SQL_TEXT, Index, AnsiString(IntToStr(Value)));
        SQL_VARYING   : EncodeString(SQL_VARYING, Index, AnsiString(IntToStr(Value)));
      else
        raise EZIBConvertError.Create(SUnsupportedDataType);
      end;
      if (sqlind <> nil) then
         sqlind^ := 0; // not null
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter Long value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateLong(const Index: integer; Value: Int64);
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  SetFieldType(Index, sizeof(Int64), SQL_INT64 + 1, 0);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : PSmallInt(sqldata)^ := Value * IBScaleDivisor[sqlscale];
        SQL_LONG   : PInteger(sqldata)^  := Value * IBScaleDivisor[sqlscale];
        SQL_INT64,
        SQL_QUAD   : PInt64(sqldata)^    := Value * IBScaleDivisor[sqlscale];
        SQL_DOUBLE : PDouble(sqldata)^   := Value;
      else
        raise EZIBConvertError.Create(SUnsupportedDataType);
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : PDouble(sqldata)^   := Value;
        SQL_LONG      : PInteger(sqldata)^ := Value;
        SQL_D_FLOAT,
        SQL_FLOAT     : PSingle(sqldata)^ := Value;
        SQL_BOOLEAN   : PSmallint(sqldata)^ := Value;
        SQL_SHORT     : PSmallint(sqldata)^ := Value;
        SQL_INT64     : PInt64(sqldata)^ := Value;
        SQL_TEXT      : EncodeString(SQL_TEXT, Index, AnsiString(IntToStr(Value)));
        SQL_VARYING   : EncodeString(SQL_VARYING, Index, AnsiString(IntToStr(Value)));
      else
        raise EZIBConvertError.Create(SUnsupportedDataType);
      end;
      if (sqlind <> nil) then
         sqlind^ := 0; // not null
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter null value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateNull(const Index: Integer; Value: boolean);
begin
  CheckRange(Index);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
    if (sqlind <> nil) then
      case Value of
        True  : sqlind^ := -1; //NULL
        False : sqlind^ :=  0; //NOT NULL
      end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter PAnsiChar value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdatePChar(const Index: Integer; Value: PAnsiChar);
var
  TempString: AnsiString;
begin
  TempString := Value;
  UpdateString(Index, TempString);
end;

{**
   Set up parameter Interbase QUAD value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateQuad(const Index: Word; const Value: TISC_QUAD);
begin
  CheckRange(Index);
  SetFieldType(Index, sizeof(TISC_QUAD), SQL_QUAD + 1, 0);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
    if not ((sqlind <> nil) and (sqlind^ = -1)) then
    begin
      case (sqltype and not(1)) of
        SQL_QUAD, SQL_DOUBLE, SQL_INT64, SQL_BLOB, SQL_ARRAY: PISC_QUAD(sqldata)^ := Value;
      else
        raise EZIBConvertError.Create(SUnsupportedDataType);
      end;
      if (sqlind <> nil) then
          sqlind^ := 0; // not null
    end
    else
      raise EZIBConvertError.Create(SUnsupportedDataType);
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter short value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateShort(const Index: Integer; Value: SmallInt);
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  SetFieldType(Index, sizeof(Smallint), SQL_SHORT + 1, 0);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : PSmallInt(sqldata)^ := Value * IBScaleDivisor[sqlscale];
        SQL_LONG   : PInteger(sqldata)^  := Value * IBScaleDivisor[sqlscale];
        SQL_INT64,
        SQL_QUAD   : PInt64(sqldata)^    := Value * IBScaleDivisor[sqlscale];
        SQL_DOUBLE : PDouble(sqldata)^   := Value;
      else
        raise EZIBConvertError.Create(SUnsupportedDataType);
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : PDouble(sqldata)^   := Value;
        SQL_LONG      : PInteger(sqldata)^ := Value;
        SQL_D_FLOAT,
        SQL_FLOAT     : PSingle(sqldata)^ := Value;
        SQL_BOOLEAN   : PSmallint(sqldata)^ := Value;
        SQL_SHORT     : PSmallint(sqldata)^ := Value;
        SQL_INT64     : PInt64(sqldata)^ := Value;
        SQL_TEXT      : EncodeString(SQL_TEXT, Index, AnsiString(IntToStr(Value)));
        SQL_VARYING   : EncodeString(SQL_VARYING, Index, AnsiString(IntToStr(Value)));
      else
        raise EZIBConvertError.Create(SUnsupportedDataType);
      end;
      if (sqlind <> nil) then
         sqlind^ := 0; // not null
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter String value
   @param Index the target parameter index
   @param Value the source value
}

procedure TZParamsSQLDA.UpdateString(const Index: Integer; Value: RawByteString);
var
 SQLCode: SmallInt;
 Stream: TStream;
begin
  CheckRange(Index);
//  SetFieldType(Index, Length(Value) + 1, SQL_TEXT + 1, 0);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));
    case SQLCode of
      SQL_TEXT      : EncodeString(SQL_TEXT, Index, Value);
      SQL_VARYING   : EncodeString(SQL_VARYING, Index, Value);
      SQL_LONG      : PInteger (sqldata)^ := StrToInt(String(Value)); //AVZ
      SQL_SHORT     : PSmallInt (sqldata)^ := StrToInt(String(Value));
      SQL_TYPE_DATE : EncodeString(SQL_DATE, Index, Value);
      SQL_DOUBLE    : PDouble (sqldata)^ := ZStrToFloat(Value) * IBScaleDivisor[sqlscale]; //AVZ
      SQL_D_FLOAT,
      SQL_FLOAT     : PSingle (sqldata)^ := ZStrToFloat(Value) * IBScaleDivisor[sqlscale];  //AVZ
      SQL_INT64     : PInt64(sqldata)^ := Trunc(ZStrToFloat(Value) * IBScaleDivisor[sqlscale]); //AVZ - INT64 value was not recognized
      SQL_BLOB, SQL_QUAD:
        begin
          Stream := TStringStream.Create(Value);
          try
            WriteBlob(index, Stream);
          finally
            Stream.Free;
          end;
        end;
    else
      raise EZIBConvertError.Create(SErrorConvertion);
    end;
    if (sqlind <> nil) then
         sqlind^ := 0; // not null
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Set up parameter Time value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateTime(const Index: Integer; Value: TDateTime);
begin
  SetFieldType(Index, sizeof(Cardinal), SQL_TYPE_TIME + 1, 0);
  UpdateDateTime(Index, Value);
end;

{**
   Set up parameter Timestamp value
   @param Index the target parameter index
   @param Value the source value
}
procedure TZParamsSQLDA.UpdateTimestamp(const Index: Integer; Value: TDateTime);
begin
  SetFieldType(Index, sizeof(TISC_QUAD), SQL_TIMESTAMP + 1, 0);
  UpdateDateTime(Index, Value);
end;

{**
   Write stream to blob field
   @param Index an index field number
   @param Stream the souse data stream
}
procedure TZParamsSQLDA.WriteBlob(const Index: Integer; Stream: TStream);
var
  Buffer: PAnsiChar;
  BlobId: TISC_QUAD;
  BlobHandle: TISC_BLOB_HANDLE;
  StatusVector: TARRAY_ISC_STATUS;
  BlobSize, CurPos, SegLen: Integer;
begin
  BlobHandle := 0;
  Stream.Seek(0, 0);

  { create blob handle }
  FPlainDriver.isc_create_blob2(@StatusVector, FHandle, FTransactionHandle,
    @BlobHandle, @BlobId, 0, nil);
  CheckInterbase6Error(FPlainDriver, StatusVector);

  Stream.Position := 0;
  BlobSize := Stream.Size;
  Buffer := AllocMem(BlobSize);
  Try
    Stream.ReadBuffer(Buffer^, BlobSize);

    { put data to blob }
    CurPos := 0;
    SegLen := DefaultBlobSegmentSize;
    while (CurPos < BlobSize) do
    begin
      if (CurPos + SegLen > BlobSize) then
        SegLen := BlobSize - CurPos;
      if FPlainDriver.isc_put_segment(@StatusVector, @BlobHandle, SegLen,
            PAnsiChar(@Buffer[CurPos])) > 0 then
        CheckInterbase6Error(FPlainDriver, StatusVector);
      Inc(CurPos, SegLen);
    end;

    { close blob handle }
    FPlainDriver.isc_close_blob(@StatusVector, @BlobHandle);
    CheckInterbase6Error(FPlainDriver, StatusVector);

    Stream.Seek(0, 0);
    UpdateQuad(Index, BlobId);
  Finally
    Freemem(Buffer);
  End;
end;

{ TResultSQLDA }

{**
   Decode Interbase field value to pascal string
   @param Code the Interbase data type
   @param Index field index
   @result the field string
}
function TZResultSQLDA.DecodeString(const Code: Smallint;
   const Index: Word): RawByteString;
var
   l: integer;
  procedure SetAnsi(Ansi: PAnsiChar; Len: Longint);
  begin
    SetLength(Result, Len);
    System.Move(Ansi^, PAnsiChar(Result)^, Len);
  end;
begin
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  case Code of
    SQL_TEXT:
      begin
        SetAnsi(sqldata, sqllen);
        // Trim only spaces. TrimRight also removes other characters)
        l := sqllen;
        while (l > 0) and (Result[l] = ' ') do
           dec(l);
        if l < sqllen then
           result := copy(result, 1, l);
      end;
    SQL_VARYING : SetAnsi(PISC_VARYING(sqldata).str, PISC_VARYING(sqldata).strlen);
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Decode Interbase field value to pascal string
   @param Code the Interbase data type
   @param Index field index
   @param Str the field string
}
procedure TZResultSQLDA.DecodeString2(const Code: Smallint; const Index: Word;
  out Str: RawByteString);
begin
  Str := DecodeString(Code, Index);
end;

{**
   Return BigDecimal field value
   @param Index the field index
   @return the field BigDecimal value
}
function TZResultSQLDA.GetBigDecimal(const Index: Integer): Extended;
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    Result := 0;
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : Result := PSmallInt(sqldata)^ / IBScaleDivisor[sqlscale];
        SQL_LONG   : Result := PInteger(sqldata)^  / IBScaleDivisor[sqlscale];
        SQL_INT64,
        SQL_QUAD   : Result := PInt64(sqldata)^    / IBScaleDivisor[sqlscale];
        SQL_DOUBLE : Result := PDouble(sqldata)^;
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : Result := PDouble(sqldata)^;
        SQL_LONG      : Result := PInteger(sqldata)^;
        SQL_D_FLOAT,
        SQL_FLOAT     : Result := PSingle(sqldata)^;
        SQL_BOOLEAN   : Result := PSmallint(sqldata)^;
        SQL_SHORT     : Result := PSmallint(sqldata)^;
        SQL_INT64     : Result := PInt64(sqldata)^;
        SQL_TEXT      : Result := StrToFloat(String(DecodeString(SQL_TEXT, Index)));
        SQL_VARYING   : Result := StrToFloat(String(DecodeString(SQL_VARYING, Index)));
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
   end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return Boolean field value
   @param Index the field index
   @return the field boolean value
}
function TZResultSQLDA.GetBoolean(const Index: Integer): Boolean;
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    Result := False;
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : Result := PSmallInt(sqldata)^ div IBScaleDivisor[sqlscale] <> 0;
        SQL_LONG   : Result := PInteger(sqldata)^  div IBScaleDivisor[sqlscale] <> 0;
        SQL_INT64,
        SQL_QUAD   : Result := PInt64(sqldata)^    div IBScaleDivisor[sqlscale] <> 0;
        SQL_DOUBLE : Result := Trunc(PDouble(sqldata)^) > 0;
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : Result := Trunc(PDouble(sqldata)^) <> 0;
        SQL_LONG      : Result := PInteger(sqldata)^ <> 0;
        SQL_D_FLOAT,
        SQL_FLOAT     : Result := Trunc(PSingle(sqldata)^) <> 0;
        SQL_BOOLEAN   : Result := PSmallint(sqldata)^ <> 0;
        SQL_SHORT     : Result := PSmallint(sqldata)^ <> 0;
        SQL_INT64     : Result := PInt64(sqldata)^ <> 0;
        SQL_TEXT      : Result := StrToInt(String(DecodeString(SQL_TEXT, Index))) <> 0;
        SQL_VARYING   : Result := StrToInt(String(DecodeString(SQL_VARYING, Index))) <> 0;
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return Byte field value
   @param Index the field index
   @return the field Byte value
}
function TZResultSQLDA.GetByte(const Index: Integer): Byte;
begin
  Result := Byte(GetShort(Index));
end;

{**
   Return Bytes field value
   @param Index the field index
   @return the field Bytes value
}
function TZResultSQLDA.GetBytes(const Index: Integer): TByteDynArray;
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  Result := nil;
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));

      case SQLCode of
        SQL_TEXT, SQL_VARYING:
          begin
            SetLength(Result, sqllen);
            System.Move(PAnsiChar(sqldata)^, Pointer(Result)^, sqllen);
          end;
        else
          raise EZIBConvertError.Create(Format(SErrorConvertionField,
            [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return Date field value
   @param Index the field index
   @return the field Date value
}
function TZResultSQLDA.GetDate(const Index: Integer): TDateTime;
begin
  Result := Trunc(GetTimestamp(Index));
end;

{**
   Return Double field value
   @param Index the field index
   @return the field Double value
}
function TZResultSQLDA.GetDouble(const Index: Integer): Double;
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    Result := 0;
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : Result := PSmallInt(sqldata)^ / IBScaleDivisor[sqlscale];
        SQL_LONG   : Result := PInteger(sqldata)^  / IBScaleDivisor[sqlscale];
        SQL_INT64,
        SQL_QUAD   : Result := PInt64(sqldata)^    / IBScaleDivisor[sqlscale];
        SQL_DOUBLE : Result := PDouble(sqldata)^;
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : Result := PDouble(sqldata)^;
        SQL_LONG      : Result := PInteger(sqldata)^;
        SQL_D_FLOAT,
        SQL_FLOAT     : Result := PSingle(sqldata)^;
        SQL_BOOLEAN   : Result := PSmallint(sqldata)^;
        SQL_SHORT     : Result := PSmallint(sqldata)^;
        SQL_INT64     : Result := PInt64(sqldata)^;
        SQL_TEXT      : Result := StrToFloat(String(DecodeString(SQL_TEXT, Index)));
        SQL_VARYING   : Result := StrToFloat(String(DecodeString(SQL_VARYING, Index)));
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return Float field value
   @param Index the field index
   @return the field Float value
}
function TZResultSQLDA.GetFloat(const Index: Integer): Single;
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    Result := 0;
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : Result := PSmallInt(sqldata)^ / IBScaleDivisor[sqlscale];
        SQL_LONG   : Result := PInteger(sqldata)^  / IBScaleDivisor[sqlscale];
        SQL_INT64,
        SQL_QUAD   : Result := PInt64(sqldata)^    / IBScaleDivisor[sqlscale];
        SQL_DOUBLE : Result := PDouble(sqldata)^;
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : Result := PDouble(sqldata)^;
        SQL_LONG      : Result := PInteger(sqldata)^;
        SQL_D_FLOAT,
        SQL_FLOAT     : Result := PSingle(sqldata)^;
        SQL_BOOLEAN   : Result := PSmallint(sqldata)^;
        SQL_SHORT     : Result := PSmallint(sqldata)^;
        SQL_INT64     : Result := PInt64(sqldata)^;
        SQL_TEXT      : Result := StrToFloat(String(DecodeString(SQL_TEXT, Index)));
        SQL_VARYING   : Result := StrToFloat(String(DecodeString(SQL_VARYING, Index)));
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return Integer field value
   @param Index the field index
   @return the field Integer value
}
function TZResultSQLDA.GetInt(const Index: Integer): Integer;
begin
  Result := Integer(GetLong(Index));
end;

{**
   Return Long field value
   @param Index the field index
   @return the field Long value
}
function TZResultSQLDA.GetLong(const Index: Integer): Int64;
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    Result := 0;
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : Result := PSmallInt(sqldata)^ div IBScaleDivisor[sqlscale];
        SQL_LONG   : Result := PInteger(sqldata)^  div IBScaleDivisor[sqlscale];
        SQL_INT64,
        SQL_QUAD   : Result := PInt64(sqldata)^    div IBScaleDivisor[sqlscale];
        SQL_DOUBLE : Result := Trunc(PDouble(sqldata)^);
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : Result := Trunc(PDouble(sqldata)^);
        SQL_LONG      : Result := PInteger(sqldata)^;
        SQL_D_FLOAT,
        SQL_FLOAT     : Result := Trunc(PSingle(sqldata)^);
        SQL_BOOLEAN   : Result := PSmallint(sqldata)^;
        SQL_SHORT     : Result := PSmallint(sqldata)^;
        SQL_INT64     : Result := PInt64(sqldata)^;
        SQL_TEXT      : Result := StrToInt(String(DecodeString(SQL_TEXT, Index)));
        SQL_VARYING   : Result := StrToInt(String(DecodeString(SQL_VARYING, Index)));
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return PAnsiChar field value
   @param Index the field index
   @return the field PAnsiChar value
}
function TZResultSQLDA.GetPChar(const Index: Integer): PChar;
var
  TempStr: String;
begin
  TempStr := ZDbcString(GetString(Index));
  Result := PChar(TempStr);
end;

{**
   Return Short field value
   @param Index the field index
   @return the field Short value
}
function TZResultSQLDA.GetShort(const Index: Integer): SmallInt;
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    Result := 0;
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : Result := PSmallInt(sqldata)^ div IBScaleDivisor[sqlscale];
        SQL_LONG   : Result := PInteger(sqldata)^  div IBScaleDivisor[sqlscale];
        SQL_INT64,
        SQL_QUAD   : Result := PInt64(sqldata)^    div IBScaleDivisor[sqlscale];
        SQL_DOUBLE : Result := Trunc(PDouble(sqldata)^);
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : Result := Trunc(PDouble(sqldata)^);
        SQL_LONG      : Result := PInteger(sqldata)^;
        SQL_D_FLOAT,
        SQL_FLOAT     : Result := Trunc(PSingle(sqldata)^);
        SQL_BOOLEAN   : Result := PSmallint(sqldata)^;
        SQL_SHORT     : Result := PSmallint(sqldata)^;
        SQL_INT64     : Result := PInt64(sqldata)^;
        SQL_TEXT      : Result := StrToInt(String(DecodeString(SQL_TEXT, Index)));
        SQL_VARYING   : Result := StrToInt(String(DecodeString(SQL_VARYING, Index)));
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return String field value
   @param Index the field index
   @return the field String value
}
function TZResultSQLDA.GetString(const Index: Integer): RawByteString;
var
  SQLCode: SmallInt;
  TempAnsi: AnsiString;
begin
  CheckRange(Index);
  Result := '';
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : Result := RawByteString(FloatToStr(PSmallInt(sqldata)^ / IBScaleDivisor[sqlscale]));
        SQL_LONG   : Result := RawByteString(FloatToStr(PInteger(sqldata)^  / IBScaleDivisor[sqlscale]));
        SQL_INT64,
        SQL_QUAD   : Result := RawByteString(FloatToStr(PInt64(sqldata)^    / IBScaleDivisor[sqlscale]));
        SQL_DOUBLE : Result := RawByteString(FloatToStr(PDouble(sqldata)^));
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : Result := RawByteString(FloatToStr(PDouble(sqldata)^));
        SQL_LONG      : Result := RawByteString(IntToStr(PInteger(sqldata)^));
        SQL_D_FLOAT,
        SQL_FLOAT     : Result := RawByteString(FloatToStr(PSingle(sqldata)^));
        SQL_BOOLEAN   :
          if Boolean(PSmallint(sqldata)^) = True then
            Result := 'YES'
          else
            Result := 'NO';
        SQL_SHORT     : Result := RawByteString(IntToStr(PSmallint(sqldata)^));
        SQL_INT64     : Result := RawByteString(IntToStr(PInt64(sqldata)^));
        SQL_TEXT      : DecodeString2(SQL_TEXT, Index, Result);
        SQL_VARYING   : DecodeString2(SQL_VARYING, Index, Result);
        SQL_BLOB      : if VarIsEmpty(FDefaults[Index]) then
                        begin
                          ReadBlobFromString(Index, TempAnsi);
                          FDefaults[Index] := TempAnsi;
                        end
                        else
                          Result := {$IFDEF WITH_FPC_STRING_CONVERSATION}AnsiString{$ELSE}RawByteString{$ENDIF}(FDefaults[Index]);

      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
  end;
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return Time field value
   @param Index the field index
   @return the field Time value
}
function TZResultSQLDA.GetTime(const Index: Integer): TDateTime;
begin
  Result := Frac(GetTimestamp(Index));
end;

{**
   Return Timestamp field value
   @param Index the field index
   @return the field Timestamp value
}
function TZResultSQLDA.GetTimestamp(const Index: Integer): TDateTime;
var
  TempDate: TCTimeStructure;
begin
  CheckRange(Index);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  begin
    Result := 0;
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;

    case (sqltype and not(1)) of
        SQL_TIMESTAMP : begin
                          FPlainDriver.isc_decode_timestamp(PISC_TIMESTAMP(sqldata), @TempDate);
                          Result := SysUtils.EncodeDate(TempDate.tm_year + 1900,
                            TempDate.tm_mon + 1, TempDate.tm_mday) + EncodeTime(TempDate.tm_hour,
                          TempDate.tm_min, TempDate.tm_sec, Word((PISC_TIMESTAMP(sqldata).timestamp_time mod 10000) div 10));
                        end;
        SQL_TYPE_DATE : begin
                          FPlainDriver.isc_decode_sql_date(PISC_DATE(sqldata), @TempDate);
                          Result := SysUtils.EncodeDate(Word(TempDate.tm_year + 1900),
                            Word(TempDate.tm_mon + 1), Word(TempDate.tm_mday));
                        end;
        SQL_TYPE_TIME : begin
                          FPlainDriver.isc_decode_sql_time(PISC_TIME(sqldata), @TempDate);
                          Result := SysUtils.EncodeTime(Word(TempDate.tm_hour), Word(TempDate.tm_min),
                            Word(TempDate.tm_sec),  Word((PISC_TIME(sqldata)^ mod 10000) div 10));
                        end;
        else
          Result := Trunc(GetDouble(Index));
        end;
  end;
 {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Indicate field null
   @param Index the field index
   @return true if fied value NULL overwise false
}
function TZResultSQLDA.IsNull(const Index: Integer): Boolean;
begin
  CheckRange(Index);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
    Result := (sqlind <> nil) and (sqlind^ = ISC_NULL);
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return Interbase QUAD field value
   @param Index the field index
   @return the field Interbase QUAD value
}
function TZResultSQLDA.GetQuad(const Index: Integer): TISC_QUAD;
begin
  CheckRange(Index);
  {$R-}
  with FXSQLDA.sqlvar[Index] do
  if not ((sqlind <> nil) and (sqlind^ = -1)) then
    case (sqltype and not(1)) of
      SQL_QUAD, SQL_DOUBLE, SQL_INT64, SQL_BLOB, SQL_ARRAY: result := PISC_QUAD(sqldata)^;
    else
      raise EZIBConvertError.Create(SUnsupportedDataType + ' ' + inttostr((sqltype and not(1))));
    end
  else
    raise EZIBConvertError.Create('Invalid State.');
  {$IFOPT D+}
{$R+}
{$ENDIF}
end;

{**
   Return Variant field value
   @param Index the field index
   @return the field Variant value
}
function TZResultSQLDA.GetValue(const Index: Word): Variant;
var
  SQLCode: SmallInt;
begin
  CheckRange(Index);
  with FXSQLDA.sqlvar[Index] do
  begin
    VarClear(Result);
    if (sqlind <> nil) and (sqlind^ = -1) then
         Exit;
    SQLCode := (sqltype and not(1));

    if (sqlscale < 0)  then
    begin
      case SQLCode of
        SQL_SHORT  : Result := PSmallInt(sqldata)^ / IBScaleDivisor[sqlscale];
        SQL_LONG   : Result := PInteger(sqldata)^  / IBScaleDivisor[sqlscale];
        SQL_INT64,
        SQL_QUAD   : Result := PInt64(sqldata)^    / IBScaleDivisor[sqlscale];
        SQL_DOUBLE : Result := PDouble(sqldata)^;
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
    end
    else
      case SQLCode of
        SQL_DOUBLE    : Result := PDouble(sqldata)^;
        SQL_TIMESTAMP : Result := GetTimestamp(Index);
        SQL_TYPE_DATE : Result := GetDate(Index);
        SQL_TYPE_TIME : Result := GetTime(Index);
        SQL_LONG      : Result := PInteger(sqldata)^;
        SQL_D_FLOAT,
        SQL_FLOAT     : Result := PSingle(sqldata)^;
        SQL_BOOLEAN:
                     begin
                       if FPlainDriver.GetProtocol <> 'interbase-7' then
                         raise EZIBConvertError.Create(SUnsupportedDataType);
                       Result := IntToStr(PSmallint(sqldata)^);
                     end;
        SQL_SHORT     : Result := PSmallint(sqldata)^;
        SQL_INT64     : Result := PInt64(sqldata)^;
        SQL_TEXT      : Result := DecodeString(SQL_TEXT, Index);
        SQL_VARYING   : Result := DecodeString(SQL_VARYING, Index);
        SQL_BLOB      : if VarIsEmpty(FDefaults[Index]) then
                        begin
                          ReadBlobFromVariant(Index, FDefaults[Index]);
                          Result := FDefaults[Index];
                        end
                        else
                          Result := Double(FDefaults[Index]);
      else
        raise EZIBConvertError.Create(Format(SErrorConvertionField,
          [GetFieldAliasName(Index), GetNameSqlType(SQLCode)]));
      end;
  end;
end;

destructor TZResultSQLDA.Destroy;
begin
  FreeParamtersValues;
  FreeMem(FXSQLDA);
  inherited Destroy;
end;

{**
   Read blob data to string
   @param Index an filed index
   @param Str destination string
}
procedure TZResultSQLDA.ReadBlobFromString(const Index: Word; var Str: AnsiString);
var
  Size: LongInt;
  Buffer: Pointer;
begin
  ReadBlobBufer(FPlainDriver, FHandle, FTransactionHandle, GetQuad(Index),
    Size, Buffer);
  try
    SetLength(Str, Size);
    SetString(Str, PAnsiChar(Buffer), Size);
  finally
    FreeMem(Buffer, Size);
  end;
end;

{**
   Read blob data to stream
   @param Index an filed index
   @param Stream destination stream object
}
procedure TZResultSQLDA.ReadBlobFromStream(const Index: Word; Stream: TStream);
var
  Size: LongInt;
  Buffer: Pointer;
begin
  ReadBlobBufer(FPlainDriver, FHandle, FTransactionHandle, GetQuad(Index),
    Size, Buffer);
  try
    Stream.Seek(0, 0);
    Stream.Write(Buffer^, Size);
    Stream.Seek(0, 0);
  finally
    FreeMem(Buffer, Size);
  end;
end;

{**
   Read blob data to variant value
   @param Index an filed index
   @param Value destination variant value
}
procedure TZResultSQLDA.ReadBlobFromVariant(const Index: Word;
  var Value: Variant);
var
  Size: LongInt;
  Buffer: Pointer;
  PData: Pointer;
begin
  ReadBlobBufer(FPlainDriver, FHandle, FTransactionHandle, GetQuad(Index),
    Size, Buffer);
  Value := VarArrayCreate([0, Size-1], varByte);
  PData := VarArrayLock(Value);
  try
    move(Buffer^, PData^, Size);
  finally
    VarArrayUnlock(Value);
    FreeMem(Buffer, Size);
  end;
end;

procedure TZResultSQLDA.AllocateSQLDA;
begin
  inherited AllocateSQLDA;
  SetLength(FDefaults, GetFieldCount);
end;


end.

