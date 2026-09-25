# PROXTEL PBX Standard v1.0

PBX work must begin with a read-only baseline and preserve evidence before mutation.

Architecture must explicitly cover FreePBX, Asterisk, PJSIP, SIP/RTP, endpoints, trunks, carriers, dialplan, routing, Caller ID, failover, recording, QoS, network security, monitoring and rollback.

Production changes must be validated and explicitly authorized. Service restarts, firewall reloads, FreePBX apply actions, carrier changes and deployment are never automatic.

CRM governs CRM-domain records and APIs. Development owns repository code and installer implementation. PBX owns telephony-domain semantics and release validation.
