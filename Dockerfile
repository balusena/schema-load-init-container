FROM dokken/centos-8
RUN yum install -y epel-release git && \
    yum install -y mysql mongodb-org-shell && \
    yum clean all
COPY mongo.repo /etc/yum.repos.d/mongo.repo
COPY run.sh /run.sh
RUN chmod +x /run.sh
ENTRYPOINT ["/bin/bash", "/run.sh"]
