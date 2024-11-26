#!/bin/bash
# 
#
# Created by Kenneth Weber on 12/2/2019.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# Please cite:
#	Weber II KA, Chen Y, Wang X, Kahnt T, Parrish TB. Lateralization of Cervical Spinal Cord Activity During an Isometric Upper Extremity Motor Task. NeuroImage 2016;125:233-243.
#	Jenkinson, M., Bannister, P., Brady, M., Smith, S., 2002. Improved optimization for the robust and accurate linear registration and motion correction of brain images. Neuroimage 17, 825-841.
#	Jenkinson, M., Beckmann, C.F., Behrens, T.E., Woolrich, M.W., Smith, S.M., 2012. FSL. Neuroimage 62, 782-790.
#	Cohen-Adad, J., et al. (2009). Slice-by-slice motion correction in spinal cord fMRI: SliceCorr. Proceedings of the 17th Annual Meeting of the International Society for Magnetic Resonance in Medicine, Honolulu, USA 
#	Weber II, K. A., et al. (2014). Choice of Motion Correction Method Affects Spinal Cord fMRI Results. 20th Annual Meeting of  the Organization for Human Brain Mapping, Hamburg, Germany.

function usage()
{
cat << EOF

DESCRIPTION
  Perform 2D slicewise registration of the 4D time series input image to the reference image using the reference weighting mask image.
  Outputs include the motion corrected image time series, the motion corrected mean image, the motion corrected TSNR image, and a compressed folder containing the transformation matrices.
  Requires that FSL is installed. This was last updated using FSL Version 6.0. This only works for multi-echo with three echoes.
  
USAGE
  `basename ${0}` -i <input_echo_1> -j <input_echo_2> -k <input_echo_3> -r <reference> -m <mask> -o <output>

MANDATORY ARGUMENTS
  -i <input_echo_1>            First echo input image
  -j <input_echo_2>            Second echo input image
  -k <input_echo_3>            Third echo input image
  -r <reference>               Reference image
  -m <mask>                    Reference weighting mask image
  -o <output>                  Output filename postfix

EOF
}

if [ ! ${#@} -gt 0 ]; then
    usage `basename ${0}`
    exit 1
fi

#Initialization of variables
scriptname=${0}
input_echo_1=
input_echo_2=
input_echo_3=
reference=
mask=
output=

while getopts “hi:j:k:r:m:o:” OPTION
do
	case $OPTION in
	 h)
			usage
			exit 1
			;;
         i)
		 	input_echo_1=$OPTARG
         		;;
	j)
		 	input_echo_2=$OPTARG
         		;;
		k)
		 	input_echo_3=$OPTARG
         		;;
	 r)
	                reference=$OPTARG
	                ;;
         m)
			mask=$OPTARG
         		;;
	 o)
	                output=$OPTARG
		        ;;
         ?)
             usage
             exit
             ;;
     esac
done

# Check the parameters
if [[ -z ${input_echo_1} ]]; then
	 echo "ERROR: First echo input image not specified. Exit program."
     exit 1
fi
if [[ -z ${input_echo_2} ]]; then
	 echo "ERROR: Second echo input image not specified. Exit program."
     exit 1
fi
if [[ -z ${input_echo_3} ]]; then
	 echo "ERROR: Third echo input image not specified. Exit program."
     exit 1
fi
if [[ -z ${reference} ]]; then
     echo "ERROR: Reference not specified. Exit program."
     exit 1
fi
if [[ -z ${mask} ]]; then
    echo "ERROR: Mask not specified. Exit program."
    exit 1
fi
if [[ -z ${output} ]]; then
    echo "ERROR: Output not specified. Exit program."
    exit 1
fi

# Check if the input files exist and are readable
if [[ ! -a ${input_echo_1} ]]; then
     echo "ERROR: ${input_echo_1} does not exist or is not readable. Exit program."
     exit 1
fi
if [[ ! -a ${input_echo_2} ]]; then
     echo "ERROR: ${input_echo_2} does not exist or is not readable. Exit program."
     exit 1
