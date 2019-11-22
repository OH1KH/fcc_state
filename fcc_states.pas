program fcc_states;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp , strutils;

type

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TMyApplication }

procedure TMyApplication.DoRun;

var

  tfIn,tfOUT,dupOut: TextFile;
  s,t: string;
  call,state,ids,Ocall,Ostate :string;
  id,Oid,r,p,d,i,x : longint;
  FccEn        :TStringList;



begin
  if ParamCount<>1 then
   begin
    WriteHelp
   end
  else
 begin

  Ocall:='call';
  Ostate:='state';
  Oid:=0;
  r:=0;
  p:=0;
  d:=0;
  x:=0;

  AssignFile(dupOut,'fcc_rejects.txt');
  AssignFile(tfIn, Paramstr(1));
  try
    reset(tfIn);
    rewrite(dupOut);
    FccEn := TStringList.Create;
    FccEn.Sorted:=False;
    FccEn.Duplicates:=dupAccept;
    Writeln('Reading ',ParamStr(1),' ...');
    while not eof(tfIn) do
    begin
     readln(tfIn, s);
     inc(r);
      call := ExtractDelimited(5,s,['|']);
      ids := ExtractDelimited(2,s,['|']);
      state := ExtractDelimited(18,s,['|']);
     if ( (call<>'') and (state<>'') and (ids <>'')) then  FccEn.Add(call+'-'+ids+'='+state)
      else
        begin
         writeln(dupOut, call+'-'+ids+'='+state);
         inc(x);
        end;
    end;
   except
    on E: EInOutError do
     writeln('File handling error occurred. Details: ', E.Message);
  end;
  CloseFile(tfIn);
  CloseFile(dupOut);
  Writeln('Sorting...');
  FccEn.Sort;

  Writeln('Writing fcc_states.tab ...');

  AssignFile(tfOut, 'fcc_states.tab');
  AssignFile(dupOut,'fcc_dupes.txt');
  try
    reset(tfIn);
    rewrite(tfOut);
    rewrite(dupOut);
    for i:=0 to  FccEn.Count-1 do
    begin
      s:= FccEn.Strings[i];
      t := ExtractWord(1,s,['=']);
      call := ExtractWord(1,t,['-']);
      id := StrToIntDef(ExtractWord(2,t,['-']),-1);
      state := ExtractWord(2,s,['=']);

      if ( (call<>'') and (state<>'') and (id >=0)) then
      begin
        if call<> Ocall then
         Begin
           writeln(tfOut,Ocall,'=',Ostate);//write old call=state if next call is different
           Ocall:=call;
           Oid := id;
           Ostate := state;
           inc(p);
         end
         else
          Begin  //if they are same calls
            writeln(dupOut,Ocall,'=',Ostate);//write old call=state to dupe list
            inc(d);
            if id > Oid then  //if id is bigger than old id save call and state as old
                              //should remain finally the higest id call to print
                              //needs one extra line to end of file to get all printed
             begin
              Ocall:=call;
              Oid := id;
              Ostate := state;
             end;

          end;
       end;
      end;

    writeln(tfOut,Ocall,'=',Ostate);   //last remaining
    FreeAndNil(FccEn);
    CloseFile(tfOut);
    CloseFile(dupOut);
  except
    on E: EInOutError do
     writeln('File handling error occurred. Details: ', E.Message);
  end;
  Writeln('Read:       ',r,' lines.');
  Writeln('Rejected:   ',x,' lines.');
  Writeln('Written:    ',p,' lines.');
  Writeln('Duplicates: ',d,' lines.');
end;
 Terminate;
end;
constructor TMyApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TMyApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TMyApplication.WriteHelp;
begin
  Writeln();
  Writeln('Usage (in this order):');
  Writeln('(You can paint 4 lines below with mouse, then drop them, using middle button (wheel), to command line');
  Writeln();
  Writeln('    cd ~/.config/cqrlog/ctyfiles');
  Writeln('    wget -nc -nd http://wireless.fcc.gov/uls/data/complete/l_amat.zip');
  Writeln('    unzip -o l_amat.zip EN.dat');
  Writeln('    ',ParamStr(0),' EN.dat');
  Writeln();
  Writeln('Result file is fcc_states.tab used by cqrlog.');
  Writeln('It should be placed to ~/.config/cqrlog/ctyfiles folder');
  Writeln('fcc_dupes.txt and fcc_rejects.txt are holding removed lines (just for check)');
  Writeln();
end;

var
  Application: TMyApplication;
begin
  Application:=TMyApplication.Create(nil);
  Application.Title:='fcc_states';
  Application.Run;
  Application.Free;
end.

