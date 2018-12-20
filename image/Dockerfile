
FROM node:8-jessie
ENV NODE_ENV=production
RUN mkdir /home/node/app; chown node /home/node/app
RUN mkdir /w; chown node /w
USER node
WORKDIR /home/node/app
RUN git init && git remote add origin git://github.com/c9/core.git ; git fetch origin \
    && git checkout origin/master > /tmp/git_checkout.log 2>&1 \
    && scripts/install-sdk.sh

USER root
RUN apt-get -y update && apt-get -y install git rsync less vim unzip \
  && mkdir -p /etc/sudoers.d \
  && echo "node ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/node \
  && chmod 0440 /etc/sudoers.d/node
ARG TERRAFORM_VERSION=0.11.11
RUN curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin && \
    rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip
COPY entrypoint.sh /home/node/app/
# RUN chown node /home/node/app/entrypoint.sh
RUN chmod +x /home/node/app/entrypoint.sh

USER node
# DOES NOT YET WORK ARG C9COREURL=git://github.com/BrianFlannery/c9core.git
# DOES NOT YET WORK RUN git remote add alt $C9COREURL && git fetch alt && git checkout alt/master
ENV WORKSPACE_USERPW="user1:u1pw"
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' configs/standalone.js
EXPOSE 8181
ENTRYPOINT ["/home/node/app/entrypoint.sh"]
