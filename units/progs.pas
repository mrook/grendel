unit progs;

interface

procedure init_progs;

implementation

uses
    chars,
    dtypes,
    mudthread,
    gvm;

procedure grendelVMError(owner : TObject; msg : string);
begin
  raise GException.Create('gvm.pas', 'VM error in context of ' + GNPC(owner).name^ + ': ' + msg);
end;

procedure grendelSystemTrap(owner : TObject; msg : string);
begin
  interpret(GNPC(owner), msg);
end;

procedure init_progs;
begin
  setVMError(grendelVMError);
  setSystemTrap(grendelSystemTrap);
end;

end.
