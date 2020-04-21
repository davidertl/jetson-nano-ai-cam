#!/bin/bash

#works
#https://github.com/umlaeute/v4l2loopback
#sudo modprobe v4l2loopback video_nr=8,9  card_label="Virtual Video Sink 8","Virtual Video Sink 9"  buffers=1
#gst-launch-1.0 -v videotestsrc ! video/x-raw, width=1920, height=1080, format=BGRx ! v4l2sink device=/dev/video9
#gst-launch-1.0 v4l2src device=/dev/video9 ! videoconvert ! ximagesink
#sudo modprobe -r v4l2loopback

#gst-launch-1.0 v4l2src device=/dev/video0 ! "video/x-raw,width=1920,height=1080,framerate=30/1" ! tee name=rec ! queue ! v4l2sink device=/dev/video8 rec. ! queue ! v4l2sink device=/dev/video9

~/skip_sudo.sh

declare -A VIDEO_CAMERA_INPUTS
declare -A yolo_detection_options

#upload_detections=true
upload_detections=false
myIPAddress=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | tr '\n' '|' )
myIPAddress=${myIPAddress::-1}
echo 255 | sudo tee /sys/devices/pwm-fan/target_pwm

v4l2src_pipeline_str=""
v4l2src_ending_pipeline_str=""
nvvidconv_flip=""
resize_to_resolution="N/A"
video_file_for_v4l2src_pipeline=""

test_videos_dir="/home/jetsonnano/test-videos"

#map it to HDMI output
export DISPLAY=:0

#today=`date +%Y-%m-%d.%H:%M:%S`
today=`date +%Y%m%d-%H%M%S`

yolo_detection_options[0,0]="Face Mask (Require GUI X11)"
yolo_detection_options[0,1]="~/trained-weight/mask2020/obj.edge.data"
yolo_detection_options[0,2]="~/trained-weight/mask2020/yolov3-tiny-var.cfg"
yolo_detection_options[0,3]="~/trained-weight/mask2020/yolov3-tiny-var.weights"
yolo_detection_options[0,4]="-thresh 0.70 -mjpeg_port 8090 -json_port 8070 "

yolo_detection_options[1,0]="Face Mask No display (http://${myIPAddress}:8090)"
yolo_detection_options[1,1]="${yolo_detection_options[0,1]}" ##same
yolo_detection_options[1,2]="${yolo_detection_options[0,2]}" ##same
yolo_detection_options[1,3]="${yolo_detection_options[0,3]}" ##same
yolo_detection_options[1,4]="-dont_show ${yolo_detection_options[0,4]} "

yolo_detection_options[2,0]="Face Mask High accuracy (Require GUI X11)"
yolo_detection_options[2,1]="~/trained-weight/mask2020/obj.edge.data"
yolo_detection_options[2,2]="~/trained-weight/mask2020/yolov3-tiny-832.cfg"
yolo_detection_options[2,3]="~/trained-weight/mask2020/yolov3-tiny-832.weights"
yolo_detection_options[2,4]="-thresh 0.70 -mjpeg_port 8090 -json_port 8070 "

yolo_detection_options[3,0]="Face Mask High accuracy (http://${myIPAddress}:8090)"
yolo_detection_options[3,1]="${yolo_detection_options[2,1]}" ##same
yolo_detection_options[3,2]="${yolo_detection_options[2,2]}" ##same
yolo_detection_options[3,3]="${yolo_detection_options[2,3]}" ##same
yolo_detection_options[3,4]="-dont_show ${yolo_detection_options[2,4]} "

yolo_detection_options[4,0]="++Best HK Police 512+(Require GUI X11)"
yolo_detection_options[4,1]="~/trained-weight/police2020/obj.edge.data"
yolo_detection_options[4,2]="~/trained-weight/police2020/yolov3-tiny-512-rotate-40.cfg"
yolo_detection_options[4,3]="~/trained-weight/police2020/yolov3-tiny-512-rotate-40-more_var.weights"
yolo_detection_options[4,4]="-thresh 0.3 -mjpeg_port 8090 -json_port 8070 "

yolo_detection_options[5,0]="HK Police 512+(http://${myIPAddress}:8090)"
yolo_detection_options[5,1]="${yolo_detection_options[4,1]}" ##same
yolo_detection_options[5,2]="${yolo_detection_options[4,2]}" ##same
yolo_detection_options[5,3]="${yolo_detection_options[4,3]}" ##same
yolo_detection_options[5,4]="-dont_show ${yolo_detection_options[4,4]} "

yolo_detection_options[6,0]="HK Police 512 (Require GUI X11)"
yolo_detection_options[6,1]="~/trained-weight/police2020/obj.edge.data"
yolo_detection_options[6,2]="~/trained-weight/police2020/yolov3-tiny-512.cfg"
yolo_detection_options[6,3]="~/trained-weight/police2020/yolov3-tiny-512.weights"
yolo_detection_options[6,4]="-thresh 0.3 -mjpeg_port 8090 -json_port 8070 "

yolo_detection_options[7,0]="80 Different objects (Require GUI X11)"
yolo_detection_options[7,1]="~/trained-weight/reference/coco.data"
yolo_detection_options[7,2]="~/trained-weight/reference/yolov3-tiny.cfg"
yolo_detection_options[7,3]="~/trained-weight/reference/yolov3-tiny.weights"
yolo_detection_options[7,4]="-thresh 0.40 -mjpeg_port 8090 -json_port 8070 "

yolo_detection_options[8,0]="80 Different objects (http://${myIPAddress}:8090)"
yolo_detection_options[8,1]="${yolo_detection_options[6,1]}" ##same
yolo_detection_options[8,2]="${yolo_detection_options[6,2]}" ##same
yolo_detection_options[8,3]="${yolo_detection_options[6,3]}" ##same
yolo_detection_options[8,4]="-dont_show ${yolo_detection_options[6,4]} "

yolo_detection_options[9,0]="*HK Police 512 no angle (Require GUI X11)"
yolo_detection_options[9,1]="~/trained-weight/police2020/obj.edge.data"
yolo_detection_options[9,2]="~/trained-weight/police2020/yolov3-tiny.cfg"
yolo_detection_options[9,3]="~/trained-weight/police2020/yolov3-tiny.weights.ok"
yolo_detection_options[9,4]="-thresh 0.3 -mjpeg_port 8090 -json_port 8070 "



#pause
clear

display_usage_help()
{
printf "Usages \n"
printf "./select-camera.sh start :::: Auto detect resource and restart, log file: restart-log.log\n"
printf "./select-camera.sh once :::: Auto start, without restart\n"
printf "./select-camera.sh stop :::: stop and quit loop\n"
printf "once defaults to /dev/video0\n\n"
}

