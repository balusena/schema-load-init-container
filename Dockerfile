FROM dokken/centos-8

# Install necessary packages
RUN yum install -y epel-release git \
    && yum install -y mysql mongodb-org-shell \
    && yum clean all

# Copy repository file and script
COPY mongo.repo /etc/yum.repos.d/mongo.repo
COPY run.sh /run.sh

# Set execute permission on the script
RUN chmod +x /run.sh

# Specify the entry point
ENTRYPOINT ["bash", "/run.sh"]

