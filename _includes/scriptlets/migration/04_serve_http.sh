while true; do ( echo "HTTP/1.0 200 Ok"; echo; echo "Migration test" ) | nc -l -p 8080; done
