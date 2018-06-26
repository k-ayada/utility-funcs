#!/bin/bash
function unzipAll(){
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
