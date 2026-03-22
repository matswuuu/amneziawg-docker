# amneziawg-docker
Dockerfile for amneziawg-go

https://hub.docker.com/r/matswuuu/amneziawg-client

```yaml
  amneziawg:
    container_name: amneziawg
    image: matswuuu/amneziawg-client:main
    environment:
      - AWG_INTERFACE=awg0
    volumes:
      - ./config:/etc/amnezia/amneziawg # dir with .conf file
    ports:
      - "51820:51820/udp"
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
```