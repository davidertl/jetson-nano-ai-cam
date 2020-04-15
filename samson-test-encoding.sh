clear
#nvgstcapture --camsrc=0 --mode=2  --enc-bitrate=400000 --file-name=test-capture.mp4  --cap-dev-node=0 

#--video_enc=0
#--file_type=mp4 
#--color=2
#--prev_res=3



# pcr:4
# br: 4000000

#convert h264 video files to inverted

## omxh265dec enable-low-outbuffer=1 disable-dvfs=1 
## nvv4l2decoder enable-max-performance=1

<< 'MULTILINE-COMMENT'

gst-launch-1.0 filesrc location=~/test-videos/LIVE-Recording-20200414-180630.mp4 ! \
  qtdemux name=demux demux.video_0 ! queue ! h265parse ! nvv4l2decoder enable-max-performance=1 ! \
  nvoverlaysink -e

MULTILINE-COMMENT


<< 'MULTILINE-COMMENT'
gst-launch-1.0 filesrc location=~/test-videos/inverted-LIVE-Recording-20200414-180630.mp4 ! \
   qtdemux name=demux demux.video_0 ! queue ! h265parse ! nvv4l2decoder enable-max-performance=1 ! \
   nvvidconv flip-method=2 ! \
   nvv4l2h265enc bitrate=7000000 ! h265parse ! qtmux ! \
   filesink location=LIVE-Recording-20200414-180630.mp4 -e
MULTILINE-COMMENT

   #nvoverlaysink -e