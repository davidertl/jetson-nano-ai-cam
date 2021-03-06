#/bin/bash

#gst-launch-1.0 v4l2src device="/dev/video0" ! "video/x-raw, width=(int)1920, height=(int)1080, format=(string)YUY2" ! xvimagesink -e

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            #gst-launch-1.0 v4l2src io-mode=2 device=/dev/video0 do-timestamp=true ! video/x-raw, format=YUY2, width=1920, height=1080, framerate=30/1 ! videoconvert ! video/x-raw, format=I420 !   nvvidconv ! nvoverlaysink sync=false async=false  -e


#gst-launch-1.0 v4l2src  device=/dev/video0 do-timestamp=true ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegparse ! nvjpegdec ! video/x-raw ! nvvidconv ! 'video/x-raw(memory:NVMM)' ! fpsdisplaysink video-sink=fakesink  text-overlay=false sync=false async=false -e


#gst-launch-1.0 v4l2src device=/dev/video0 do-timestamp=true ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegparse ! nvjpegdec ! video/x-raw ! nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)RGBA' ! nvoverlaysink sync=false -e

#gst-launch-1.0 v4l2src io-mode=2 device=/dev/video0 ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegparse ! nvjpegdec ! video/x-raw !  'video/x-raw(memory:NVMM),format=NV12' !  fpsdisplaysink video-sink=nvoverlaysink text-overlay=true -v -e

gst-launch-1.0 v4l2src io-mode=2 device=/dev/video0 do-timestamp=true ! video/x-raw, format=YUY2, width=1920, height=1080, framerate=30/1 ! videoconvert ! video/x-raw, format=I420 !   nvvidconv ! fpsdisplaysink video-sink=nvoverlaysink text-overlay=true -v -e

gst-launch-1.0 v4l2src device='/dev/video0' ! 'video/x-raw, format=(string)YUY2, width=(int)1920, height=(int)1080, framerate=(fraction)30/1' ! nvvidconv ! nvv4l2h264enc ! h264parse ! flvmux ! rtmpsink location='rtmp://192.168.1.10:1935/live/35'


gst-launch-1.0 v4l2src device='/dev/video0' ! 'video/x-raw, format=(string)YUY2, width=(int)1920, height=(int)1080, framerate=(fraction)30/1' !  videoconvert ! video/x-raw, format=I420 ! nvvidconv ! nvv4l2h264enc ! h264parse ! flvmux ! rtmpsink location='rtmp://a.rtmp.youtube.com/live2/wemg-rygj-ye4v-4z6u'

#rtmp://a.rtmp.youtube.com/live2/wemg-rygj-ye4v-4z6u


	
gst-launch-1.0 -v videotestsrc ! nvvidconv ! nvv4l2h264enc ! h264parse ! flvmux  ! rtmpsink location='rtmp://a.rtmp.youtube.com/live2/wemg-rygj-ye4v-4z6u live=1'




#works

#works on vlc/potplayer/web player
#rtmp://192.168.1.10/live/demo2


#gst-launch-1.0 -v videotestsrc ! nvvidconv ! nvv4l2h264enc ! h264parse ! flvmux  ! rtmpsink location='rtmp://192.168.1.10/live/demo2' -e

#gst-launch-1.0 -v v4l2src io-mode=2 device='/dev/video0' ! 'video/x-raw, format=(string)YUY2, width=(int)1920, height=(int)1080, framerate=(fraction)60/1' !  nvvidconv ! nvv4l2h264enc ! h264parse ! flvmux ! rtmpsink location='rtmp://192.168.1.10/live/demo2' -e

gst-launch-1.0 ximagesrc use-damage=0 remote=1 ! videoconvert ! omxh264enc control-rate=2 bitrate=4000000 ! video/x-h264, stream-format=byte-stream ! rtph264pay mtu=1400 ! udpsink host=192.168.1.10 port=5000 sync=false async=false

export DISPLAY=:0

python3 ~/jetson-nano-ai-cam/nano_cam_test.py --video 'filesrc location=/home/jetsonnano/test-videos/LIVE-Recording-20200414-174105.mp4 ! qtdemux name=demux demux.video_0 ! queue ! h265parse ! nvv4l2decoder enable-max-performance=1 ! nvvidconv ! video/x-raw, format=BGRx, framerate=60/1 ! queue !  videoconvert ! queue ! video/x-raw, format=BGR,framerate=60/1 ! appsink sync=true'

##works to load h264 mp4 file

python3 ~/jetson-nano-ai-cam/nano_cam_test.py --video 'filesrc location=/home/jetsonnano/test-videos/songs.mp4 ! qtdemux ! queue ! h264parse ! omxh264dec ! nvvidconv ! video/x-raw, format=BGRx ! queue ! videoconvert ! queue ! video/x-raw, format=BGR ! appsink async=false'

#resize to 1280x720
python3 ~/jetson-nano-ai-cam/nano_cam_test.py --video 'filesrc location=/home/jetsonnano/test-videos/songs.mp4 ! qtdemux ! queue ! h264parse ! omxh264dec ! nvvidconv ! video/x-raw, width=(int)1280, height=(int)720, format=BGRx ! queue ! videoconvert ! queue ! video/x-raw, format=BGR ! appsink async=false'

#use ffprobe to get codec_name
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height -of default=noprint_wrappers=1:nokey=1  /home/jetsonnano/test-videos/songs.mp4