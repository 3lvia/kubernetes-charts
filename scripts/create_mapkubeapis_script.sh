#awk '{print "helm mapkubeapis -n "$2 " " $1}' releases2.txt >mapkubeapis.sh
awk '{print "helm mapkubeapis -n "$1 " " $2}' ingress.txt >mapkubeapis_ingress.sh
