[web_hosts]
%{ for ip in web_hosts ~}
${ip}
%{ endfor ~}
[db_hosts]
%{ for ip in db_hosts ~}
${ip}
%{ endfor ~}