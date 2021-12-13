#cloud-config
users:
  - default
  - name: node-exporter
    system: true
    lock_passwd: true
  - name: elasticsearch
    system: true
    lock_passwd: true
write_files:
  #Elasticsearch tls files
  - path: /etc/elasticsearch/tls/server.key
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, server_key)}
  - path: /etc/elasticsearch/tls/server.pem
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, join("", [server_certificate, ca_certificate]))}
  - path: /etc/elasticsearch/tls/ca.pem
    owner: root:root
    permissions: "0400"
    content: |
      ${indent(6, ca_certificate)}
  #Elasticsearch configuration files
  - path: /etc/elasticsearch/jvm.options
    owner: root:root
    permissions: "0444"
    content: |
      #Taking the settings as are in the elasticsearch distribution,
      #minus the heap size and settings for previous jdk versions not in use

      #Heap
      -Xms__HEAP_SIZE__m
      -Xmx__HEAP_SIZE__m

      #G1GC Configuration
      14-:-XX:+UseG1GC
      14-:-XX:G1ReservePercent=25
      14-:-XX:InitiatingHeapOccupancyPercent=30

      #JVM temporary directory
      -Djava.io.tmpdir=/opt/es-temp

      #Heap dump
      -XX:+HeapDumpOnOutOfMemoryError
      -XX:HeapDumpPath=data

      #Fatal errors
      -XX:ErrorFile=logs/hs_err_pid%p.log

      # JDK 9+ GC logging
      9-:-Xlog:gc*,gc+age=trace,safepoint:file=logs/gc.log:utctime,pid,tags:filecount=32,filesize=64m
  - path: /etc/elasticsearch/elasticsearch.yml
    owner: root:root
    permissions: "0444"
    content: |
      xpack:
        security:
          enabled: true
          authc:
            anonymous:
              username: anonymous_user
              roles: superuser
              authz_exception: true
          http:
            ssl:
              enabled: true
              key: "/etc/elasticsearch/tls/server.key"
              certificate: "/etc/elasticsearch/tls/server.pem"
              certificate_authorities: ["/etc/elasticsearch/tls/ca.pem"]
          transport:
            ssl:
              enabled: true
              verification_mode: certificate
              key: "/etc/elasticsearch/tls/server.key"
              certificate: "/etc/elasticsearch/tls/server.pem"
              certificate_authorities: ["/etc/elasticsearch/tls/ca.pem"]
      path:
        data: /var/lib/elasticsearch
      network:
        host: 0.0.0.0
      discovery:
        seed_hosts: ${domain}
      node:
        master: ${master ? "true" : "false"}
        data: ${master ? "false" : "true"}
        ingest: ${master ? "false" : "true"}
      cluster:
        name: ${cluster_name}
        initial_master_nodes:
%{ for idx in range(initial_masters_count) ~}
          - ${format("%s%d", base_name, idx + 1)}
%{ endfor ~}
%{ if s3_access_key != "" ~}
      s3:
        client:
          default:
            endpoint: ${s3_endpoint}
            protocol: ${s3_protocol}
            #path_style_access: true
            #signer_override: "S3SignerType"
%{ endif ~}
  #Elasticsearch systemd configuration
  - path: /usr/local/bin/set_es_heap
    owner: root:root
    permissions: "0555"
    content: |
      #!/bin/bash
%{ if master ~}
      HEAP_SIZE=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') * 3 / 4 / 1024 ))
%{ else ~}
      HEAP_SIZE=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 2 / 1024 ))
%{ endif ~}
      sed "s/__HEAP_SIZE__/$HEAP_SIZE/g" -i /etc/elasticsearch/jvm.options
  - path: /etc/systemd/system/elasticsearch.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Elasticsearch"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      Environment=ES_PATH_CONF=/etc/elasticsearch
      Environment=LOG4J_FORMAT_MSG_NO_LOOKUPS=true
      #https://www.elastic.co/guide/en/elasticsearch/reference/current/system-config.html
      LimitNOFILE=65535
      LimitNPROC=4096
      User=elasticsearch
      Group=elasticsearch
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=/opt/es/bin/elasticsearch

      [Install]
      WantedBy=multi-user.target
  #Prometheus node exporter systemd configuration
  - path: /etc/systemd/system/node-exporter.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Prometheus Node Exporter"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      User=node-exporter
      Group=node-exporter
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=/usr/local/bin/node_exporter

      [Install]
      WantedBy=multi-user.target
