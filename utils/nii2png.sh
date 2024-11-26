#!/bin/bash
# 
#
# Created by Kenneth Weber on 2/25/2019.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#

function usage()
{
cat << EOF

DESCRIPTION
  Convert 3D nii volume to coronal, sagittal, and axial png images. This was last updated using FSL Version 5.0.
  
USAGE
  `basename ${0}` -i <input>

MANDATORY ARGUMENTS
  -i <input>                   Input image
  
EOF
}

if [ ! ${#@} -gt 0 ]; then
    usage `basename ${0}`
    exit 1
fi

#Initialization of variables

scriptname=${0}
input=
while getopts “hi:r:m:o:” OPTION
do
	case $OPTION in
	 h)
			usage
			exit 1
			;;
         i)
		 	input=$OPTARG
         		;;
         ?)
             usage
             exit
             ;;
     esac
done

# Check if the mandatory parameters were input

if [[ -z ${input} ]]; then
	 echo "ERROR: Input not specified. Exit program."
     exit 1
fi

# Check if the input files exist and are readable
if [[ ! -a ${input} ]]; then
     echo "ERROR: ${input} does not exist or is not readable. Exit program."
     exit 1
fi

# Check extensions of the input files

if [[ ${input} != *.nii.gz ]] && [[ ${input} != *.nii ]] && [[ ${input} != *.img ]] && [[ ${input} != *.img.gz ]]; then
	 echo "ERROR: ${input} does not have .nii.gz, .nii, .img, or .img.gz extension. Exit program."
	 exit 1
fi

# Check if 3D not 4D of the input files

dim4=`fslval ${input} dim4`
if (( ${dim4} != 1 )); then
	 echo "ERROR: ${input} is 4D. Exit program."
	 exit 1
fi

#Remove extension from files

input=`remove_ext ${input}`

# Check if the dimensions of files are the same

xdimi=`fslval ${input} dim1`
ydimi=`fslval ${input} dim2`
zdimi=`fslval ${input} dim3`

#Remove path from input files

input=$(basename ${input})

#Perform motion correction

for ((i=0; i<=xdimi; i++));do
	slicer ${input} -u -x -${i} ${input}_x_${i}.png
done

for ((i=0; i<=ydimi; i++));do
	slicer ${input} -u -y -${i} ${input}_y_${i}.png
done

for ((i=0; i<=zdimi; i++));do
	slicer ${input} -u -z -${i} ${input}_z_${i}.png
done

exit 0

