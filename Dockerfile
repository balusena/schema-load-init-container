FROM        dokken/centos-8
RUN         yum install epel-release git -y
RUN         yum install mysql mongodb-org-shell -y
COPY        mongo.repo /etc/yum.repos.d/mongo.repo
COPY        run.sh /run.sh
ENTRYPOINT  [ "bash", "/run.sh" ]