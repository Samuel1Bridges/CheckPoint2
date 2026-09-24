#!/bin/bash


echo "Memory"
top_mem=$(ps -eo pid=,pcpu=,pmem=,args= --sort=-pmem | head -n 5)


while read -r pid cpu mem command; do
        printf "PID: %s | CPU: %.1f%% | MEM: %.1f%% | CMD: %s\n" \
                "$pid" "$cpu" "$mem"  "$command"
done <<< "$top_mem"

echo
echo 
echo 
top_mem=$(ps -eo pid=,pcpu=,pmem=,args= --sort=-pmem | head -n 5)


while read -r pid cpu mem command; do
        printf "PID: %s | CPU: %.1f%% | MEM: %.1f%% | CMD: %s\n" \
                "$pid" "$cpu" "$mem"  "$command"
done <<< "$top_mem"


mem_usage=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')

if [ "$mem_usage" -gt 80 ]; then

            echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Memory usage at ${mem_usage}%" \

fi




echo
echo
echo "Cpu"

top_cpu=$(ps -eo pid=,pcpu=,pmem=,args= --sort=-pcpu | head -n 5)


while read -r pid cpu mem command; do
	printf "PID: %s | CPU: %.1f%% | MEM: %.1f%% | CMD: %s\n" \
 		"$pid" "$cpu" "$mem"  "$command"
done <<< "$top_cpu"


total_cpu=$( awk ' {sum += $3} END {printf "%.1f", sum}' <<< "$top_cpu")

echo "Total CPU usage: ${total_cpu}%"



read -rp "Terminate them all? (y/N)" action


case "$action" in
	Y|y|yes)
		echo "Terminate all user processes"

		while read -r pid cpu mem command; do

    			# Get the UID that owns this process
    			uid=$(ps -o uid= -p "$pid" | tr -d ' ')

    			# Only terminate normal user processes
    			if [[ -n "$uid" && "$uid" -ge 1000 && "$uid" -ne 65534 ]]; then

        			kill -TERM "$pid"
        			echo "Sent SIGTERM to $pid. Waiting 3 seconds..."
        			sleep 3

        			if kill -0 "$pid" 2>/dev/null; then
            				kill -KILL "$pid"
            				echo "Process $pid did not stop -- sent SIGKILL."
        			else
            				echo "Process $pid stopped gracefully."
        			fi

    			else
        			echo "Skipping system process $pid."
    			fi

		done <<< "$top_cpu"
                ;;
       N |n|no )
                echo "next"
                ;;

        * )
                echo"Unknown"
                ;;

esac

read -rp "Enter PID to act on (or press Enter to exit): "  pid

# Check if PID is still running
if ! kill -0 "$pid" 2>/dev/null; then
    echo "PID $hold is not running."
    exit 0
fi

read -rp "Choose an action -- [t]erminate, [n]renice: " act

case "$act" in

	t|T|terminate)
		echo "Terminating"
		

    			if kill -TERM "$pid" 2>/dev/null; then

       	 			echo "Sent SIGTERM to $pid. Waiting 3 seconds..."
        			sleep 3

        			if ps -p "$pid" > /dev/null; then
            				kill -TERM "$pid"
            				echo "Process $pid did not stop -- sent SIGKILL."
      	 			else
            				echo "Process $pid stopped gracefully."
        			fi

    			else
        			echo "Process $pid could not be terminated -- permission denied."
    			fi

		
	;;

	n|N|nrenice)
		echo "nrenice"
		read -rp "Enter new nice value (0..19): " nice_value
		# Check that it is an integer from 0 to 19
		if ! [[ "$nice_value" =~ ^[0-9]+$ ]] || (( nice_value < 0 || nice_value  > 19 )); then
    			echo "Error: nice value must be in 0..19."
		else
    			renice -n "$nice_value" -p "$hold"

    			if [ $? -eq 0 ]; then
        			echo "Process $pid set to nice value $nice_value"
    			fi
		fi

	;;
	
	*)
		echo "Unknown action"
	;;

esac
