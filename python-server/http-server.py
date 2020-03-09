from flask import Flask
app = Flask(__name__)

@app.route('/')
def helloWorld():
	return 'hello World\n'


@app.route('/reboot')
def reboot():
	return 'reboot\n'

@app.route('/send/<name>')
def send_name(name):
   if name =='admin':
      return redirect(url_for('hello_admin'))
   else:
      return redirect(url_for('hello_guest',guest = name))
	#return 'Sending %s!\n' % name

#test
#now
#debug
#restart
#debug
#status



if __name__ == '__main__':
	app.run(host='0.0.0.0', port=8080, debug=True)

#https://linuxhint.com/rest_api_python/
#https://www.tutorialspoint.com/flask/flask_quick_guide.htm
