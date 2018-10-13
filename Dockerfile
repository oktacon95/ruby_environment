FROM centos:7

ARG JRUBY_VERSION

ENV RVM_DIRECTORY /usr/local/rvm
ENV JRUBY_VERSION 1.7.27
ENV JRUBY_DIRECTORY $RVM_DIRECTORY/rubies/jruby-$JRUBY_VERSION
ENV PATH=$PATH:$RVM_DIRECTORY/bin:$JRUBY_DIRECTORY/bin

COPY ./files/settings.xml /root/.m2/

# which is needed to install rvm, clean up afterwards
RUN yum install -y which \
	&& yum clean all \
	&& rm -rf /var/cache/yum \
	\
# Install mpapis public key
	&& if ! { `gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3`; } ; then \
 	curl -sSL https://rvm.io/mpapis.asc | gpg --import -; \
  	fi \
  	\
# Install RVM
	&& curl -sSL https://get.rvm.io | bash -s stable \
	\
# Install JRuby and its build-requirements
	&& source /etc/profile \
	&& rvm requirements \
	&& rvm install jruby $JRUBY_VERSION

RUN jruby -S gem install bundler \
	numerizer \
	chronic_duration \
	clamp \
	coderay \
	concurrent-ruby \
	diff-lcs \
	docile \
	multi_json \
	elasticsearch-api \
	multipart-post \
	faraday \
	elasticsearch-transport \
	elasticsearch \
	ffi \
	filesize \
	fivemat:1.3.6 \
	gem_publisher \
	insist \
	jar-dependencies \
	jrjackson \
	jruby-openssl \
	json \
	openssl_pkcs8_pure \
	manticore \
	minitar \
	method_source \
	spoon \
	pry \
	ruby-maven-libs \
	ruby-maven \
	rubyzip \
	tilt \
	stud \
	thread_safe \
	polyglot \
	treetop \
	logstash-core \
	logstash-core-plugin-api \
	rspec-support:3.7.1 \
	rspec-core:3.7.1 \
	rspec-expectations:3.7.0 \
	rspec-mocks:3.7.0 \
	rspec:3.7.0 \
	rspec-wait \
	logstash-devutils \
	simplecov-html \
	simplecov \
	nexus

# create jruby user
RUN groupadd -r jruby -g 1001 \
	&& useradd -u 1001 -r -g jruby -d $JRUBY_DIRECTORY -s /bin/bash -c "jruby user" jruby \
	&& chmod 755 $JRUBY_DIRECTORY \
	&& chown jruby:jruby $JRUBY_DIRECTORY

COPY ./files/poll-filesystem /usr/bin/
COPY ./files/build-gem /usr/bin/
COPY ./files/upload-gem /usr/bin/

RUN chown jruby:jruby /usr/bin/poll-filesystem \
	&& chown jruby:jruby /usr/bin/upload-gem \
	&& chown jruby:jruby /usr/bin/build-gem \
    && chmod +x /usr/bin/upload-gem \
    && chmod +x /usr/bin/build-gem \
    && chmod +x /usr/bin/poll-filesystem

USER jruby

ENTRYPOINT ["/usr/bin/poll-filesystem"]