fi
if [[ ! -a ${input_echo_3} ]]; then
     echo "ERROR: ${input_echo_3} does not exist or is not readable. Exit program."
     exit 1
fi
if [[ ! -a ${reference} ]]; then
     echo "ERROR: ${reference} does not exist or is not readable. Exit program."
     exit 1
fi
if [[ ! -a ${mask} ]]; then
    echo "ERROR: ${mask} does not exist or is not readable. Exit program."
    exit 1
fi

# Check extensions of the input files
if [[ ${input_echo_1} != *.nii.gz ]] && [[ ${input_echo_1} != *.nii ]] && [[ ${input_echo_1} != *.img ]] && [[ ${input_echo_1} != *.img.gz ]]; then
	 echo "ERROR: ${input_echo_1} does not have .nii.gz, .nii, .img, or .img.gz extension. Exit program."
	 exit 1
fi
if [[ ${input_echo_2} != *.nii.gz ]] && [[ ${input_echo_2} != *.nii ]] && [[ ${input_echo_2} != *.img ]] && [[ ${input_echo_2} != *.img.gz ]]; then
	 echo "ERROR: ${input_echo_2} does not have .nii.gz, .nii, .img, or .img.gz extension. Exit program."
	 exit 1
fi
if [[ ${input_echo_3} != *.nii.gz ]] && [[ ${input_echo_3} != *.nii ]] && [[ ${input_echo_3} != *.img ]] && [[ ${input_echo_3} != *.img.gz ]]; then
	 echo "ERROR: ${input_echo_3} does not have .nii.gz, .nii, .img, or .img.gz extension. Exit program."
	 exit 1
fi
if [[ ${reference} != *.nii.gz ]] && [[ ${reference} != *.nii ]] && [[ ${reference} != *.img ]] && [[ ${reference} != *.img.gz ]]; then
	 echo "ERROR: ${reference} does not have .nii.gz, .nii, .img, or .img.gz extension. Exit program."
	 exit 1
fi
if [[ ${mask} != *.nii.gz ]] && [[ ${mask} != *.nii ]] && [[ ${mask} != *.img ]] && [[ ${mask} != *.img.gz ]]; then
	 echo "ERROR: ${maskt} does not have .nii.gz, .nii, .img, or .img.gz extension. Exit program."
	 exit 1
fi

#Remove extension from files
input_echo_1=`remove_ext ${input_echo_1}`
input_echo_2=`remove_ext ${input_echo_2}`
input_echo_3=`remove_ext ${input_echo_3}`

# Check if the dimensions of files are the same
xdimi1=`fslval ${input_echo_1} dim1`
xdimi2=`fslval ${input_echo_2} dim1`
xdimi3=`fslval ${input_echo_3} dim1`
xdimr=`fslval ${reference} dim1`
xdimm=`fslval ${mask} dim1`
ydimi1=`fslval ${input_echo_1} dim2`
ydimi2=`fslval ${input_echo_2} dim2`
ydimi3=`fslval ${input_echo_3} dim2`
ydimr=`fslval ${reference} dim2`
ydimm=`fslval ${mask} dim2`
zdimi1=`fslval ${input_echo_1} dim3`
zdimi2=`fslval ${input_echo_2} dim3`
zdimi3=`fslval ${input_echo_3} dim3`
zdimr=`fslval ${reference} dim3`
zdimm=`fslval ${mask} dim3`
tdimi1=`fslval ${input_echo_1} dim4`
tdimi2=`fslval ${input_echo_2} dim4`
tdimi3=`fslval ${input_echo_3} dim4`
tr=`fslval ${input_echo_1} pixdim4` # Calculate TR or sampling period for time series

if (( "${xdimi1}" != "${xdimm}" )) || (( "${xdimr}" != "${xdimm}" )) || (( "${ydimi1}" != "${ydimm}" )) || (( "${ydimr}" != "${ydimm}" )) || (( "${zdimi1}" != "${zdimm}" )) || (( "${zdimr}" != "${zdimm}" )) || (( "${xdimi1}" != "${xdimi2}" )) || (( "${xdimi1}" != "${xdimi3}" )) || (( "${ydimi1}" != "${ydimi2}" )) || (( "${ydimi1}" != "${ydimi3}" )) || (( "${zdimi1}" != "${zdimi2}" )) || (( "${zdimi1}" != "${zdimi3}" )) || (( "${tdimi1}" != "${tdimi2}" )) || (( "${tdimi1}" != "${tdimi3}" )); then
    echo "ERROR: Dimensions of files do not match. Exit program."
    exit 1
