FROM        dokken/centos-8
RUN         yum install epel-release git -y
COPY        mongo.repo /etc/yum.repos.d/mongo.repo
RUN         yum install mysql mongodb-org-shell -y
COPY        run.sh /run.sh
ENTRYPOINT  [ "bash", "/run.sh" ]