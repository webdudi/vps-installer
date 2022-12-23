#!/bin/bash


iptables -A FORWARD -i docker0 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o docker0 -j ACCEPT
iptables -A POSTROUTING -t nat -o eth0 -j MASQUERADE