#sudo sh -c "echo -1 > /sys/module/usbcore/parameters/autosuspend"

echo $BASHPID > ~/jetson-nano-ai-cam/SELECTCAMERA_PID

nvvidconv_flip=""

pause()
{
	read -n1 -r -p "Press any key to continue..." key
	case $key in
		 $'\e')
		 printf "\n(Escape key)\n"
		 printf "v4l2src_pipeline_str:\n$v4l2src_pipeline_str\n\n"
		 exit 0	
		 ;;
	esac

}

kill_darknet()
{

	##Actual check
	darknet_pid=$(pgrep darknet)

	if [ "$darknet_pid" == "" ]; then
		##darknet not running, need to run again
		echo "Darknet not running"
	else
		sudo pgrep darknet | xargs sudo kill -9
	fi

}


kill_darknet_slient()
{

	##Actual check
	darknet_pid=$(pgrep darknet)

	if [ "$darknet_pid" != "" ]; then
		sudo pgrep darknet | xargs sudo kill -9
	fi

}

#function for looping and check memory usage and autokill and restart
loop() {

  # This is the loop.
  now=`date +%s`

  if [ -z $last ]; then
    last=`date +%s`
  fi

  # Do everything you need the daemon to do.
  # check if process exists

  #if not, run again
  #~/jetson-nano-ai-cam/select-camera.sh once
  
  # Check to see how long we actually need to sleep for. If we want this to run
  # once a minute and it's taken more than a minute, then we should just run it
  # anyway.


  #alt for check mem usage
  #pmap 22634 | tail -n 1 | awk '/[0-9]K/{print $2}'

  autorun=true

  last=`date +%s`


  #clear
  ~/skip_sudo.sh
  #echo "start loop"

	datetime=$(date '+%Y-%m-%d %H:%M:%S')

  ##Actual check
  darknet_pid=$(pgrep darknet)
  if [ "$darknet_pid" == "" ]; then
    ##darknet not running, need to run again
    echo "Darknet not found, start $datetime" >> ~/jetson-nano-ai-cam/restart-log.log

    ~/jetson-nano-ai-cam/select-camera.sh once
    #exit 0  
  fi

  ##Set low power
#  if [[ $( sudo nvpmodel -q | awk '/[0-9]+$/ {print $1}') == 0 ]]; then
#     sudo nvpmodel -m 1
#     printf "\nSet to 5W successfully\n"
#  fi
   

  darknet_pid=$(pgrep darknet)

  darknet_virt=$(cat /proc/$darknet_pid/stat | cut -d" " -f23)

  if [ $darknet_virt -ge 16000000000  ]; then

    echo "Consumed too much memory, restart!";

    echo "Too much resource, restart $datetime" >> ~/jetson-nano-ai-cam/restart-log.log
    
    kill_darknet
    printf "All darknet process killed\n";
    sleep 3

    ~/jetson-nano-ai-cam/select-camera.sh once

    #exit 0
  fi

  loadavg_1m=$( cat /proc/loadavg | cut -d" " -f1)
  acceptable_max_cpuload=7

  if (( $(awk 'BEGIN {print ("'$loadavg_1m'" >= "'$acceptable_max_cpuload'")}') )); then
#  if [ "$acceptable_max_cpuload" -ge "$loadavg_1m" ]; then

    echo "Overloading system, restart!";
    echo "Overload, restart $datetime" >> ~/jetson-nano-ai-cam/restart-log.log
    
    kill_darknet
    printf "All darknet process killed\n";
    sleep 3

    ~/jetson-nano-ai-cam/select-camera.sh once

    #exit 0  
  fi



	if [[ $( cat /proc/meminfo | grep SwapFree | awk '{print $2}' ) != "" ]]; then

		percentage_free_swap=$( free | grep Swap | awk '{ print $4/$2 }' )
		acceptable_percentage_free_swap=0.3


		if (( $(awk 'BEGIN {print ("'$percentage_free_swap'" <= "'$acceptable_percentage_free_swap'")}') )); then

			echo "Too much swap, restart!";
			echo "Swap overload, restart $datetime" >> ~/jetson-nano-ai-cam/restart-log.log
			
			kill_darknet
			printf "All darknet process killed\n";
			sleep 3

			~/jetson-nano-ai-cam/select-camera.sh once

			#exit 0  
		fi
		
	fi




	free_memory=$( cat /proc/meminfo | grep MemFree | head -n 1 | awk '{print $2}' )
	acceptable_free_memory=450000


#	if (( $(awk 'BEGIN {print ("'$free_memory'" <= "'$acceptable_free_memory'")}') )); then
  if [ "$free_memory" -le "$acceptable_free_memory" ]; then

		echo "Too little memory left, restart!";
		echo "memory usage overload, restart $datetime" >> ~/jetson-nano-ai-cam/restart-log.log
		
		kill_darknet
		printf "All darknet process killed\n";
		sleep 3

		~/jetson-nano-ai-cam/select-camera.sh once

		#exit 0  
	fi
	


	runInterval=0

  # Set the sleep interval
  if [[ ! $((now-last+runInterval+1)) -lt $((runInterval)) ]]; then
    sleep $((now-last+runInterval))
  fi

  # Startover

	if [[ $( cat /proc/meminfo | grep SwapFree | awk '{print $2}' ) != "" ]]; then
	  echo "$datetime ### Darknet memused: $darknet_virt	System Load: $loadavg_1m	Percentage Free Swap: $percentage_free_swap";
	else
		echo "$datetime ### Darknet memused: $darknet_virt	System Load: $loadavg_1m	Percentage Free Swap: 1";
	fi

  echo "End Loop, sleep 2s";
  sleep 2
  loop
}


###################
#Detects if there are arguments from the command line
###################

autorun=false;
if [ "$1" == "once" ]; then
	autorun=true
fi

quit_darknet=false;
if [ "$1" == "stop" ]; then
	quit_darknet=true
	kill_darknet
	killall select-camera.sh
	exit 0
fi

if [ "$1" == "start" ]; then
	loop
	exit 0
fi

if [ "$1" == "--test-video" ]; then
	if [[ -d "$2" ]]; then
		test_videos_dir=$2
	else
		echo "Directory: $2 is not valid"
		exit 0
	fi
fi


###################
#show info function
###################
show_device_info()
{

			dpkg-query --show nvidia-l4t-core

			printf "compare latest version with: https://developer.nvidia.com/embedded/linux-tegra-archive\n";

			sudo nmcli device
			sudo nmcli con			
			sudo lsusb 
			sudo modem-manager.mmcli -L
			pause
			sudo mmcli -m $modem_id
}



