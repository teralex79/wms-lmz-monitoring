#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"

package require BWidget
package require BLT
  namespace import blt::*

wm   title . "Monitoring SWMS v3.0"
wm geometry . "=+550+300"
wm protocol . WM_DELETE_WINDOW ExitPr
focus -force .

console show

set wms(src_path) "./src/monitoring"
set wms(conf_path) "./conf/monitoring"
set wms(log_path) "./log/monitoring"
set wms(data_path) "./data"

catch [file mkdir $wms(conf_path)/smart_place]
catch [file mkdir $wms(log_path)]
catch [file mkdir $wms(data_path)]


source $wms(src_path)/wms_clnt_TT.tcl
source $wms(src_path)/wms_clnt_Spec.tcl
source $wms(src_path)/wms_clnt_Adam.tcl

  set wms(lst) {0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z}

  set wms(zond) {S01 S04 S05 S07 A1 A2}
  set wms(zndjntctr) 0
  set wms(temp) 0
  set wms(meas) 0
  set wms(tempaver) 1

  set wms(L,S01) {25}
  set wms(L,S04) {35}
  set wms(L,S05) {45}
  set wms(L,S07) {45}
  set wms(L,A1)  {35}
  set wms(L,A2)  {25}
  set wms(sph) 0

  set cnt 0
  foreach name $wms(zond) {

    set wms($name,conf,active)  0
    set wms($name,state)  "Пауза"
    set wms($name,adr,moxa)  "192.168.0.123"
    set wms($name,port,swms) "4003"
    set wms($name,port,adam) "4004"
    set wms($name,conf,adr)  $cnt
    set wms($name,done)         1
    set wms($name,join)         0
    set wms($name,swms,IntTime) 8
    set wms($name,swms,PixMode) 0
    set wms($name,trav)       1.0
    set wms($name,meas,temp)    0

    set wms($name,swms,Iocalc) {}
    for {set i 0} {$i<1043} {incr i} {

      lappend wms($name,swms,Iocalc) 1
    }
    incr cnt
  }

  set wms(conf,t_cicl)  2000
  set wms(state)   "Пауза"
  set wms(com) {}

  menu .menu -tearoff 0
  . configure -menu .menu

  set m .menu.file
  menu $m -tearoff 0
  .menu add cascade -label "File" -menu $m -underline 0

  $m add command -label "Exit" -command ExitPr

  set m .menu.prop
  menu $m -tearoff 0
  .menu add cascade -label "Options" -menu $m -underline 0

  $m add command -label "Properties" -command Properties
  $m add check -label "Измерение температуры" -variable wms(temp) -command TTContr
  $m add check -label "Контроль свед/разв" -variable wms(zndjntctr) -command "RunAdam"

  $m add command -label "Read_Io" -command "ReadIo"
  $m add command -label "AddChart" -command {
    foreach name $wms(zond) {
      if {$wms($name,conf,active)} {
        AddChart $name
      }
    }
  }
#  set m1 .menu.prop.io
#  $m add cascade -label "Read_Io" -menu $m1 -underline 0
#  menu $m1  -tearoff 0
#  foreach name $wms(zond) {
#    $m1 add command -label "$name" -command "ReadIo $name"
#  }


  set mf [frame .mf]
  grid $mf -row 0 -column 0 -sticky nw
  
  set rw 0
  set cmn 0
  label $mf.lbmeasnm -text "Имя файла" -relief ridge
  grid $mf.lbmeasnm -row $rw -column $cmn -sticky nw
  
  incr cmn
  entry $mf.enmeasnm -textvar wms(measnm) -relief ridge
  grid $mf.enmeasnm -row $rw -column $cmn -sticky nw

  set cmn 0
  incr rw
  button $mf.btIo -text "Save_Io" -command {Meas_Io}
  grid $mf.btIo -row $rw -column $cmn -columnspan 2 -sticky news

  incr rw
  button $mf.btstart -text "Старт" -command {set wms(meas) 1; ChangeBt 1; Meas}
  grid $mf.btstart -row $rw -column $cmn -columnspan 2 -sticky news

  incr rw
  label $mf.lb2 -textvar wms(state) -relief ridge
  grid $mf.lb2 -row $rw -column $cmn -columnspan 2 -sticky news

  incr rw
  label $mf.lb3 -textvar wms(X) -relief ridge
  grid $mf.lb3 -row $rw -column $cmn -columnspan 2 -sticky news

  incr rw
  button $mf.join1 -text "Свести" -width 10 -command "ZondContr 1"
  grid $mf.join1 -row $rw -column $cmn -columnspan 2 -sticky news

  incr rw
  label $mf.lb4 -textvar val(en3) -width 11 -relief sunken
  grid $mf.lb4 -row $rw -column $cmn -columnspan 2 -sticky news

