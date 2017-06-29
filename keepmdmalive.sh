#!/usr/bin/bash -l
#$ -S /usr/bin/bash

#configs
AUTH="username:pass";
RouterIP="192.168.1.1";
IP="4.2.2.4"; # it's better to use provider DNS or gateway ip instead.
SSID="wifi_ssid";


cleanup ()
{
	kill -s SIGTERM $!
	exit 0
}

resetModem ()
{
    logger "$0 - Going to restart modem"
    [[ $(cat $home.mdmReset) == 0 ]] && echo 1 > $home.mdmReset;
    allpts=$(who | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | awk 'BEGIN{ORS=","}{print $2}');
    allpts=${allpts%?};
    printf "\n\t\t*** To All PTS Users: Going to reset the modem in 10s $(date +%a-%T) ***\n\t\t\tYou may cancel it by writing 0 to ~/.mdmReset\n\n" | tee $(eval "echo /dev/{$allpts}");
    cnt=0;
    while [[ $((++cnt)) < 10 && $(cat $home.mdmReset) > 0 ]];
    do
        sleep 1s;
    done
    if [[ $(cat $home.mdmReset) > 0 ]]; then
        ret="$(curl -s -m 100 --data "ctype=pppoe&todo=reboot&SID=$sid" -H "Authorization: Basic ${auth}" http://${RouterIP}/setup.cgi)"
        if ! [[ $ret =~ $rxunauthorized ]]; then
            echo 0 > $home.mdmReset
            sleep 3m
        else
            #echo 1 > $home.mdmReset;
            return 1;
        fi
    else
        printf "\n\t\tCanceled!\n" | tee $(eval "echo /dev/{$allpts}");
        #if reset request is due to multiple connection tries, and canceled by user then we give it 5min extra time.
        [[ $triedconn == 5 ]] && ((triedconn-=30));
    fi
    return 0;
}

trap cleanup SIGINT SIGTERM;

rxifstat='<[a-zA-Z 0-9"=]+ifstatus"[a-zA-Z ]+="([a-zA-Z]+)';
rxsid='<[a-zA-Z 0-9"=]+SID"[a-zA-Z ]+="([0-9]+)"';
#rxnet="^\*[a-zA-Z0-9 -]+${SSID}"; #not needed as we check wpa_cli instead on netctl-auto
rxunauthorized='401 Unauthorized';
home="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
sid='';
triedconn=0;
cval=0;
unath=0;
istargetnet=1; #start by false
lifstat='start';
lsid='';
net=1;
auth=$(base64 <(echo -n ${AUTH}));

logger "$0 - Starting loop for Keeping Old Linksys Modem Alive, checking every 10sec"
[ -s $home.mdmReset ] || echo -n 0 > $home.mdmReset;
#sleep 10s
while [ 1 ];
do
	if wpa_cli -i wlan0 status | grep -q "${SSID}"; then
        [[ $istargetnet != 0 ]] && istargetnet=0 && logger "$0 - ${SSID} detected.";
		ifstat='';
        [[ $unath == 1 ]] && [[ $cval == 2 ]] && cval=0;
		if [[ $cval == 0 ]]; then
			status="$(curl -s -m 10 -H "Authorization: Basic ${auth}" http://${RouterIP}/setup.cgi?next_file=Setup.htm)";
			(( cval++ ));
		else
			status="$(curl -s -m 10 -H "Authorization: Basic ${auth}" http://${RouterIP}/setup.cgi?next_file=Status.htm)";
			[[ $status =~ $rxifstat ]] && ifstat="${BASH_REMATCH[1]}";
            [[ $lifstat != $ifstat ]] && lifstat=$ifstat && logger "$0 - stats is $ifstat";
            cval=2;
		fi
		
		[[ $status =~ $rxsid ]] && sid="${BASH_REMATCH[1]}";
        [[ $lsid != $sid ]] && lsid=$sid && logger "$0 - SID is $sid";
		
        if [[ $(cat $home.mdmReset) > 0 ]]; then
            # restart modem
            resetModem && unath=0 || unath=1;
		elif [[ $ifstat != "Up" ]] && ! ping -q -w1 -c1 $IP > /dev/null; then
            # for connectivity check we can also: [[ $(wpa_cli -i wlan0 ping 2> /dev/null) == 'PONG' ]] ==> no it's not seem to check internet conns
            [[ $net != 1 ]] && net=1 && logger "$0 - Net is down";
			if [[ $triedconn == 5 ]]; then
				# restart modem
                resetModem && unath=0 || unath=1;
			else
				# connect
                [[ $triedconn == 0 ]] && logger "$0 - Start trying to connect for 6 times including 5mins extra if reset canceled.";
				ret="$(curl -s -m 10 --data "ctype=pppoe&todo=connect&message=&SID=$sid" -H "Authorization: Basic ${auth}" http://${RouterIP}/setup.cgi)"
				if [[ $ret =~ $rxunauthorized ]]; then
                    unath=1;
                else
                    unath=0;
					((triedconn++));
					sleep 10s;
				fi
			fi
		else
			triedconn=0;
            [[ $net != 0 ]] && net=0 && logger "$0 - Net is Up";
		fi
		ping -q -w1 -c1 $IP > /dev/null && sleep 10s
	else
        [[ $istargetnet != 1 ]] && istargetnet=1 && logger "$0 - No ${SSID}"
		sleep 1m
		wait $!
	fi
done