fi

# Check the $FSLOUTPUTTYPE and assign the extension extension
if [ ${FSLOUTPUTTYPE} == 'NIFTI_GZ' ]; then
  file_ext=nii.gz
elif [ ${FSLOUTPUTTYPE} == 'NIFTI' ]; then
  file_ext=nii
elif [ ${FSLOUTPUTTYPE} == 'NIFTI_PAIR_GZ' ]; then
  file_ext=img.gz
elif [ ${FSLOUTPUTTYPE} == 'NIFTI_PAIR' ]; then
  file_ext=img
elif [ ${FSLOUTPUTTYPE} == 'ANALYZE_GZ' ]; then
  file_ext=img.gz
elif [ ${FSLOUTPUTTYPE} == 'ANALYZE' ]; then
  file_ext=img
else
    echo "ERROR: ${FSLOUTPUTTYPE} is not supported. Exit program."
    exit 1
fi

# Move input files to temporary folder and enter temporary folder
tmp_folder=`mktemp -u tmp.XXXXXXXXXX`
mkdir ${tmp_folder}
imcp ${input_echo_1} ${input_echo_2} ${input_echo_3} ${reference} ${mask} ./${tmp_folder}
cd ${tmp_folder}

#Remove path from input files
input_echo_1=$(basename ${input_echo_1})
input_echo_2=$(basename ${input_echo_2})
input_echo_3=$(basename ${input_echo_3})
reference=$(basename ${reference})
mask=$(basename ${mask})

# Check if mask has any empty slices before running motion correction
fslsplit ${mask} mask_slice -z ## split ${mask} into slices
last_slice=$(echo "scale=0; $zdimi1-1" | bc) #get top z slice number with 0 being first slice in z direction

for ((i=0; i<=$last_slice; i++)) ; do ##for loop for slices
  slice_number="$(printf "%04d" ${i})"
  min=`fslstats mask_slice${slice_number} -R | cut -d " " -f1`
  max=`fslstats mask_slice${slice_number} -R | cut -d " " -f2`
  if [ $(echo "${min} < 0" | bc) == 1 ] || [ $(echo "${max} <= 0" | bc) == 1 ] || [ $(echo "${min} >= ${max}" | bc ) == 1 ]; then # Needed to use the bc command to compare integer to floating point variable
    echo "ERROR: Mask has empty slices. Exit program."
    cd ..
    rm -rf ${tmp_folder}
    exit 1
  fi
done

# Perform motion correction
last_volume=$(echo "scale=0; $tdimi1-1" | bc) #Find index of last volume

fslsplit ${reference} ref_slice -z ## split ${reference} into slices 

fslsplit ${input_echo_1} echo_1_vol -t
fslsplit ${input_echo_2} echo_2_vol -t
fslsplit ${input_echo_3} echo_3_vol -t

for ((i=0; i<=$last_volume; i++)); do 
  vol="$(printf "vol%04d" ${i})"
  fslsplit echo_1_${vol} echo_1_${vol}_slice -z # Split each volume of input into slices
  fslsplit echo_2_${vol} echo_2_${vol}_slice -z # Split each volume of input into slices
  fslsplit echo_3_${vol} echo_3_${vol}_slice -z # Split each volume of input into slices
done

