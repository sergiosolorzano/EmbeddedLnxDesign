if [ -f /etc/lsb-release ] && grep -qi "ubuntu" /etc/lsb-release; then
  echo "This system is running Ubuntu"
else
  echo "This system is not running Ubuntu"
fi