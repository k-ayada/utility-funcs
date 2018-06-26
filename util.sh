#!/bin/bash
unzipAll(){
   if [ "$#" -eq  "0" ]; then 
        echo "usage unzipAll <fully qualified path of zip file- wieldcards supported> [<out dir -defaults pwd>]
   fi
   if [ -z "$2" ]; then 
      outDir = "."
   else 
      outDir = "$2"
    counter=0
    for f in "${1}"; do
        unzip ${f} -d ${outDir}
        counter=$((counter+1))
    done
    print "Unzipped ${counter} zip-files"
}  

zipIt() {
   if [ "$#" -eq  "0" ]; then 
        echo "usage zipIt <path to file>"
   fi
   if [ -z "$2" ]; then 
      outDir = "."
   else
    rc=0
    fl=$1   
    `7za a -t7z  "$fl.7z"  "$fl"`
 }
 
 zipInfo() {
   for zips in $(ls "$1"); do
      for raw in `zipinfo -1 $zips`; do
         echo "$zips : $raw"
      done
   done
 }
