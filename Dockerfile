FROM alpine:3.5
MAINTAINER Arvind Rawat <arvindr226@gmail.com>

ENV HADOOP_VERSION 2.8.0

ENV HADOOP_URL  http://www-eu.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz

RUN apk update && apk add  bash \
				curl \
				curl-dev \
				tar \
				gzip \
				wget


RUN wget -q "$HADOOP_URL" -O hadoop.tar.gz \
	&& tar -C /usr/local -xzf hadoop.tar.gz \
	&& rm hadoop.tar.gz \
	&& cd /usr/local && mv hadoop-${HADOOP_VERSION} hadoop

RUN apk add --update --no-cache openjdk8-jre openssh openssh-client
ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop
ENV HADOOP_COMMON_LIB_NATIVE_DIR /usr/local/hadoop/lib/native

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk/jre\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

RUN mkdir $HADOOP_PREFIX/input

ADD core-site.xml.template $HADOOP_PREFIX/etc/hadoop/core-site.xml.template
RUN sed s/HOSTNAME/localhost/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
ADD hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

ADD mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

#ADD native /usr/local/hadoop/
#RUN mv /usr/local/hadoop/lib /usr/local/hadoop/lib_org
#RUN ls /usr/local/hadoop/
#ADD native /usr/local/hadoop/lib/
#RUN ls /usr/local/hadoop/lib
#RUN mv /usr/local/hadoop/native  /usr/local/hadoop/lib

RUN $HADOOP_PREFIX/bin/hdfs namenode -format

RUN sed -ie 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
RUN sed -ri 's/#HostKey \/etc\/ssh\/ssh_host_key/HostKey \/etc\/ssh\/ssh_host_key/g' /etc/ssh/sshd_config
RUN sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey \/etc\/ssh\/ssh_host_rsa_key/g' /etc/ssh/sshd_config
RUN sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_dsa_key/HostKey \/etc\/ssh\/ssh_host_dsa_key/g' /etc/ssh/sshd_config
RUN sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/g' /etc/ssh/sshd_config
RUN sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ed25519_key/HostKey \/etc\/ssh\/ssh_host_ed25519_key/g' /etc/ssh/sshd_config
RUN /usr/bin/ssh-keygen -A
RUN ssh-keygen -t rsa -b 4096 -f  /etc/ssh/ssh_host_key
RUN echo -e "Host * \n   UserKnownHostsFile /dev/null \n  StrictHostKeyChecking no \n  LogLevel quiet" >> /etc/ssh/ssh_config
RUN mkdir ~/.ssh 
RUN cp /etc/ssh/ssh_host_rsa_key ~/.ssh/id_rsa && cp /etc\/ssh\/ssh_host_rsa_key.pub  ~/.ssh/authorized_keys

RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh

CMD /usr/sbin/sshd -D BACKGROUND && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/root
CMD /usr/sbin/sshd -D BACKGROUD && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -put $HADOOP_PREFIX/etc/hadoop/ input

COPY docker-entry.sh /root/
RUN chmod +x /root/docker-entry.sh
#ENTRYPOINT ["/root/docker-entry.sh"]

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# Mapred ports
EXPOSE 10020 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122
