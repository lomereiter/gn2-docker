FROM ubuntu-debootstrap

MAINTAINER Artem Tarasov <lomereiter@gmail.com>
WORKDIR /root

# based on https://github.com/zsloan/genenetwork2/blob/master/misc/gn_installation_notes.txt

# Add keys an source to install the latest stable version of R
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" > /etc/apt/sources.list.d/r-stable-trusty.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

# Add keys an source to install the latest stable version of nginx
RUN echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu trusty main" > /etc/apt/sources.list.d/nginx-stable-trusty.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C && \

# install the software
RUN apt-get update && \
    apt-get install -y python-dev libffi-dev libmysqlclient-dev \
    libatlas-base-dev gfortran g++ python-pip libyaml-dev \
    mysql-server r-base r-base-dev colordiff ntp ufw wget \
    redis-server nginx

# install virtualenv, set default interpreter to bash
RUN pip install virtualenv
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN virtualenv ve27

# MySQL setup
ADD mysql_setup.sql /tmp/mysql_setup.sql
RUN /etc/init.d/mysql start && mysql < /tmp/mysql_setup.sql

## Download the simplified DB from the old sourceforge repository
## and pipe it into MySQL on the fly so as not to waste time
RUN /etc/init.d/mysql start && \
    wget --quiet -O - 'http://downloads.sourceforge.net/project/genenetwork/db_webqtl_simplified_1.sql.gz?r=&ts=1429273316&use_mirror=iweb' | \
    gzip -dc | mysql --user=GN --password=mypass db_webqtl

# fetch the list of Python module dependencies
RUN wget --quiet https://raw.githubusercontent.com/zsloan/genenetwork2/master/misc/requirements.txt

# install pp module separately
RUN wget http://www.parallelpython.com/downloads/pp/pp-1.6.3.tar.gz && \
    tar xvf pp-1.6.3.tar.gz && \
    cd pp-1.6.3 && source ~/ve27/bin/activate && \
    python setup.py install 

# install numpy separately (otherwise installation of scipy fails in the next step)
RUN source ~/ve27/bin/activate && pip install numpy==1.7.0

## install qtlreaper
RUN wget "http://downloads.sourceforge.net/project/qtlreaper/qtlreaper/1.1.1/qtlreaper-1.1.1.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fqtlreaper%2Ffiles%2Flatest%2Fdownload&ts=1358975786&use_mirror=iweb" && \
    mv -v "qtlreaper-1.1.1.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fqtlreaper%2Ffiles%2Flatest%2Fdownload&ts=1358975786&use_mirror=iweb" qtlreaper-1.1.1.tar.gz && \
    tar xvf qtlreaper-1.1.1.tar.gz && \
    mkdir ~/ve27/include/python2.7/Reaper && \
    cd qtlreaper-1.1.1 && source ~/ve27/bin/activate && \
    python setup.py install 

## install numarray
RUN wget "http://downloads.sourceforge.net/project/numpy/Old%20Numarray/1.5.2/numarray-1.5.2.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fnumpy%2Ffiles%2FOld%2520Numarray%2F1.5.2%2Fnumarray-1.5.2.tar.gz%2Fdownload&ts=1358978306&use_mirror=superb-dca2" && \
    mv -v numarray-1.5.2* numarray-1.5.2.tar.gz && \
    tar xvf numarray-1.5.2.tar.gz && \
    cd numarray-1.5.2 && source ~/ve27/bin/activate && \
    python setup.py install 

# install the rest of the required modules
RUN source ~/ve27/bin/activate && \
    sed -i 's/MySQL-python==1.2.4/MySQL-python==1.2.5/g' requirements.txt && \
    pip install -r requirements.txt && \
    pip install rpy2

# install R/qtl
RUN apt-get install -y r-cran-qtl
RUN apt-get install -y supervisor

COPY my_settings.py /root/
COPY run_gn2_server.sh /root/
COPY supervisord.conf /etc/supervisor/conf.d/
RUN mkdir -p /var/log/supervisor

EXPOSE 80

# until path settings are introduced, simply use the same path
RUN mkdir -p /home/zas1024

# download and install / unpack plink (a requirement)
RUN wget http://pngu.mgh.harvard.edu/~purcell/plink/dist/plink-1.07-x86_64.zip && \
    unzip plink-1.07-x86_64.zip -d /home/zas1024

RUN git clone git@github.com:genenetwork/pylmm_gn2.git /home/zas1024/pyLMM

CMD ["/usr/bin/supervisord"]
