FROM centos
ADD run.sh /
RUN mkdir -p /usr/local/nginx/html
ADD index.html /usr/local/nginx/html/

VOLUME ["/usr/local/nginx/html"]

CMD ["/run.sh"]
