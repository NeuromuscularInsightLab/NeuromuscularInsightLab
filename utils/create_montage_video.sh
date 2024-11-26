#!/bin/sh
# 
#
#Make 4D image movie
#
# Created by Kenneth Weber on 4/19/2016.
# Copyright 2016 Dr. Kenneth Weber LTD. All rights reserved.

# How to use bash create_montage_video.sh filename.nii.gz min_intensity_value max_intensity_value

filename=$1
min=$2
max=$3

function quit {
   exit
}  
function create_montage_video {
	xdim=`fslval $filename dim1`
    ydim=`fslval $filename dim2`
    zdim=`fslval $filename dim3`
    tdim=`fslval $filename dim4`
    pixdimx=`fslval $filename pixdim1`
    pixdimy=`fslval $filename pixdim2`
    pixdimz=`fslval $filename pixdim3`
	height=$(echo "scale=0; sqrt(${zdim})" | bc -l)
	width=$(echo "scale=0; ${zdim}/${height}" | bc -l)
	width=$(echo "scale=0; ${width}*${xdim}*${pixdimx}" | bc -l)
	fslsplit $filename vol -t
for file in vol0***.nii.gz; do
	fname=`$FSLDIR/bin/remove_ext ${file}` 
	slicer $file -u -i $min $max -A $width $fname.png
	rm $file
done
	ffmpeg -r 2.5 -start_number 0 -i vol%04d.png -c:v libx264 -vf fps=5 -pix_fmt yuv420p $filename.mov
	v=vol****.png
	rm $v
}  

for file in vol0***.nii.gz; do
	fname=`$FSLDIR/bin/remove_ext ${file}` 
	slicer $file -u -i $min $max -z -7 $fname.png
	#rm $file
done

create_montage_video
quit


