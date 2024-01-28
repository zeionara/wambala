#!/bin/bash

set -e

source_dir="$1"
destination_dir="${2:-assets}"

if test -z "$source_dir"; then
  echo "Source dir is required"
  exit 1
fi

destination_file="$(echo $source_dir | rev | cut -d '/' -f1 | rev).mp4"

if test ! -d "$destination_dir"; then
  mkdir -p "$destination_dir"
fi

tmp_root=/tmp/wambala
aspect_ratio="1920:1080"
encoder='h264_nvenc'

# ffmpeg -i $root/17064367211710.mp4 -i $root/17064368545480.mp4 -i $root/17064368545671.webm -filter_complex concat=n=3:v=1:a=1 $root/output.mp4
# ffmpeg -i $root/17064367211710.mp4 -i $root/17064368545480.mp4 -i $root/17064368545671.webm -filter_complex "[0:v]scale=1280:720[v0];[1:v]scale=1280:720[v1];[2:v]scale=1280:720[v2];[v0][0:a][v1][1:a][v2][2:a]concat=n=3:v=1:a=1[v][a]" -map "[v]" -map "[a]" -strict -2 $root/output.mp4
# ffmpeg -i $root/17064367211710.mp4 -filter_complex "[0:v]scale=1280:720[v0]" -map "[v]" -map "[a]" -strict -2 $root/output.mp4
# ffmpeg -i $root/17064367211710.mp4 -i $root/17064368545480.mp4 -c:v h264_nvenc -filter_complex "[0]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1[v0];[1]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1[v1];[v0][0:a:0][v1][1:a:0]concat=n=2:v=1:a=1[v][a]" -map "[v]" -map "[a]" $root/output.mp4

# ffmpeg -i $root/17064367211710.mp4 -c:v libx264 -c:a aac -strict experimental $root/output.mp4
# ffmpeg -i $root/17064367211710.mp4 -filter_complex "[0:v]scale=1024:1024[v];[v]setdar=1:1[vout];[0:a]aformat=sample_fmts=fltp:channel_layouts=stereo[aout]" -map "[vout]" -map "[aout]" -c:v libx264 -c:a aac -strict experimental $root/output.mp4
# ffmpeg -i $root/17064367211710.mp4 -filter_complex "[0:v]scale=$aspect_ratio:force_original_aspect_ratio=decrease,pad=$aspect_ratio:(ow-iw)/2:(oh-ih)/2[v];[v]setdar=1:1[vout];[0:a]aformat=sample_fmts=fltp:channel_layouts=stereo[aout]" -map "[vout]" -map "[aout]" -c:v $encoder -c:a aac -strict experimental $root/output.mp4 -y
# ffmpeg -i $root/17064367211710.mp4 -filter_complex "[0:v]scale=$aspect_ratio:force_original_aspect_ratio=decrease,pad=$aspect_ratio:(ow-iw)/2:(oh-ih)/2[vout];[0:a]aformat=sample_fmts=fltp:channel_layouts=stereo[aout]" -map "[vout]" -map "[aout]" -c:v $encoder -c:a aac -strict experimental $root/output.mp4 -y

# ffmpeg -i $root/17064367211710.mp4 -i $root/17064368545480.mp4 -filter_complex "[0:v]scale=1024:1024:force_original_aspect_ratio=decrease,pad=1024:1024:(ow-iw)/2:(oh-ih)/2[v0];[1:v]scale=1024:1024:force_original_aspect_ratio=decrease,pad=1024:1024:(ow-iw)/2:(oh-ih)/2[v1];[0:a]aformat=sample_fmts=fltp:channel_layouts=stereo[a0];[1:a]aformat=sample_fmts=fltp:channel_layouts=stereo[a1]" -map "[v0]" -map "[a0]" -map "[v1]" -map "[a1]" -c:v libx264 -c:a aac -strict experimental output_joined_with_audio.mp4

# ffmpeg -i $root/17064367211710.mp4 -i $root/17064368545480.mp4 -filter_complex \
#   "[0:v]scale=1024:1024:force_original_aspect_ratio=decrease,pad=1024:1024:(ow-iw)/2:(oh-ih)/2[v0]; \
#    [1:v]scale=1024:1024:force_original_aspect_ratio=decrease,pad=1024:1024:(ow-iw)/2:(oh-ih)/2[v1]; \
#    [0:a]aformat=sample_fmts=fltp:channel_layouts=stereo[a0]; \
#    [1:a]aformat=sample_fmts=fltp:channel_layouts=stereo[a1]" \
#   -map "[vout]" -map "[aout]" -c:v libx264 -c:a aac -strict experimental $root/output.mp4

if test -d $tmp_root; then
  rm -rf $tmp_root
fi

mkdir -p $tmp_root

# setdar=1:1,
n_files=0
for file in $source_dir/*; do
  n_files=$((n_files + 1))
done

i=1
for file in $source_dir/*; do
  file="$(echo $file | rev | cut -d '/' -f1 | rev)"
  output_file=$(echo $file | cut -d '.' -f1).mp4

  echo handling $file \($i / $n_files\)
  i=$((i + 1))

  ffmpeg -fflags +genpts -i $source_dir/$file -f lavfi -t 0.1 -i anullsrc \
    -filter_complex " \
      [0:v]scale=$aspect_ratio:force_original_aspect_ratio=decrease,pad=$aspect_ratio:(ow-iw)/2:(oh-ih)/2,fps=30,setpts=PTS-STARTPTS[vout]; \
      aformat=sample_fmts=fltp:channel_layouts=stereo,aresample=44100[aout]
    " \
    -map "[vout]" -map "[aout]" -c:v $encoder -c:a aac -strict experimental $tmp_root/$output_file
  echo "file '$output_file'" >> $tmp_root/index.txt
done

# cat $tmp_root/index.txt

ffmpeg -fflags +genpts -f concat -i $tmp_root/index.txt -c:v $encoder -c:a aac -strict experimental $destination_dir/$destination_file -y
