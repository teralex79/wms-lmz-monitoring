proc RunAdam {} {
global rs wms

  set cnt 0
  foreach name $wms(zond) {
    if {$wms($name,conf,active)} {
      set a [lsearch $wms(com) "$wms($name,adr,moxa):$wms($name,port,adam)"]
      if {$a==-1} {
        if {[catch {socket $wms($name,adr,moxa) $wms($name,port,adam)} rs($name,adam)]} {

           set answ [tk_messageBox -message "��� ����� � $wms($name,adr,moxa):$wms($name,port,adam) ������. ��������� ����������� ���������." -title "Error" -type ok -icon error]
        } else {
           fconfigure $rs($name,adam) -buffering line -translation cr -blocking 0
           fileevent  $rs($name,adam) readable [list handleRemCmdAdam $rs($name,adam) $name]
           lappend wms(com) "$wms($name,adr,moxa):$wms($name,port,adam)"
        }
      }
    }
  }
  if {$wms(zndjntctr)} {ZondContr 0}
}

proc handleRemCmdAdam {f name} {
global wms ent

# Delete the handler if the input was exhausted.
  if {[eof $f]} {
      fileevent $f readable {}
      close     $f
      return
  }

  set ent(11) [gets $f]
  set wms(adam,ready) 1
}

proc ZondContr {i} {
global ent rs wms

  foreach name $wms(zond) {
    if {$wms($name,conf,active)} {

      set adr [format "%02X" $wms($name,conf,adr)]
      if {$i} {

        set wms(adam,ready) 0
        puts $rs($name,adam) \@${adr}DO00
        flush $rs($name,adam)
        if {!$wms(adam,ready)} {vwait wms(adam,ready)}
#        set ent(11) [gets $rs($wms($name,com,adam))]
        .mf.join1 configure -text "������. ����������" -command "ZondContr 0"
      } else {

        set wms(adam,ready) 0
        puts $rs($name,adam) \@${adr}DO01
        flush $rs($name,adam)
        if {!$wms(adam,ready)} {vwait wms(adam,ready)}
#        set ent(11) [gets $rs($wms($name,com,adam))]
        .mf.join1 configure -text "������. ��������" -command "ZondContr 1"
      }
			after 500 "CheckZond $name $adr $i 1 "
    }
  }
}

proc CheckZond {name adr a c} {
global rs wms val ent

  set wms(adam,ready) 0
  puts $rs($name,adam) "\@${adr}DI"
  flush $rs($name,adam)
  if {!$wms(adam,ready)} {vwait wms(adam,ready)}
#  set ent(11) [gets $rs($wms($name,com,adam))]
  set pos [string range $ent(11) end-2 end-2]

  if {[string range $ent(11) end end]} {
    if {!$pos} {
      set val(en3) "������"
      set wms($name,join) 1
    } else {
      set val(en3) "��������"
      set wms($name,join) 0
    }
    set wms(done,$name) 1
  } else {
    if {$c<3} {
      incr c
      after 500
      CheckZond $name ${adr} $a $c
    } else {
      if {$a} {
        set name1 "�� ������"
      } else {
        set name1 "�� ��������"
      }
      set answ [tk_messageBox -message "���� $name $name1. ��������� �������?" -title "Error" -type yesno -icon error]

      if {$answ=="yes"} {
        CheckZond $name ${adr} $a 1
      } else {
        set wms(done,$name) 1
      }
    }
  }
}

