
Program LORD_Patcher;

{$MODE DELPHI}
{$APPTYPE GUI}

Uses 
Windows, CommDlg;

Const 
  EDT_PATH   = 101;
  BTN_BROWSE = 102;
  BTN_PATCH  = 103;
  MEMO_LOG   = 104;

  WND_W = 480;
  WND_H = 350;



{ Single-byte patch — reversed from lordcfg.exe registration check at virtual CS:0x1BBD
    mov byte ptr [0x218], 0  →  mov byte ptr [0x218], 1
    Changes the "keys don't match → unregistered" path to also write 1 (registered).
    Any 5 numbers entered will pass. }
  PATCH_OFFSET = $749D;

{ ── Helpers ── }

Procedure LogLine(hMemo: HWND; Const S: AnsiString);

Var Len: Integer;
Begin
  Len := GetWindowTextLengthA(hMemo);
  SendMessageA(hMemo, EM_SETSEL, Len, Len);
  SendMessageA(hMemo, EM_REPLACESEL, 0, LPARAM(PAnsiChar(S + #13#10)));
End;

Function ByteToHex(B: Byte): AnsiString;

Const Hex: AnsiString = '0123456789ABCDEF';
Begin
  Result := '$' + Hex[(B shr 4) + 1] + Hex[(B And $F) + 1];
End;

Function BrowseForFile(hOwner: HWND; out Path: AnsiString): Boolean;

Var 
  OFN : TOpenFilenameA;
  Buf : array[0..MAX_PATH] Of AnsiChar;
Begin
  Result := False;
  ZeroMemory(@OFN, SizeOf(OFN));
  ZeroMemory(@Buf, SizeOf(Buf));
  OFN.lStructSize := SizeOf(OFN);
  OFN.hwndOwner   := hOwner;
  OFN.lpstrFilter := 'EXE Files'#0'*.exe'#0'All Files'#0'*.*'#0#0;
  OFN.lpstrFile   := Buf;
  OFN.nMaxFile    := MAX_PATH;
  OFN.lpstrTitle  := 'Select LORDCFG.EXE';
  OFN.Flags       := OFN_FILEMUSTEXIST Or OFN_PATHMUSTEXIST Or OFN_HIDEREADONLY;
  If GetOpenFileNameA(@OFN) Then
    Begin
      Path   := AnsiString(Buf);
      Result := True;
    End;
End;

Function FileReadBytes(Const Path: AnsiString; Offset: DWORD;
                       Var Buf: Array Of Byte; Count: Integer): Boolean;

Var 
  hFile : THandle;
  Read  : DWORD;
Begin
  Result := False;
  hFile := CreateFileA(PAnsiChar(Path), GENERIC_READ, FILE_SHARE_READ,
           Nil, OPEN_EXISTING, 0, 0);
  If hFile = INVALID_HANDLE_VALUE Then Exit;
  Try
    If SetFilePointer(hFile, Offset, Nil, FILE_BEGIN) = DWORD($FFFFFFFF) Then
      Exit;
    Result := ReadFile(hFile, Buf[0], Count, Read, Nil) And (Read = DWORD(Count)
              );
  Finally
    CloseHandle(hFile);
End;
End;

Function FileWriteByte(Const Path: AnsiString; Offset: DWORD; Value: Byte):

                                                                         Boolean
;

Var 
  hFile   : THandle;
  Written : DWORD;
Begin
  Result := False;
  hFile := CreateFileA(PAnsiChar(Path), GENERIC_WRITE, 0,
           Nil, OPEN_EXISTING, 0, 0);
  If hFile = INVALID_HANDLE_VALUE Then Exit;
  Try
    If SetFilePointer(hFile, Offset, Nil, FILE_BEGIN) = DWORD($FFFFFFFF) Then
      Exit;
    Result := WriteFile(hFile, Value, 1, Written, Nil) And (Written = 1);
  Finally
    CloseHandle(hFile);
End;
End;

Function MakeBackupPath(Const Path: AnsiString): AnsiString;

Var i: Integer;
Begin
  Result := Path;
  For i := Length(Path) Downto 1 Do
    If Path[i] = '.' Then
      Begin
        Result := Copy(Path, 1, i - 1) + '.BAK';
        Exit;
      End;
  Result := Path + '.BAK';
End;

{ ── Patch logic ── }

Procedure DoPatch(hWnd: HWND);

Var 
  PathBuf  : array[0..MAX_PATH] Of AnsiChar;
  ExePath  : AnsiString;
  BakPath  : AnsiString;
  Actual   : array[0..4] Of Byte;
  Expected : array[0..4] Of Byte;
  Patched  : array[0..4] Of Byte;
  hMemo    : HWND;
  i        : Integer;
  Match    : Boolean;
  HexStr   : AnsiString;
Begin
  hMemo := GetDlgItem(hWnd, MEMO_LOG);

  GetWindowTextA(GetDlgItem(hWnd, EDT_PATH), PathBuf, MAX_PATH);
  ExePath := AnsiString(PathBuf);

  If ExePath = '' Then
    Begin
      LogLine(hMemo,
              'ERROR: No file selected. Use Browse to choose LORDCFG.EXE.');
      Exit;
    End;

  { Expected: C6 06 18 02 00  (fail path writes 0 = unregistered) }
  Expected[0] := $C6;
  Expected[1] := $06;
  Expected[2] := $18;
  Expected[3] := $02;
  Expected[4] := $00;
  { Patched:  C6 06 18 02 01  (fail path now writes 1 = registered) }
  Patched[0]  := $C6;
  Patched[1]  := $06;
  Patched[2]  := $18;
  Patched[3]  := $02;
  Patched[4]  := $01;

  LogLine(hMemo, '---------------------------------------');
  LogLine(hMemo, 'File:   ' + ExePath);

  { Read 5 bytes at patch location }
  If Not FileReadBytes(ExePath, PATCH_OFFSET, Actual, 5) Then
    Begin
      LogLine(hMemo, 'ERROR:  Cannot read file. Check the path and try again.');
      Exit;
    End;

  { Already patched? }
  Match := True;
  For i := 0 To 4 Do
    If Actual[i] <> Patched[i] Then
      Begin
        Match := False;
        Break;
      End;
  If Match Then
    Begin
      LogLine(hMemo, 'INFO:   File is already patched. Nothing to do.');
      Exit;
    End;

  { Verify expected bytes }
  Match := True;
  For i := 0 To 4 Do
    If Actual[i] <> Expected[i] Then
      Begin
        Match := False;
        Break;
      End;
  If Not Match Then
    Begin
      HexStr := '';
      For i := 0 To 4 Do
        HexStr := HexStr + ByteToHex(Actual[i]) + ' ';
      LogLine(hMemo, 'ERROR:  Unexpected bytes at offset $749D: ' + HexStr);
      LogLine(hMemo,
              '        Wrong version of LORDCFG.EXE, or already modified.');
      Exit;
    End;

  { Backup }
  BakPath := MakeBackupPath(ExePath);
  If Not CopyFileA(PAnsiChar(ExePath), PAnsiChar(BakPath), False) Then
    Begin
      LogLine(hMemo, 'ERROR:  Could not create backup. Is the folder writable?')
      ;
      Exit;
    End;
  LogLine(hMemo, 'Backup: ' + BakPath);

  { Write the single patched byte }
  If Not FileWriteByte(ExePath, PATCH_OFFSET + 4, $01) Then
    Begin
      LogLine(hMemo,
              'ERROR:  Write failed. Remove read-only attribute and retry.');
      Exit;
    End;

  LogLine(hMemo, 'Patch:  Offset $749D+4  |  $00 -> $01  |  SUCCESS');
  LogLine(hMemo, '');
  LogLine(hMemo, 'LORDCFG.EXE will now accept any registration numbers.');
  LogLine(hMemo, 'Enter any 5 numbers (e.g. 1 2 3 4 5) when prompted.');
End;

{ ── Control helpers ── }

Procedure MakeLabel(hParent: HWND; Const Cap: PAnsiChar; X, Y, W, H: Integer);

Var hCtl: HWND;
Begin
  hCtl := CreateWindowExA(0, 'STATIC', Cap, WS_CHILD Or WS_VISIBLE,
          X, Y, W, H, hParent, HMENU(0), HInstance, Nil);
  SendMessageA(hCtl, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
End;

Procedure MakeLabelCentered(hParent: HWND; Const Cap: PAnsiChar; Y, H: Integer);

Var hCtl: HWND;
Begin
  hCtl := CreateWindowExA(0, 'STATIC', Cap,
          WS_CHILD Or WS_VISIBLE Or SS_CENTER,
          0, Y, WND_W, H, hParent, HMENU(0), HInstance, Nil);
  SendMessageA(hCtl, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
End;

Procedure MakeButton(hParent: HWND; Const Cap: PAnsiChar; ID, X, Y, W, H:
                     Integer;
                     IsDefault: Boolean);

Var 
  Style: DWORD;
  hCtl : HWND;
Begin
  Style := WS_CHILD Or WS_VISIBLE Or WS_TABSTOP;
  If IsDefault Then Style := Style Or BS_DEFPUSHBUTTON
  Else Style := Style Or BS_PUSHBUTTON;
  hCtl := CreateWindowExA(0, 'BUTTON', Cap, Style,
          X, Y, W, H, hParent, HMENU(ID), HInstance, Nil);
  SendMessageA(hCtl, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
End;

{ ── Window procedure ── }

Function WndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT
;
stdcall;

Const PAD = 12;

Var 
  SelPath : AnsiString;
  hCtl    : HWND;
Begin
  Result := 0;
  Case Msg Of 

    WM_CREATE:
               Begin
      { Path row }
                 MakeLabel(hWnd, 'LORDCFG.EXE path:', PAD, PAD, 440, 18);

                 hCtl := CreateWindowExA(WS_EX_CLIENTEDGE, 'EDIT', '',
                         WS_CHILD Or WS_VISIBLE Or WS_TABSTOP Or ES_AUTOHSCROLL,
                         PAD, PAD + 22, WND_W - PAD * 2 - 88, 22,
                         hWnd, HMENU(EDT_PATH), HInstance, Nil);
                 SendMessageA(hCtl, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT)
                 , 1);

                 MakeButton(hWnd, 'Browse...', BTN_BROWSE,
                            WND_W - PAD - 84, PAD + 21, 84, 24, False);

      { Log }
                 MakeLabel(hWnd, 'Log:', PAD, PAD + 58, 60, 16);

                 hCtl := CreateWindowExA(WS_EX_CLIENTEDGE, 'EDIT', '',
                         WS_CHILD Or WS_VISIBLE Or WS_VSCROLL Or
                         ES_MULTILINE Or ES_READONLY Or ES_AUTOVSCROLL,
                         PAD, PAD + 76, WND_W - PAD * 2, 148,
                         hWnd, HMENU(MEMO_LOG), HInstance, Nil);
                 SendMessageA(hCtl, WM_SETFONT, GetStockObject(ANSI_FIXED_FONT),
                 1);

      { Patch button }
                 MakeButton(hWnd, 'Backup && Patch LORDCFG.EXE', BTN_PATCH,
                            PAD, PAD + 234, WND_W - PAD * 2, 28, True);

      { Branding }
                 MakeLabelCentered(hWnd, '>>>  Quantum Pixelator  <<<', PAD +
                                   272, 16);
               End;

    WM_COMMAND:
                Begin
                  Case LOWORD(wParam) Of 
                    BTN_BROWSE:
                                If BrowseForFile(hWnd, SelPath) Then
                                  SetWindowTextA(GetDlgItem(hWnd, EDT_PATH),
                                  PAnsiChar(SelPath));
                    BTN_PATCH:
                               DoPatch(hWnd);
                  End;
                End;

    WM_DESTROY:
                PostQuitMessage(0);

    Else
      Result := DefWindowProcA(hWnd, Msg, wParam, lParam);
  End;
End;

{ ── Entry point ── }

Var 
  WC      : TWndClassA;
  Msg     : TMsg;
  MainWnd : HWND;
  WR      : TRect;
  X, Y    : Integer;

Begin
  ZeroMemory(@WC, SizeOf(WC));
  WC.style         := CS_HREDRAW Or CS_VREDRAW;
  WC.lpfnWndProc   := @WndProc;
  WC.hInstance     := HInstance;
  WC.hIcon         := LoadIconA(0, IDI_APPLICATION);
  WC.hCursor       := LoadCursorA(0, IDC_ARROW);
  WC.hbrBackground := HBRUSH(COLOR_BTNFACE + 1);
  WC.lpszClassName := 'LordPatcher';
  RegisterClassA(WC);

  SystemParametersInfoA(SPI_GETWORKAREA, 0, @WR, 0);
  X := WR.Left + (WR.Right  - WR.Left - WND_W) Div 2;
  Y := WR.Top  + (WR.Bottom - WR.Top  - WND_H) Div 2;

  MainWnd := CreateWindowExA(
             0,
             'LordPatcher',
             'LORD v4.07  -  LORDCFG.EXE Patcher',
             WS_OVERLAPPED Or WS_CAPTION Or WS_SYSMENU Or WS_MINIMIZEBOX,
             X, Y, WND_W, WND_H,
             0, 0, HInstance, Nil);

  ShowWindow(MainWnd, SW_SHOWNORMAL);
  UpdateWindow(MainWnd);

  While GetMessageA(@Msg, 0, 0, 0) Do
    Begin
      If Not IsDialogMessage(MainWnd, @Msg) Then
        Begin
          TranslateMessage(@Msg);
          DispatchMessageA(@Msg);
        End;
    End;
End.