for ((i=0; i<=$last_slice; i++)) ; do #For loop for slices
  slice="$(printf "slice%04d" ${i})"
  for ((j=0; j<=$last_volume; j++)); do  #Performs FLIRT for each volume of the slice specified by ${vol} and ${slice}  
    vol="$(printf "vol%04d" ${j})"
    flirt -in echo_1_${vol}_${slice} -ref ref_${slice} -out echo_1_${vol}_${slice}_mcf -omat ${vol}_${slice}_mcf.mat -bins 256 -cost normcorr -nosearch -2D -refweight mask_${slice} -interp trilinear
    echo "flirt -in echo_1_${vol}_${slice} -ref ref_${slice} -out echo_1_${vol}_${slice}_mcf -omat ${vol}_${slice}_mcf.mat -bins 256 -cost normcorr -nosearch -2D -refweight mask_${slice} -interp trilinear"
	
	flirt -in echo_2_${vol}_${slice} -ref ref_${slice} -applyxfm -init ${vol}_${slice}_mcf.mat -out echo_2_${vol}_${slice}_mcf -interp trilinear -2D -setbackground 0
	flirt -in echo_3_${vol}_${slice} -ref ref_${slice} -applyxfm -init ${vol}_${slice}_mcf.mat -out echo_3_${vol}_${slice}_mcf -interp trilinear -2D -setbackground 0
	
  done
  v="echo_1_vol????_${slice}_mcf.${file_ext}"
  fslmerge -tr echo_1_merge_${slice} ${v} ${tr} #Merge motion corrected volumes of the ${slice_number} slice together
  v="echo_2_vol????_${slice}_mcf.${file_ext}"
  fslmerge -tr echo_2_merge_${slice} ${v} ${tr} #Merge motion corrected volumes of the ${slice_number} slice together
  v="echo_3_vol????_${slice}_mcf.${file_ext}"
  fslmerge -tr echo_3_merge_${slice} ${v} ${tr} #Merge motion corrected volumes of the ${slice_number} slice together
done

v="echo_1_merge_slice????.${file_ext}"
fslmerge -z ${input_echo_1}_${output} $v #Merge the slices together
v="echo_2_merge_slice????.${file_ext}"
fslmerge -z ${input_echo_2}_${output} $v #Merge the slices together
v="echo_3_merge_slice????.${file_ext}"
fslmerge -z ${input_echo_3}_${output} $v #Merge the slices together

v="vol0???_slice????_mcf.mat"
mkdir ${output}_mat #Save the .mat files for later use
mv $v ./${output}_mat/
tar -czf ${output}_mat.tar.gz ./${output}_mat

#Compute mean and TSNR images
fslmaths ${input_echo_1}_${output} -Tmean ${input_echo_1}_${output}_mean
fslmaths ${input_echo_1}_${output} -Tstd ${input_echo_1}_${output}_std
fslmaths ${input_echo_1}_${output}_mean -div ${input_echo_1}_${output}_std ${input_echo_1}_${output}_tsnr

fslmaths ${input_echo_2}_${output} -Tmean ${input_echo_2}_${output}_mean
fslmaths ${input_echo_2}_${output} -Tstd ${input_echo_2}_${output}_std
fslmaths ${input_echo_2}_${output}_mean -div ${input_echo_2}_${output}_std ${input_echo_2}_${output}_tsnr

fslmaths ${input_echo_3}_${output} -Tmean ${input_echo_3}_${output}_mean
fslmaths ${input_echo_3}_${output} -Tstd ${input_echo_3}_${output}_std
fslmaths ${input_echo_3}_${output}_mean -div ${input_echo_3}_${output}_std ${input_echo_3}_${output}_tsnr

#Copy files to parent directory
cp ${output}_mat.tar.gz ../
imcp ${input_echo_1}_${output} ${input_echo_1}_${output}_mean ${input_echo_1}_${output}_tsnr ../
imcp ${input_echo_2}_${output} ${input_echo_2}_${output}_mean ${input_echo_2}_${output}_tsnr ../
imcp ${input_echo_3}_${output} ${input_echo_3}_${output}_mean ${input_echo_3}_${output}_tsnr ../

#Move up to parent directory
cd ..

#Delete temporary folder

rm -rf ${tmp_folder}

echo "Run the following to view the results:"
echo "fslview_deprecated ${input_echo_1}_${output} ${input_echo_1}_${output}_mean ${input_echo_1}_${output}_tsnr -l render3 &"

exit 0