###################
#Show camera selection dialog
###################
show_menu_camera_selection()
{


	unset dialog_menu
	dialog_menu=()
	tmp_str=""

	#echo ${video_camera_array[@]}

	for (( i=0; i<${#video_camera_array[@]}; i++ ));
	do

		#echo "Name:	${VIDEO_CAMERA_INPUTS[$i,1]}"
		#echo "Type:	${VIDEO_CAMERA_INPUTS[$i,2]}"
		#echo ${VIDEO_CAMERA_INPUTS[$i,3]}
		#echo ${VIDEO_CAMERA_INPUTS[$i,4]}
		#echo "Width:	${VIDEO_CAMERA_INPUTS[$i,5]}"
		#echo "Height:	${VIDEO_CAMERA_INPUTS[$i,6]}"
		#echo "FPS:	${VIDEO_CAMERA_INPUTS[$i,7]}"

		tmp_str="(${VIDEO_CAMERA_INPUTS[$i,0]} ${VIDEO_CAMERA_INPUTS[$i,2]}) ${VIDEO_CAMERA_INPUTS[$i,5]}x${VIDEO_CAMERA_INPUTS[$i,6]}@${VIDEO_CAMERA_INPUTS[$i,7]}fps - ${VIDEO_CAMERA_INPUTS[$i,1]} "

		dialog_menu+=($i)
		dialog_menu+=($tmp_str)
		#dialog_menu+=("")

	done



	dialog_menu+=("k")
	dialog_menu+=("Kill Interference")
	dialog_menu+=("q")
	dialog_menu+=("Quit")
	dialog_menu+=("o")
	dialog_menu+=("Advanced Options")

	
	#Looping videos in from the folder $test_videos_dir
	IFS=$'\n\r'
	readarray -t test_videos < <(find "$test_videos_dir" -name "*.mp4" ! -path "*/archive/*" )
	for (( i=0; i<${#test_videos[*]}; i++ ));
	do
		dialog_menu+=("V${i}")
		this_video="${test_videos[$i]}"
		dialog_menu+=("${this_video##*/}")
	done

	return_str=$(whiptail --backtitle "Listing all the UVC Cameras" \
										--title "Select the video device" \
										--menu "/dev/video*" 16 78 8  \
										"${dialog_menu[@]}" 3>&1 1>&2 2>&3)

	#echo $return_str
	#pause
	camera_num=$(echo $return_str | rev | cut -b -1 )

	if [ "$return_str" != "" ]; then
		if [ $(echo $return_str | head -c 1)  == "V" ]; then
			test_video_index=${return_str:1}
			video_file_for_v4l2src_pipeline="${test_videos[$test_video_index]}"
		fi
	fi
		
	build_pipeline

	case $return_str in

		"k")
			kill_darknet
			show_menu_camera_selection
		;;
		

		"q")
			printf "\nQuit\n"
			exit 0
		;;
		
		"o")
			show_menu_advanced_options
		;;

		"")
			printf "\n(Escape key)\n"
			exit 0
		;;

		*)
			show_menu_camera_functions_lv1
		;;

	esac


}


##"02" "Image rotate 180" \


###################
#Advanced Options menu
###################
show_menu_advanced_options()
{

	back_title="Chosen Camera: ${VIDEO_CAMERA_INPUTS[$camera_num,1]} ${VIDEO_CAMERA_INPUTS[$camera_num,0]} ${VIDEO_CAMERA_INPUTS[$camera_num,5]}x${VIDEO_CAMERA_INPUTS[$camera_num,6]}@${VIDEO_CAMERA_INPUTS[$camera_num,7]}fps"

	current_power_mode=$(sudo nvpmodel -q | awk '/NV Power Mode/ {print $4}')

	function_selection=$(whiptail --backtitle "${back_title}" \
										--title "Advanced Options" \
										--menu "Select the below functions" 25 78 14 \
										"00" "Rotate Camera 180 (Current:${nvvidconv_flip})" \
										"01" "Resize the source (Current:${resize_to_resolution})" \
										"02" "Toggle FPS(Current: ${framerate})" \
										"03" "Toggle Power Mode(Current: ${current_power_mode})" \
										"04" "Reset Jetson Hotspot" \
										"05" "Reset Mobile Network" \
										"06" "Toggle Post to server(Current: ${upload_detections})" \
										"07" "Network Configurator" \
										"08" "Reset onboard camera with nvargus-daemon" \
										"09" "Reset ngrok" \
										"10" "Send Test Notification" \
										"11" "Show info" \
										"12" "Show camera" \
										"13" "Reboot" \
										"14" "Shutdown" 3>&1 1>&2 2>&3)


	##function_selection=$(echo $return_str | cut -b 1 )

	case $function_selection in

		00)
			clear
			if [[ $nvvidconv_flip == "" ]]; then
				nvvidconv_flip="flip-method=2 "
			else	
				nvvidconv_flip=""
			fi
	
			printf "Rotate camera by 180degree: $nvvidconv_flip\n";

			#pause
			
		;;



		01)
			clear
			case $resize_to_resolution in
				"N/A")
					resize_to_resolution="1280x720"
				;;
				"1280x720")
					resize_to_resolution="640x360"
				;;
				"640x360")
					resize_to_resolution="N/A"
				;;
			esac
			show_menu_advanced_options
		;;

		02)
			clear
			if [ $framerate == 30 ]; then
				framerate=10
			else	
				framerate=30
			fi	
			printf "New Framerate: $framerate\n";
			show_menu_advanced_options
			#pause
		;;

		03)
			clear
			if [[ $( sudo nvpmodel -q | awk '/[0-9]+$/ {print $1}') == 0 ]]; then
				sudo nvpmodel -m 1
				sudo sh -c "echo -1 > /sys/module/usbcore/parameters/autosuspend"
				printf "\nSet to 5W successfully\n"
			else	
				#MAXN
				sudo nvpmodel -m 0

				sudo sh -c "echo -1 > /sys/module/usbcore/parameters/autosuspend"
				sudo sh -c "echo 1 > /sys/devices/system/cpu/cpu0/online"
				sudo sh -c "echo 1 > /sys/devices/system/cpu/cpu1/online"
				sudo sh -c "echo 1 > /sys/devices/system/cpu/cpu2/online"
				sudo sh -c "echo 1 > /sys/devices/system/cpu/cpu3/online"
				sudo sh -c "echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
				sudo sh -c "echo performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor"
				sudo sh -c "echo performance > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor"
				sudo sh -c "echo performance > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor"
				printf "\nSet to 10W successfully\n"
								
			fi
	
			sudo nvpmodel -q
			
			printf "No of CPU: $(grep -c ^processor /proc/cpuinfo)\n";
			#pause
			show_menu_advanced_options
		;;


		04)
			clear

			sudo nmcli device
			sudo nmcli con 

			sudo mmcli -m 0 -d
			sudo mmcli -m 0 -e
			#sudo mmcli -m 0 -r ##hardware pin is broken

			mobile_device_name=$(nmcli con show | awk ' /mobile_network/ {print $4}')
			if [[ $mobile_device_name == "--" && -e $(lsusb | grep Modem) ]]; then
				lsusb | awk ' /Modem/ {gsub(/:/,""); system("sudo ~/jetson-nano-ai-cam/usbreset /dev/bus/usb/"$2 "/" $4)}'

				sudo mmcli -m 0 -d
				sudo mmcli -m 0 -e

				sudo nmcli con up mobile_network
				sudo nmcli con mod mobile_network connection.autoconnect yes

			else
				printf "Modem Not found, maybe need to replug or maybe you need reboot\n"
			fi

			pause
		;;

		06)
			clear
			if [[ $upload_detections == true ]]; then
				upload_detections=false
				printf "Will not send to server\n";
				#sudo python3 ~/jetson-nano-ai-cam/show.py "Will Not send to server"
			else
				upload_detections=true
				printf "Will send to server\n";
				#sudo python3 ~/jetson-nano-ai-cam/show.py "Will send to server"
			fi

			pause
			show_menu_advanced_options
		;;

		07)
			clear
			sudo nmtui 

			pause
		;;


		08)
			clear
			sudo systemctl restart nvargus-daemon
	
			printf "systemctl restart nvargus-daemon\n";

			pause
		;;

		09)
			clear
			sudo pgrep ngrok | xargs sudo kill -9
			sudo /root/ngrok/ngrok start -all &	
			#sleep 1
			ngrok_domains=$(sudo tail -4 /root/ngrok/log.txt | awk ' /addr\=/ { gsub(/url=tcp\:\/\/|url=/, ""); print $NF}' )
			#sudo python3 ~/jetson-nano-ai-cam/show.py $ngrok_domains

			printf "ngrok restarted\n";

			pause
		;;


		10)
			clear
			printf "Sending Test Message\n";
			## need to use full path
			~/jetson-nano-ai-cam/send_http.sh "Test from: $myIPAddress" "$PWD/demo-jetson-nano.jpg";

			pause
		;;



		11)
			clear

			show_device_info
			pause

			#sudo modem-manager.mmcli -m 2

			sudo tail -4 /root/ngrok/log.txt | awk ' /addr\=/ { gsub(/url=tcp\:\/\/|url=/, ""); print $NF}' 
			printf "IP: $myIPAddress\n";

			sudo python3 info.py
			printf "Screen updated\n";
			
			pause
		;;


		12)
			printf "Doing: v4l2-ctl --device=$d -D --list-formats-ext \n"
			clear

			for d in /dev/video* ; do echo $d ; v4l2-ctl --device=$d -D --list-formats-ext  ; echo '===============' ; done

			pause
		;;


		13)
			clear
			printf "Reboot in 2s\n";
			sleep 2
			sudo systemctl reboot -i
			pause
			exit 0
		;;

		14)
			clear
			printf "Shutdown in 3s\n";
			sleep 3
			sudo systemctl poweroff -i
			pause
			exit 0
		;;


		$'\e') 
			printf "\n\nEXIT \n\n"
			exit 0
		;;

		*)
			clear
			select_function=-1
			
		;;
	esac

	show_menu_camera_selection

}



