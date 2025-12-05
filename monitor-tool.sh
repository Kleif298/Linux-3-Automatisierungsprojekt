while [ true ]; do
    echo "Monitoring system resources..."
    top -b -n1 | head -n 10
    sleep 60
done;