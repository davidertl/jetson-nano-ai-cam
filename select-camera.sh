#!/bin/bash

~/skip_sudo.sh

declare -A VIDEO_CAMERA_INPUTS
post_to_server=true;
myIPAddress=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | tr '\n' '|' )

echo 255 | sudo tee /sys/devices/pwm-fan/target_pwm

clear
printf "Usages \n"
printf "./select-camera.sh start :::: Auto detect resource and restart, log file: restart-log.log\n"
printf "./select-camera.sh once :::: Auto start, without restart\n"
printf "./select-camera.sh stop :::: stop and quit loop\n"
printf "autorun defaults to /dev/video0\n\n"

sudo sh -c "echo -1 > /sys/module/usbcore/parameters/autosuspend"

echo $BASHPID > ~/jetson-nano-ai-cam/SELECTCAMERA_PID

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

  ##Actual check
  darknet_pid=$(pgrep darknet)
  if [ "$darknet_pid" == "" ]; then
    ##darknet not running, need to run again
    echo "Darknet not found, restart $datetime" >> ~/jetson-nano-ai-cam/restart-log.log

    ~/jetson-nano-ai-cam/select-camera.sh autorun
    #exit 0  
  fi

  ##Set low power
#  if [[ $( sudo nvpmodel -q | awk '/[0-9]+$/ {print $1}') == 0 ]]; then
#     sudo nvpmodel -m 1
#     printf "\nSet to 5W successfully\n"
#  fi
  

  datetime=$(date '+%Y-%m-%d %H:%M:%S')

  darknet_pid=$(pgrep darknet)

  darknet_virt=$(cat /proc/$darknet_pid/stat | cut -d" " -f23)

             #13836177408
  if [ $darknet_virt -ge 13900000000  ]; then

    echo "Consumed too much memory, restart!";

    echo "Too much resource, restart $datetime" >> ~/jetson-nano-ai-cam/restart-log.log
    
    kill_darknet
    printf "All darknet process killed\n";
    sleep 3

    ~/jetson-nano-ai-cam/select-camera.sh once

    #exit 0
  fi

  loadavg_1m=$( cat /proc/loadavg | cut -d" " -f1)
  acceptable_cpuload=5

  if (( $(awk 'BEGIN {print ("'$loadavg_1m'" >= "'$acceptable_cpuload'")}') )); then

    echo "Overloading system, restart!";
    echo "Overload, restart $datetime" >> ~/jetson-nano-ai-cam/restart-log.log
    
    kill_darknet
    printf "All darknet process killed\n";
    sleep 3

    ~/jetson-nano-ai-cam/select-camera.sh once

    #exit 0  
  fi

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


  # Set the sleep interval
  if [[ ! $((now-last+runInterval+1)) -lt $((runInterval)) ]]; then
    sleep $((now-last+runInterval))
  fi

  # Startover
  echo "$datetime ### Darknet memused: $darknet_virt	System Load: $loadavg_1m	Percentage Free Swap: $percentage_free_swap";
  echo "End Loop, sleep 2s";
  sleep 2
  loop
}


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




#Check if mobile device is plugged in, if yes and  not activated, try to activate it
mobile_device_name=$(nmcli con show | awk ' /mobile_network/ {print $4}')
if [[ $mobile_device_name == "--" && -e $(lsusb | grep Modem) ]]; then
	
	sudo nmcli con up mobile_network
	sudo nmcli con mod mobile_network connection.autoconnect yes
fi



#enable location

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

#Check if jetson_hotspot is enabled, if yes and  not activated, try to activate it
jetson_hotspot=$(nmcli con show | awk ' /jetson_hotspot/ {print $4}')
if [[ $jetson_hotspot == "--" ]]; then
	sudo nmcli con up jetson_hotspot
	sudo nmcli con mod jetson_hotspot connection.autoconnect yes
fi


#today=`date +%Y-%m-%d.%H:%M:%S`
today=`date +%Y%m%d-%H%M%S`

shopt -s nullglob
video_camera_array=(/dev/video*)
shopt -u nullglob # Turn off nullglob to make sure it doesn't interfere with anything later

#sudo nvpmodel -q