###################
#Camera functions level
###################
show_menu_camera_functions_lv1()
{

	##just kill in case it is running
	kill_darknet_slient

	back_title="Chosen Camera: ${VIDEO_CAMERA_INPUTS[$camera_num,1]} ${VIDEO_CAMERA_INPUTS[$camera_num,0]} ${VIDEO_CAMERA_INPUTS[$camera_num,5]}x${VIDEO_CAMERA_INPUTS[$camera_num,6]}@${VIDEO_CAMERA_INPUTS[$camera_num,7]}fps"

	function_selection=$(whiptail --backtitle "${back_title}" \
										--title "Camera Function" \
										--menu "Select the below functions" 25 78 14 \
										"00" "Python Cam test CV2 ('F' fullscreen, esc quit)" \
										"01" "Yolo V3 Detection Selection" \
										"02" "retinaface_pt - trt_cc show faces (fullscreen)" \
										"03" "Face identification - mtcnn_facenet" \
										"04" "MTCNN_FaceDectection_TensorRT (doesn't work)" \
										"05" "jkjung-avt MTCNN TensorRT ('F' fullscreen, esc quit)" \
										"06" "tf-pose-estimation (a few mins to build engine)" \
										"07" "trt-pose densenet(a mins to load model)" \
										"08" "trt-pose resnet(a mins to load model)" \
										"09" "Record video to ~/xxx.mov" \
										"10" "(not done yet)Live Low latency WebRTC" \
										"20" "Direct Display to HDMI" \
										"21" "Advanced Options" \
										"22" "Reboot" \
										"23" "Shutdown" 3>&1 1>&2 2>&3)

	case $function_selection in
		"") 
			printf "\n(Escape key)\n"
			clear
			show_menu_camera_selection
			exit 0
		;;

		00)
			clear
			echo "Simple Python CV2 Test"
			execute_str="python3 nano_cam_test.py --video '$v4l2src_pipeline_str $v4l2src_ending_pipeline_str'"
			printf "\nDebug: $execute_str\n"
			cd ~/jetson-nano-ai-cam
			eval $execute_str
		;;

		01)
			clear
			echo "Yolo V3 Inference"
			show_menu_yolov3_detection_options

		;;

		02)
			clear
			echo "retinaface - show faces"
			execute_str="./retinaface '$v4l2src_pipeline_str $v4l2src_ending_pipeline_str'"
			printf "\nDebug: $execute_str\n"
			cd ~/StrangeAI/retinaface_pt/trt_cc/retinaface/build/
			eval $execute_str


		;;

		03)
			clear
			echo "mtcnn_facenet, must only do 1920x1080 or need to redo all the engine, https://github.com/samsonadmin/mtcnn_facenet_cpp_tensorRT"
			echo "Put images of people in the imgs folder. Please only use images that contain one face."
			echo "NEW FEATURE:You can now add faces while the algorithm is running. When you see the OpenCV GUI, press \"N\" on your keyboard to add a new face. The camera input will stop until you have opened your terminal and put in the name of the person you want to add."
			echo "Escape to quit"

			pause
			execute_str="./mtcnn_facenet_cpp_tensorRT '$v4l2src_pipeline_str $v4l2src_ending_pipeline_str'"
			printf "\nDebug: $execute_str\n"	
			cd ~/mtcnn_facenet_cpp_tensorRT/build
			eval $execute_str
		;;

		04)
			clear
			echo "MTCNN_FaceDectection_TensorRT (doesn't work, nothing is shown on screen)"
			execute_str="./build/main '$v4l2src_pipeline_str $v4l2src_ending_pipeline_str'"
			printf "\nDebug: $execute_str\n"
			cd ~/MTCNN_FaceDetection_TensorRT
			eval $execute_str
		;;

		05)
			clear
			echo "jkjung-avt MTCNN TensorRT"
			execute_str="python3 trt_mtcnn.py --v4l2 '$v4l2src_pipeline_str $v4l2src_ending_pipeline_str'"
			printf "\nDebug: $execute_str\n"
			cd ~/jkjung-avt/tensorrt_demos
			eval $execute_str
		;;


		06)
			clear
			echo "tf-pose-estimation"
			execute_str="python3 run_webcam.py --video='$v4l2src_pipeline_str $v4l2src_ending_pipeline_str' --model=mobilenet_v2_small --resize=432x368 --tensorrt=True --showBG=False"
			printf "\nDebug: $execute_str\n"
			cd ~/tf-pose-estimation
			eval $execute_str
		;;

		07)
			clear
			echo "trt-pose (densenet)"
			execute_str="python3 get_keypoint_from_video.py --model=densenet --video='$v4l2src_pipeline_str $v4l2src_ending_pipeline_str'"
			printf "\nDebug: $execute_str\n"
			cd ~/NVIDIA-AI-IOT/trt_pose/tasks/human_pose
			eval $execute_str
		;;

		08)
			clear
			echo "trt-pose (resnet)"
			execute_str="python3 get_keypoint_from_video.py --model=resnet --video='$v4l2src_pipeline_str $v4l2src_ending_pipeline_str'"
			printf "\nDebug: $execute_str\n"
			cd ~/NVIDIA-AI-IOT/trt_pose/tasks/human_pose
			eval $execute_str
		;;

		09)
			clear
			echo "Recording Live"
			today=`date +%Y%m%d-%H%M%S`
			FILE="~/LIVE-Recording-$today.mp4"
			sudo mount /dev/sda1 /media/5a5cff49-52fe-4e32-b1dc-886e34ce958b
			if [[ -d "/media/5a5cff49-52fe-4e32-b1dc-886e34ce958b" ]]; then
				echo "/media/5a5cff49-52fe-4e32-b1dc-886e34ce958b exist"
				FILE="/media/5a5cff49-52fe-4e32-b1dc-886e34ce958b/LIVE-Recording-$today.mp4"
			fi
			
			#execute_str="sudo gst-launch-1.0 -e $v4l2src_pipeline_str nvvidconv ! 'video/x-raw(memory:NVMM), width=1920, height=1080, format=NV12, framerate=$framerate/1' !  tee name=t  t. ! nvv4l2h265enc bitrate=9800000 ! h265parse ! qtmux ! filesink location=$FILE -e  t. ! nvoverlaysink sync=false async=false -e "

			execute_str="sudo gst-launch-1.0 -e $v4l2src_pipeline_str nvvidconv ! 'video/x-raw(memory:NVMM), format=NV12, framerate=$framerate/1' !  tee name=t  t. ! nvv4l2h265enc bitrate=9800000 ! h265parse ! qtmux ! filesink location=$FILE -e  t. ! nvoverlaysink sync=false async=false -e "


			printf "\nDebug: $execute_str\n"
			cd ~
			eval $execute_str
		;;

		20)
			clear
			##nvoverlaysink	##fullscreen, fast
			##nveglglessink	##non fullscreen, slow
			##nv3dsink fast? can use drop=true
			##nvvideosink
			##xvimagesink

			#v4l2src_display_str="v4l2src io-mode=2 device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} do-timestamp=true ! image/jpeg, width=${VIDEO_CAMERA_INPUTS[$camera_num,5]}, height=${VIDEO_CAMERA_INPUTS[$camera_num,6]}, framerate=$framerate/1 ! jpegparse ! nvjpegdec ! video/x-raw ! nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)I420' ! nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)NV12' ! nvoverlaysink sync=false async=false"	

			#logo overlay
			#v4l2src_pipeline_str+="gdkpixbufoverlay location=~/jetson-nano-ai-cam/carryai-simple-dark.png offset-x=-1 offset-y=1 ! "

			execute_str="gst-launch-1.0 $v4l2src_pipeline_str nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)NV12' ! nvoverlaysink sync=false async=false -e"


			printf "\nDebug v4l2src_pipeline: \n$v4l2src_pipeline_str\n"

			printf "\nDebug: $execute_str\n"
	
			eval $execute_str

			pause

		;;


		21)
			show_menu_advanced_options
		;;

		22)
			clear
			printf "Reboot in 2s\n";
			sleep 2
			sudo systemctl reboot -i
			pause

		;;

		23)
			clear
			printf "Shutdown in 3s\n";
			sleep 3
			sudo systemctl poweroff -i
			pause
		;;

		*)
		;;

	esac

	exit 0
}


