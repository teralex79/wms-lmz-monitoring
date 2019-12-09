proc string2hex {s} {
  binary scan $s H* hex
  regsub -all (..) $hex {\\x\1}
  return $hex
}

proc handleRemCmd {f name} {
global wms

# Delete the handler if the input was exhausted.
  if {[eof $f]} {
      fileevent $f readable {}
      close     $f
      return
  }
# Read and handle the incoming information.
  set a [catch {set bs0 [read $f]}]

  if {!$a} {
#puts "gets COM $name $bs0"
#update
    set lngth "[string length $bs0]"
    if {$lngth>0} {

      for {set i 0} {$i<$lngth} {incr i} {
        set bs_bit [string range $bs0 $i $i]
        if {![string is alnum $bs_bit]} {
          binary scan $bs_bit a1 bs_bin

          set bs_hex [string2hex $bs_bin]
          switch [string tolower $bs_hex] {

            "00"       {set bs1 #NUL}
            "01"       {set bs1 #SOH}
            "02"       {set bs1 #STX}
            "03"       {set bs1 #ETX}
            "04"       {set bs1 #EOT}
            "05"       {set bs1 #ENQ}
            "06"       {set bs1 #ACK}
            "07"       {set bs1 #BEL}
            "08"       {set bs1 #BS }
            "09"       {set bs1 #TAB}
            "0a"       {set bs1 #LF }
            "0b"       {set bs1 #VT }
            "0c"       {set bs1 #FF }
            "0d"       {set bs1 #CR }
            "0e"       {set bs1 #SO }
            "0f"       {set bs1 #SI }
            "10"       {set bs1 #DLE}
            "11"       {set bs1 #DC1}
            "12"       {set bs1 #DC2}
            "13"       {set bs1 #DC3}
            "14"       {set bs1 #DC4}
            "15"       {set bs1 #NAK}
            "16"       {set bs1 #SYN}
            "17"       {set bs1 #ETB}
            "18"       {set bs1 #CAN}
            "19"       {set bs1 #EM }
            "1a"       {set bs1 #SUB}
            "1b"       {set bs1 #ESC}
            "1c"       {set bs1 #FS }
            "1d"       {set bs1 #GS }
            "1e"       {set bs1 #RS }
            "1f"       {set bs1 #US }
            "default"  {set bs1 $bs_bin}
          }
        } else {

          set bs1 $bs_bit
        }
        set wms($name,string) "$wms($name,string)$bs1"
      }

      set wms($name,answ) [eval list [string map {#ACK " " #CR " " #LF " "} $wms($name,string)]]
      if {([string match -nocase "*>*" $wms($name,string)] && $wms($name,cmd)!="S") || ($wms($name,cmd)=="S" && [llength [lsearch -all $wms($name,answ) "*>*"]]==2)} {
        set wms($name,socket,status) 0
      }
    }
  }
}

proc runSWMS {name} {
global wms

# establish communication with swms program
  if {$wms($name,conf,active)} {
    if {[catch {socket $wms($name,adr,moxa) $wms($name,port,swms)} wms($name,socket,swms)]} {

       set answ [tk_messageBox -message "Нет связи с $wms($name,adr,moxa):$wms($name,port,swms) портом. Проверьте подключение устройств." -title "Error" -type ok -icon error]
       set wms(active) 0
    } else {
       fconfigure $wms($name,socket,swms) -buffering line -translation cr -blocking 0
       fileevent  $wms($name,socket,swms) readable [list handleRemCmd $wms($name,socket,swms) $name]
       set wms(active) 1
       set wms(X) $name
       Init_SWMS $name $wms($name,join)
    }
  } else {
    catch {
      catch {destroy .graph${name}}
      close $wms($name,socket,swms)
    }
  }
}

proc SendCmdCOM {a cmd name} {
global wms

  set wms($name,socket,status) 1
  set wms($name,string) ""
  set wms($name,cmd) $cmd

  if {$cmd=="aA" || $cmd=="bB" || $cmd=="v"} {
    puts -nonewline $wms($name,socket,swms) $cmd
  } else {
    puts $wms($name,socket,swms) $cmd
  }
  flush $wms($name,socket,swms)
  if {$wms($name,socket,status)} {vwait wms($name,socket,status)}
}

proc Init_SWMS {name join} {
global wms

  if {$name=="all"} {
    foreach name $wms(zond) {
      if {$wms(type,$name)=="swms"} {
        Init_SWMS $name $join
      }
    }
  } else {

    SendCmdCOM init aA $name

    SendCmdCOM init "?x-1" $name
    if {[lindex $wms($name,answ) 0]=="?x-1"} {
      set cnt 1
      foreach item {SName l0 l1 l2 l3 slc nlcc0 nlcc1 nlcc2 nlcc3 nlcc4 nlcc5 nlcc6 nlcc7 pnlc} {
        set wms($name,swms,$item) [lindex $wms($name,answ) $cnt]
        incr cnt
      }
      set wms($name,swms,lamda) ""
      for {set i 0} {$i<1044} {incr i} {

        lappend wms($name,swms,lamda) [expr {$wms($name,swms,l0) + $wms($name,swms,l1)*$i + \
                                      $wms($name,swms,l2)*$i*$i + $wms($name,swms,l3)*$i*$i*$i}]
      }
      foreach lamda $wms($name,swms,lamda) {

        set wms($name,$lamda,Io) 1
      }

      set wms($name,swms,Init) "inited"
      AddChart $name
    } else {
      set wms($name,swms,Init) $wms($name,answ)
    }
  }
}

proc Meas_SWMS {name join} {
global wms

  if {$name=="all"} {
    foreach name $wms(zond) {
      if {$wms(type,$name)=="swms"} {
        if {$wms($name,swms,Init)=="inited" || $wms($name,swms,Init)=="active"} {Meas_SWMS $name $join}
      }
    }
  } else {
    if {$wms($name,swms,Init)!="inited"} {

      Init_SWMS $name $join
    }
    SendCmdCOM meas aA $name
    SendCmdCOM meas I$wms($name,swms,IntTime) $name
    SendCmdCOM meas P$wms($name,swms,PixMode) $name
    SendCmdCOM meas S $name
    set wms($name,swms,Imeas,$join) [lreplace [lreplace $wms($name,answ) 0 7] end-1 end]
    set Iblack ""
    foreach item {0 1 2 3 1038 1039 1040 1041 1042 1043} {
      lappend Iblack [lindex $wms($name,swms,Imeas,$join) $item]
    }

    set wms($name,swms,Iblack) [lindex [lsort -increasing $Iblack] 5]
    set wms($name,swms,Icalc) ""
    foreach item $wms($name,swms,Imeas,$join) {
      lappend wms($name,swms,Icalc) [expr {$item - $wms($name,swms,Iblack)}]
    }
    catch {global x${name}Spec y${name}Spec}
    catch {global x${name}IIo_Spec y${name}IIo_Spec}
    catch {global x${name}I y${name}300 y${name}460 y${name}520 y${name}630}
    catch {global x${name}IIo y${name}300_IIo y${name}460_IIo y${name}520_IIo y${name}630_IIo}

    foreach wave {300 460 520 630} nwv {127 331 408 550} {
      set wms(I,$name,$wave) [lindex $wms($name,swms,Icalc) $nwv]
      set Io [lindex $wms($name,swms,Iocalc) $nwv]
      if {$Io==0} {
        if {$wms(I,$name,$wave)!=0} {
          set Io $wms(I,$name,$wave)
        } else {
          set Io 1
        }
      }
      set wms(IIo,$name,$wave) [expr {1.0*$wms(I,$name,$wave)/$Io}]
      set wms(IIoF,$name,$wave) [format "%6.3f" $wms(IIo,$name,$wave)]
    }

#    set wms(I,$name,300) [lindex $wms($name,swms,Icalc) 127]
#    set wms(I,$name,460) [lindex $wms($name,swms,Icalc) 331]
#    set wms(I,$name,520) [lindex $wms($name,swms,Icalc) 408]
#    set wms(I,$name,630) [lindex $wms($name,swms,Icalc) 550]

    set tm [clock seconds]
    set x${name}I(++end)   $tm
    set y${name}300(++end) $wms(I,$name,300)
    set y${name}460(++end) $wms(I,$name,460)
    set y${name}520(++end) $wms(I,$name,520)
    set y${name}630(++end) $wms(I,$name,630)

    if {[x${name}I length]>5700} {
      x${name}I    delete 0
      y${name}300  delete 0
      y${name}460  delete 0
      y${name}520  delete 0
      y${name}630  delete 0
    }

    set x${name}IIo(++end) $tm
    set y${name}300_IIo(++end) $wms(IIo,$name,300)
    set y${name}460_IIo(++end) $wms(IIo,$name,460)
    set y${name}520_IIo(++end) $wms(IIo,$name,520)
    set y${name}630_IIo(++end) $wms(IIo,$name,630)

    if {[x${name}IIo length]>5700} {
      x${name}Io       delete 0
      y${name}300_IIo  delete 0
      y${name}460_IIo  delete 0
      y${name}520_IIo  delete 0
      y${name}630_IIo  delete 0
    }

    x${name}Spec set {}
    y${name}Spec set {}
    x${name}IIo_Spec set {}
    y${name}IIo_Spec set {}

    for {set i 0} {$i<1044} {incr i} {

      set x${name}Spec(++end) [lindex $wms($name,swms,lamda) $i]
      set y${name}Spec(++end) [lindex $wms($name,swms,Icalc) $i]
    }
    for {set i 65} {$i<955} {incr i} {
      set x${name}IIo_Spec(++end) [lindex $wms($name,swms,lamda) $i]

      set a [lindex $wms($name,swms,Icalc) $i]
      set b [lindex $wms($name,swms,Iocalc) $i]
      if {$b==0} {
        if {$a!=0} {
          set b $a
        } else {
          set b 1
        }
      }
      set y${name}IIo_Spec(++end) [expr {1.0*$a/$b}]
    }
  }
}

proc Meas_Io {} {
global wms

  .mf.btstart configure -state disabled
  .mf.btIo configure -state disabled

  foreach name $wms(zond) {
    if {$wms($name,conf,active)} {
      set wms($name,time) [clock format [clock seconds] -format "%H:%M:%S"]
      set join $wms($name,join)
      if {$wms($name,swms,Init)!="inited"} {

        Init_SWMS $name $join
      }
      SendCmdCOM meas aA $name
      SendCmdCOM meas I$wms($name,swms,IntTime) $name
      SendCmdCOM meas P$wms($name,swms,PixMode) $name
      SendCmdCOM meas S $name
      set wms($name,swms,Imeas,$join) [lreplace [lreplace $wms($name,answ) 0 7] end-1 end]
      set Iblack ""
      foreach item {0 1 2 3 1038 1039 1040 1041 1042 1043} {
        lappend Iblack [lindex $wms($name,swms,Imeas,$join) $item]
      }

      set wms($name,swms,Iblack) [lindex [lsort -increasing $Iblack] 5]
      set wms($name,swms,Iocalc) {}
      foreach item $wms($name,swms,Imeas,$join) {
        lappend wms($name,swms,Iocalc) [expr {$item - $wms($name,swms,Iblack)}]
      }
      SaveIo $name $join
    }
  }
  .mf.btstart configure -state active
  .mf.btIo configure -state active
}