# Hadoop install on docker 

# To start hadoop containers.
This docker images in built on alpine 3.5 light OS.

This is working image, need to make changes for docker-compose.yml to start containers on deamon.

<pre>
docker pull arivndr226/hadoop
docker run -it -p 50070:50070 arvindr226/hadoop /root/docker-entry.sh -bash
</pre>


Suggestion Please on arvindr226@gmail.com
