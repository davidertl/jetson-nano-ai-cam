#bin/bash
today=`date +%Y-%m-%d.%H:%M:%S`


cd /home/samson/install_yolo/AlexeyAB/darknet


#can only do 10fps in high power mode because otherwise it cannon process fast enough and cause artifacts
#can only do 5fps in low power mode


##slowest
#./darknet detector demo cfg/samson-obj.data cfg/samson-yolov3-tiny.cfg backup/samson-yolov3-tiny_final.weights "v4l2src io-mode=2 device=/dev/video1 do-timestamp=true ! video/x-h264, width=1920, height=1080, framerate=10/1, streamformat=byte-stream !  omxh264dec ! videoconvert ! appsink sync=false async=false" --thresh 0.4

##jpegdec > nvjpegdec
./darknet detector demo cfg/samson-obj.data cfg/samson-yolov3-tiny.cfg backup/samson-yolov3-tiny_final.weights "v4l2src io-mode=2 device=/dev/video0 ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegparse ! jpegdec ! videoscale ! videoconvert ! tee name=t t.! appsink sync=false async=false" -dont_show -mjpeg_port 8090 -json_port 8070 -map


##best for lowpower mode, as it can only do 5fps, use YUV gives least lag


#hdmi capture card
#./darknet detector demo cfg/samson-obj.data cfg/samson-yolov3-tiny.cfg backup/samson-yolov3-tiny_final.weights "v4l2src io-mode=2 device=/dev/video1 do-timestamp=true ! video/x-raw, width=1920, height=1080, framerate=30/1 ! videoconvert ! tee name=t   t. !  appsink sync=false async=false" --thresh 0.6


#./darknet detector demo cfg/samson-obj.data cfg/samson-yolov3-tiny.cfg backup/samson-yolov3-tiny_final.weights "v4l2src io-mode=2 device=/dev/video0 do-timestamp=true ! video/x-raw, width=1920, height=1080, framerate=5/1 ! videoconvert ! tee name=t   t. !  appsink sync=false async=false" -dont_show -mjpeg_port 8090 -json_port 8070 -map

v4l2-ctl --device=/dev/video1 --set-ctrl brightness=146
v4l2-ctl --device=/dev/video1 --set-ctrl saturation=106
v4l2-ctl --device=/dev/video1 --set-ctrl hue=3
v4l2-ctl --device=/dev/video1 --set-ctrl contrast=130


#gst-launch-1.0 v4l2src device="/dev/video1" ! "video/x-raw, width=(int)1920, height=(int)1080, framerae=30/1, format=(string)YUY2" ! xvimagesink sync=false -e


#./darknet detector demo cfg/samson-obj.data cfg/samson-yolov3-tiny.cfg backup/samson-yolov3-tiny_final.weights "v4l2src io-mode=1 device=/dev/video1 do-timestamp=true ! video/x-raw, width=1600, height=1200, framerate=5/1 ! videoconvert ! tee name=t   t. !  appsink sync=false async=false" --thresh 0.6

#nvarguscamerasrc
#./darknet detector demo cfg/samson-obj.data cfg/samson-yolov3-tiny.cfg backup/samson-yolov3-tiny_final.weights "nvarguscamerasrc ! video/x-raw(memory:NVMM), width=(int)1600, height=(int)1200, format=(string)NV12, framerate=(fraction)30/1 ! nvvidconv flip-method=2 ! video/x-raw, format=(string)BGRx ! videoconvert ! video/x-raw, format=(string)BGR ! appsink" --thresh 0.4


#sony starvis
#./darknet detector demo cfg/samson-obj.data cfg/samson-yolov3-tiny.cfg backup/samson-yolov3-tiny_final.weights "v4l2src io-mode=2 device=/dev/video0 do-timestamp=true ! video/x-raw, width=1920, height=1080, framerate=30/1 ! videoconvert ! tee name=t   t. !  appsink sync=false async=false" --thresh 0.4 -dont_show
