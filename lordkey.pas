
Program LORD_Keygen;

{$MODE DELPHI}
{$APPTYPE GUI}

Uses 
Windows;

Const 
  EDIT_SYSOP = 101;
  EDIT_BBS   = 102;
  BTN_GEN    = 103;
  EDIT_K1    = 104;
  EDIT_K2    = 105;
  EDIT_K3    = 106;
  EDIT_K4    = 107;
  EDIT_K5    = 108;

  WND_W = 380;
  WND_H = 345;

{ ── Key computation (reversed from lordcfg.exe CS:0x03F7) ── }

Procedure UpperStr(Var S: AnsiString);

Var i: Integer;
Begin
  For i := 1 To Length(S) Do
    If S[i] In ['a'..'z'] Then
      S[i] := Chr(Ord(S[i]) - 32);
End;

Procedure ComputeLordKeys(Const SysopName, BBSName: AnsiString;
                          out K1, K2, K3, K4, K5: LongWord);

Var 
  Sysop, BBS  : AnsiString;
  PS, PB      : AnsiString;
  acc1        : Word;
  acc2, acc3,
  acc4, acc5  : LongWord;
  i, ch       : Integer;
  ValidCount  : Integer;
  PadCtr      : Byte;
Begin
  Sysop := SysopName;
  BBS   := BBSName;
  UpperStr(Sysop);
  UpperStr(BBS);



{ ── Key 1: sysop, 16-bit
       odd  index → acc += char
       even index → acc += char * 256 }
  acc1 := 0;
  For i := 1 To Length(Sysop) Do
    Begin
      ch := Ord(Sysop[i]);
      If (i And 1) = 1 Then
        acc1 := Word(acc1 + ch)
      Else
        acc1 := Word(acc1 + ch * 256);
    End;
  K1 := acc1;

  { ── Key 2: BBS, same alternating pattern, 32-bit → low word }
  acc2 := 0;
  For i := 1 To Length(BBS) Do
    Begin
      ch := Ord(BBS[i]);
      If (i And 1) = 1 Then
        Inc(acc2, LongWord(ch))
      Else
        Inc(acc2, LongWord(ch) * 256);
    End;
  K2 := acc2 And $FFFF;



{ ── Key 3: interleaved sysop+BBS with zero-padding on shorter string
       odd  index → char from (padded) sysop
       even index → char from (padded) BBS }
  PS := Sysop;
  PB := BBS;
  PadCtr := 0;
  If Length(PS) > Length(PB) Then
    While Length(PB) < Length(PS) Do
      Begin
        PB := PB + Chr(PadCtr);
        Inc(PadCtr);
      End
      Else If Length(PB) > Length(PS) Then
             While Length(PS) < Length(PB) Do
               Begin
                 PS := PS + Chr(PadCtr);
                 Inc(PadCtr);
               End;
  acc3 := 0;
  For i := 1 To Length(PS) Do
    Begin
      If (i And 1) = 1 Then ch := Ord(PS[i])
      Else                  ch := Ord(PB[i]);
      Inc(acc3, LongWord(ch));
    End;
  K3 := acc3;



{ ── Key 4: sysop, sum of (char shr 1), divided by count of A-Z/space chars
       valid-char count is capped at 4 }
  ValidCount := 0;
  For i := 1 To Length(Sysop) Do
    If (Sysop[i] = ' ') Or ((Sysop[i] >= 'A') And (Sysop[i] <= 'Z')) Then
      Inc(ValidCount);
  If ValidCount > 4 Then ValidCount := 4;
  acc4 := 0;
  For i := 1 To Length(Sysop) Do
    Inc(acc4, LongWord(Ord(Sysop[i]) shr 1));
  If ValidCount > 0 Then
    acc4 := acc4 Div LongWord(ValidCount);
  K4 := acc4 And $FFFF;

  { ── Key 5: BBS, sum of (char shr 1), doubled if acc < $3FFFFFFF }
  acc5 := 0;
  For i := 1 To Length(BBS) Do
    Inc(acc5, LongWord(Ord(BBS[i]) shr 1));
  If ($7FFFFFFE - acc5) > acc5 Then
    acc5 := acc5 * 2;
  K5 := acc5 And $FFFF;
End;

{ ── Generate and display ── }

Procedure Generate(hWnd: HWND);

Var 
  SysopBuf, BBSBuf : array[0..255] Of AnsiChar;
  K1, K2, K3, K4, K5 : LongWord;
  S : AnsiString;