###################
#Yolo v3 different detection options
###################
show_menu_yolov3_detection_options()
{

	##remove older files than 2 days
	if [[ -d "/home/jetsonnano/images" ]]; then
		sudo find /home/jetsonnano/images -name "*.jpg" -type f -mtime +2 -exec rm -f {} \;
	fi


	back_title="Chosen Camera: ${VIDEO_CAMERA_INPUTS[$camera_num,1]} ${VIDEO_CAMERA_INPUTS[$camera_num,0]} ${VIDEO_CAMERA_INPUTS[$camera_num,5]}x${VIDEO_CAMERA_INPUTS[$camera_num,6]}@${VIDEO_CAMERA_INPUTS[$camera_num,7]}fps"

	unset dialog_menu
	dialog_menu=()

	#length of a dimension cannot be known, total array divid by 6 columns
	no_rows=${#yolo_detection_options[@]}/5
	for (( i=0; i<$no_rows; i++ ));
	do
		dialog_menu+=("${i}")
		dialog_menu+=("${yolo_detection_options[$i,0]}")
	done


	function_selection=$(whiptail --backtitle "${back_title}" \
										--title "Select Dataset for YoloV3" \
										--menu "Select Below are dataset to try out" 25 78 14 \
										"${dialog_menu[@]}" 3>&1 1>&2 2>&3)

	clear
	printf "v4l2src_pipeline_str:\n$v4l2src_pipeline_str v4l2src_ending_pipeline_str\n\n"

	if [ "$function_selection" == "" ]; then
			show_menu_camera_functions_lv1
			#printf "\n\nEXIT \n\n"
			#exit 0		
	fi
	
	echo "$function_selection ${yolo_detection_options[$function_selection,0]}  "

	case ${VIDEO_CAMERA_INPUTS[$camera_num,2]} in
		"RG10")
			#needto remove nvjpeg
			#v4l2src_pipeline_str=${v4l2src_pipeline_str//nvjpegdec/jpegdec}
			v4l2src_pipeline_str=${v4l2src_pipeline_str//\'/''} ##remove the ' for nvarguscamerasrc
		;;
	esac

	yolo_exec_str="./darknet detector demo "



	execute_str=$(cat <<-EOF
		$yolo_exec_str \
		${yolo_detection_options[$function_selection,1]} \
		${yolo_detection_options[$function_selection,2]} \
		${yolo_detection_options[$function_selection,3]} \
		${yolo_detection_options[$function_selection,4]} \
		'$v4l2src_pipeline_str $v4l2src_ending_pipeline_str'  
	EOF
	)

	if [[ $upload_detections == true ]]; then
		upload_detection_str=$(cat <<-EOF
  			-prefix ~/images/d${today} | gawk -F: '/JETSON_NANO_DETECTION:[.]*/ { gsub(/,\s\W/, ":"); gsub(/,\s/, ","); system("~/jetson-nano-ai-cam/send_http.sh " "\"" \$2 "\" " \$3)} '
		EOF
		)
	else
		##remove the prefix arg
		#execute_str=${execute_str//-prefix/_prefix}
		upload_detection_str=""
	fi

	execute_str+="$upload_detection_str"


	#1>&2
	#&>/dev/null &

	if (whiptail --title "Launch in interactive mode?" --yesno "Launching in debug mode or no to start background." 8 78); then
			#execute_str="nohup $execute_str &"
			echo ""
	else
			execute_str="nohup $execute_str &"
	fi

	printf "\nDebug:\n$execute_str\n\n"

	echo "$v4l2src_pipeline_str" >> ~/jetson-nano-ai-cam/launch.log
	echo "" >> ~/jetson-nano-ai-cam/launch.log
	echo "$execute_str" >> ~/jetson-nano-ai-cam/launch.log
	echo "" >> ~/jetson-nano-ai-cam/launch.log

	darknet_pid=$(pgrep darknet)
	sudo pgrep darknet

	echo "$darknet_pid" >> ~/jetson-nano-ai-cam/launch.log

	echo "**********************" >> ~/jetson-nano-ai-cam/launch.log
	echo "" >> ~/jetson-nano-ai-cam/launch.log

	cd ~/darknet	
	eval $execute_str

	pause


}


###################
#Building the Execution String
###################
build_pipeline()
{

	v4l2src_pipeline_str="v4l2src io-mode=2 device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} do-timestamp=true ! "
	v4l2src_ending_pipeline_str=""

	case ${VIDEO_CAMERA_INPUTS[$camera_num,2]} in

		"YUYV")
			v4l2src_pipeline_str+="video/x-raw, format=YUY2, "
		;;

		"MJPG")
			v4l2src_pipeline_str+="image/jpeg, "
		;;

		"H264")
			v4l2src_pipeline_str+="video/x-h264, "
		;;	

	esac


	##samson last
	v4l2src_pipeline_str+="width=${VIDEO_CAMERA_INPUTS[$camera_num,5]}, height=${VIDEO_CAMERA_INPUTS[$camera_num,6]}, framerate=$framerate/1 ! "
	##samson last
	#v4l2src_pipeline_str+=" tee name=t   t. ! "
	# t. ! v4l2sink device=/dev/video9


	case ${VIDEO_CAMERA_INPUTS[$camera_num,2]} in


		"RG10")
			#onboard camera completely different
			v4l2src_pipeline_str="nvarguscamerasrc ! 'video/x-raw(memory:NVMM), width=(int)1600, height=(int)1200, format=(string)NV12, framerate=(fraction)30/1' ! nvvidconv ${nvvidconv_flip} ! 'video/x-raw, format=(string)BGRx' ! "
			#v4l2src_pipeline_str="nvarguscamerasrc ! 'video/x-raw(memory:NVMM), width=(int)1640, height=(int)1232, format=(string)NV12, framerate=(fraction)30/1' ! "
			#v4l2src_pipeline_str="nvarguscamerasrc ! 'video/x-raw(memory:NVMM), width=(int)1640, height=(int)1232, format=(string)NV12, framerate=(fraction)30/1' ! nvvidconv flip-method=2 ! 'video/x-raw, format=(string)BGRx' ! videoconvert ! 'video/x-raw, format=(string)BGR' ! tee name=t  t. !"
		;;

		"YUYV")

			case $resize_to_resolution in
				"1280x720")
					v4l2src_pipeline_str+="videoscale method=bilinear sharpen=1 sharpness=2 ! video/x-raw, width=1280, height=720 ! "
				;;
				"640x360")
					v4l2src_pipeline_str+="videoscale method=bilinear sharpen=1 sharpness=2 ! video/x-raw, width=640, height=360 ! "
				;;
			esac

			if [[ $nvvidconv_flip == "flip-method=2 " ]]; then
				v4l2src_pipeline_str+="nvvidconv flip-method=2 ! "
				#v4l2src_pipeline_str+="videoflip video-direction=2 ! "
			fi			
			
			#v4l2src_pipeline_str+="videoconvert ! video/x-raw, format=I420 ! "
		;;

		"MJPG")

			#v4l2src_pipeline_str+="jpegparse ! nvjpegdec ! video/x-raw,format=I420 !"
			v4l2src_pipeline_str+="jpegparse ! jpegdec ! "

			case $resize_to_resolution in
				"1280x720")
					v4l2src_pipeline_str+="videoscale method=1 sharpen=1 ! video/x-raw, width=1280, height=720 ! "
				;;
				"640x360")
					v4l2src_pipeline_str+="videoscale method=1 sharpen=1 ! video/x-raw, width=640, height=360 ! "
				;;
			esac

			if [[ $nvvidconv_flip == "flip-method=2 " ]]; then
			#	v4l2src_pipeline_str+="nvvidconv flip-method=2 ! "
				v4l2src_pipeline_str+="videoflip video-direction=2 ! "
			fi	

			##jpegdec > nvjpegdec
		
			## working with nvoverlay, not yolo
			#v4l2src_pipeline_str+="jpegparse ! nvjpegdec ! video/x-raw ! nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)RGBA' ! "

			#works for display only
			#v4l2src_pipeline_str+="jpegparse ! nvjpegdec ! video/x-raw ! nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)I420' ! nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)NV12' ! "

			#opencv expects BGR
			
		;;

		"H264")
			# Jetson Nano    enable-low-outbuffer=1 
			# Jetson Nano max perf   disable-dvfs=1
			# can use nvv4l2decoder instead of omxh266dec
			#v4l2src_pipeline_str+="queue ! h264parse ! omxh264dec enable-low-outbuffer=1 disable-dvfs=1 !"
			v4l2src_pipeline_str+="omxh264dec enable-low-outbuffer=1 disable-dvfs=1 !"
			#v4l2src_pipeline_str+="queue ! h264parse ! nvv4l2decoder enable-max-performance=1 ! nvvidconv ! video/x-raw(memory:NVMM), format=BGRx ! " 

			case $resize_to_resolution in
				"1280x720")
					v4l2src_pipeline_str+="videoscale method=1 sharpen=1 ! video/x-raw, width=1280, height=720 ! "
				;;
				"640x360")
					v4l2src_pipeline_str+="videoscale method=1 sharpen=1 ! video/x-raw, width=640, height=360 ! "
				;;
			esac

			if [[ $nvvidconv_flip == "flip-method=2 " ]]; then
				v4l2src_pipeline_str+=" videoflip video-direction=2 ! "
			fi
			
			
			#v4l2src_pipeline_str+="nvv4l2decoder ! "
		;;	

	esac


	#if there is video_file_for_v4l2src_pipeline, then just use the video
	#useless right now, to be developed
	if [ "$video_file_for_v4l2src_pipeline" != "" ]; then

	 	#first, get the codec used, is that hevc or h264 for now
		codec_used=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$video_file_for_v4l2src_pipeline")
		case $codec_used in
			"hevc")
				v4l2src_pipeline_str="filesrc location=\"$video_file_for_v4l2src_pipeline\" ! qtdemux name=demux demux.video_0 ! queue ! h265parse ! nvv4l2decoder enable-max-performance=1 ! nvvidconv ! video/x-raw, format=BGRx ! queue ! "
			;;
			"h264")
				v4l2src_pipeline_str="filesrc location=\"$video_file_for_v4l2src_pipeline\" ! qtdemux ! queue ! h264parse ! omxh264dec ! nvvidconv ! video/x-raw, format=BGRx ! queue ! "
			;;
		esac

		case $resize_to_resolution in
			"1280x720")
				v4l2src_pipeline_str+="videoscale method=bilinear sharpen=1 sharpness=2 ! video/x-raw, width=1280, height=720 ! "
			;;
			"640x360")
				v4l2src_pipeline_str+="videoscale method=bilinear sharpen=1 sharpness=2 ! video/x-raw, width=640, height=360 ! "
			;;
		esac

		if [[ $nvvidconv_flip == "flip-method=2 " ]]; then
			v4l2src_pipeline_str+="nvvidconv flip-method=2 ! "
			#v4l2src_pipeline_str+="videoflip video-direction=2 ! "
		fi		

		printf "\nDebug: Loading File: \"$video_file_for_v4l2src_pipeline\":$codec_used\n$v4l2src_pipeline_str\n"

	fi


	#tee name=t   t. ! identity drop-allocation=1 ! v4l2sink device=/dev/video9 
	# t. ! v4l2sink device=/dev/video9

	v4l2src_ending_pipeline_str+="videoconvert ! queue ! video/x-raw, format=BGR ! "
	##v4l2src_ending_pipeline_str+="appsink sync=false async=false "

	if [ "$video_file_for_v4l2src_pipeline" != "" ]; then
		v4l2src_ending_pipeline_str+="appsink sync=true "
	else
		v4l2src_ending_pipeline_str+="appsink sync=false async=true "
	fi

	#v4l2src_pipeline_str+=" tee name=t t. ! nvvidconv ! omxh264enc control-rate=2  bitrate=6000000 peak-bitrate=6500000  preset-level=2 profile=8 !  'video/x-h264, stream-format=(string)byte-stream, level=(string)5.2' ! h264parse ! qtmux ! filesink location=/mnt/sandisk/$today.mov t. ! "
	

	#printf "Debug:\n$v4l2src_pipeline_str\n\n";
	#pause

}