if (( ${#video_camera_array[@]} == 0 )); then
    echo "No Cameras found" >&2

	##Todo make buzzer sound
	
    exit 0
fi

echo "Found devices ============================";
echo "${video_camera_array[@]}"

##----GET basic info

this_device_id="nothing"

for (( i=0; i<${#video_camera_array[@]}; i++ ));
do

	this_device_id="${video_camera_array[$i]}"
	VIDEO_CAMERA_INPUTS[$i,0]="$this_device_id"

	#v4l2-ctl --device=$this_device_id --list-formats-ext

	#get Name
	VIDEO_CAMERA_INPUTS[$i,1]=$(v4l2-ctl --device=$this_device_id --all | grep "Card.*type" | cut -d ' ' -f 8-)

	#Rasperri pi camera
	if [[ $(v4l2-ctl --device=$i --list-formats-ext --list-formats | awk '/RG10'/ | wc -l ) > 0 ]]; 
	then
		VIDEO_CAMERA_INPUTS[$i,2]="RG10"
	fi

	if [[ $(v4l2-ctl --device=$this_device_id --list-formats-ext --list-formats | awk '/YUYV'/ | wc -l ) > 0 ]];
	then
		VIDEO_CAMERA_INPUTS[$i,2]="YUYV"
	fi

	if [[ $(v4l2-ctl --device=$i --list-formats-ext --list-formats | awk '/MJPG'/ | wc -l ) > 0 ]]; 
	then
		VIDEO_CAMERA_INPUTS[$i,2]="MJPG"
	fi

	if [[ $(v4l2-ctl --device=$i --list-formats-ext --list-formats | awk '/H264'/ | wc -l ) > 0 ]]; 
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

	##echo "Sorted array: ${sorted_array[*]}"

	VIDEO_CAMERA_INPUTS[$i,4]="${sorted_array[-1]}" ##THE hight resolution the cam can do

	selected_width=0
	selected_height=0


	##Manual test if 1920x1080 30fps is supported, if yes, then use if
	this_fps_string="$( v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$i,0]} --list-frameintervals=width=1920,height=1080,pixelformat=${VIDEO_CAMERA_INPUTS[$i,2]} )"

	#printf  "$this_fps_string"

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

	#force 30fps
	framerate=30



	##skip test if 1920x1080 works
	if [[ $selected_width == "0" ]]; then

		##test if it can do 30 fps by testing with string 30.000 fps
		for ((j=${#sorted_array[@]}-1; j>=0; j-- ));
		do
			this_res="${sorted_array[$j]}"
			#printf  "\n[$j) $this_res]: "
			this_width=$( printf ${this_res} | cut -d 'x' -f 1 ) 
			this_height=$( printf ${this_res} | cut -d 'x' -f 2 ) 

			selected_width=$this_width
			selected_height=$this_height

			#printf  "debug: v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$i,0]} --list-frameintervals=width=$this_width,height=$this_height,pixelformat=${VIDEO_CAMERA_INPUTS[$i,2]} \n"

			this_fps_string="$( v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$i,0]} --list-frameintervals=width=$this_width,height=$this_height,pixelformat=${VIDEO_CAMERA_INPUTS[$i,2]} )"

			##printf  "$this_fps_string"

			if [[ $this_fps_string ==  *"30.000 fps"* ]]; then
				#printf "yes\n"
				framerate=30
				break	##break loop, as it is supported, not need find another one
			else
				#if it cannot find 30fps, it will revert to 5fps, just incase		
				framerate=5
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


echo ""

echo "Output ============================";




#echo "${VIDEO_CAMERA_INPUTS[@]}" 

camera_num="-1"



#regex=^[0-9]+$
regex=^[0-9]+$

#while  ! [[ ( "${camera_num}" =~ ${regex} ) ]];

while ! [[ ( "${camera_num}" =~ ${regex} ) && ("$camera_num" -ge 0) && ("$camera_num" -lt ${#video_camera_array[@]})  ]];
do

	for (( i=0; i<${#video_camera_array[@]}; i++ ));
	do
		#echo $i

		echo "Input:	${VIDEO_CAMERA_INPUTS[$i,0]}"
		echo "Name:	${VIDEO_CAMERA_INPUTS[$i,1]}"
		echo "Type:	${VIDEO_CAMERA_INPUTS[$i,2]}"
		#echo ${VIDEO_CAMERA_INPUTS[$i,3]}
		#echo ${VIDEO_CAMERA_INPUTS[$i,4]}
		echo "Width:	${VIDEO_CAMERA_INPUTS[$i,5]}"
		echo "Height:	${VIDEO_CAMERA_INPUTS[$i,6]}"
		echo "FPS:	${VIDEO_CAMERA_INPUTS[$i,7]}"

		echo "------------------------";

	done


	end_num=$(( ${#video_camera_array[@]}-1 ))

	#printf "[0-${end_num}]\n"	

	printf "\nOther Functions: \n"
	printf "a. Toggle Post to server\n"
	printf "q. Kill running darknet interference\n"
	printf "f. Toggle FPS(Current: $framerate)\n"
	printf "p. Toggle Power Mode\n"
	printf "h. Reset Jetson Hotspot\n"
	printf "m. Reset Mobile Network\n"
	printf "n. Network Configurator\n"
	printf "c. Reset onboard camera with nvargus-daemon\n"
	printf "g. Reset ngrok\n"
	printf "t. Send Test Notification\n"
	printf "s. Show info\n"
	printf "v. Show camera\n"
	printf "r. Reboot\n"
	printf "o. Shutdown\n"

	printf "\nWhich Camera would you like to use? "

	## autorun, then directly assume it is camera 0
	if $autorun ; then
		camera_num="0"

	elif $quit_darknet ; then
		
		camera_num="q"
	else
		read -p "[0-${end_num}]: " -n1 camera_num	
	fi


	case $camera_num in

		a)
			clear
			if [[ $post_to_server == true ]]; then
				post_to_server=false
				printf "Will not send to server\n";
				#sudo python3 ~/jetson-nano-ai-cam/show.py "Will Not send to server"
			else
				post_to_server=true
				printf "Will send to server\n";
				#sudo python3 ~/jetson-nano-ai-cam/show.py "Will send to server"
			fi

			select_function=-1
			continue
		;;

		f)
			clear
			if [ $framerate == 30 ]; then
				framerate=10
			else	
				framerate=30
			fi
	
			printf "New Framerate: $framerate\n";
			select_function=-1
			continue
		;;


		q)
			clear
			if [[ $(sudo pgrep darknet) == "" ]]; then
				printf "Darknet process Not found\n";
				#sudo python3 ~/jetson-nano-ai-cam/show.py "Darknet not found"
			else
				kill_darknet
				#sudo python3 ~/jetson-nano-ai-cam/show.py "Darknet killed"
				printf "All darknet process killed\n";
			fi

			select_function=-1

			#don't loop if if from para
			if ! $quit_darknet ; then
				continue
			else
				exit 0;
			fi
		;;


		p)
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
			select_function=-1
			continue
		;;

		m)
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
			select_function=-1
			continue
		;;


		c)
			clear
			sudo systemctl restart nvargus-daemon
	
			printf "systemctl restart nvargus-daemon\n";
			select_function=-1
			continue
		;;

		t)
			clear
			printf "Sending Test Message\n";
			## need to use full path
			~/jetson-nano-ai-cam/send_http.sh "Test from: $myIPAddress" "$PWD/demo-jetson-nano.jpg";

			select_function=-1
			continue
		;;

		g)
			clear
			sudo pgrep ngrok | xargs sudo kill -9
			sudo /root/ngrok/ngrok start -all &	
			#sleep 1
			ngrok_domains=$(sudo tail -4 /root/ngrok/log.txt | awk ' /addr\=/ { gsub(/url=tcp\:\/\/|url=/, ""); print $NF}' )
			#sudo python3 ~/jetson-nano-ai-cam/show.py $ngrok_domains

			printf "ngrok restarted\n";
			select_function=-1
			continue
		;;



		s)
			clear
			sudo nmcli device
			sudo nmcli con 
			sudo lsusb 
			sudo modem-manager.mmcli -L
			sudo mmcli -m $modem_id
			#sudo modem-manager.mmcli -m 2

			sudo tail -4 /root/ngrok/log.txt | awk ' /addr\=/ { gsub(/url=tcp\:\/\/|url=/, ""); print $NF}' 
			printf "IP: $myIPAddress\n";

			sudo python3 ~/jetson-nano-ai-cam/info.py
			printf "Screen updated\n";
			select_function=-1
			continue
		;;


		v)
			printf "Doing: v4l2-ctl --device=$d -D --list-formats-ext \n"
			clear

			for d in /dev/video* ; do echo $d ; v4l2-ctl --device=$d -D --list-formats-ext  ; echo '===============' ; done

			printf "Screen updated\n";
			select_function=-1
			continue
		;;


		n)
			clear
			sudo nmtui 
			select_function=-1
			continue
		;;

		r)
			clear
			printf "Reboot in 2s\n";
			sleep 2
			sudo systemctl reboot -i
		;;

		o)
			clear
			printf "Shutdown in 3s\n";
			sleep 3
			sudo systemctl poweroff -i
		;;


		$'\e') 
			printf "\n\nEXIT \n\n"
			exit 0
			break
		;;

		*)
			clear
			select_function=-1
			continue
		;;
	esac


done

printf "Chosen: ${VIDEO_CAMERA_INPUTS[$camera_num,1]} ${VIDEO_CAMERA_INPUTS[$camera_num,0]}\n"


#darknet_police_str="./darknet detector demo ./cfg/samson-obj.data ./cfg/samson-yolov3-tiny.cfg backup/samson-yolov3-tiny_final.weights "

#darknet_police_str="./darknet detector demo ./cfg/samson-obj.data ./cfg/samson-yolov3-tiny.cfg ../../trained-weight/police2020/samson-yolov3-tiny_final.weights "

darknet_police_str="./darknet detector demo ~/trained-weights/police/interference-samson-obj.data ~/trained-weights/police/interference-samson-yolov3-tiny.cfg ~/trained-weights/police/samson-yolov3-tiny_final.weights "

darknet_coco_str="./darknet detector demo ./cfg/coco.data ./cfg/yolov3-tiny.cfg ./yolov3-tiny.weights "

v4l2src_pipeline_str="v4l2src io-mode=2 device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} do-timestamp=true ! "


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


v4l2src_pipeline_str+="width=${VIDEO_CAMERA_INPUTS[$camera_num,5]}, height=${VIDEO_CAMERA_INPUTS[$camera_num,6]}, framerate=$framerate/1 ! "

case ${VIDEO_CAMERA_INPUTS[$camera_num,2]} in


	"RG10")
		#onboard camera completely different
		v4l2src_pipeline_str="nvarguscamerasrc ! 'video/x-raw(memory:NVMM), width=(int)1600, height=(int)1200, format=(string)NV12, framerate=(fraction)30/1' ! nvvidconv flip-method=2 ! 'video/x-raw, format=(string)BGRx' ! videoconvert ! 'video/x-raw, format=(string)BGR' ! "
		#v4l2src_pipeline_str="nvarguscamerasrc ! 'video/x-raw(memory:NVMM), width=(int)1640, height=(int)1232, format=(string)NV12, framerate=(fraction)30/1' ! nvvidconv flip-method=2 ! 'video/x-raw, format=(string)BGRx' ! videoconvert ! 'video/x-raw, format=(string)BGR' ! tee name=t  t. !"
	;;

	"YUYV")
		
		v4l2src_pipeline_str+="videoconvert ! video/x-raw, format=I420 ! "
	;;

	"MJPG")
		##jpegdec > nvjpegdec
	
		## working with nvoverlay, not yolo
		#v4l2src_pipeline_str+="jpegparse ! nvjpegdec ! video/x-raw ! nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)RGBA' ! "

		#works for display only
		#v4l2src_pipeline_str+="jpegparse ! nvjpegdec ! video/x-raw ! nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)I420' ! nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)NV12' ! "

		#opencv expects BGR
		v4l2src_pipeline_str+="jpegparse ! jpegdec ! video/x-raw,format=I420 ! videoconvert ! video/x-raw,format=(string)BGR ! "
	;;

	"H264")
		# Jetson Nano    enable-low-outbuffer=1 
		# Jetson Nano max perf   disable-dvfs=1
		v4l2src_pipeline_str+="omxh264dec enable-low-outbuffer=1  disable-dvfs=1 ! videoconvert ! "
		#v4l2src_pipeline_str+="nvv4l2decoder ! "
	;;	

