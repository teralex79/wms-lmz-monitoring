#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"

proc FileDialog {} {
global so dp path

## Predvaritel'noe zadanie puti k konfiguratsionnomu faylu

  set w ./data

## Opisanie tipov otobrazhaemih faylov

  set types {

    {"Data files" {.txt}}
    {"All files" *}
  }

  set infile ""

## Operatsia otkritija fayla

  set file [tk_getOpenFile -initialfile $infile -filetypes $types -parent . -initialdir $w]

  if {[llength $file]} {

    ReadFiles $file
  }
}

#console show
proc ReadFiles {fl} {
global spec

  set of [open $fl]
  set n 3

  set of1 [open [string range $fl 0 end-4]_Flow_$n.txt "w"]
  set of2 [open [string range $fl 0 end-4]_Tube_$n.txt "w"]
  set of3 [open [string range $fl 0 end-4]_JoinF_$n.txt "w"]
  set of4 [open [string range $fl 0 end-4]_JoinT_$n.txt "w"]

  set data [read $of]
  close $of

  set lines [split $data \n]

  set flag 0
  set flag2 0
  foreach str $lines {
    if {[llength $str]>0} {
      if {!$flag} {
        if {[lindex $str 0]=="hh:mm:ss"} {
          set flag 1
          set part1 [string range $str 0 96]

          puts -nonewline $of1 $part1
          puts -nonewline $of2 $part1
          puts -nonewline $of3 $part1
          puts -nonewline $of4 $part1
          if {[lindex $str end]=="I_Black"} {

            set flag2 1
            set str [lrange $str 0 end-1]
          }
          set part2 [lrange $str 11 end]
          set cnt 0
          set aver 0
          set lst [list $of1 $of2 $of3 $of4]

          foreach item $part2 {

            set aver [expr {$aver + $item}]
            incr cnt
            if {$cnt==$n} {
              foreach off $lst {
                puts -nonewline $off "[format "%9.1f" [expr {1.0*$aver/$n}]]"
              }
              set cnt 0
              set aver 0
            }
          }
          foreach off $lst {
            puts $off ""
          }
        }
      } else {

        set part1 [string range $str 0 96]

        if {$flag2} {

          set spec(Iblack) 0
          set str [lrange $str 0 end-1]
        } else {
          set Iblack {}
          foreach item {0 1 2 3 1038 1039 1040 1041 1042 1043} {
            lappend Iblack [lindex $str [expr {$item+11}]]
          }
          set spec(Iblack) [lindex [lsort -increasing $Iblack] 5]
        }
        set part2 [lrange $str 11 end]

        if {[lindex $str 5]} {
          if {[expr {round([lindex $str 6])}]>=254 || [expr {round([lindex $str 6])}]>=276} {

            set off $of3
          } elseif {[expr {round([lindex $str 6])}]==1} {

            set off $of4
          }
        } else {
          if {[expr {round([lindex $str 6])}]>=254 || [expr {round([lindex $str 6])}]>=276} {

            set off $of1
          } elseif {[expr {round([lindex $str 6])}]==1} {

            set off $of2
          }
        }
        puts -nonewline $off $part1

        set cnt 0
        set aver 0
        foreach item $part2 {
          set aver [expr {$aver + [expr {$item - $spec(Iblack)}]}]
          incr cnt
          if {$cnt==$n} {

            puts -nonewline $off "[format "%9.2f" [expr {1.0*$aver/$n}]]"
            set cnt 0
            set aver 0
          }
        }
        puts $off ""
      }
    }
  }

  close $of1
  close $of2
  close $of3
  close $of4
  exit
}

FileDialog