proc ChangeBt {a} {
global wms

  if {$a} {

    set txt "Стоп"
    set b 0
    set cmd {}
    set stt active
    .mf.join1 configure -state disabled
    .menu.prop entryconfigure 0 -state disable
    .mf.btIo configure -state disabled
    update
  } else {

    set txt "Старт"
    set b 1
    set cmd Meas
    set stt disabled
#    .mf.join1 configure -state active
    .mf.btIo configure -state active
    update
  }
  .mf.btstart configure -text $txt -state $stt -command "set wms(meas) $b; ChangeBt $b; $cmd"
#  .mf.btIo configure -state $stt
}

proc Properties {} {
global wms meas

  toplevel .prop
  wm title .prop "Настройки"
  wm geometry .prop "=670x400+450+200"
  wm protocol .prop WM_DELETE_WINDOW "ReadIni; destroy .prop"
  focus .prop

  set swms [frame .prop.frpar]
  grid $swms -row 0 -column 0 -sticky nw


  set cnt1 0
  set lst {name active trav Adr_Moxa Port_swms Port_adam Adr_adam PixMode IntTime SName l0 l1 l2 l3 Init Save T_cicl}
  foreach item $lst {

    label $swms.title${cnt1}0 -text "$item" -width 10 -anchor w -relief ridge
    grid $swms.title${cnt1}0 -row $cnt1 -column 0 -sticky news
    incr cnt1
  }

  set cnt2 1
  foreach name $wms(zond) {

    set lst {name active trav adr_moxa port_swms port_adam adr PixMode IntTime SName l0 l1 l2 l3 Init save}

    set cnt1 0
    foreach item $lst {

      if {![info exists wms($name,conf,$item)]} {set wms($name,conf,$item) 0}

      if {[string range $item 0 3]=="port"} {

        set type [string range $item 5 end]
        set item "port"
      }

      switch $item {

        "IntTime"  {entry $swms.$cnt1$cnt2 -textvariable wms($name,swms,$item) -justify right -width 13}
        "PixMode"  {ComboBox $swms.$cnt1$cnt2 -width 11 -textvariable wms($name,swms,$item)\
                    -values {0 1 3 4} -justify right -state disabled}
        "name"     {label $swms.$cnt1$cnt2 -text "$name" -relief ridge -width 13 -anchor w}
        "adr_moxa" {ComboBox $swms.$cnt1$cnt2 -width 13 -textvariable wms($name,adr,moxa)\
                    -values {192.168.0.123 192.168.0.124} -justify right}
        "port"     {ComboBox $swms.$cnt1$cnt2 -width 13 -textvariable wms($name,port,$type)\
                    -values {4001 4002 4003 4004} -justify right}
        "adr"      {ComboBox $swms.${cnt1}${cnt2} -textvariable wms($name,conf,adr) -width 8 -justify right\
                    -values {0 1 2 3 4 5 6 7 8 9} -command "Valid1 $name" -modifycmd "Valid1 $name"}
        "trav"     {entry $swms.${cnt1}${cnt2} -textvar wms($name,trav) -width 13 -relief ridge -justify right}
        "save"     {button $swms.${cnt1}${cnt2} -text "Save_$name" -width 10 -justify right -command "SaveIni $name"}
        "active"   {checkbutton $swms.${cnt1}${cnt2} -var wms($name,conf,active) -relief ridge -command "runSWMS $name"}
        "default"  {label $swms.$cnt1$cnt2 -textvar wms($name,swms,$item) -relief ridge -width 13 -anchor w}
      }
      grid $swms.$cnt1$cnt2 -row $cnt1 -column $cnt2 -sticky nw
      incr cnt1
    }
    incr cnt2
  }

  entry $swms.${cnt1}1 -textvariable wms(conf,t_cicl) -width 10 -justify right
  grid  $swms.${cnt1}1 -row $cnt1 -column 1 -columnspan 3 -sticky news

  label $swms.title${cnt1}4 -text "мс" -width 10 -anchor w -relief ridge
  grid  $swms.title${cnt1}4 -row $cnt1 -column 4 -sticky nw

  set bt [frame .prop.frbt]
  grid $bt -row 1 -column 0 -sticky nw

#  button $bt.save -text "Сохранить" -width 10 -command {

#    after 100 {
#      SaveIni
#      ReadIni
#    }
#    destroy .prop
#  }
#  grid $bt.save -row 0 -column 0 -padx 1 -pady 2

  button $bt.cnsl -text "Закрыть" -width 10 -command {
          after 100 ReadIni
          destroy .prop
        }
  grid $bt.cnsl -row 0 -column 0 -padx 1 -pady 2
}