esac

#v4l2src_pipeline_str+=" tee name=t t. ! nvvidconv ! omxh264enc control-rate=2  bitrate=6000000 peak-bitrate=6500000  preset-level=2 profile=8 !  'video/x-h264, stream-format=(string)byte-stream, level=(string)5.2' ! h264parse ! qtmux ! filesink location=/mnt/sandisk/$today.mov t. ! "


v4l2src_pipeline_str+=" appsink sync=false async=false "

#printf "$v4l2src_pipeline_str\n\n";

darknet_exe_str+=" \"$v4l2src_pipeline_str\" "


select_function="-1"

execute_str=""

printf "\n"

#--list-ctrls-menus
##disable auto exposure 1-disable auto exposure, 3-enable auto exposure
#eval $(v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} -c exposure_auto=3 )
#eval $(v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} -c gamma=80 )
#eval $(v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} -c backlight_compensation=0 )
#eval $(v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} -c gain=0 )

#read

## create needed dir
if [ ! -d ~/images ]; then
  mkdir -p ~/images;
fi

regex=^[0-9]+$

while  ! [[ ( "${select_function}" =~ ${regex} )  ]];
do

#	printf "0. Select another Device\n"
	printf "Functions: \n"
	printf "1. Display Device details\n"
	printf "\x1b[;33;1m"
	printf "2. GUI DEMO Display - HDMI\n"
	printf "\x1b[;31;1m" 
	printf "3. Darknet YoloV3-Police Normal (Require GUI X11)\n"
	printf "4. Darknet YoloV3-Police NO Display MJPG http://$myIPAddress:8090\n"
	printf "\x1b[0;m"	
	printf "5. Darknet YoloV3-Tiny Normal (Require GUI X11)\n"
	printf "\x1b[;36;1;3m"
	printf "6. Darknet YoloV3-Tiny NO Display MJPG http://$myIPAddress:8090\n"
	printf "\x1b[0;m"	
	printf "\e[0;32m"
	printf "7. DEMO MJPG http://$myIPAddress:8090\n"
	printf "\x1b[0;m"

	## autorun, then go directly to YoloV3-Police No Display
	if $autorun ; then
		select_function="4"
	else
		read -n1 select_function
	fi


	case $select_function in
		$'\e') 
			printf "\n\nEXIT \n\n"
			exit 0
			break
		;;

		1)
			clear
			execute_str="v4l2-ctl --device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} --list-formats-ext --all"
			printf "\nDebug: $execute_str\n"
			eval $execute_str
			select_function=-1
			continue
		;;

		2)
			clear
			##nvoverlaysink	##fullscreen, fast
			##nveglglessink	##non fullscreen, slow
			##nv3dsink
			##nvvideosink
			##xvimagesink
			case ${VIDEO_CAMERA_INPUTS[$camera_num,2]} in
				"RG10")					
					#v4l2src_pipeline_str=${v4l2src_pipeline_str//1640/1920}	
					#v4l2src_pipeline_str=${v4l2src_pipeline_str//1232/1080}	

					v4l2src_display_str="nvarguscamerasrc ! 'video/x-raw(memory:NVMM), width=(int)1640, height=(int)1232, format=(string)NV12, framerate=(fraction)30/1' ! nvvidconv flip-method=2 ! nvoverlaysink sync=false async=false"					
					execute_str="gst-launch-1.0 $v4l2src_display_str -e"
				;;
				"MJPG")					
					#v4l2src_display_str="v4l2src io-mode=2 device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} do-timestamp=true ! image/jpeg, width=${VIDEO_CAMERA_INPUTS[$camera_num,5]}, height=${VIDEO_CAMERA_INPUTS[$camera_num,6]}, framerate=$framerate/1 ! jpegparse ! nvjpegdec ! video/x-raw ! nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)I420' ! nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)NV12' ! nvoverlaysink sync=false async=false"	

					#working
					#v4l2src_display_str="v4l2src io-mode=2 device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} do-timestamp=true ! image/jpeg, width=${VIDEO_CAMERA_INPUTS[$camera_num,5]}, height=${VIDEO_CAMERA_INPUTS[$camera_num,6]}, framerate=$framerate/1 ! jpegparse ! nvjpegdec ! video/x-raw ! nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)RGBA' ! nvoverlaysink sync=false async=false"			

					v4l2src_display_str="v4l2src io-mode=2 device=${VIDEO_CAMERA_INPUTS[$camera_num,0]} do-timestamp=true ! image/jpeg, width=${VIDEO_CAMERA_INPUTS[$camera_num,5]}, height=${VIDEO_CAMERA_INPUTS[$camera_num,6]}, framerate=$framerate/1 ! jpegparse ! jpegdec ! video/x-raw ! nvvidconv ! 'video/x-raw(memory:NVMM), format=(string)I420' ! nvoverlaysink sync=false async=false"		


					execute_str="gst-launch-1.0 $v4l2src_display_str -e"


				;;

				*)
					#v4l2src_display_str=${v4l2src_pipeline_str//appsink/ nvvidconv ! 'video/x-raw\(memory:NVMM\), format=I420,  width=\(int\)1920, height=\(int\)1080, framerate=30/1' ! nvoverlaysink}
					v4l2src_display_str=${v4l2src_pipeline_str//appsink/ nvvidconv ! nvoverlaysink}
					
					#v4l2src_display_str=${v4l2src_display_str//appsink/ xvimagesink}
					execute_str="gst-launch-1.0 $v4l2src_display_str -e"
				;;
			esac
		
			#execute_str="gst-launch-1.0 $v4l2src_display_str -e"
			printf "\nDebug: $execute_str\n"
	
			eval $execute_str
			select_function=-1
			continue
		;;

		3)
			clear
			#cd ~/AlexeyAB/darknet
			cd ~/modified-alexeyab-darknet

			kill_darknet_slient

			#needto remove nvjpeg
			#v4l2src_pipeline_str=${v4l2src_pipeline_str//nvjpegdec/jpegdec}

			v4l2src_pipeline_str=${v4l2src_pipeline_str//\'/''} ##remove the ' for nvarguscamerasrc

			##change to 15fps
			#v4l2src_pipeline_str=${v4l2src_pipeline_str//30/5}

			case ${VIDEO_CAMERA_INPUTS[$camera_num,2]} in
				"RG10")

					execute_str="$darknet_police_str \"$v4l2src_pipeline_str -e\" -thresh 0.4"
				;;
				*)

					execute_str="$darknet_police_str -c $camera_num -thresh 0.4"
				;;
			esac

			#execute_str="$darknet_police_str \"$v4l2src_pipeline_str -e\" -thresh 0.4"

			
			printf "\nDebug: $execute_str\n"
			eval $execute_str
			select_function=-1
			continue
		;;

		4)
			clear
			#cd ~/AlexeyAB/darknet
			cd ~/modified-alexeyab-darknet

			kill_darknet_slient

			#needto remove nvjpeg
			#v4l2src_pipeline_str=${v4l2src_pipeline_str//nvjpegdec/jpegdec}

			v4l2src_pipeline_str=${v4l2src_pipeline_str//\'/''} ##remove the ' for nvarguscamerasrc

			case ${VIDEO_CAMERA_INPUTS[$camera_num,2]} in
				"RG10")

					execute_str="$darknet_police_str \"$v4l2src_pipeline_str -e\" -thresh 0.5 -dont_show -prefix ~/images/d$today -mjpeg_port 8090 -json_port 8070 &"
				;;
				*)

					#execute_str="$darknet_police_str -c $camera_num -thresh 0.4 -dont_show -prefix ~/images/d$today -mjpeg_port 8090 -json_port 8070"