###################
#script starts here
###################


#Check if mobile device is plugged in, if yes and  not activated, try to activate it
mobile_device_name=$(nmcli con show | awk ' /mobile_network/ {print $4}')
if [[ $mobile_device_name == "--" && -e $(lsusb | grep Modem) ]]; then
	
	sudo nmcli con up mobile_network
	sudo nmcli con mod mobile_network connection.autoconnect yes
fi



#enable location


###################
#init and get environment variables
###################

modem_id=0

modem_id=$( sudo modem-manager.mmcli -L | awk ' /Modem\// { print $1 }' | awk -F/ '{print $NF}' )


if [[ -e $(lsusb | grep Modem) ]]; then

	sudo mmcli -m $modem_id --messaging-list-sms
	sudo mmcli -m $modem_id --location-enable-3gpp > /dev/null
	sudo mmcli -m $modem_id --location-enable-agps > /dev/null
	sudo mmcli -m $modem_id --location-enable-gps-nmea > /dev/null
	sudo mmcli -m $modem_id --location-enable-gps-raw > /dev/null
	sudo mmcli -m $modem_id --location-enable-cdma-bs > /dev/null
	sudo mmcli -m $modem_id --location-enable-gps-unmanaged > /dev/null
	sudo mmcli -m $modem_id --location-set-enable-signal > /dev/null
	sudo mmcli -m $modem_id --location-status > /dev/null

	clear
	sudo mmcli -m $modem_id --location-get

