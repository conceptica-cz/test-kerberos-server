FROM ubuntu:jammy
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y krb5-kdc krb5-admin-server
RUN apt-get clean


WORKDIR /app

COPY init.sh init.sh
RUN chmod +x init.sh

CMD ["/app/init.sh"]