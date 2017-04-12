This is a Graphite server example on vagrant.
==========================================================================

# Features
	1. install graphite(carbon) 
	2. install statsd node.js version 
	3. install collectd
	4. install grafana

# Execution
```
	vagrant up
	#vagrant destroy -f && vagrant up
```

# Run
```
- graphite
	http://192.168.82.170:8080
	http://192.168.82.170:8080/render?target=test.count&from=-10min&format=json
- grafana
	http://192.168.82.170
	admin / admin
```

# Add datasource in grafana
```
	http://server.tz.com/datasources/new
	Add data source
	Name: graphite
	Default: check
	Url: http://192.168.82.170:8080
```

# Test insert data
```
	$> vagrant ssh

	echo "test.count 4 `date +%s`" | nc -q0 127.0.0.1 2003
	echo "test.count 8 `date +%s`" | nc -q0 127.0.0.1 2003
	echo "test.count 100 `date +%s`" | nc -q0 127.0.0.1 2003
	
	echo "metric_name:metric_value|type_specification" | nc -u -w0 127.0.0.1 8125
	echo "sample.gauge:16|g" | nc -u -w0 127.0.0.1 8125 
	echo "sample.gauge:10|g" | nc -u -w0 127.0.0.1 8125  
	echo "sample.gauge:18|g" | nc -u -w0 127.0.0.1 8125 
	echo "sample.gauge:18|g" | nc -u -w0 127.0.0.1 8125 
	
	echo "sample.set:50|s" | nc -u -w0 127.0.0.1 8125
	echo "sample.set:50|s" | nc -u -w0 127.0.0.1 8125
	echo "sample.set:50|s" | nc -u -w0 127.0.0.1 8125
	echo "sample.set:50|s" | nc -u -w0 127.0.0.1 8125
	echo "sample.set:11|s" | nc -u -w0 127.0.0.1 8125  
	echo "sample.set:11|s" | nc -u -w0 127.0.0.1 8125
	
	echo "test.count 4 `date +%s`" | nc -q0 127.0.0.1 2003
	sleep 10
	echo "test.count 8 `date +%s`" | nc -q0 127.0.0.1 2003
	sleep 10
	echo "test.count 100 `date +%s`" | nc -q0 127.0.0.1 2003
	
	http://192.168.82.170:8080
	
	for i in 4 6 8 16 2; do echo "test.count $i `date +%s`" | nc -q0 127.0.0.1 2003; sleep 6; done
	
	http://192.168.82.170
```