##output string
##execute_str=$(cat <<EOF
##$darknet_police_str -c $camera_num -thresh 0.05 -dont_show -prefix ~/images/d$today -mjpeg_port 8090 -json_port 8070 | 
##gawk -F: '/JETSON_NANO_DETECTION:[.]*/ { gsub(/,\s\W/, ":"); gsub(/,\s/, ","); system("~/jetson-nano-ai-cam/send_http.sh " "\"" \$2 "\" " \$3)} ' &
##EOF


##no putput string
##execute_str=$(cat <<EOF
##nohup $darknet_police_str -c $camera_num -thresh 0.03 -dont_show -prefix ~/images/d$today -mjpeg_port 8090 -json_port 8070 | 
##gawk -F: '/JETSON_NANO_DETECTION:[.]*/ { gsub(/,\s\W/, ":"); gsub(/,\s/, ","); system("~/jetson-nano-ai-cam/send_http.sh " "\"" \$2 "\" " \$3)} ' ##&>/dev/null &
##EOF


execute_str=$(cat <<EOF
nohup $darknet_police_str -c $camera_num -thresh 0.03 -dont_show -prefix ~/images/d$today -mjpeg_port 8090 -json_port 8070 
EOF

)


				;;
			esac

			printf "\nDebug: $execute_str\n"
			eval $execute_str
			sudo pgrep darknet
			continue
		;;		

		5)
			clear
			#cd ~/AlexeyAB/darknet
			cd ~/modified-alexeyab-darknet


			kill_darknet
			
			#needto remove nvjpeg
			#v4l2src_pipeline_str=${v4l2src_pipeline_str//nvjpegdec/jpegdec}

			v4l2src_pipeline_str=${v4l2src_pipeline_str//\'/''} ##remove the ' for nvarguscamerasrc

			##change to 15fps
			v4l2src_pipeline_str=${v4l2src_pipeline_str//30/5}


			case ${VIDEO_CAMERA_INPUTS[$camera_num,2]} in
				"RG10")

					execute_str="$darknet_coco_str \"$v4l2src_pipeline_str -e\" -thresh 0.1"
				;;
				*)

					#execute_str="$darknet_coco_str \"$v4l2src_pipeline_str -e\" -thresh 0.4"
					execute_str="$darknet_coco_str -c $camera_num -thresh 0.1"
				;;
			esac




			printf "\nDebug: \n$execute_str\n"
			eval $execute_str
			continue
		;;

		6)
			clear
			#cd ~/AlexeyAB/darknet
			cd ~/modified-alexeyab-darknet


			kill_darknet

			#needto remove nvjpeg
			v4l2src_pipeline_str=${v4l2src_pipeline_str//nvjpegdec/jpegdec}

			v4l2src_pipeline_str=${v4l2src_pipeline_str//\'/''} ##remove the ' for nvarguscamerasrc


			case ${VIDEO_CAMERA_INPUTS[$camera_num,2]} in
				"RG10")

					execute_str="$darknet_coco_str \"$v4l2src_pipeline_str -e\" -thresh 0.4 -dont_show -prefix ~/images/d$today -mjpeg_port 8090 -json_port 8070 &"
				;;
				*)

					#execute_str="$darknet_coco_str -c $camera_num -thresh 0.4 -dont_show -prefix ~/images/d$today -mjpeg_port 8090 -json_port 8070 | sed 's/JETSON_NANO_DETECTION\://g' | sed 's/\,\W\:/:/g' | awk -F: '{ system (\"~/jetson-nano-ai-cam/send_http.sh\" "'$1 $2'" ) }'"

					#execute_str="$darknet_coco_str -c $camera_num -thresh 0.4 -dont_show -prefix ~/images/d$today -mjpeg_port 8090 -json_port 8070 |  grep JETSON_NANO_DETECTION | sed 's/JETSON_NANO_DETECTION\://g' | sed 's/ //g' | sed 's/\,\W/|/g' | awk -F'|' ' {print ("~/jetson-nano-ai-cam/send_http.sh "\$1" "\$2) | "sh" }  '  

					execute_str=$(cat <<EOF
$darknet_coco_str -c $camera_num -thresh 0.4 -dont_show -prefix ~/images/d$today -mjpeg_port 8090 -json_port 8070 | 
gawk -F: '/JETSON_NANO_DETECTION:[.]*/ { gsub(/,\s\W/, ":"); gsub(/,\s/, ","); system("~/jetson-nano-ai-cam/send_http.sh" " \"" \$2 "\" " \$3)} '  &
EOF
)

					##ori
					##execute_str="$darknet_coco_str -c $camera_num -thresh 0.4 -dont_show -prefix ~/images/d$today -mjpeg_port 8090 -json_port 8070 | grep JETSON_NANO_DETECTION";

				;;
			esac
	

			printf "\nDebug: \n$execute_str\n"
			eval $execute_str

			sudo pgrep darknet
			continue
		;;	

		7)
			clear
			#to do
			select_function=-1
			continue
		;;

		8)
			clear

			select_function=-1
			continue
		;;

		

	esac	


done


#############################################
#below for for checking the darknet process



runInterval=5 # In seconds








#nohup loop &>/dev/null &


#eval $darknet_police_str

#nohup command &>/dev/null &
