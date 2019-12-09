proc TTContr {} {
global wms

 if {$wms(temp)} {
   runtt 192.168.0.38
 } else {
#   exittt
   close $wms(socket,tt)
 }
}

set wms(runtt) 0
proc runtt {adr} {
global wms
puts runtt
# establish communication with sm program
  if {[catch {set s [socket $adr 4442]}]} {
    if {$wms(runtt)} {
      set answ [tk_messageBox -message "Error localhost TT 4442\n Запустить TruTemp?" -title "Error localhost" -type yesno -icon error]
      if {$answ=="yes" && [info hostname]=="wmsn"} {
        exec -- wish "V:/Terentjev/Work/WMS_New/WMS_Zond/WMS_TT/WMS_TT.tcl" &
        after 200 "runtt localhost"
      } else {

        set wms(temp) 0
      }
    } else {
      incr wms(runtt)
      exec -- wish "V:/Terentjev/Work/WMS_New/WMS_Zond/WMS_TT/WMS_TT.tcl" &
      after 200 {runtt localhost}
    }
  } else {

    fconfigure $s -buffering line
    fileevent $s readable [list handleSocketTT $s]
    set wms(socket,tt) $s
    SendSocketTT ConTT 0 0 0 0
#    puts $wms(socket,tt) "Connect"
#    flush $wms(socket,tt)
  }
}

# Прием командного отклика от TrueTemp сервера
proc handleSocketTT {f} {
global wms

# Delete the handler if the input was exhausted.
  if {[eof $f]} {

    fileevent $f readable {}
    close     $f
    set wms(temp) 0
    return
  }

# Read and handle the incoming information.
  set r [gets $f]
  set lr [eval list $r]
  if {[llength $lr]} {

    for {set i 0} {$i<10} {incr i} {

      set idata($i) [lindex $lr $i]
    }

    switch $idata(1) {

      "Meas" {

        switch $idata(2) {

          "done" {
            set wms($idata(3),meas,temp) [format "%6.2f" $idata(5)]
            set wms(X) "$idata(3) $wms($idata(3),meas,temp)"
            if {$idata(6)>=$wms(tempaver)} {
            
              set wms(busytemp) 0
              set wms(busytemp,$idata(3)) 0
            }
          }
        }
      }

      "Error" {

        tk_messageBox -message $lr -title "Error TT" -type ok -icon error
      }
    }
  }
}

proc MeasTemp {name n rep aver} {
global wms

  SendSocketTT Meas $name $n $rep $aver
}

proc SendSocketTT {cmd arg1 arg2 arg3 arg4} {
global wms

  catch {
    puts $wms(socket,tt) "$cmd $arg1 $arg2 $arg3 $arg4"
    flush $wms(socket,tt)
  }
}

proc exittt {} {
global wms

  SendSocketTT Exit 0 0 0 0
#  puts $wms(socket,tt) "Exit"
#  flush $wms(socket,tt)
  close $wms(socket,tt)
}
