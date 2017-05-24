#
#	NormalizeAndDiscoverNovelJunctions.sh
#	May 18th, 2017
#	dennis.kao@sickkids.ca
#
#	
#	Usage: input=input.txt sample=sample ./NormalizeAndDiscoverNovelJunctions.sh
#	OR		input=input.txt sample=sample mindread=10 threshold=0.5 transcript_model=gencode.txt ./NormalizeAndDiscoverNovelJunctions.sh
#
#
#	Input - file generated by SpliceJunctionDiscovery.py or rnaseq.splice_junction_discovery.pbs
#	Output - Generates 3 files in the same directory as the input file: 
# 		1) norm_input.txt: input file with an additional column for normalized read counts
# 		2) novel_sample_norm_input.txt: file from 1) that only includes splice junction sites specific to the sample
#		3) threshold_novel_sample_norm_input.txt: file from 2) with splice sites with a normalized read count > threshold

beryl_home=~/tools/MendelianRNA-seq
baseDir=`pwd`

#	Mandatory parameters
if [ -z "$input" ];
	then
		echo "ERROR - Specify an input file"
		exit 1
fi

if [ -z "$sample" ];
	then
		echo "ERROR - Specify the sample name used in the input file"
		exit 2
fi

#	Default parameters
if [ -z "$minread" ];
	then
		minread=10
fi

if [ -z "$threshold" ];
	then
		threshold=0.5
fi

if [ -z "$transcript_model" ];
	then
		transcript_model="$beryl_home/gencode.comprehensive.splice.junctions.txt"
fi

inputFileName=`basename $input`
outputFilePath=`dirname $input`

step1Output="norm_"$inputFileName
step2Output="novel_"$sample"_norm_"$inputFileName
step3Output="threshold"$threshold"_novel_"$sample"_norm_"$inputFileName

#	Actual computation
echo -e "\n========	RUNNING NormalizeAndDiscoverNovelJunctions.sh	========\n"

echo "1. Normalizing read counts in $input"
$beryl_home/Analysis/NormalizeSpliceJunctionValues.py -transcript_model=$transcript_model -splice_file=$input --normalize > $outputFilePath/$step1Output 
echo -e "Output: $step1Output\n"

echo "2. Filtering for minimum read count and novel junctions" 
cat $outputFilePath/$step1Output | grep $sample | awk "{ if (\$5 == 1 && \$4 >= $minread ) print \$0 }" > $outputFilePath/$step2Output
echo -e "Output: $step2Output\n"

echo "3. Filtering out for neither annotated junctions and a minimum normalize read count"
cat $outputFilePath/$step2Output | grep -v "Neither annotated" | sed 's/:10-1-M//' | sed 's/:10-1-M//' | awk "{if (\$9 > $threshold) print \$0}" > $outputFilePath/$step3Output
echo -e "Output: $step3Output\n"

echo "DONE - NormalizeAndDiscoverNovelawJunctions.sh has finished running"
echo "Output files can be found in: $outputFilePath"
