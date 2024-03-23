FROM dokken/centos-8
RUN yum install -y epel-release git
RUN yum install -y mongodb-org-shell
COPY mongo.repo /etc/yum.repos.d/mongo.repo
COPY run.sh /
RUN chmod +x /run.sh
ENTRYPOINT ["/run.sh"]
