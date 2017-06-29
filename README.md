# keepmdmalive - for Linksys WAG54G2

A service specially writen to keep old Linksys WAG54G2 ADSL wireless modem router, 
connections alive. 

I have an old type of this modem in home and one of its power circuit capacitors leaks,
so modem loose connection on high loads. So I wrote this simple service script to watch
modem status and request to connect when link is down and restart modem when connect request 
does not work. it works for me :)

It is distributed in the hope that it will be useful to or inspire someone.

## Applications

Currently this script doesn't support any kind device other than Linksys WAG54G2 which
is a ADSL wireless modem router.
If you have device with similar web interface, this should work for you either!
It configured to automatically work in linux systems with `bash` and `systemd` init system. 
but should work on any `bash` implementations, if you manage a manual/automatic way to run 
the script.

## Installation

Put both `keepmdmalive.sh` and `.mdmReset` in a directory and make `keepmdmalive.sh` executable,
```
git clone https://github.com/2i3r/keepmdmalive.git
cd keepmdmalive
chmod +x keepmdmalive.sh
```
Replace configs in `keepmdmalive.sh` file with your info, such as username and password of device web interface in `AUTH`, router local ip address in `RouterIP`, any ip to check connection in `IP` (gateway or DNS address of internet provider is best choice) and SSID of your wireless network in `SSID`
> keepmdmalive.sh 4,8
```
...
#configs
AUTH="username:pass";
RouterIP="192.168.1.1";
IP="4.2.2.4"; 
SSID="wifi_ssid";
...
```
Enter path to `keepmdmalive.sh` in the `keepmdmalive.service` file and then move it to `/etc/systemd/system/`
```
sed "s~ExecStart=.*\.sh$~ExecStart=$(readlink -e keepmdmalive.sh)~;" keepmdmalive.service
sudo mv keepmdmalive.service /etc/systemd/system/
```
Enable service and start it
```
systemctl enable keepmdmalive
systemctl start keepmdmalive
```



## License

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
