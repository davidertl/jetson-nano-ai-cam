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

#mjpg-streamer   
mjpg-streamer -i "input_uvc.so --device /dev/video0 -r 1920x1080 -f 30 -q 60" 

mjpg-streamer -i "gst-launch-1.0 v4l2src io-mode=2 device=/dev/video0 do-timestamp=true ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegparse ! jpegdec !  nvvidconv  ! 'video/x-raw(memory:NVMM), format=(string)NV12' ! nvvidconv ! nvegltransform ! nveglglessink -e"

#http://192.168.1.89:8080/?action=stream  




##Works for streaming video0
gst-launch-1.0 rtpbin name=rtpbin v4l2src device=/dev/video0 io-mode=2 do-timestamp=true ! "video/x-raw, format=(string)YUY2, width=(int)1920, height=(int)1080" ! nvvidconv ! "video/x-raw(memory:NVMM), format=(string)I420" ! videoconvert ! omxh264enc bitrate=7000000 insert-sps-pps=true preset-level=1 profile=8 ! 'video/x-h264, level=(string)5.1, stream-format=(string)byte-stream' ! h264parse ! rtph264pay mtu=1400 config-interval=1 pt=96 ! udpsink host=192.168.1.10 port=5000

##works for streaming x11 image, however will be slow during inference, and will lag
gst-launch-1.0 rtpbin name=rtpbin ximagesrc use-damage=0 remote=1 ! videoconvert ! omxh264enc bitrate=7000000 insert-sps-pps=true preset-level=1 profile=8 ! 'video/x-h264, level=(string)5.1, stream-format=(string)byte-stream' ! h264parse ! rtph264pay mtu=1400 config-interval=1 pt=96 ! udpsink host=192.168.1.10 port=5000


#doesn't work for 265
#gst-launch-1.0 rtpbin name=rtpbin v4l2src device=/dev/video0 io-mode=2 do-timestamp=true ! "video/x-raw, format=(string)YUY2, width=(int)1920, height=(int)1080" ! nvvidconv ! 'video/x-raw(memory:NVMM), width=1920, height=1080, format=NV12, framerate=60/1' ! nvv4l2h265enc bitrate=8000000 ! rtph265pay mtu=1400 ! udpsink host=$CLIENT_IP port=5000 sync=false async=false


#success
#https://stackoverflow.com/questions/56263099/jetson-tx2-multicast-udp-stream-with-gstreamer

##jetson.sdp
#
#v=0
#c=IN IP4 239.127.1.21
#m=video 5000 RTP/AVP 96 #
#a=rtpmap:96 H264/90000
#


nano_cam_test.py --video 'v4l2src io-mode=2 device=/dev/video0 do-timestamp=true ! video/x-raw, format=YUY2, width=1920, height=1080, framerate=60/1 !  videoconvert ! video/x-raw, format=BGR ! appsink sync=false async=true '