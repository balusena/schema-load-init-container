FROM dokken/centos-8

# Install necessary packages
RUN yum install -y epel-release && \
    yum install -y git && \
    yum install -y https://repo.mongodb.org/yum/redhat/8/mongodb-org/4.4/x86_64/RPMS/mongodb-org-shell-4.4.3-1.el8.x86_64.rpm && \
    yum install -y mysql && \
    yum clean all

# Copy repository file and script
COPY mongo.repo /etc/yum.repos.d/mongo.repo
COPY run.sh /run.sh

# Set execute permission on the script
RUN chmod +x /run.sh

# Specify the entry point
ENTRYPOINT ["bash", "/run.sh"]