proc Valid1 {name} {
global wms

  set list1 {}

  foreach nm $wms(zond) {

    lappend list1 $wms($nm,conf,adr)
  }

  foreach nm $wms(zond) {
    if {$wms($name,conf,adr)==$wms($nm,conf,adr) && $name!=$nm && $wms($name,port,adam)==$wms($nm,port,adam) && $wms($name,adr,moxa)==$wms($nm,adr,moxa)} {
      foreach n {0 1 2 3 4 5} {
        if {[lsearch -all $list1 $n]<0} {

          set wms($nm,conf,adr) $n
        }
      }
    }
  }
}

proc Meas {} {
global wms

  set wms(dt) 0

  if {$wms(meas)} {

    set t1 [clock clicks -milliseconds]

    set wms(state) "Измеряется"
    update

    set wms(ms) 1

    foreach name $wms(zond) {
      if {$wms($name,conf,active)} {
        set wms($name,time) [clock format [clock seconds] -format "%H:%M:%S"]
        Meas_SWMS $name $wms($name,join)
        if {$wms(temp)} {
          set wms(busytemp) 1
          MeasTemp $name 1 1 1
          if {$wms(busytemp)} {vwait wms(busytemp)}
#          set wms($name,meas,temp)
#          set wms($name,meas,temp) 0
        } else {
          set wms($name,meas,temp) 0
        }
        SaveFile $name $wms($name,join)
      }
    }
    
    set t2 [clock clicks -milliseconds]
    set wms(ms) 0
  }

  set dt [expr {round($wms(conf,t_cicl) - ($t2 - $t1))}]
  ContDown $dt
}

proc ContDown {dt} {
global wms

  update
  set wms(state) [format "%4.2f" [expr {$dt/1000.}]]
  if {$wms(meas)} {
    if {$dt>0} {

      after 10 ContDown [expr {$dt - 10}]
    } else {
      Meas
    }
  } else {

    set wms(state) "Пауза"
    .mf.btstart configure -state active
    .mf.join1 configure -state active
    .menu.prop entryconfigure 0 -state active
    update
  }
}

proc FindMeasDate {} {
global wms

## Поиск всех тестовых замеров на текущий день и установка следующего имени замера

 set part "[clock format [clock seconds] -format "%y%m%d"]"

 set g [glob -nocomplain -directory "$wms(data_path)/$part/" -tails "$wms(data_path)/$part/" -type f "${part}*"]
 set old 0

  if {[llength $g]} {
     foreach item $g {
      set part2 "[lsearch -exact $wms(lst) [string range $item 8 8]]"

      if {$old<=$part2} {set old $part2}
    }

    set testmn "${part}_0[lindex $wms(lst) [expr {$old+1}]]"
  } else {

    set testmn "${part}_00"
  }

  set wms(measnm) "$testmn"
}

proc FormatXTicks {w value} {

    set lxname [clock format $value -format %H:%M:%S]
    return $lxname
}