fi





shopt -s nullglob
video_camera_array=(/dev/video*)
shopt -u nullglob # Turn off nullglob to make sure it doesn't interfere with anything later

#sudo nvpmodel -q


if (( ${#video_camera_array[@]} == 0 )); then
    echo "No Cameras found" >&2


	###################
	#show some extra info here
	###################
	show_device_info

	##Todo make buzzer sound
	
    #exit 0
fi


#Check if jetson_hotspot is enabled, if yes and  not activated, try to activate it
jetson_hotspot=$(nmcli con show | awk ' /jetson_hotspot/ {print $4}')
if [[ $jetson_hotspot == "--" ]]; then
	sudo nmcli con up jetson_hotspot
	sudo nmcli con mod jetson_hotspot connection.autoconnect yes
fi



#########----GET camera basic info


#echo "Found devices ============================";
#echo "${video_camera_array[@]}"

this_device_id="nothing"

##Getting supported camera modes
for (( i=0; i<${#video_camera_array[@]}; i++ ));
do

	this_device_id="${video_camera_array[$i]}"
	VIDEO_CAMERA_INPUTS[$i,0]="$this_device_id"

	#echo "v4l2-ctl --device=$this_device_id --list-formats-ext"
	

	#get Name
	VIDEO_CAMERA_INPUTS[$i,1]=$(v4l2-ctl --device=$this_device_id --all | grep "Card.*type" | cut -d ' ' -f 8-)

	#Rasperri pi camera
	if [[ $(v4l2-ctl --device=$this_device_id --list-formats-ext --list-formats | awk '/RG10'/ | wc -l ) > 0 ]]; 
	then
		VIDEO_CAMERA_INPUTS[$i,2]="RG10"
	fi

	if [[ $(v4l2-ctl --device=$this_device_id --list-formats-ext --list-formats | awk '/YUYV'/ | wc -l ) > 0 ]];
	then
		VIDEO_CAMERA_INPUTS[$i,2]="YUYV"
	fi

	if [[ $(v4l2-ctl --device=$this_device_id --list-formats-ext --list-formats | awk '/MJPG'/ | wc -l ) > 0 ]]; 
	then
		VIDEO_CAMERA_INPUTS[$i,2]="MJPG"
	fi

	if [[ $(v4l2-ctl --device=$this_device_id --list-formats-ext --list-formats | awk '/H264'/ | wc -l ) > 0 ]]; 
	then
		VIDEO_CAMERA_INPUTS[$i,2]="H264"
	fi

	#get Width
	#VIDEO_CAMERA_INPUTS[$i,4]=$(v4l2-ctl --device=$this_device_id --all | grep "Width\/Height" | cut -d ' ' -f 8- | cut -d '/' -f 1)

	#get Height
	#VIDEO_CAMERA_INPUTS[$i,5]=$(v4l2-ctl --device=$this_device_id --all | grep "Width\/Height" | cut -d ' ' -f 8- | cut -d '/' -f 2)


done


##----Get Frame Size
#IFS=$'\n\r'
#printf "\nGet Frame Size ============================\n\n";

for (( i=0; i<${#video_camera_array[@]}; i++ ));
do

	##empty string if it cannot detect for the tee isn't active, so cannot detect the support color space
	if [ "${VIDEO_CAMERA_INPUTS[$i,2]}" == "" ]; then
		selected_width="N/A"
		selected_height="N/A"
		continue
	fi

	#echo "$i. Doing: v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$i,0]} --list-framesizes=${VIDEO_CAMERA_INPUTS[$i,2]} "

	##Assume TargetFrame rate = 30
	framerate=30

	VIDEO_CAMERA_INPUTS[$i,3]=$( v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$i,0]} --list-framesizes=${VIDEO_CAMERA_INPUTS[$i,2]} | cut -d ' ' -f 3-  )

	#echo "${VIDEO_CAMERA_INPUTS[$i,3]}"  #in multiple line

	#put it into temp_array
	IFS=$'\n\r'
	readarray -t temp_array <<< ${VIDEO_CAMERA_INPUTS[$i,3]}

	#sort it reverse
	sorted_array=($(sort -t 'x' -k 2n <<<"${temp_array[*]}"))

	#echo "Sorted array: ${sorted_array[*]}, size: ${#temp_array[@]}"


	if [ "${#temp_array[@]}" -gt "1" ]; then
		VIDEO_CAMERA_INPUTS[$i,4]="${sorted_array[-1]}" ##THE highest resolution the cam can do
	else
		VIDEO_CAMERA_INPUTS[$i,4]="${sorted_array[0]}" ##THE highest resolution the cam can do
	fi
	

	selected_width=0
	selected_height=0


	##Manual test if 1920x1080 30fps is supported, if yes, then use if
	this_fps_string="$( v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$i,0]} --list-frameintervals=width=1920,height=1080,pixelformat=${VIDEO_CAMERA_INPUTS[$i,2]} )"

	#printf  "$this_fps_string"

	#Init assume 15fps
	framerate=15

	#detect if 60fps is supported
	if [[ $this_fps_string ==  *"60.000 fps"* ]]; then
		#printf "yes\n"
		framerate=60
		selected_width=1920
		selected_height=1080
	fi


	#if 30fps is supported, force it
	if [[ $this_fps_string ==  *"30.000 fps"* ]]; then
		#printf "yes\n"
		framerate=30
		selected_width=1920
		selected_height=1080
	fi


	##skip test if 1920x1080 works

	#echo " ${#sorted_array[@]} "

	if [[ $selected_width == "0" ]]; then

		##test if it can do 30 fps by testing with string 30.000 fps
		for ((j=${#sorted_array[@]}-1; j>=0; j-- ));
		do
			this_res="${sorted_array[$j]}"
			printf  "\n[$j) $this_res]: "
			this_width=$( printf ${this_res} | cut -d 'x' -f 1 ) 
			this_height=$( printf ${this_res} | cut -d 'x' -f 2 ) 

			selected_width=$this_width
			selected_height=$this_height

			#printf  "debug: v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$i,0]} --list-frameintervals=width=$this_width,height=$this_height,pixelformat=${VIDEO_CAMERA_INPUTS[$i,2]} \n"

			this_fps_string="$( v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$i,0]} --list-frameintervals=width=$this_width,height=$this_height,pixelformat=${VIDEO_CAMERA_INPUTS[$i,2]} )"

			##printf  "$this_fps_string"

			#Init assume 15fps
			framerate=15

			#detect if 60fps is supported
			if [[ $this_fps_string ==  *"60.000 fps"* ]]; then
				framerate=60
				break
			fi


			#if 30fps is supported, force it
			if [[ $this_fps_string ==  *"30.000 fps"* ]]; then
				framerate=30
				break
			fi

		done

	fi
	

	#echo "Final array: ${sorted_array[*]}"

	VIDEO_CAMERA_INPUTS[$i,5]="${selected_width}"
	VIDEO_CAMERA_INPUTS[$i,6]="${selected_height}"
	VIDEO_CAMERA_INPUTS[$i,7]=$framerate

	#printf "\nSelected Size: ${selected_width}  x  ${selected_height}"
	#printf  "\n\n------------------------\n";

done

#########----End camera basic info


##end_num=$(( ${#video_camera_array[@]}-1 ))



function_selection=-1

if $quit_darknet; then
	function_selection="q"
fi




## autorun, then directly assume it is camera 0
if $autorun; then
	camera_num="0"

else
	#old# read -p "[0-${end_num}]: " -n1 camera_num	

	show_menu_camera_selection

fi

function_selection=""
#show_menu_advanced_options

function_selection=1




#printf "Chosen: ${VIDEO_CAMERA_INPUTS[$camera_num,1]} ${VIDEO_CAMERA_INPUTS[$camera_num,0]}\n"

#printf "\n"

#--list-ctrls-menus
#-L to list details
#eval $(v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} -L
##disable auto exposure 1-disable auto exposure, 3-enable auto exposure
#eval $(v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} -c exposure_auto=3 )
#eval $(v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} -c gamma=80 )
#eval $(v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} -c backlight_compensation=0 )
#eval $(v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} -c gain=0 )

#read

## create needed dir
if [[ ! -d ~/images ]]; then
  mkdir -p ~/images;
fi

show_menu_camera_functions_lv1



#############################################
#below for for checking the darknet process



runInterval=5 # In seconds


display_usage_help