%{ if s3_access_key != "" ~}
  - path: /opt/setup-s3-snapshot-credentials.sh
    owner: root:root
    permissions: "0500"
    content: |
      #!/bin/sh
      /opt/es/bin/elasticsearch-keystore create
      printf "${s3_access_key}" | /opt/es/bin/elasticsearch-keystore add --stdin --force s3.client.default.access_key
      printf "${s3_secret_key}" | /opt/es/bin/elasticsearch-keystore add --stdin --force s3.client.default.secret_key
%{ endif ~}
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg-agent
  - software-properties-common
  - libdigest-sha-perl
runcmd:
  #Add dns servers
  - echo "DNS=${join(" ", nameserver_ips)}" >> /etc/systemd/resolved.conf
  - systemctl stop systemd-resolved
  - systemctl start systemd-resolved
  #Install elasticsearch
  ##Get elasticsearch executables
  - wget -O /opt/elasticsearch-7.14.1-linux-x86_64.tar.gz https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.14.1-linux-x86_64.tar.gz
  - wget -O /opt/elasticsearch-7.14.1-linux-x86_64.tar.gz.sha512 https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.14.1-linux-x86_64.tar.gz.sha512
  - cd /opt && shasum -a 512 -c elasticsearch-7.14.1-linux-x86_64.tar.gz.sha512
  - tar zxvf /opt/elasticsearch-7.14.1-linux-x86_64.tar.gz -C /opt
  - mv /opt/elasticsearch-7.14.1 /opt/es
  - chown -R elasticsearch:elasticsearch /opt/es
  - rm /opt/elasticsearch-7.14.1-linux-x86_64.tar.gz /opt/elasticsearch-7.14.1-linux-x86_64.tar.gz.sha512
  ##Setup requisite directories, non-templated files and permissions
  - mkdir -p /var/lib/elasticsearch && chown -R elasticsearch:elasticsearch /var/lib/elasticsearch
  - mkdir -p /opt/es-temp && chown -R elasticsearch:elasticsearch /opt/es-temp
  - cp /opt/es/config/log4j2.properties /etc/elasticsearch/log4j2.properties
  - chown -R elasticsearch:elasticsearch /etc/elasticsearch
  ##Runtime configuration adjustments
  - /usr/local/bin/set_es_heap
  - echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
  - echo 'vm.swappiness = 1' >> /etc/sysctl.conf
  - sysctl -p
  ##Install s3 snapshot plugin
%{ if s3_access_key != "" ~}
  - /opt/es/bin/elasticsearch-plugin install --batch repository-s3
  - mkdir -p /home/elasticsearch
  - chown elasticsearch:elasticsearch /home/elasticsearch
  - chown elasticsearch:elasticsearch /opt/setup-s3-snapshot-credentials.sh
  - runuser -l elasticsearch -c '/opt/setup-s3-snapshot-credentials.sh'
  - rm /opt/setup-s3-snapshot-credentials.sh
%{ endif ~}
  ##Launch service
  - systemctl enable elasticsearch
  - systemctl start elasticsearch
  #Install prometheus node exporter as a binary managed as a systemd service
  - wget -O /opt/node_exporter.tar.gz https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
  - mkdir -p /opt/node_exporter
  - tar zxvf /opt/node_exporter.tar.gz -C /opt/node_exporter
  - cp /opt/node_exporter/node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin/node_exporter
  - chown node-exporter:node-exporter /usr/local/bin/node_exporter
  - rm -r /opt/node_exporter && rm /opt/node_exporter.tar.gz
  - systemctl enable node-exporter
  - systemctl start node-exporter