proc AddChart {name} {
global meas wms max
  catch {destroy .graph${name}}

  switch $name {

    S01 {set cnt1 0; set cnt2 0}
    S04 {set cnt1 1; set cnt2 0}
    S05 {set cnt1 0; set cnt2 1}
    S07 {set cnt1 1; set cnt2 1}
    A1  {set cnt1 0; set cnt2 0}
    A2  {set cnt1 0; set cnt2 1}
  }

  toplevel .graph$name
  wm geometry .graph$name "=+[expr {30+$cnt1*610}]+[expr {80+$cnt2*540}]"
  wm title .graph$name "Graph $name"

  set tnb [blt::tabnotebook .graph$name.nb -takefocus 1 -samewidth no]
  pack $tnb -expand yes -fill both
  set tab 0
  foreach tb {IIo I Spec IIo_Spec} {
    catch "$tnb delete $tab; destroy $tnb.c${name}"
    switch $tb {

      "IIo" {

       $tnb insert $tab -text "$tb" -selectbackground RoyalBlue2

        set c [canvas $tnb.c${name}$tb -width 570 -height 300 -bg grey -highlightbackground  grey]
        pack $c
        $tnb tab configure $tab -window $c -anchor nw -fill both

        stripchart $c.sc -width 480 -height 300 -plotpadx {0 0} -plotpady {0 0} -plotbackground grey\
                         -fg black -bg grey
        $c create window 90 10 -window $c.sc -anchor nw

          global x${name}$tb y${name}630_$tb y${name}520_$tb y${name}460_$tb y${name}300_$tb

          vector create x${name}$tb y${name}630_$tb y${name}520_$tb y${name}460_$tb y${name}300_$tb

#          $c.sc xaxis configure -title "" -autorange 21600 -stepsize 4320 -subdivisions 3 -color black -shiftby 10 -command FormatXTicks
          $c.sc xaxis configure -title "" -autorange 7200 -stepsize 1440 -subdivisions 3 -color black -shiftby 10 -command FormatXTicks

          $c.sc grid configure -hide no -dashes {2 2} -color black

          $c.sc yaxis configure -title "IIo" -min 0 -titlecolor black -color black -justify right -rotate 90 -min 0 -max 1.2

          $c.sc element create "IIo(630)" -ydata y${name}630_$tb -xdata  x${name}$tb\
           -label "" -mapy y -fill red -symbol diamond -outline red -color red -pixels 3  -linewidth 1
          $c.sc element create "IIo(520)" -ydata y${name}520_$tb -xdata  x${name}$tb\
           -label "" -mapy y -fill green -symbol diamond -outline green -color green -pixels 3  -linewidth 1
          $c.sc element create "IIo(460)" -ydata y${name}460_$tb -xdata  x${name}$tb\
           -label "" -mapy y -fill blue -symbol diamond -outline blue -color blue -pixels 3  -linewidth 1
          $c.sc element create "IIo(300)" -ydata y${name}300_$tb -xdata  x${name}$tb\
           -label "" -mapy y -fill violet -symbol diamond -outline violet -color violet -pixels 3  -linewidth 1

          frame $c.fr -width 80 -height 300 -bg grey
          $c create window 0 10 -window $c.fr -anchor nw
          set cnt 0
          foreach color {630 520 460 300} clr {red green blue violet} {

            label $c.fr.$color -text "IIo_$color" -fg $clr -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
            grid  $c.fr.$color -row $cnt -column 0 -sticky news
            label $c.fr.var$color -textvar wms(IIoF,$name,$color) -fg $clr -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
            grid  $c.fr.var$color -row $cnt -column 1 -sticky news
            incr cnt
          }
          label $c.fr.temp -text "T" -fg white -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
          grid  $c.fr.temp -row $cnt -column 0 -sticky news
          label $c.fr.vartemp -textvar wms($name,meas,temp) -fg white -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
          grid  $c.fr.vartemp -row $cnt -column 1 -sticky news
          incr cnt

#          menu $tnb.pmenu$name -tearoff 0
#          $tnb.pmenu$name add check -label "Autoscaling" -variable dasop($name,autosc)
#           -command "AutoScale $name $tab($n) $tnb $n"

      }
      "IIo_Spec" {

       $tnb insert $tab -text "$tb" -selectbackground RoyalBlue2

        set c [canvas $tnb.c${name}$tb -width 570 -height 300 -bg grey -highlightbackground  grey]
        pack $c
        $tnb tab configure $tab -window $c -anchor nw -fill both

        graph $c.sc -width 560 -height 300 -plotpadx {0 0} -plotpady {0 0} -plotbackground grey\
                         -fg black -bg grey
        $c create window 10 10 -window $c.sc -anchor nw

          global x${name}$tb y${name}$tb

          vector create x${name}$tb y${name}$tb

          $c.sc xaxis configure -title "l,nm" -min 200 -max 1000 -color black

          $c.sc grid configure -hide no -dashes {2 2} -color black

          $c.sc yaxis configure -title "IIo" -min 0 -titlecolor red -color red -justify right -rotate 90

          $c.sc element create "IIo" -ydata y${name}$tb -xdata  x${name}$tb\
           -label "" -mapy y -fill red -outline red -color red -pixels 0  -linewidth 1
      }
      "Spec" {

       $tnb insert $tab -text "$tb" -selectbackground RoyalBlue2

        set c [canvas $tnb.c${name}$tb -width 570 -height 300 -bg grey -highlightbackground  grey]
        pack $c
        $tnb tab configure $tab -window $c -anchor nw -fill both

        graph $c.sc -width 560 -height 300 -plotpadx {0 0} -plotpady {0 0} -plotbackground grey\
                         -fg black -bg grey
        $c create window 10 10 -window $c.sc -anchor nw

          global x${name}$tb y${name}$tb

          vector create x${name}$tb y${name}$tb

          $c.sc xaxis configure -title "l,nm" -min 200 -max 1000 -color black

          $c.sc grid configure -hide no -dashes {2 2} -color black

          $c.sc yaxis configure -title "I" -min -1000 -titlecolor red -color red -justify right -rotate 90

          $c.sc element create "I" -ydata y${name}$tb -xdata  x${name}$tb\
           -label "" -mapy y -fill red -outline red -color red -pixels 0  -linewidth 1
      }
      "I" {

       $tnb insert $tab -text "$tb" -selectbackground RoyalBlue2

        set c [canvas $tnb.c${name}$tb -width 570 -height 300 -bg grey -highlightbackground  grey]
        pack $c
        $tnb tab configure $tab -window $c -anchor nw -fill both

        stripchart $c.sc -width 480 -height 300 -plotpadx {0 0} -plotpady {0 0} -plotbackground grey\
                         -fg black -bg grey
        $c create window 90 10 -window $c.sc -anchor nw

          global x${name}$tb y${name}630 y${name}520 y${name}460 y${name}300

          vector create x${name}$tb y${name}630 y${name}520 y${name}460 y${name}300

#          $c.sc xaxis configure -title "" -autorange 21600 -stepsize 4320 -subdivisions 3 -color black -shiftby 10 -command FormatXTicks
          $c.sc xaxis configure -title "" -autorange 7200 -stepsize 1440 -subdivisions 3 -color black -shiftby 10 -command FormatXTicks

          $c.sc grid configure -hide no -dashes {2 2} -color black

          $c.sc yaxis configure -title "I" -min 0 -max 1000 -titlecolor black -color black -justify right -rotate 90

      set max($name,$tb) [lindex [eval list [$c.sc yaxis limits]] 1]

          $c.sc element create "I(630)" -ydata y${name}630 -xdata  x${name}$tb\
           -label "" -mapy y -fill red -symbol diamond -outline red -color red -pixels 3  -linewidth 1
          $c.sc element create "I(520)" -ydata y${name}520 -xdata  x${name}$tb\
           -label "" -mapy y -fill green -symbol diamond -outline green -color green -pixels 3  -linewidth 1
          $c.sc element create "I(460)" -ydata y${name}460 -xdata  x${name}$tb\
           -label "" -mapy y -fill blue -symbol diamond -outline blue -color blue -pixels 3  -linewidth 1
          $c.sc element create "I(300)" -ydata y${name}300 -xdata  x${name}$tb\
           -label "" -mapy y -fill violet -symbol diamond -outline violet -color violet -pixels 3  -linewidth 1

          frame $c.fr -width 80 -height 300 -bg grey
          $c create window 0 10 -window $c.fr -anchor nw
          set cnt 0
          foreach color {630 520 460 300} clr {red green blue violet} {

            label $c.fr.$color -text "I_$color" -fg $clr -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
            grid  $c.fr.$color -row $cnt -column 0 -sticky news
            label $c.fr.var$color -textvar wms(I,$name,$color) -fg $clr -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
            grid  $c.fr.var$color -row $cnt -column 1 -sticky news
            incr cnt
          }
          label $c.fr.temp -text "T" -fg white -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
          grid  $c.fr.temp -row $cnt -column 0 -sticky news
          label $c.fr.vartemp -textvar wms($name,meas,temp) -fg white -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
          grid  $c.fr.vartemp -row $cnt -column 1 -sticky news
          incr cnt

          set w [labelframe $c.lf1l -text "Y max" -font -*-helvetica-bold-r-*-8-*-*-*-*-*-*-koi8-r]
          $c create window 160 0 -window $w -anchor ne
#
          spinbox $w.sb -width 5 -from -999 -to 70000 -increment 500 -textvariable max($name,$tb)\
           -justify right -font -*-helvetica-bold-r-*-18-*-*-*-*-*-*-koi8-r\
           -command "ConfY $c $name max $tb"
#
          bind $w.sb <Return> "ConfY $c $name max $tb"
          bind $w.sb <KeyRelease> "ConfY $c $name max $tb"
#
          pack $w.sb
#          menu $tnb.pmenu$name -tearoff 0
#          $tnb.pmenu$name add check -label "Autoscaling" -variable dasop($name,autosc)
#           -command "AutoScale $name $tab($n) $tnb $n"

      }
    }
    incr tab
  }
}
#console show
proc ConfY {c name type scale} {
global dasop max min increm

 if {[info exist max($name,$scale)]} {

#  if {$dasop($name,autosc)} {
#
#    if {[lsearch -exact $dasop($name,autosc,store) $scale$ngr$name ]==-1} {

#      if {$dasop($name,autosc,cnt)!=1} {
#
#        incr dasop($name,autosc,cnt) -1
#        lappend dasop($name,autosc,store) $scale$ngr$name
#      } else {
#
#        set dasop($name,autosc) 0
#      }
#    }
#  }
#puts "max1 $max($name,$scale)"

  if {$type=="max"} {
#puts "max2 $max($name,$scale)"
#    if {$max($name,$scale,$ngr)>$min($name,$scale,$ngr)} {
#
      $c.sc yaxis configure -max $max($name,$scale)
#    } else {

#      set max($name,$scale) [expr {$max($name,$scale)+100}]
#    }
  } elseif {$type=="up"} {

      set max($name,$scale,$ngr) [expr {$max($name,$scale,$ngr)+$increm($name,$scale,$ngr)}]
      set min($name,$scale,$ngr) [expr {$min($name,$scale,$ngr)+$increm($name,$scale,$ngr)}]

      $c.sc$ngr axis configure a$scale -max $max($name,$scale,$ngr)
      $c.sc$ngr axis configure a$scale -min $min($name,$scale,$ngr)
  } elseif {$type=="down"} {
      set max($name,$scale,$ngr) [expr {$max($name,$scale,$ngr) - $increm($name,$scale,$ngr)}]
      set min($name,$scale,$ngr) [expr {$min($name,$scale,$ngr) - $increm($name,$scale,$ngr)}]

      $c.sc$ngr axis configure a$scale -min $min($name,$scale,$ngr)
      $c.sc$ngr axis configure a$scale -max $max($name,$scale,$ngr)
  } else {

    if {$max($name,$scale,$ngr)>$min($name,$scale,$ngr)} {

      $c.sc$ngr axis configure a$scale -min $min($name,$scale,$ngr)
    } else {

      set min($name,$scale,$ngr) [expr {$min($name,$scale,$ngr) - $increm($name,$scale,$ngr)}]
    }
  }
 }
 update
}

