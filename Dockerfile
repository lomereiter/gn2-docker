FROM ubuntu-debootstrap

MAINTAINER Artem Tarasov <lomereiter@gmail.com>

# based on https://github.com/zsloan/genenetwork2/blob/master/misc/gn_installation_notes.txt

# install the software
RUN apt-get update && \
    apt-get install -y git etckeeper python-dev libmysqlclient-dev \
    libatlas-base-dev gfortran g++ python-pip libyaml-dev \
    mysql-server r-base-dev colordiff ntp ufw vim supervisor wget \
    redis-server

RUN echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu trusty main" > /etc/apt/sources.list.d/nginx-stable-trusty.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C && \
    apt-get update && \
    apt-get install -y nginx

# install virtualenv, set default interpreter to bash
RUN pip install virtualenv
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN cd /root && virtualenv ve27

# MySQL setup
ADD mysql_setup.sql /tmp/mysql_setup.sql
RUN /etc/init.d/mysql start && mysql < /tmp/mysql_setup.sql

## Download the simplified DB from the old sourceforge repository
## and pipe it into MySQL on the fly so as not to waste time
RUN cd /root && /etc/init.d/mysql start && \
    wget --quiet -O - 'http://downloads.sourceforge.net/project/genenetwork/db_webqtl_simplified_1.sql.gz?r=&ts=1429273316&use_mirror=iweb' | \
    gzip -dc | mysql --user=GN --password=mypass db_webqtl

# Clone the Github repo
RUN cd /root && git clone git://github.com/zsloan/genenetwork2.git gene

# install pp module separately
RUN cd /root && \
    wget http://www.parallelpython.com/downloads/pp/pp-1.6.3.tar.gz && \
    tar xvf pp-1.6.3.tar.gz && \
    cd pp-1.6.3 && source ~/ve27/bin/activate && \
    python setup.py install 

# install numpy separately (otherwise installation of scipy fails in the next step)
RUN source ~/ve27/bin/activate && pip install numpy==1.7.0

## install qtlreaper
RUN cd /root && wget "http://downloads.sourceforge.net/project/qtlreaper/qtlreaper/1.1.1/qtlreaper-1.1.1.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fqtlreaper%2Ffiles%2Flatest%2Fdownload&ts=1358975786&use_mirror=iweb" && \
    mv -v "qtlreaper-1.1.1.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fqtlreaper%2Ffiles%2Flatest%2Fdownload&ts=1358975786&use_mirror=iweb" qtlreaper-1.1.1.tar.gz && \
    tar xvf qtlreaper-1.1.1.tar.gz && \
    mkdir ~/ve27/include/python2.7/Reaper && \
    cd qtlreaper-1.1.1 && source ~/ve27/bin/activate && \
    python setup.py install 

## install numarray
RUN cd /root && wget "http://downloads.sourceforge.net/project/numpy/Old%20Numarray/1.5.2/numarray-1.5.2.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fnumpy%2Ffiles%2FOld%2520Numarray%2F1.5.2%2Fnumarray-1.5.2.tar.gz%2Fdownload&ts=1358978306&use_mirror=superb-dca2" && \
    mv -v numarray-1.5.2* numarray-1.5.2.tar.gz && \
    tar xvf numarray-1.5.2.tar.gz && \
    cd numarray-1.5.2 && source ~/ve27/bin/activate && \
    python setup.py install 

# install the rest of the required modules
RUN cd /root && source ~/ve27/bin/activate && \
    sed -i 's/MySQL-python==1.2.4/MySQL-python==1.2.5/g' gene/misc/requirements.txt && \
    pip install -r gene/misc/requirements.txt && \
    pip install rpy2

## change all the hard-coded paths
RUN cd /root/gene/wqflask && find . -type f -print0 | xargs -0 sed -i 's/\/home\/zas1024/\/root/g'
## the downloaded DB doesn't have the attributes table, so ignore them
RUN sed -i 's/self\.get_attributes()/self\.attributes = {}/g' /root/gene/wqflask/wqflask/show_trait/SampleList.py

ADD my_settings.py /root/my_settings.py
ADD run_gn2_server.sh /root/run_gn2_server.sh

# Copy supervisord settings and run it
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor
EXPOSE 80
CMD ["/usr/bin/supervisord"]
