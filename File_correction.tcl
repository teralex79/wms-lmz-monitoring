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
  set of1 [open [string range $fl 0 end-4]_Flow.txt "w"]
  set of2 [open [string range $fl 0 end-4]_Tube.txt "w"]
  set of3 [open [string range $fl 0 end-4]_JoinF.txt "w"]
  set of4 [open [string range $fl 0 end-4]_JoinT.txt "w"]

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
          if {[lindex $str end]=="I_Black"} {

            set flag2 1
            set str [string range $str 0 end-8]
          }
          puts $of1 $str
          puts $of2 $str
          puts $of3 $str
          puts $of4 $str
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
        foreach item $part2 {
          puts -nonewline $off "[format "%8d" [expr {$item - $spec(Iblack)}]]"
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