proc AutoScale {name tab tnb n} {
global dasop max min increm

  set dasop($name,autosc) 1

  set dasop($name,autosc,store) ""

  set cnt 0

  for {set i 0} {$i<$dasop($name,numbgr)} {incr i} {

    for {set scale 1} {$scale<=[lindex $dasop($name,scale) $i]} {incr scale} {

      $tnb.c${name}.sc$i axis configure a$scale -min "" -max ""
      set max($name,$scale,$i) [lindex [eval list [$tnb.c${name}.sc$i axis limits a$scale]] 1]
      set min($name,$scale,$i) [lindex [eval list [$tnb.c${name}.sc$i axis limits a$scale]] 0]
      update
      incr cnt
    }
  }
  set dasop($name,autosc,cnt) $cnt
  UpdateBox $name $tab $tnb $n
}

proc UpdateBox {name tab tnb n} {
global dasop max min increm

  if {$dasop($name,autosc) && $dasop(run)} {

    for {set i 0} {$i<$dasop($name,numbgr)} {incr i} {

      for {set scale 1} {$scale<=[lindex $dasop($name,scale) $i]} {incr scale} {

        set max($name,$scale,$i) [format "%5.3f" [lindex [eval list [$tnb.c${name}.sc$i axis limits a$scale]] 1]]
        set min($name,$scale,$i) [format "%5.3f" [lindex [eval list [$tnb.c${name}.sc$i axis limits a$scale]] 0]]
        update
      }
    }
    after $dasop(delay) "UpdateBox $name $tab $tnb $n"
  }
}

