
yolov3-tiny>onnx

https://blog.csdn.net/weixin_43562948/article/details/104724461?depth_1-utm_source=distribute.pc_relevant.none-task&utm_source=distribute.pc_relevant.none-task

模型转换
yolov3-tiny—>onnx
新建yolov3_tiny_to_onnx.py文件

python3 yolov3_tiny_to_onnx.py --model yolov3-416


同时这个py文件还支持yolov3-416、yolov3-288、yolov3-608、yolov3-tiny-288这些模型。

运行上述命令之后，会生成一个onnx的模型。

==================
onnx—>trt
新建文件：onnx_to_tensorrt.py

python3 onnx_to_tensorrt.py --model yolov3-416

稍等一会，执行完成后便会生成一个.trt文件。这个便是tensorRT要用到的模型。


=========