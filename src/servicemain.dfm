object ServiceGrendel: TServiceGrendel
  OldCreateOrder = False
  AllowPause = False
  DisplayName = 'Grendel MUD Server'
  AfterInstall = ServiceAfterInstall
  OnExecute = ServiceExecute
  OnStart = ServiceStart
  OnStop = ServiceStop
  Left = 478
  Top = 386
  Height = 150
  Width = 215
end