proc ReadIni {} {
global wms rs meas
  foreach name $wms(zond) {
    if {[file exists "$wms(conf_path)/[info hostname]_$name.ini"]} {

      set ini [open "$wms(conf_path)/[info hostname]_$name.ini" "r"]

      set data [read $ini]
      close $ini
      set lines [split $data \n]

      set i 0
      foreach str $lines {

        if {[string length $str]>0 && [string first # $str]!=0 && [lindex $str 0]!="#"} {

          set [lindex $str 0] [lindex $str 1]
        }
        incr i
      }
    }
  }
  if {$wms(zndjntctr)} {RunAdam}
#  if {$wms(temp)} {runtt }
}

proc SaveIni {name} {
global wms meas

  set of [open $wms(conf_path)/[info hostname]_$name.ini "w"]

  puts $of "wms(conf,t_cicl) $wms(conf,t_cicl)"
#  puts $of "wms(temp) $wms(temp)"
  puts $of "wms(zndjntctr) $wms(zndjntctr)"
#  puts $of "wms(temp) 0"
#  puts $of "wms(zndjntctr) 0"

#  foreach name $wms(zond) {

    puts $of ""
    puts $of "# $name"
    puts $of ""

    puts $of "wms($name,adr,moxa) $wms($name,adr,moxa)"
    puts $of "wms($name,port,swms) $wms($name,port,swms)"
    puts $of "wms($name,port,adam) $wms($name,port,adam)"
    puts $of "wms($name,conf,adr) $wms($name,conf,adr)"

    puts $of "wms($name,swms,IntTime) $wms($name,swms,IntTime)"
    puts $of "wms($name,swms,PixMode) $wms($name,swms,PixMode)"
#  }
  close $of
}

proc SaveFile {name join} {
global wms

  set part "[clock format [clock seconds] -format "%y%m%d"]"
  catch [file mkdir $wms(data_path)/$part/]
  if {![file exists "$wms(data_path)/$part/$wms(measnm)_$name.txt"] } {

    set head 1
  } else {

    set head 0
  }

  set log [open "$wms(data_path)/$part/$wms(measnm)_$name.txt" "a"]

  if {$head} {

    set ctime [clock seconds]
    set date [clock format $ctime -format "%y_%m_%d"]

    puts -nonewline $log "Дата: ${date}; "
    puts -nonewline $log "Имя_замера: $wms(measnm); "
    puts -nonewline $log "Имя_зонда: $name; "
    puts -nonewline $log "Тип Модуля: swms "

    puts -nonewline $log "$wms($name,swms,SName)"

    puts $log ""

    puts $log ""

    puts -nonewline $log "L(мм)=$wms(L,$name); "

    foreach item {l0 l1 l2 l3 slc nlcc0 nlcc1 nlcc2 nlcc3 nlcc4 nlcc5 nlcc6 nlcc7 pnlc} {
      puts -nonewline $log "$item=$wms($name,swms,$item); "
    }

    puts $log ""

    puts $log ""

    foreach lamda $wms($name,swms,lamda) {

      puts -nonewline $log "K([format "%6d" [expr {int($lamda*1000)}]])=1.0; "
    }

    puts $log ""

    puts $log ""

    puts -nonewline $log "hh:mm:ss"
    puts -nonewline $log "[format "%16s" ADR_Moxa]"
    puts -nonewline $log "[format "%9s" PRT_SWMS]"
    puts -nonewline $log "[format "%9s" PRT_ADAM]"
    puts -nonewline $log "[format "%5s" Adr]"
    puts -nonewline $log "[format "%5s" Join]"
    puts -nonewline $log "[format "%6s" tr,mm]"
    puts -nonewline $log "[format "%9s" T,C]"
    puts -nonewline $log "[format "%9s" T_cicl]"
    puts -nonewline $log "[format "%9s" PixMode]"
    puts -nonewline $log "[format "%12s" IntTime(мс)]"
    foreach lamda $wms($name,swms,lamda) {

      puts -nonewline $log "[format "%8d" [expr {int($lamda*1000)}]]"
    }
    puts -nonewline $log "[format "%8s" I_Black]"

    puts $log ""
    puts $log ""
  }

  puts -nonewline $log $wms($name,time)
  puts -nonewline $log [format "%16s"  $wms($name,adr,moxa)]
  puts -nonewline $log [format "%9s"   $wms($name,port,swms)]
  puts -nonewline $log [format "%9s"   $wms($name,port,adam)]
  puts -nonewline $log [format "%5d"   $wms($name,conf,adr)]
  puts -nonewline $log [format "%5d"   $join]
  puts -nonewline $log [format "%6.1f" $wms($name,trav)]
  puts -nonewline $log [format "%9.1f" $wms($name,meas,temp)]
  puts -nonewline $log [format "%9.0f" $wms(conf,t_cicl)]
  puts -nonewline $log [format "%9d"   $wms($name,swms,PixMode)]
  puts -nonewline $log [format "%12d"  $wms($name,swms,IntTime)]

#  foreach meas $wms($name,swms,Imeas,$join)
  foreach meas $wms($name,swms,Icalc) {
    puts -nonewline $log "[format "%8d" $meas]"
  }
  puts -nonewline $log "[format "%8d" $wms($name,swms,Iblack)]"
  puts $log ""
  close $log
}

proc SaveIo {name join} {
global wms

  set part "[clock format [clock seconds] -format "%y%m%d"]"
  catch [file mkdir $wms(data_path)/$part/]
  if {![file exists "$wms(data_path)/$part/${name}_Io.txt"] } {

    set head 1
  } else {

    set head 0
  }

  set log [open "$wms(data_path)/$part/${name}_Io.txt" "a"]

  if {$head} {

    set ctime [clock seconds]
    set date [clock format $ctime -format "%y_%m_%d"]

    puts -nonewline $log "Дата: ${date}; "
    puts -nonewline $log "Имя_зонда: $name; "
    puts -nonewline $log "Тип Модуля: swms "

    puts -nonewline $log "$wms($name,swms,SName)"

    puts $log ""

#    puts $log "Темновой ток: $wms($name,swms,Iblack)"
#    puts $log ""

    puts -nonewline $log "L(мм)=$wms(L,$name); "

    foreach item {l0 l1 l2 l3 slc nlcc0 nlcc1 nlcc2 nlcc3 nlcc4 nlcc5 nlcc6 nlcc7 pnlc} {
      puts -nonewline $log "$item=$wms($name,swms,$item); "
    }

    puts $log ""

    puts $log ""

    foreach lamda $wms($name,swms,lamda) {

      puts -nonewline $log "K([format "%6d" [expr {int($lamda*1000)}]])=1.0; "
    }

    puts $log ""

    puts $log ""

    puts -nonewline $log "hh:mm:ss"
    puts -nonewline $log "[format "%16s" ADR_Moxa]"
    puts -nonewline $log "[format "%9s" PRT_SWMS]"
    puts -nonewline $log "[format "%9s" PRT_ADAM]"
    puts -nonewline $log "[format "%5s" Adr]"
    puts -nonewline $log "[format "%5s" Join]"
    puts -nonewline $log "[format "%6s" tr,mm]"
    puts -nonewline $log "[format "%9s" T,C]"
    puts -nonewline $log "[format "%9s" T_cicl]"
    puts -nonewline $log "[format "%9s" PixMode]"
    puts -nonewline $log "[format "%12s" IntTime(мс)]"
    foreach lamda $wms($name,swms,lamda) {

      puts -nonewline $log "[format "%8d" [expr {int($lamda*1000)}]]"
    }
    puts -nonewline $log "[format "%8s" I_Black]"

    puts $log ""
    puts $log ""
  }

  puts -nonewline $log $wms($name,time)
  puts -nonewline $log [format "%16s"  $wms($name,adr,moxa)]
  puts -nonewline $log [format "%9s"   $wms($name,port,swms)]
  puts -nonewline $log [format "%9s"   $wms($name,port,adam)]
  puts -nonewline $log [format "%5d"   $wms($name,conf,adr)]
  puts -nonewline $log [format "%5d"   $join]
  puts -nonewline $log [format "%6.1f" $wms($name,trav)]
  puts -nonewline $log [format "%9.1f" $wms($name,meas,temp)]
  puts -nonewline $log [format "%9.0f" $wms(conf,t_cicl)]
  puts -nonewline $log [format "%9d"   $wms($name,swms,PixMode)]
  puts -nonewline $log [format "%12d"  $wms($name,swms,IntTime)]

  foreach meas $wms($name,swms,Iocalc) {
    puts -nonewline $log "[format "%8d" $meas]"
  }
  puts -nonewline $log "[format "%8d" $wms($name,swms,Iblack)]"

  puts $log ""
  close $log
}

proc ReadIo {} {
global wms
  set n 0
  foreach name $wms(zond) {
    if {$wms($name,conf,active)} {
      set part "[clock format [clock seconds] -format "%y%m%d"]"
      if {[file exists "$wms(data_path)/$part/${name}_Io.txt"]} {
        set log [open "$wms(data_path)/$part/${name}_Io.txt" "r"]
        set data [read $log]
        close $log
        set lines [split $data \n]

        set flag 0
        foreach str $lines {
          if {[llength $str]>0} {
            if {!$flag} {
              if {[lindex $str 0]=="hh:mm:ss"} {
                set flag 1
                set wms($name,time,Io) {}
              }
            } else {
              lappend wms($name,time,Io) [lindex $str 0]
              set wms($name,Io,[lindex $str 0]) [lrange $str 11 end]
            }
          }
        }
        catch {destroy .io$name}
        toplevel .io$name
        wm title .io$name "$name Io time"
        wm geometry .io$name "=30x10+[expr {15 + $n}]+65"

        set tm [frame .io$name.time]
        pack $tm -side top -expand yes -fill both

         label $tm.label -text "Выберите время Io:"
         pack $tm.label -side top -fill x -expand yes
         scrollbar $tm.scroll -command "$tm.list yview"
         pack $tm.scroll -side right -fill y
         listbox $tm.list -yscroll "$tm.scroll set" -setgrid 1 -height 10
         pack $tm.list -side left -expand yes -fill both

        foreach tm1 $wms($name,time,Io) {
          $tm.list insert end $tm1
        }

        $tm.list selection set 0
        set nm $name
        button .io$name.close -text Close -command "GetListBox $nm"
        pack .io$name.close -side top -fill x
        bind $tm.list <Double-1> "GetListBox $nm"
      }
    }
    incr n 250
  }
}

proc GetListBox {name} {
global wms

#puts $name
#puts [.io$name.time.list get [.io$name.time.list curselection]]

  set wms($name,swms,Iocalc) $wms($name,Io,[.io$name.time.list get [.io$name.time.list curselection]])
#puts "wms($name,swms,Iocalc) $wms($name,swms,Iocalc)"
  .io$name.time.list delete 0 end
  destroy .io$name
}

proc ExitPr {} {
global rs wms

  set wms(meas) 0
  after 1000
  foreach name $wms(zond) {
    SaveIni $name
  }

  exit
}

FindMeasDate
ReadIni
update