Begin
  GetWindowTextA(GetDlgItem(hWnd, EDIT_SYSOP), SysopBuf, 255);
  GetWindowTextA(GetDlgItem(hWnd, EDIT_BBS),   BBSBuf,   255);

  If (SysopBuf[0] = #0) Or (BBSBuf[0] = #0) Then
    Begin
      MessageBoxA(hWnd,
                  'Please enter both Sysop Name and BBS Name.',
                  'Input Required',
                  MB_OK Or MB_ICONWARNING);
      Exit;
    End;

  ComputeLordKeys(AnsiString(SysopBuf), AnsiString(BBSBuf), K1, K2, K3, K4, K5);

  Str(K1, S);
  SetWindowTextA(GetDlgItem(hWnd, EDIT_K1), PAnsiChar(S));
  Str(K2, S);
  SetWindowTextA(GetDlgItem(hWnd, EDIT_K2), PAnsiChar(S));
  Str(K3, S);
  SetWindowTextA(GetDlgItem(hWnd, EDIT_K3), PAnsiChar(S));
  Str(K4, S);
  SetWindowTextA(GetDlgItem(hWnd, EDIT_K4), PAnsiChar(S));
  Str(K5, S);
  SetWindowTextA(GetDlgItem(hWnd, EDIT_K5), PAnsiChar(S));
End;

{ ── Layout constants ── }

Const 
  LBL_X = 12;
  LBL_W = 136;
  LBL_H = 18;
  EDT_X = 152;
  EDT_W = 212;
  EDT_H = 22;
  PAD   = 33;
  TOP   = 14;

{ ── Control helpers ── }

Procedure MakeLabel(hParent: HWND; Const Caption: PAnsiChar; X, Y, W, H: Integer
);

Var hCtl: HWND;
Begin
  hCtl := CreateWindowExA(0, 'STATIC', Caption, WS_CHILD Or WS_VISIBLE,
          X, Y, W, H, hParent, HMENU(0), HInstance, Nil);
  SendMessageA(hCtl, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
End;

Procedure MakeEdit(hParent: HWND; ID, X, Y, W, H: Integer;
                   Const Def: PAnsiChar; Flags: DWORD);

Var hCtl: HWND;
Begin
  hCtl := CreateWindowExA(WS_EX_CLIENTEDGE, 'EDIT', Def,
          WS_CHILD Or WS_VISIBLE Or WS_TABSTOP Or ES_AUTOHSCROLL Or Flags,
          X, Y, W, H, hParent, HMENU(ID), HInstance, Nil);
  SendMessageA(hCtl, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
End;

Procedure MakeLabelCentered(hParent: HWND; Const Caption: PAnsiChar; Y, H:
                            Integer);

Var hCtl: HWND;
Begin
  hCtl := CreateWindowExA(0, 'STATIC', Caption,
          WS_CHILD Or WS_VISIBLE Or SS_CENTER,
          0, Y, WND_W, H, hParent, HMENU(0), HInstance, Nil);
  SendMessageA(hCtl, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
End;

Procedure MakeButton(hParent: HWND; Const Caption: PAnsiChar;
                     ID, X, Y, W, H: Integer);

Var hCtl: HWND;
Begin
  hCtl := CreateWindowExA(0, 'BUTTON', Caption,
          WS_CHILD Or WS_VISIBLE Or WS_TABSTOP Or BS_DEFPUSHBUTTON,
          X, Y, W, H, hParent, HMENU(ID), HInstance, Nil);
  SendMessageA(hCtl, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 1);
End;

{ ── Window procedure ── }

Function WndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT
;
stdcall;

Const 
  RO = ES_READONLY or ES_CENTER;
Begin
  Result := 0;
  Case Msg Of 

    WM_CREATE:
               Begin
                 MakeLabel(hWnd, 'Sysop Name:',    LBL_X, TOP,            LBL_W,
                           LBL_H);
                 MakeEdit (hWnd, EDIT_SYSOP, EDT_X, TOP - 2, EDT_W, EDT_H, '', 0
                 );

                 MakeLabel(hWnd, 'BBS Name:',      LBL_X, TOP + PAD,      LBL_W,
                           LBL_H);
                 MakeEdit (hWnd, EDIT_BBS, EDT_X, TOP + PAD - 2, EDT_W, EDT_H,
                           '', 0);

                 MakeButton(hWnd, 'Generate Keys', BTN_GEN,
                            LBL_X, TOP + PAD*2 + 4, EDT_X + EDT_W - LBL_X, 26);

                 MakeLabel(hWnd, 'Number 1:',      LBL_X, TOP + PAD*3 + 8,
                           LBL_W, LBL_H);
                 MakeEdit (hWnd, EDIT_K1, EDT_X, TOP + PAD*3 + 6,  EDT_W, EDT_H,
                           '', RO);

                 MakeLabel(hWnd, 'Number 2:',      LBL_X, TOP + PAD*4 + 8,
                           LBL_W, LBL_H);
                 MakeEdit (hWnd, EDIT_K2, EDT_X, TOP + PAD*4 + 6,  EDT_W, EDT_H,
                           '', RO);

                 MakeLabel(hWnd, 'Number 3:',      LBL_X, TOP + PAD*5 + 8,
                           LBL_W, LBL_H);
                 MakeEdit (hWnd, EDIT_K3, EDT_X, TOP + PAD*5 + 6,  EDT_W, EDT_H,
                           '', RO);

                 MakeLabel(hWnd, 'Number 4:',      LBL_X, TOP + PAD*6 + 8,
                           LBL_W, LBL_H);
                 MakeEdit (hWnd, EDIT_K4, EDT_X, TOP + PAD*6 + 6,  EDT_W, EDT_H,
                           '', RO);

                 MakeLabel(hWnd, 'Number 5:',      LBL_X, TOP + PAD*7 + 8,
                           LBL_W, LBL_H);
                 MakeEdit (hWnd, EDIT_K5, EDT_X, TOP + PAD*7 + 6,  EDT_W, EDT_H,
                           '', RO);

                 MakeLabelCentered(hWnd, '>>>  Quantum Pixelator  <<<', TOP +
                                   PAD*8 + 10, 16);
               End;

    WM_COMMAND:
                If LOWORD(wParam) = BTN_GEN Then
                  Generate(hWnd);

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
  WC.lpszClassName := 'LordKeygen';
  RegisterClassA(WC);

  SystemParametersInfoA(SPI_GETWORKAREA, 0, @WR, 0);
  X := WR.Left + (WR.Right  - WR.Left - WND_W) Div 2;
  Y := WR.Top  + (WR.Bottom - WR.Top  - WND_H) Div 2;

  MainWnd := CreateWindowExA(
             0,
             'LordKeygen',
             'LORD v4.07  -  Registration Keygen',
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
